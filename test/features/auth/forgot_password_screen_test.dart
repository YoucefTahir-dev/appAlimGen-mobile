import 'package:app_alim_gen_mobile/app/providers.dart';
import 'package:app_alim_gen_mobile/core/storage/token_storage.dart';
import 'package:app_alim_gen_mobile/features/auth/data/auth_repository.dart';
import 'package:app_alim_gen_mobile/features/auth/data/session_repository.dart';
import 'package:app_alim_gen_mobile/features/auth/presentation/forgot_password_screen.dart';
import 'package:app_alim_gen_mobile/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository()
    : super(dio: Dio(), session: SessionRepository(MemoryTokenStorage()));

  String? requestedEmail;

  @override
  Future<void> requestPasswordReset(String email) async {
    requestedEmail = email.trim();
  }
}

void main() {
  testWidgets('valide puis affiche toujours le message neutre', (tester) async {
    final repository = _FakeAuthRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(
          locale: Locale('fr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: ForgotPasswordScreen(),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('password-reset-submit')));
    await tester.pump();
    expect(find.text('Ce champ est obligatoire.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('reset-email')),
      'person@example.com',
    );
    await tester.tap(find.byKey(const Key('password-reset-submit')));
    await tester.pumpAndSettle();

    expect(repository.requestedEmail, 'person@example.com');
    expect(find.byKey(const Key('password-reset-success')), findsOneWidget);
  });
}
