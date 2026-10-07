import 'dart:async';

import 'package:app_alim_gen_mobile/app/providers.dart';
import 'package:app_alim_gen_mobile/core/errors/app_failure.dart';
import 'package:app_alim_gen_mobile/features/auth/domain/auth_models.dart';
import 'package:app_alim_gen_mobile/features/auth/data/biometric_auth_service.dart';
import 'package:app_alim_gen_mobile/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AuthStatus { initializing, unauthenticated, authenticated }

class AuthState {
  const AuthState({
    required this.status,
    this.user,
    this.restoreFailure,
    this.biometricOfferPending = false,
  });
  const AuthState.initializing() : this(status: AuthStatus.initializing);
  const AuthState.unauthenticated({AppFailure? restoreFailure})
    : this(status: AuthStatus.unauthenticated, restoreFailure: restoreFailure);
  const AuthState.authenticated(UserProfile user)
    : this(status: AuthStatus.authenticated, user: user);
  final AuthStatus status;
  final UserProfile? user;
  final AppFailure? restoreFailure;
  final bool biometricOfferPending;
}

class AuthController extends Notifier<AuthState> {
  StreamSubscription<AppFailure>? _expiration;

  @override
  AuthState build() {
    _log('APP_BOOT');
    _expiration = ref.read(sessionEventsProvider).expired.listen((_) {
      _log('UNAUTHENTICATED reason=session_expired');
      state = const AuthState.unauthenticated();
    });
    ref.onDispose(() => _expiration?.cancel());
    Future.microtask(restore);
    return const AuthState.initializing();
  }

  Future<void> restore() async {
    final session = await ref.read(sessionRepositoryProvider).restore();
    if (session == null) {
      _log('TOKEN_NOT_FOUND');
      _log('UNAUTHENTICATED reason=no_session');
      state = const AuthState.unauthenticated();
      return;
    }
    _log('TOKEN_FOUND');
    final biometrics = ref.read(biometricSessionManagerProvider);
    if (await biometrics.hasConfiguredStoredSession()) {
      final result = await biometrics.unlock(reason: _biometricReason());
      if (result != BiometricAuthResult.success) {
        _log('UNAUTHENTICATED reason=biometric_${result.name}');
        state = const AuthState.unauthenticated();
        return;
      }
      _log('BIOMETRIC_AUTHENTICATED');
    }
    await _restoreSession();
  }

  Future<void> _restoreSession() async {
    _log('SESSION_RESTORE');
    try {
      final user = await ref.read(authRepositoryProvider).me();
      _log('AUTHENTICATED source=session_restore');
      state = AuthState.authenticated(user);
    } catch (error) {
      final failure = ref.read(errorMapperProvider).map(error);
      if (failure.kind == FailureKind.authentication) {
        await ref.read(sessionRepositoryProvider).clear();
        _log('UNAUTHENTICATED reason=invalid_session');
        state = const AuthState.unauthenticated();
        return;
      }
      // Une panne réseau ne prouve pas que la session est invalide. Les jetons
      // sont conservés et l'erreur reste interne au bootstrap, jamais au form.
      _log('UNAUTHENTICATED reason=restore_unavailable code=${failure.code}');
      state = AuthState.unauthenticated(restoreFailure: failure);
    }
  }

  void completeLogin(UserProfile user) {
    _log('AUTHENTICATED source=manual_login');
    state = AuthState.authenticated(user);
    Future.microtask(() async {
      final shouldOffer = await ref
          .read(biometricSessionManagerProvider)
          .shouldOfferFor(user.id);
      if (shouldOffer &&
          state.status == AuthStatus.authenticated &&
          state.user?.id == user.id) {
        state = AuthState(
          status: AuthStatus.authenticated,
          user: user,
          biometricOfferPending: true,
        );
      }
    });
  }

  Future<BiometricAuthResult> unlockWithBiometrics() async {
    final manager = ref.read(biometricSessionManagerProvider);
    if (!await manager.canUnlockStoredSession()) {
      return BiometricAuthResult.unavailable;
    }
    final result = await manager.unlock(reason: _biometricReason());
    if (result == BiometricAuthResult.success) await _restoreSession();
    return result;
  }

  Future<BiometricAuthResult> enableBiometrics() async {
    final user = state.user;
    if (user == null) return BiometricAuthResult.unavailable;
    final result = await ref
        .read(biometricSessionManagerProvider)
        .enableFor(userId: user.id, reason: _biometricReason());
    dismissBiometricOffer();
    return result;
  }

  Future<BiometricAuthResult> disableBiometrics() => ref
      .read(biometricSessionManagerProvider)
      .disable(reason: _biometricReason());

  void dismissBiometricOffer() {
    final user = state.user;
    if (state.status == AuthStatus.authenticated && user != null) {
      state = AuthState.authenticated(user);
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    _log('UNAUTHENTICATED reason=logout');
    state = const AuthState.unauthenticated();
  }

  void _log(String event) {
    if (kDebugMode) debugPrint('[AUTH] $event');
  }

  String _biometricReason() =>
      AppLocalizations(ref.read(localeProvider)).text('biometricReason');
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
