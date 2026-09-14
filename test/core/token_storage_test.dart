import 'package:app_alim_gen_mobile/core/storage/token_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MemoryTokenStorage écrit, lit et efface une session', () async {
    final storage = MemoryTokenStorage();
    expect(await storage.read(), isNull);
    await storage.write(
      const StoredTokens(access: 'access', refresh: 'refresh'),
    );
    expect((await storage.read())?.access, 'access');
    expect((await storage.read())?.refresh, 'refresh');
    await storage.clear();
    expect(await storage.read(), isNull);
  });

  test(
    'SecureTokenStorage persiste la paire dans une écriture logique',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      final storage = SecureTokenStorage(storage: const FlutterSecureStorage());

      await storage.write(
        const StoredTokens(access: 'access-new', refresh: 'refresh-new'),
      );

      final restored = await storage.read();
      expect(restored?.access, 'access-new');
      expect(restored?.refresh, 'refresh-new');
      await storage.clear();
      expect(await storage.read(), isNull);
    },
  );

  test('SecureTokenStorage migre les anciennes clés séparées', () async {
    FlutterSecureStorage.setMockInitialValues({
      'auth.access': 'legacy-access',
      'auth.refresh': 'legacy-refresh',
    });
    final storage = SecureTokenStorage(storage: const FlutterSecureStorage());

    final restored = await storage.read();

    expect(restored?.access, 'legacy-access');
    expect(restored?.refresh, 'legacy-refresh');
  });
}
