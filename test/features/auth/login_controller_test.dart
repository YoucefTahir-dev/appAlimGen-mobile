import 'package:app_alim_gen_mobile/app/providers.dart';
import 'package:app_alim_gen_mobile/core/errors/app_failure.dart';
import 'package:app_alim_gen_mobile/core/storage/token_storage.dart';
import 'package:app_alim_gen_mobile/features/auth/data/auth_repository.dart';
import 'package:app_alim_gen_mobile/features/auth/data/session_repository.dart';
import 'package:app_alim_gen_mobile/features/auth/domain/auth_models.dart';
import 'package:app_alim_gen_mobile/features/auth/presentation/login_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _TimeoutAuthRepository extends AuthRepository {
  _TimeoutAuthRepository()
    : super(dio: Dio(), session: SessionRepository(_UnusedStorage()));

  var calls = 0;

  @override
  Future<LoginResult> login({
    required String username,
    required String password,
  }) async {
    calls++;
    throw const AppFailure(
      kind: FailureKind.timeout,
      code: 'TIMEOUT',
      message: 'Le serveur met trop de temps à répondre.',
    );
  }
}

class _UnusedStorage implements TokenStorage {
  @override
  Future<void> clear() async {}

  @override
  Future<StoredTokens?> read() async => null;

  @override
  Future<void> write(StoredTokens tokens) async {}
}

void main() {
  test(
    'le login reste idle avant toute interaction puis expose son propre timeout',
    () async {
      final repository = _TimeoutAuthRepository();
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      expect(container.read(loginControllerProvider).status, LoginStatus.idle);
      expect(container.read(loginControllerProvider).failure, isNull);
      expect(repository.calls, 0);

      await container
          .read(loginControllerProvider.notifier)
          .submit('admin', 'secret');

      final state = container.read(loginControllerProvider);
      expect(repository.calls, 1);
      expect(state.status, LoginStatus.idle);
      expect(state.failure?.kind, FailureKind.timeout);
      expect(
        state.failure?.message,
        'Le serveur met trop de temps à répondre.',
      );
    },
  );
}
