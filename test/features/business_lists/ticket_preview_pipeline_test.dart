import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:async';

import 'package:app_alim_gen_mobile/app/providers.dart';
import 'package:app_alim_gen_mobile/features/business_lists/data/business_repositories.dart';
import 'package:app_alim_gen_mobile/features/business_lists/domain/invoice_document.dart';
import 'package:app_alim_gen_mobile/features/business_lists/presentation/invoice_preview_screen.dart';
import 'package:app_alim_gen_mobile/features/business_lists/presentation/invoice_document_view.dart';
import 'package:app_alim_gen_mobile/features/printers/data/printer_print_profile_store.dart';
import 'package:app_alim_gen_mobile/features/printers/domain/printer_print_profile.dart';
import 'package:app_alim_gen_mobile/features/printers/domain/printer_summary.dart';
import 'package:app_alim_gen_mobile/features/printers/services/esc_pos_printer_driver.dart';
import 'package:app_alim_gen_mobile/features/printers/services/printer_test_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/printing_fixtures.dart';

class _Invoices extends Mock implements InvoicesRepository {}

class _Driver extends EscPosPrinterDriver {
  Uint8List? rasterBytes;
  final rasterReady = Completer<void>();
  @override
  Uint8List rasterTicket({
    required Uint8List rgba,
    required int width,
    required int height,
    PrinterPrintProfile profile = const PrinterPrintProfile(),
  }) {
    rasterBytes = super.rasterTicket(
      rgba: rgba,
      width: width,
      height: height,
      profile: profile,
    );
    rasterReady.complete();
    return rasterBytes!;
  }
}

class _Locale extends LocaleController {
  _Locale(this.language);
  final String language;
  @override
  Locale build() => Locale(language);
}

class _Profiles implements PrinterPrintProfileStore {
  PrinterPrintProfile profile = const PrinterPrintProfile(pauseMs: 0);
  @override
  Future<PrinterPrintProfile> read(PrinterDetails printer) async => profile;
  @override
  Future<void> save(PrinterDetails printer, PrinterPrintProfile value) async {
    profile = value;
  }
}

void main() {
  for (final width in [58, 80]) {
    for (final information in [false, true]) {
      for (final language in ['fr', 'en']) {
        testWidgets(
          'print action rasterizes displayed 7 products despite another API order ($width/$information/$language)',
          (tester) async {
            final sale = printingSale(information: information);
            final repository = _Invoices();
            final reversedPayload = InvoiceDocumentData(
              sale: sale,
            ).toTicketPayload();
            reversedPayload['items'] = (reversedPayload['items'] as List)
                .reversed
                .toList();
            when(
              () => repository.printData(37, width: width, language: language),
            ).thenAnswer((_) async => reversedPayload);
            final transport = RecordingPrinterTransport();
            final driver = _Driver();
            await tester.pumpWidget(
              ProviderScope(
                overrides: [
                  invoicesRepositoryProvider.overrideWithValue(repository),
                  localeProvider.overrideWith(() => _Locale(language)),
                  printerTestServiceProvider.overrideWithValue(
                    PrinterTestService(transport, driver),
                  ),
                  printerPrintProfileStoreProvider.overrideWithValue(
                    _Profiles(),
                  ),
                ],
                child: MaterialApp(
                  locale: Locale(language),
                  supportedLocales: [Locale(language)],
                  localizationsDelegates: GlobalMaterialLocalizations.delegates,
                  home: InvoicePreviewScreen(
                    sale: sale,
                    canPrint: true,
                    canViewPdf: false,
                    initialPrinter: printingPrinter(width),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            var lastY = double.negativeInfinity;
            for (final name in exampleProductNames) {
              final text = find.textContaining(name);
              expect(text, findsOneWidget);
              final y = tester.getTopLeft(text).dy;
              expect(y, greaterThan(lastY));
              lastY = y;
            }
            await tester.tap(find.byKey(const Key('preview-print-action')));
            // Engine image conversion completes on the real async queue;
            // widget continuations and requested frames also need fake pumps.
            // Alternate both instead of settling the indeterminate spinner.
            for (var i = 0; i < 100 && driver.rasterBytes == null; i++) {
              await tester.pump(const Duration(milliseconds: 16));
              await tester.runAsync(
                () => Future<void>.delayed(const Duration(milliseconds: 10)),
              );
            }
            expect(driver.rasterBytes, isNotNull);
            await tester.pumpAndSettle();
            verify(
              () => repository.printData(37, width: width, language: language),
            ).called(1);
            expect(transport.stream, orderedEquals(driver.rasterBytes!));
            expect(find.text('COMPANY-PRIVATE'), findsOneWidget);
            if (!information) {
              expect(find.textContaining('CLIENT-PRIVATE'), findsNothing);
            }
            expect(transport.events, isNot(contains('disconnect')));
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  for (final width in [58, 80]) {
    for (final information in [false, true]) {
      testWidgets(
        '50-line offscreen preview is captured and reconstructed through all raster bands ($width/$information)',
        (tester) async {
          final sale = printingSale(count: 50, information: information);
          final key = GlobalKey();
          await tester.pumpWidget(
            MaterialApp(
              locale: const Locale('fr'),
              supportedLocales: const [Locale('fr')],
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              home: Scaffold(
                body: SingleChildScrollView(
                  child: RepaintBoundary(
                    key: key,
                    child: InvoiceDocumentView(
                      data: InvoiceDocumentData(sale: sale),
                      paper: width == 58
                          ? InvoicePaper.mm58
                          : InvoicePaper.mm80,
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          expect(boundary.size.height, greaterThan(600));
          expect(
            tester
                .getTopLeft(find.textContaining(sale.lines.last.productName))
                .dy,
            lessThan(tester.getTopLeft(find.text('TOTAL TTC')).dy),
          );
          if (!information) {
            expect(find.text('COMPANY-PRIVATE'), findsOneWidget);
            expect(find.textContaining('CLIENT-PRIVATE'), findsNothing);
            expect(find.textContaining('NIF-PRIVATE'), findsNothing);
          }
          await tester.runAsync(() async {
            final image = await boundary.toImage(
              pixelRatio: (width == 58 ? 384 : 576) / boundary.size.width,
            );
            try {
              final raw = (await image.toByteData(
                format: ui.ImageByteFormat.rawRgba,
              ))!.buffer.asUint8List();
              final bytes = EscPosPrinterDriver().rasterTicket(
                rgba: raw,
                width: image.width,
                height: image.height,
              );
              var offset = 8;
              var sourceRow = 0;
              while (sourceRow < image.height) {
                expect(bytes.sublist(offset, offset + 4), [29, 118, 48, 0]);
                final stride = bytes[offset + 4] + 256 * bytes[offset + 5];
                final rows = bytes[offset + 6] + 256 * bytes[offset + 7];
                expect(rows, inInclusiveRange(1, 128));
                offset += 8;
                for (var row = 0; row < rows; row++, sourceRow++) {
                  for (var byte = 0; byte < stride; byte++) {
                    var expected = 0;
                    for (var bit = 0; bit < 8; bit++) {
                      final x = byte * 8 + bit;
                      if (x >= image.width) break;
                      final at = (sourceRow * image.width + x) * 4;
                      final darkness =
                          (raw[at] * 299 +
                              raw[at + 1] * 587 +
                              raw[at + 2] * 114) ~/
                          1000;
                      if (raw[at + 3] > 32 && darkness < 180) {
                        expected |= 128 >> bit;
                      }
                    }
                    expect(
                      bytes[offset++],
                      expected,
                      reason: 'row $sourceRow byte $byte',
                    );
                  }
                }
              }
              expect(sourceRow, image.height);
              expect(bytes.sublist(offset), [10, 10, 10, 29, 86, 0]);
            } finally {
              image.dispose();
            }
          });
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'local transport settings persist without a printer API mutation',
    (tester) async {
      final profiles = _Profiles();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            printerPrintProfileStoreProvider.overrideWithValue(profiles),
          ],
          child: MaterialApp(
            locale: const Locale('fr'),
            supportedLocales: const [Locale('fr')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: InvoicePreviewScreen(
              sale: printingSale(),
              canPrint: true,
              canViewPdf: false,
              initialPrinter: printingPrinter(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('printer-local-settings')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, '256');
      final save = find.text('Enregistrer sur ce téléphone');
      await tester.scrollUntilVisible(
        save,
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(profiles.profile.chunkBytes, 256);
      expect(find.byKey(const Key('preview-print-action')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
