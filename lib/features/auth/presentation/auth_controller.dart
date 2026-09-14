import 'dart:async';

import 'package:app_alim_gen_mobile/app/providers.dart';
import 'package:app_alim_gen_mobile/core/errors/app_failure.dart';
import 'package:app_alim_gen_mobile/features/auth/domain/auth_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AuthStatus { restoring, unauthenticated, submitting, authenticated }

class AuthState {
  const AuthState({required this.status, this.user, this.failure});
  const AuthState.restoring() : this(status: AuthStatus.restoring);
  const AuthState.unauthenticated([AppFailure? failure])
    : this(status: AuthStatus.unauthenticated, failure: failure);
  const AuthState.authenticated(UserProfile user)
    : this(status: AuthStatus.authenticated, user: user);
  final AuthStatus status;
  final UserProfile? user;
  final AppFailure? failure;
}

class AuthController extends Notifier<AuthState> {
  StreamSubscription<AppFailure>? _expiration;

  @override
  AuthState build() {
    _expiration = ref
        .read(sessionEventsProvider)
        .expired
        .listen((failure) => state = AuthState.unauthenticated(failure));
    ref.onDispose(() => _expiration?.cancel());
    Future.microtask(restore);
    return const AuthState.restoring();
  }

  Future<void> restore() async {
    final session = await ref.read(sessionRepositoryProvider).restore();
    if (session == null) {
      state = const AuthState.unauthenticated();
      return;
    }
    try {
      state = AuthState.authenticated(
        await ref.read(authRepositoryProvider).me(),
      );
    } catch (error) {
      await ref.read(sessionRepositoryProvider).clear();
      state = AuthState.unauthenticated(
        ref.read(errorMapperProvider).map(error),
      );
    }
  }

  Future<void> login(String username, String password) async {
    state = const AuthState(status: AuthStatus.submitting);
    try {
      final result = await ref
          .read(authRepositoryProvider)
          .login(username: username, password: password);
      state = AuthState.authenticated(result.user);
    } catch (error) {
      state = AuthState.unauthenticated(
        ref.read(errorMapperProvider).map(error),
      );
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AuthState.unauthenticated();
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
