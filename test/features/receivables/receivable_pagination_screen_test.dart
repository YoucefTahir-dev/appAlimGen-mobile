import 'package:app_alim_gen_mobile/app/providers.dart';
import 'package:app_alim_gen_mobile/core/errors/app_failure.dart';
import 'package:app_alim_gen_mobile/core/errors/error_mapper.dart';
import 'package:app_alim_gen_mobile/features/auth/domain/auth_models.dart';
import 'package:app_alim_gen_mobile/features/auth/presentation/auth_controller.dart';
import 'package:app_alim_gen_mobile/features/receivables/data/receivables_repository.dart';
import 'package:app_alim_gen_mobile/features/receivables/domain/receivable.dart';
import 'package:app_alim_gen_mobile/features/receivables/presentation/receivables_screen.dart';
import 'package:app_alim_gen_mobile/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'receivable_page_fixture.dart';

const _user = UserProfile(
  id: 1,
  username: 'synthetic',
  firstName: '',
  lastName: '',
  email: '',
  phone: '',
  role: 'Vendeur',
  permissions: {'commerce.add_customerpayment'},
);

class _Auth extends AuthController {
  @override
  AuthState build() => const AuthState.authenticated(_user);
}

class _Repository extends ReceivablesRepository {
  _Repository() : super(Dio(), const ErrorMapper());
  final requests = <List<int>>[];
  bool failNext = false, openingOnly = false;
  @override
  Future<ReceivableAccount> getAccount(
    int clientId, {
    int page = 1,
    int paymentsPage = 1,
    int openingPage = 1,
  }) async {
    requests.add([page, paymentsPage, openingPage]);
    if (failNext) {
      failNext = false;
      throw const AppFailure(
        kind: FailureKind.network,
        code: 'SYNTHETIC',
        message: 'Synthetic network error',
      );
    }
    return ReceivableAccount.fromPagedJson(
      accountPageFixture(
        page: page,
        paymentsPage: paymentsPage,
        openingPage: openingPage,
        openingOnly: openingOnly,
      ),
    );
  }
}

Widget _app(_Repository repository) => ProviderScope(
  overrides: [
    authControllerProvider.overrideWith(_Auth.new),
    receivablesRepositoryProvider.overrideWithValue(repository),
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
    home: ReceivableDetailScreen(clientId: 7, clientName: 'Synthetic client'),
  ),
);

Future<void> _tapPage(WidgetTester tester, String key) async {
  final button = find.byKey(ValueKey(key));
  await tester.scrollUntilVisible(button, 400, maxScrolls: 40);
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'three histories navigate independently and replace the displayed page',
    (tester) async {
      final repository = _Repository();
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();
      expect(repository.requests, [
        [1, 1, 1],
      ]);
      // Every invoice on page 1 is paid, but global debt still permits collection.
      expect(find.byType(FloatingActionButton), findsOneWidget);
      await _tapPage(tester, 'invoices-next');
      expect(repository.requests.last, [2, 1, 1]);
      expect(find.text('SYNTH-INVOICE-1'), findsNothing);
      await _tapPage(tester, 'payments-next');
      expect(repository.requests.last, [2, 2, 1]);
      await _tapPage(tester, 'opening-next');
      expect(repository.requests.last, [2, 2, 2]);
      await _tapPage(tester, 'opening-previous');
      expect(repository.requests.last, [2, 2, 1]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'failed next page retries the same target, without accumulating history',
    (tester) async {
      final repository = _Repository();
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();
      repository.failNext = true;
      await _tapPage(tester, 'invoices-next');
      expect(find.text('Synthetic network error'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();
      expect(repository.requests, [
        [1, 1, 1],
        [2, 1, 1],
        [2, 1, 1],
      ]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('shared prior debt remains collectable even without invoices', (
    tester,
  ) async {
    final repository = _Repository()..openingOnly = true;
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(repository.requests, [
      [1, 1, 1],
    ]);
    expect(tester.takeException(), isNull);
  });
}
