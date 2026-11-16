import 'dart:io';
import 'dart:typed_data';

import 'package:app_alim_gen_mobile/core/files/invoice_pdf_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory temporary;
  late InvoicePdfCache cache;

  setUp(() async {
    temporary = await Directory.systemTemp.createTemp(
      'invoice-pdf-cache-test-',
    );
    cache = InvoicePdfCache(temporaryDirectory: () async => temporary);
  });

  tearDown(() async {
    if (await temporary.exists()) await temporary.delete(recursive: true);
  });

  test(
    'writes PDFs only inside the FileProvider invoice subdirectory',
    () async {
      final file = await cache.write(
        saleId: 42,
        bytes: Uint8List.fromList('%PDF-fictif'.codeUnits),
      );

      expect(await file.exists(), isTrue);
      expect(file.parent.path, endsWith(InvoicePdfCache.directoryName));
      expect(file.path, matches(RegExp(r'facture_42_[0-9]+\.pdf$')));
    },
  );

  test(
    'replaces older managed PDFs without touching unrelated cache',
    () async {
      final unrelated = File(
        '${temporary.path}${Platform.pathSeparator}keep.txt',
      );
      await unrelated.writeAsString('keep');
      final first = await cache.write(
        saleId: 1,
        bytes: Uint8List.fromList([1, 2, 3]),
      );
      final unmanaged = File(
        '${first.parent.path}${Platform.pathSeparator}keep-inside.txt',
      );
      await unmanaged.writeAsString('keep');

      final second = await cache.write(
        saleId: 2,
        bytes: Uint8List.fromList([4, 5, 6]),
      );

      expect(await first.exists(), isFalse);
      expect(await second.exists(), isTrue);
      expect(await unrelated.exists(), isTrue);
      expect(await unmanaged.exists(), isTrue);
    },
  );

  test('logout cleanup deletes only managed invoice PDFs', () async {
    final managed = await cache.write(
      saleId: 7,
      bytes: Uint8List.fromList([7]),
    );
    final unrelated = File(
      '${managed.parent.path}${Platform.pathSeparator}other.pdf',
    );
    await unrelated.writeAsBytes([8]);

    final deleted = await cache.clear();

    expect(deleted, 1);
    expect(await managed.exists(), isFalse);
    expect(await unrelated.exists(), isTrue);
  });

  test('rejects invalid document identifiers and empty content', () async {
    expect(
      () => cache.write(saleId: 0, bytes: Uint8List.fromList([1])),
      throwsArgumentError,
    );
    expect(
      () => cache.write(saleId: 1, bytes: Uint8List(0)),
      throwsArgumentError,
    );
  });

  test(
    'cleanup remains best effort when the cache directory is unavailable',
    () async {
      final unavailable = InvoicePdfCache(
        temporaryDirectory: () async => throw const FileSystemException('test'),
      );

      expect(await unavailable.clear(), 0);
    },
  );
}
