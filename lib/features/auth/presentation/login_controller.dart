import 'package:app_alim_gen_mobile/app/providers.dart';
import 'package:app_alim_gen_mobile/core/errors/app_failure.dart';
import 'package:app_alim_gen_mobile/features/auth/presentation/auth_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum LoginStatus { idle, submitting }

class LoginState {
  const LoginState({this.status = LoginStatus.idle, this.failure});
  final LoginStatus status;
  final AppFailure? failure;
  bool get isSubmitting => status == LoginStatus.submitting;
}

class LoginController extends Notifier<LoginState> {
  @override
  LoginState build() => const LoginState();

  Future<void> submit(String username, String password) async {
    if (state.isSubmitting) return;
    _log('LOGIN_SUBMIT');
    state = const LoginState(status: LoginStatus.submitting);
    try {
      final result = await ref
          .read(authRepositoryProvider)
          .login(username: username, password: password);
      state = const LoginState();
      ref.read(authControllerProvider.notifier).completeLogin(result.user);
    } catch (error) {
      state = LoginState(failure: ref.read(errorMapperProvider).map(error));
    }
  }

  void reset() {
    if (state.status != LoginStatus.idle || state.failure != null) {
      state = const LoginState();
    }
  }

  void _log(String event) {
    if (kDebugMode) debugPrint('[AUTH] $event');
  }
}

final loginControllerProvider = NotifierProvider<LoginController, LoginState>(
  LoginController.new,
);
