import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BiometricPreference {
  const BiometricPreference({required this.userId});
  final int userId;
}

abstract interface class BiometricPreferenceStore {
  Future<BiometricPreference?> read();
  Future<void> enableFor(int userId);
  Future<void> disable();
}

class SecureBiometricPreferenceStore implements BiometricPreferenceStore {
  SecureBiometricPreferenceStore(this._storage);

  static const _key = 'auth.biometric.preference.v1';
  final FlutterSecureStorage _storage;

  @override
  Future<BiometricPreference?> read() async {
    final encoded = await _storage.read(key: _key);
    if (encoded == null || encoded.isEmpty) return null;
    try {
      final data = jsonDecode(encoded);
      final userId = data is Map ? int.tryParse('${data['user_id']}') : null;
      return userId == null ? null : BiometricPreference(userId: userId);
    } on FormatException {
      await disable();
      return null;
    }
  }

  @override
  Future<void> enableFor(int userId) =>
      _storage.write(key: _key, value: jsonEncode({'user_id': userId}));

  @override
  Future<void> disable() => _storage.delete(key: _key);
}

class MemoryBiometricPreferenceStore implements BiometricPreferenceStore {
  BiometricPreference? value;

  @override
  Future<void> disable() async => value = null;

  @override
  Future<void> enableFor(int userId) async {
    value = BiometricPreference(userId: userId);
  }

  @override
  Future<BiometricPreference?> read() async => value;
}
