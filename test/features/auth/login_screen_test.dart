import 'dart:async';

import 'package:app_alim_gen_mobile/core/errors/app_failure.dart';
import 'package:app_alim_gen_mobile/app/providers.dart';
import 'package:app_alim_gen_mobile/core/storage/token_storage.dart';
import 'package:app_alim_gen_mobile/features/auth/data/biometric_auth_service.dart';
import 'package:app_alim_gen_mobile/features/auth/data/biometric_preference_store.dart';
import 'package:app_alim_gen_mobile/features/auth/data/biometric_session_manager.dart';
import 'package:app_alim_gen_mobile/features/auth/domain/auth_models.dart';
import 'package:app_alim_gen_mobile/features/auth/presentation/login_controller.dart';
import 'package:app_alim_gen_mobile/features/auth/presentation/login_screen.dart';
import 'package:app_alim_gen_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _LoginController extends LoginController {
  _LoginController(
    this.completion, {
    this.failure = const AppFailure(
      kind: FailureKind.authentication,
      code: 'AUTHENTICATION_REQUIRED',
      message: 'Identifiants invalides',
    ),
  });
  final Completer<UserProfile> completion;
  final AppFailure failure;
  @override
  LoginState build() => const LoginState();
  @override
  Future<void> submit(String username, String password) async {
    state = const LoginState(status: LoginStatus.submitting);
    try {
      await completion.future;
      state = const LoginState();
    } catch (_) {
      state = LoginState(failure: failure);
    }
  }
}

class _BiometricAuth implements BiometricAuthService {
  const _BiometricAuth(this.deviceAvailability);
  final BiometricAvailability deviceAvailability;

  @override
  Future<BiometricAvailability> availability() async => deviceAvailability;

  @override
  Future<BiometricAuthResult> authenticate({required String reason}) async =>
      BiometricAuthResult.success;
}

Widget _app(
  _LoginController Function() controller, {
  BiometricSessionManager? biometrics,
}) => ProviderScope(
  overrides: [
    loginControllerProvider.overrideWith(controller),
    biometricSessionManagerProvider.overrideWithValue(
      biometrics ??
          BiometricSessionManager(
            const _BiometricAuth(BiometricAvailability.unsupported),
            MemoryBiometricPreferenceStore(),
            MemoryTokenStorage(),
          ),
    ),
  ],
  child: const MaterialApp(
    locale: Locale('fr'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: LoginScreen(),
  ),
);

void main() {
  testWidgets('le premier affichage est idle et sans erreur', (tester) async {
    final completer = Completer<UserProfile>();
    await tester.pumpWidget(_app(() => _LoginController(completer)));
    await tester.pump();

    expect(find.byKey(const Key('login-error')), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('valide les champs obligatoires', (tester) async {
    final completer = Completer<UserProfile>();
    await tester.pumpWidget(_app(() => _LoginController(completer)));
    await tester.tap(find.byKey(const Key('login-button')));
    await tester.pump();
    expect(find.text('Ce champ est obligatoire.'), findsNWidgets(2));
  });

  testWidgets('affiche chargement puis erreur de connexion', (tester) async {
    final completer = Completer<UserProfile>();
    await tester.pumpWidget(_app(() => _LoginController(completer)));
    await tester.enterText(find.byKey(const Key('username')), 'admin');
    await tester.enterText(find.byKey(const Key('password')), 'bad');
    await tester.tap(find.byKey(const Key('login-button')));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    completer.completeError(Exception('invalid'));
    await tester.pump();
    expect(find.byKey(const Key('login-error')), findsOneWidget);
  });

  testWidgets('affiche le timeout uniquement après un vrai submit', (
    tester,
  ) async {
    final completer = Completer<UserProfile>();
    await tester.pumpWidget(
      _app(
        () => _LoginController(
          completer,
          failure: const AppFailure(
            kind: FailureKind.timeout,
            code: 'TIMEOUT',
            message: 'Le serveur met trop de temps à répondre.',
          ),
        ),
      ),
    );
    expect(find.text('Le serveur met trop de temps à répondre.'), findsNothing);

    await tester.enterText(find.byKey(const Key('username')), 'admin');
    await tester.enterText(find.byKey(const Key('password')), 'secret');
    await tester.tap(find.byKey(const Key('login-button')));
    await tester.pump();
    completer.completeError(Exception('timeout'));
    await tester.pump();

    expect(
      find.text('Le serveur met trop de temps à répondre.'),
      findsOneWidget,
    );
  });

  testWidgets('affiche la connexion biométrique seulement avec une session', (
    tester,
  ) async {
    final preferences = MemoryBiometricPreferenceStore();
    await preferences.enableFor(1);
    final tokens = MemoryTokenStorage();
    await tokens.write(const StoredTokens(access: 'a', refresh: 'r'));
    final manager = BiometricSessionManager(
      const _BiometricAuth(BiometricAvailability.available),
      preferences,
      tokens,
    );

    await tester.pumpWidget(
      _app(
        () => _LoginController(Completer<UserProfile>()),
        biometrics: manager,
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('biometric-login-button')), findsOneWidget);
  });
}
