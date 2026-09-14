import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StoredTokens {
  const StoredTokens({required this.access, required this.refresh});
  final String access;
  final String refresh;
}

abstract interface class TokenStorage {
  Future<StoredTokens?> read();
  Future<void> write(StoredTokens tokens);
  Future<void> clear();
}

class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage({FlutterSecureStorage? storage})
    : _storage =
          storage ?? const FlutterSecureStorage(aOptions: AndroidOptions());
  static const _accessKey = 'auth.access';
  static const _refreshKey = 'auth.refresh';
  final FlutterSecureStorage _storage;

  @override
  Future<StoredTokens?> read() async {
    final values = await _storage.readAll();
    final access = values[_accessKey];
    final refresh = values[_refreshKey];
    if (access == null ||
        refresh == null ||
        access.isEmpty ||
        refresh.isEmpty) {
      return null;
    }
    return StoredTokens(access: access, refresh: refresh);
  }

  @override
  Future<void> write(StoredTokens tokens) async {
    await _storage.write(key: _refreshKey, value: tokens.refresh);
    await _storage.write(key: _accessKey, value: tokens.access);
  }

  @override
  Future<void> clear() => _storage.deleteAll();
}

class MemoryTokenStorage implements TokenStorage {
  StoredTokens? value;
  @override
  Future<void> clear() async => value = null;
  @override
  Future<StoredTokens?> read() async => value;
  @override
  Future<void> write(StoredTokens tokens) async => value = tokens;
}
