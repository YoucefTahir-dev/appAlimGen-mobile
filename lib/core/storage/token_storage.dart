import 'dart:convert';

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
  static const _sessionKey = 'auth.session.v1';
  final FlutterSecureStorage _storage;

  @override
  Future<StoredTokens?> read() async {
    final encoded = await _storage.read(key: _sessionKey);
    if (encoded != null && encoded.isNotEmpty) {
      try {
        final value = jsonDecode(encoded);
        if (value is Map) {
          final access = value['access']?.toString();
          final refresh = value['refresh']?.toString();
          if (access != null &&
              access.isNotEmpty &&
              refresh != null &&
              refresh.isNotEmpty) {
            return StoredTokens(access: access, refresh: refresh);
          }
        }
      } on FormatException {
        await clear();
        return null;
      }
    }

    // Migration transparente depuis le stockage utilisé par les premières APK.
    final access = await _storage.read(key: _accessKey);
    final refresh = await _storage.read(key: _refreshKey);
    if (access == null ||
        refresh == null ||
        access.isEmpty ||
        refresh.isEmpty) {
      return null;
    }
    final tokens = StoredTokens(access: access, refresh: refresh);
    await write(tokens);
    return tokens;
  }

  @override
  Future<void> write(StoredTokens tokens) async {
    // Une seule écriture empêche de lire un access et un refresh de rotations
    // différentes si l'application est interrompue pendant la sauvegarde.
    await _storage.write(
      key: _sessionKey,
      value: jsonEncode({'access': tokens.access, 'refresh': tokens.refresh}),
    );
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _sessionKey);
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
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
