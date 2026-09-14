import 'dart:async';

import 'package:app_alim_gen_mobile/app/providers.dart';
import 'package:app_alim_gen_mobile/core/network/session_events.dart';
import 'package:app_alim_gen_mobile/core/storage/token_storage.dart';
import 'package:app_alim_gen_mobile/features/auth/data/auth_repository.dart';
import 'package:app_alim_gen_mobile/features/auth/data/session_repository.dart';
import 'package:app_alim_gen_mobile/features/auth/domain/auth_models.dart';
import 'package:app_alim_gen_mobile/features/auth/presentation/auth_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _user = UserProfile(
  id: 1,
  username: 'youcef',
  firstName: 'Youcef',
  lastName: '',
  email: '',
  phone: '',
  role: 'Administrateur',
  permissions: {'accounts.view_dashboard'},
);

class _AuthRepository extends AuthRepository {
  _AuthRepository(SessionRepository session)
    : super(dio: Dio(), session: session);

  var meCalls = 0;

  @override
  Future<UserProfile> me() async {
    meCalls++;
    return _user;
  }
}

Future<AuthState> _settledAuth(ProviderContainer container) {
  final completer = Completer<AuthState>();
  late ProviderSubscription<AuthState> subscription;
  subscription = container.listen<AuthState>(authControllerProvider, (_, next) {
    if (next.status != AuthStatus.restoring && !completer.isCompleted) {
      completer.complete(next);
      subscription.close();
    }
  }, fireImmediately: true);
  return completer.future.timeout(const Duration(seconds: 2));
}

void main() {
  test(
    'une nouvelle instance restaure la session sans nouveau login',
    () async {
      final storage = MemoryTokenStorage();
      await storage.write(
        const StoredTokens(access: 'persisted-access', refresh: 'refresh'),
      );
      final session = SessionRepository(storage);
      final auth = _AuthRepository(session);
      final events = SessionEvents();
      final container = ProviderContainer(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(session),
          authRepositoryProvider.overrideWithValue(auth),
          sessionEventsProvider.overrideWithValue(events),
        ],
      );
      addTearDown(() {
        container.dispose();
        events.dispose();
      });

      final state = await _settledAuth(container);

      expect(state.status, AuthStatus.authenticated);
      expect(state.user?.username, 'youcef');
      expect(auth.meCalls, 1);
    },
  );

  test('sans tokens le démarrage termine sur Login', () async {
    final storage = MemoryTokenStorage();
    final session = SessionRepository(storage);
    final auth = _AuthRepository(session);
    final events = SessionEvents();
    final container = ProviderContainer(
      overrides: [
        sessionRepositoryProvider.overrideWithValue(session),
        authRepositoryProvider.overrideWithValue(auth),
        sessionEventsProvider.overrideWithValue(events),
      ],
    );
    addTearDown(() {
      container.dispose();
      events.dispose();
    });

    final state = await _settledAuth(container);

    expect(state.status, AuthStatus.unauthenticated);
    expect(auth.meCalls, 0);
  });

  test(
    'une expiration globale fournit un message et purge l’état utilisateur',
    () async {
      final storage = MemoryTokenStorage();
      final session = SessionRepository(storage);
      final auth = _AuthRepository(session);
      final events = SessionEvents();
      final container = ProviderContainer(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(session),
          authRepositoryProvider.overrideWithValue(auth),
          sessionEventsProvider.overrideWithValue(events),
        ],
      );
      addTearDown(() {
        container.dispose();
        events.dispose();
      });
      await _settledAuth(container);

      events.notifyExpired();
      await Future<void>.delayed(Duration.zero);

      final state = container.read(authControllerProvider);
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.user, isNull);
      expect(state.failure?.code, 'SESSION_EXPIRED');
    },
  );
}
