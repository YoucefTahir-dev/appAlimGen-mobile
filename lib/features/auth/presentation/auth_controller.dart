import 'dart:async';

import 'package:app_alim_gen_mobile/app/providers.dart';
import 'package:app_alim_gen_mobile/core/errors/app_failure.dart';
import 'package:app_alim_gen_mobile/features/auth/domain/auth_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AuthStatus { initializing, unauthenticated, authenticated }

class AuthState {
  const AuthState({required this.status, this.user, this.restoreFailure});
  const AuthState.initializing() : this(status: AuthStatus.initializing);
  const AuthState.unauthenticated({AppFailure? restoreFailure})
    : this(status: AuthStatus.unauthenticated, restoreFailure: restoreFailure);
  const AuthState.authenticated(UserProfile user)
    : this(status: AuthStatus.authenticated, user: user);
  final AuthStatus status;
  final UserProfile? user;
  final AppFailure? restoreFailure;
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
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    _log('UNAUTHENTICATED reason=logout');
    state = const AuthState.unauthenticated();
  }

  void _log(String event) {
    if (kDebugMode) debugPrint('[AUTH] $event');
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
