import 'package:local_auth/local_auth.dart';

enum BiometricAvailability { available, unsupported, notEnrolled }

enum BiometricAuthResult {
  success,
  canceled,
  failed,
  temporaryLockout,
  permanentLockout,
  notEnrolled,
  unavailable,
}

abstract interface class BiometricAuthService {
  Future<BiometricAvailability> availability();
  Future<BiometricAuthResult> authenticate({required String reason});
}

class LocalBiometricAuthService implements BiometricAuthService {
  LocalBiometricAuthService({LocalAuthentication? authentication})
    : _authentication = authentication ?? LocalAuthentication();

  final LocalAuthentication _authentication;

  @override
  Future<BiometricAvailability> availability() async {
    try {
      final supported = await _authentication.isDeviceSupported();
      final canCheck = await _authentication.canCheckBiometrics;
      if (!supported || !canCheck) return BiometricAvailability.unsupported;
      final enrolled = await _authentication.getAvailableBiometrics();
      return enrolled.isEmpty
          ? BiometricAvailability.notEnrolled
          : BiometricAvailability.available;
    } on LocalAuthException catch (error) {
      return switch (error.code) {
        LocalAuthExceptionCode.noBiometricsEnrolled ||
        LocalAuthExceptionCode.noCredentialsSet =>
          BiometricAvailability.notEnrolled,
        _ => BiometricAvailability.unsupported,
      };
    }
  }

  @override
  Future<BiometricAuthResult> authenticate({required String reason}) async {
    try {
      final authenticated = await _authentication.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      return authenticated
          ? BiometricAuthResult.success
          : BiometricAuthResult.failed;
    } on LocalAuthException catch (error) {
      return switch (error.code) {
        LocalAuthExceptionCode.userCanceled ||
        LocalAuthExceptionCode.systemCanceled ||
        LocalAuthExceptionCode.userRequestedFallback =>
          BiometricAuthResult.canceled,
        LocalAuthExceptionCode.temporaryLockout =>
          BiometricAuthResult.temporaryLockout,
        LocalAuthExceptionCode.biometricLockout =>
          BiometricAuthResult.permanentLockout,
        LocalAuthExceptionCode.noBiometricsEnrolled ||
        LocalAuthExceptionCode.noCredentialsSet =>
          BiometricAuthResult.notEnrolled,
        LocalAuthExceptionCode.noBiometricHardware ||
        LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable ||
        LocalAuthExceptionCode.uiUnavailable => BiometricAuthResult.unavailable,
        _ => BiometricAuthResult.failed,
      };
    }
  }
}
