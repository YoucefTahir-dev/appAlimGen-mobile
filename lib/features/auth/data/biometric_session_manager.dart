import 'package:app_alim_gen_mobile/core/storage/token_storage.dart';
import 'package:app_alim_gen_mobile/features/auth/data/biometric_auth_service.dart';
import 'package:app_alim_gen_mobile/features/auth/data/biometric_preference_store.dart';

class BiometricSessionManager {
  const BiometricSessionManager(
    this._authentication,
    this._preferences,
    this._tokens,
  );

  final BiometricAuthService _authentication;
  final BiometricPreferenceStore _preferences;
  final TokenStorage _tokens;

  Future<BiometricAvailability> availability() =>
      _authentication.availability();

  Future<bool> canUnlockStoredSession() async {
    if (!await hasConfiguredStoredSession()) return false;
    return await availability() == BiometricAvailability.available;
  }

  Future<bool> hasConfiguredStoredSession() async =>
      await _preferences.read() != null && await _tokens.read() != null;

  Future<bool> isEnabledFor(int userId) async =>
      (await _preferences.read())?.userId == userId;

  Future<bool> shouldOfferFor(int userId) async =>
      !await isEnabledFor(userId) &&
      await availability() == BiometricAvailability.available;

  Future<BiometricAuthResult> unlock({required String reason}) =>
      _authentication.authenticate(reason: reason);

  Future<BiometricAuthResult> enableFor({
    required int userId,
    required String reason,
  }) async {
    if (await availability() != BiometricAvailability.available) {
      return BiometricAuthResult.unavailable;
    }
    final result = await unlock(reason: reason);
    if (result == BiometricAuthResult.success) {
      await _preferences.enableFor(userId);
    }
    return result;
  }

  Future<BiometricAuthResult> disable({required String reason}) async {
    final result = await unlock(reason: reason);
    if (result == BiometricAuthResult.success) {
      await _preferences.disable();
    }
    return result;
  }
}
