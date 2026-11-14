import 'package:app_alim_gen_mobile/features/printers/data/printer_print_profile_store.dart';
import 'package:app_alim_gen_mobile/features/printers/domain/printer_print_profile.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/printing_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('absent local profile retains the compatibility defaults', () async {
    const store = LocalPrinterPrintProfileStore(FlutterSecureStorage());
    final profile = await store.read(printingPrinter());
    expect(profile.toJson(), const PrinterPrintProfile().toJson());
  });

  test('profile persists all settings and is scoped to a printer', () async {
    const store = LocalPrinterPrintProfileStore(FlutterSecureStorage());
    const expected = PrinterPrintProfile(
      chunkBytes: 256,
      pauseMs: 20,
      rasterBandRows: 64,
      feedLines: 5,
      cutPaper: false,
    );
    await store.save(printingPrinter(), expected);
    expect((await store.read(printingPrinter())).toJson(), expected.toJson());
    const storage = FlutterSecureStorage();
    final saved = await storage.readAll();
    expect(saved.keys, ['printing.profile.v1.AA:BB:CC:DD:EE:FF']);
  });

  for (final corrupt in ['not json', '{"chunk_bytes":0}', '[]']) {
    test('corrupt local profile falls back safely: $corrupt', () async {
      const storage = FlutterSecureStorage();
      await storage.write(
        key: 'printing.profile.v1.AA:BB:CC:DD:EE:FF',
        value: corrupt,
      );
      const store = LocalPrinterPrintProfileStore(storage);
      expect(
        (await store.read(printingPrinter())).toJson(),
        const PrinterPrintProfile().toJson(),
      );
    });
  }

  test('invalid tuning is rejected before any persistence', () async {
    const store = LocalPrinterPrintProfileStore(FlutterSecureStorage());
    expect(
      () => store.save(
        printingPrinter(),
        const PrinterPrintProfile(feedLines: 0),
      ),
      throwsArgumentError,
    );
    expect(await const FlutterSecureStorage().readAll(), isEmpty);
  });
}
