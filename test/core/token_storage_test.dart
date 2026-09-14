import 'package:app_alim_gen_mobile/core/storage/token_storage.dart';
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
}
