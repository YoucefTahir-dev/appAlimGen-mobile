import 'dart:io';

import 'package:path_provider/path_provider.dart';

typedef TemporaryDirectoryResolver = Future<Directory> Function();

class InvoicePdfCache {
  InvoicePdfCache({TemporaryDirectoryResolver? temporaryDirectory})
    : _temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory;

  static const directoryName = 'invoice-pdfs';
  static final _managedName = RegExp(r'^facture_[0-9]+_[0-9]+\.pdf$');

  final TemporaryDirectoryResolver _temporaryDirectory;

  Future<File> write({required int saleId, required List<int> bytes}) async {
    if (saleId <= 0) throw ArgumentError.value(saleId, 'saleId');
    if (bytes.isEmpty) throw ArgumentError.value(bytes, 'bytes');
    await clear();
    final root = await _root(create: true);
    final file = File(
      '${root.path}${Platform.pathSeparator}'
      'facture_${saleId}_${DateTime.now().microsecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<int> clear() async {
    var deleted = 0;
    try {
      final root = await _root(create: false);
      if (!await root.exists()) return 0;
      await for (final entry in root.list(followLinks: false)) {
        if (entry is! File || !_managedName.hasMatch(_basename(entry.path))) {
          continue;
        }
        try {
          await entry.delete();
          deleted++;
        } on FileSystemException {
          // A viewer may still hold the document. A later lifecycle cleanup
          // retries without deleting unrelated cache content.
        }
      }
    } catch (_) {
      // Cache cleanup is best effort and must never block local logout.
    }
    return deleted;
  }

  Future<Directory> _root({required bool create}) async {
    final cache = await _temporaryDirectory();
    final root = Directory(
      '${cache.path}${Platform.pathSeparator}$directoryName',
    );
    if (create) await root.create(recursive: true);
    return root;
  }

  String _basename(String path) => path.split(Platform.pathSeparator).last;
}
