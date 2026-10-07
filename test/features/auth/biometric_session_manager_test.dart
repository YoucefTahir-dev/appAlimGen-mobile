import 'package:app_alim_gen_mobile/core/storage/token_storage.dart';
import 'package:app_alim_gen_mobile/features/auth/data/biometric_auth_service.dart';
import 'package:app_alim_gen_mobile/features/auth/data/biometric_preference_store.dart';
import 'package:app_alim_gen_mobile/features/auth/data/biometric_session_manager.dart';
import 'package:flutter_test/flutter_test.dart';

class _BiometricAuth implements BiometricAuthService {
  _BiometricAuth();

  BiometricAvailability deviceAvailability = BiometricAvailability.available;
  BiometricAuthResult result = BiometricAuthResult.success;
  var authenticateCalls = 0;

  @override
  Future<BiometricAvailability> availability() async => deviceAvailability;

  @override
  Future<BiometricAuthResult> authenticate({required String reason}) async {
    authenticateCalls++;
    return result;
  }
}

void main() {
  late _BiometricAuth authentication;
  late MemoryBiometricPreferenceStore preferences;
  late MemoryTokenStorage tokens;
  late BiometricSessionManager manager;

  setUp(() {
    authentication = _BiometricAuth();
    preferences = MemoryBiometricPreferenceStore();
    tokens = MemoryTokenStorage();
    manager = BiometricSessionManager(authentication, preferences, tokens);
  });

  test('ne propose pas la biométrie sur un appareil non compatible', () async {
    authentication.deviceAvailability = BiometricAvailability.unsupported;

    expect(await manager.shouldOfferFor(7), isFalse);
  });

  test('ne propose pas la biométrie sans empreinte enregistrée', () async {
    authentication.deviceAvailability = BiometricAvailability.notEnrolled;

    expect(await manager.shouldOfferFor(7), isFalse);
  });

  test('active uniquement après une authentification réussie', () async {
    expect(
      await manager.enableFor(userId: 7, reason: 'Test'),
      BiometricAuthResult.success,
    );
    expect(await manager.isEnabledFor(7), isTrue);
    expect(authentication.authenticateCalls, 1);
  });

  test('un échec ou une annulation ne mémorise pas la préférence', () async {
    for (final result in [
      BiometricAuthResult.failed,
      BiometricAuthResult.canceled,
      BiometricAuthResult.temporaryLockout,
      BiometricAuthResult.permanentLockout,
    ]) {
      authentication.result = result;
      expect(await manager.enableFor(userId: 7, reason: 'Test'), result);
      expect(await manager.isEnabledFor(7), isFalse);
    }
  });

  test('la connexion biométrique exige préférence et session', () async {
    await preferences.enableFor(7);
    expect(await manager.canUnlockStoredSession(), isFalse);

    await tokens.write(const StoredTokens(access: 'a', refresh: 'r'));
    expect(await manager.canUnlockStoredSession(), isTrue);

    await manager.disable(reason: 'Test');
    expect(await manager.canUnlockStoredSession(), isFalse);
  });

  test('désactiver supprime seulement la préférence biométrique', () async {
    await preferences.enableFor(7);
    await tokens.write(const StoredTokens(access: 'a', refresh: 'r'));

    expect(await manager.disable(reason: 'Test'), BiometricAuthResult.success);

    expect(await manager.isEnabledFor(7), isFalse);
    expect(await tokens.read(), isNotNull);
  });

  test('un échec biométrique interdit la désactivation', () async {
    await preferences.enableFor(7);
    authentication.result = BiometricAuthResult.failed;

    expect(await manager.disable(reason: 'Test'), BiometricAuthResult.failed);
    expect(await manager.isEnabledFor(7), isTrue);
  });
}
