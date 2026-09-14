import 'package:app_alim_gen_mobile/core/storage/token_storage.dart';
import 'package:app_alim_gen_mobile/features/auth/data/session_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SessionRepository délègue la persistance sécurisée', () async {
    final storage = MemoryTokenStorage();
    final repository = SessionRepository(storage);
    await repository.save(const StoredTokens(access: 'a', refresh: 'r'));
    expect((await repository.restore())?.access, 'a');
    await repository.clear();
    expect(await repository.restore(), isNull);
  });
}
