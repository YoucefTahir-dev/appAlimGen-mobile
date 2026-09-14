import 'package:app_alim_gen_mobile/core/storage/token_storage.dart';

class SessionRepository {
  const SessionRepository(this._storage);
  final TokenStorage _storage;
  Future<StoredTokens?> restore() => _storage.read();
  Future<void> save(StoredTokens tokens) => _storage.write(tokens);
  Future<void> clear() => _storage.clear();
}
