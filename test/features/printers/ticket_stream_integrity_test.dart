import 'dart:typed_data';

import 'package:app_alim_gen_mobile/features/business_lists/domain/invoice_document.dart';
import 'package:app_alim_gen_mobile/features/printers/domain/printer_print_profile.dart';
import 'package:app_alim_gen_mobile/features/printers/services/esc_pos_printer_driver.dart';
import 'package:app_alim_gen_mobile/features/printers/services/printer_test_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/printing_fixtures.dart';

void main() {
  final driver = EscPosPrinterDriver();
  for (final count in [1, 4, 7, 20, 50]) {
    for (final width in [58, 80]) {
      for (final information in [true]) {
        test(
          '$count products / $width mm / info $information: complete ordered stream',
          () async {
            final sale = printingSale(count: count, information: information);
            final document = InvoiceDocumentData(sale: sale);
            final payload = document.toTicketPayload();
            expect(
              (payload['items'] as List).map((dynamic item) => item['name']),
              sale.lines.map((line) => line.productName),
            );
            final bytes = driver.invoiceTicket(
              data: payload,
              paperWidth: width,
            );
            final transport = RecordingPrinterTransport();
            final pauses = <Duration>[];
            final progress = <int>[];
            final stages = <PrinterTestStage>[];
            final service = PrinterTestService(
              transport,
              driver,
              pause: (duration) async {
                pauses.add(duration);
              },
            );
            const profile = PrinterPrintProfile(chunkBytes: 128, pauseMs: 7);
            await service.send(
              printer: printingPrinter(width),
              bytes: bytes,
              profile: profile,
              onStage: stages.add,
              onProgress: (sent, _) => progress.add(sent),
            );

            expect(transport.stream, orderedEquals(bytes));
            expect(transport.maxConcurrentWrites, 1);
            expect(
              transport.chunks.every(
                (chunk) =>
                    chunk.isNotEmpty && chunk.length <= profile.chunkBytes,
              ),
              isTrue,
            );
            expect(
              transport.chunks.length,
              (bytes.length / profile.chunkBytes).ceil(),
            );
            expect(progress.last, bytes.length);
            expect(progress.toSet().length, progress.length);
            expect(stages.last, PrinterTestStage.sent);
            expect(pauses.length, transport.chunks.length - 1);
            expect(
              pauses.every((pause) => pause.inMilliseconds == profile.pauseMs),
              isTrue,
            );
            expect(transport.events, isNot(contains('disconnect')));

            final text = String.fromCharCodes(transport.stream);
            var previous = -1;
            for (var index = 0; index < sale.lines.length; index++) {
              final line = sale.lines[index];
              final at = text.indexOf(line.productName);
              expect(at, greaterThan(previous), reason: line.productName);
              expect(line.productName.allMatches(text).length, 1);
              previous = at;
              final next = index + 1 < sale.lines.length
                  ? text.indexOf(sale.lines[index + 1].productName)
                  : text.indexOf(information ? 'TOTAL TTC' : 'TOTAL GENERAL');
              expect(next, greaterThan(at));
              final productBlock = text.substring(at, next);
              // A 58 mm line can wrap the packaging label mid-word. All of
              // its characters must still be in this product's own block.
              expect(
                productBlock.replaceAll('\n', ''),
                contains(line.packagingName),
              );
              expect(productBlock, contains(line.unitPrice));
              expect(productBlock, contains(line.total));
              expect(
                productBlock,
                contains(
                  information
                      ? '${line.quantity} x ${line.unitPrice}'
                      : 'Qte: ${line.quantity}\n',
                ),
              );
            }
            expect(
              text.indexOf(information ? 'TOTAL TTC' : 'TOTAL GENERAL'),
              greaterThan(previous),
            );
            expect(text, contains(sale.total));
            if (count == 7) expect(sale.total, '140960.00');
            if (!information) {
              for (final secret in [
                'INVOICE-PRIVATE',
                'TICKET-PRIVATE',
                'CLIENT-PRIVATE',
                'COMPANY-PRIVATE',
                'NIF-PRIVATE',
                'PAYMENT-PRIVATE',
                'Merci',
              ]) {
                expect(text, isNot(contains(secret)));
              }
            }
            // Final line is terminated and advanced BEFORE any optional cut.
            expect(bytes.sublist(bytes.length - 6), [10, 10, 10, 29, 86, 0]);
          },
        );
      }
    }
  }

  test(
    'slow writes and two simultaneous jobs cannot interleave their chunks',
    () async {
      final transport = RecordingPrinterTransport(
        writeLatency: const Duration(milliseconds: 3),
      );
      final service = PrinterTestService(transport, driver);
      final first = Uint8List.fromList(List.filled(180, 65));
      final second = Uint8List.fromList(List.filled(150, 66));
      const profile = PrinterPrintProfile(chunkBytes: 64, pauseMs: 0);
      await Future.wait([
        service.send(
          printer: printingPrinter(),
          bytes: first,
          profile: profile,
        ),
        service.send(
          printer: printingPrinter(),
          bytes: second,
          profile: profile,
        ),
      ]);
      expect(transport.stream, orderedEquals([...first, ...second]));
      expect(transport.maxConcurrentWrites, 1);
      expect(transport.events.where((event) => event == 'connect').length, 2);
    },
  );

  test(
    'failed chunk stops the job, preserves progress and allows next job',
    () async {
      final transport = RecordingPrinterTransport()
        ..failAt = 3
        ..cleanupFails = true;
      final service = PrinterTestService(transport, driver);
      final bytes = Uint8List.fromList(List.generate(500, (i) => i % 256));
      final stages = <PrinterTestStage>[];
      const profile = PrinterPrintProfile(chunkBytes: 64, pauseMs: 0);
      await expectLater(
        service.send(
          printer: printingPrinter(),
          bytes: bytes,
          profile: profile,
          onStage: stages.add,
        ),
        throwsA(
          isA<PrinterTransmissionException>()
              .having((e) => e.sentBytes, 'completed bytes', 128)
              .having((e) => e.totalBytes, 'total', 500)
              .having(
                (e) => e.cause.toString(),
                'original error',
                contains('simulated link loss'),
              ),
        ),
      );
      expect(transport.attempts, 3);
      expect(transport.stream, orderedEquals(bytes.sublist(0, 128)));
      expect(stages, isNot(contains(PrinterTestStage.sent)));
      expect(transport.events.last, 'disconnect');
      transport.failAt = null;
      await service.send(
        printer: printingPrinter(),
        bytes: Uint8List.fromList([99]),
        profile: profile,
      );
      expect(transport.stream.last, 99);
    },
  );

  test(
    'bytes queued by a caller are copied before any async operation',
    () async {
      final transport = RecordingPrinterTransport();
      final service = PrinterTestService(transport, driver);
      final bytes = Uint8List.fromList([1, 2, 3]);
      final future = service.send(printer: printingPrinter(), bytes: bytes);
      bytes.fillRange(0, bytes.length, 99);
      await future;
      expect(transport.stream, orderedEquals([1, 2, 3]));
    },
  );

  test('feed-only profile omits cut and preserves the final total', () {
    final bytes = driver.invoiceTicket(
      data: InvoiceDocumentData(
        sale: printingSale(information: true),
      ).toTicketPayload(),
      paperWidth: 80,
      profile: const PrinterPrintProfile(feedLines: 5, cutPaper: false),
    );
    expect(bytes.sublist(bytes.length - 5), [10, 10, 10, 10, 10]);
    expect(String.fromCharCodes(bytes), contains('140960.00'));
    expect(
      String.fromCharCodes(bytes),
      isNot(contains(String.fromCharCodes([29, 86, 0]))),
    );
  });

  for (final width in [384, 576]) {
    test(
      'raster rows remain distinct and reconstruct without missing band pixels ($width dots)',
      () {
        const height = 385;
        final rgba = Uint8List(width * height * 4)
          ..fillRange(0, width * height * 4, 255);
        final expected = <int>[];
        for (var y = 0; y < height; y++) {
          final marker = 0x80 >> (y % 8);
          expected.add(marker);
          final index = (y * width + y % 8) * 4;
          rgba[index] = rgba[index + 1] = rgba[index + 2] = 0;
        }
        final bytes = driver.rasterTicket(
          rgba: rgba,
          width: width,
          height: height,
        );
        var offset = 8;
        final rows = <int>[];
        final heights = <int>[];
        while (offset < bytes.length &&
            bytes[offset] == 29 &&
            bytes[offset + 1] == 118) {
          expect(bytes.sublist(offset, offset + 4), [29, 118, 48, 0]);
          final stride = bytes[offset + 4] + 256 * bytes[offset + 5];
          final bandHeight = bytes[offset + 6] + 256 * bytes[offset + 7];
          expect(stride, width ~/ 8);
          heights.add(bandHeight);
          offset += 8;
          for (var y = 0; y < bandHeight; y++) {
            rows.add(bytes[offset]);
            expect(
              bytes
                  .sublist(offset + 1, offset + stride)
                  .every((byte) => byte == 0),
              isTrue,
            );
            offset += stride;
          }
        }
        expect(heights, [128, 128, 128, 1]);
        expect(rows, orderedEquals(expected));
        expect(bytes.sublist(offset), [10, 10, 10, 29, 86, 0]);
      },
    );
  }
}
