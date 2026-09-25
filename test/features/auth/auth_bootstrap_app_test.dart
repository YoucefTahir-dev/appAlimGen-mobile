import 'package:app_alim_gen_mobile/app/app.dart';
import 'package:app_alim_gen_mobile/app/providers.dart';
import 'package:app_alim_gen_mobile/core/network/session_events.dart';
import 'package:app_alim_gen_mobile/core/storage/token_storage.dart';
import 'package:app_alim_gen_mobile/features/auth/data/auth_repository.dart';
import 'package:app_alim_gen_mobile/features/auth/data/session_repository.dart';
import 'package:app_alim_gen_mobile/features/auth/domain/auth_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoLoginAuthRepository extends AuthRepository {
  _NoLoginAuthRepository(SessionRepository session)
    : super(dio: Dio(), session: session);

  var loginCalls = 0;
  var meCalls = 0;

  @override
  Future<LoginResult> login({
    required String username,
    required String password,
  }) async {
    loginCalls++;
    throw StateError('Aucun login automatique attendu.');
  }

  @override
  Future<UserProfile> me() async {
    meCalls++;
    throw StateError('Aucun /auth/me/ sans jeton.');
  }
}

void main() {
  testWidgets('stockage vide ouvre un Login idle sans requête automatique', (
    tester,
  ) async {
    final storage = MemoryTokenStorage();
    final session = SessionRepository(storage);
    final repository = _NoLoginAuthRepository(session);
    final events = SessionEvents();
    addTearDown(events.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(storage),
          sessionRepositoryProvider.overrideWithValue(session),
          authRepositoryProvider.overrideWithValue(repository),
          sessionEventsProvider.overrideWithValue(events),
        ],
        child: const ElAmineApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Connexion'), findsOneWidget);
    expect(find.byKey(const Key('login-error')), findsNothing);
    expect(repository.loginCalls, 0);
    expect(repository.meCalls, 0);
  });
}
