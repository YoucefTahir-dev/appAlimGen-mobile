import 'dart:io';

import 'package:app_alim_gen_mobile/core/files/invoice_pdf_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test('manifest explicitly disables backup and data transfer', () {
    final manifest = read('android/app/src/main/AndroidManifest.xml');

    expect(manifest, contains('android:allowBackup="false"'));
    expect(manifest, contains('android:fullBackupContent="@xml/backup_rules"'));
    expect(
      manifest,
      contains('android:dataExtractionRules="@xml/data_extraction_rules"'),
    );
  });

  test('backup rule sets exclude every supported private-data domain', () {
    final legacy = read('android/app/src/main/res/xml/backup_rules.xml');
    final modern = read(
      'android/app/src/main/res/xml/data_extraction_rules.xml',
    );
    const domains = {
      'root',
      'file',
      'database',
      'sharedpref',
      'external',
      'device_root',
      'device_file',
      'device_database',
      'device_sharedpref',
    };

    for (final domain in domains) {
      expect(legacy, contains('<exclude domain="$domain" path="." />'));
      expect(
        RegExp(
          RegExp.escape('<exclude domain="$domain" path="." />'),
        ).allMatches(modern),
        hasLength(2),
      );
    }
    expect(modern, contains('<cloud-backup>'));
    expect(modern, contains('<device-transfer>'));
  });

  test('FileProvider exposes only the managed invoice PDF directory', () {
    final manifest = read('android/app/src/main/AndroidManifest.xml');
    final paths = read('android/app/src/main/res/xml/file_paths.xml');
    final activity = read(
      'android/app/src/main/kotlin/com/elamine/erp/MainActivity.kt',
    );

    expect(manifest, contains('android:exported="false"'));
    expect(manifest, contains('android:grantUriPermissions="true"'));
    expect(paths, contains('path="${InvoicePdfCache.directoryName}/"'));
    expect(paths, isNot(contains('<cache-path name="invoice_pdfs" path="."')));
    expect(activity, contains('File(cacheDir, "invoice-pdfs").canonicalFile'));
    expect(activity, contains('Intent.FLAG_GRANT_READ_URI_PERMISSION'));
    expect(activity, isNot(contains('Intent.FLAG_GRANT_WRITE_URI_PERMISSION')));
  });
}
