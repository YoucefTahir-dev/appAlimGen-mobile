import 'dart:async';

import 'package:app_alim_gen_mobile/core/errors/app_failure.dart';
import 'package:app_alim_gen_mobile/features/auth/domain/auth_models.dart';
import 'package:app_alim_gen_mobile/features/auth/presentation/auth_controller.dart';
import 'package:app_alim_gen_mobile/features/auth/presentation/login_screen.dart';
import 'package:app_alim_gen_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _LoginController extends AuthController {
  _LoginController(this.completion);
  final Completer<UserProfile> completion;
  @override
  AuthState build() => const AuthState.unauthenticated();
  @override
  Future<void> login(String username, String password) async {
    state = const AuthState(status: AuthStatus.submitting);
    try {
      state = AuthState.authenticated(await completion.future);
    } catch (_) {
      state = const AuthState.unauthenticated(
        AppFailure(
          kind: FailureKind.authentication,
          code: 'AUTHENTICATION_REQUIRED',
          message: 'Identifiants invalides',
        ),
      );
    }
  }
}

Widget _app(_LoginController Function() controller) => ProviderScope(
  overrides: [authControllerProvider.overrideWith(controller)],
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
}
