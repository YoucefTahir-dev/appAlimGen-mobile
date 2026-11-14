import 'dart:async';

import 'package:app_alim_gen_mobile/app/providers.dart';
import 'package:app_alim_gen_mobile/core/errors/app_failure.dart';
import 'package:app_alim_gen_mobile/core/errors/error_mapper.dart';
import 'package:app_alim_gen_mobile/core/session/session_boundary.dart';
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

const _user = UserProfile(
  id: 1,
  username: 'synthetic-receipt-user',
  firstName: '',
  lastName: '',
  email: '',
  phone: '',
  role: 'Gestionnaire',
  permissions: {'commerce.add_customerpayment'},
);
const _account = ReceivableAccount(
  clientId: 7,
  clientName: 'Synthetic customer',
  totalInvoiced: '100.00',
  totalPaid: '0.00',
  balanceDue: '100.00',
  openingBalance: '0.00',
  unreconciledCount: 0,
  invoices: [
    ReceivableInvoice(
      id: 9,
      number: 'SYNTHETIC-INVOICE',
      date: '2026-11-12',
      total: '100.00',
      paid: '0.00',
      balance: '100.00',
      status: 'unpaid',
    ),
  ],
  payments: [],
);

class _Auth extends AuthController {
  @override
  AuthState build() => const AuthState.authenticated(_user);
}

class _Receipts extends ReceivablesRepository {
  _Receipts() : super(Dio(), const ErrorMapper());
  final requests = <Map<String, Object?>>[];
  final cancelTokens = <CancelToken?>[];
  bool failNext = false;
  Completer<void>? next;
  @override
  Future<ReceivableAccount> getAccount(
    int clientId, {
    int page = 1,
    int paymentsPage = 1,
    int openingPage = 1,
  }) async => _account;
  @override
  Future<void> allocatePayment({
    required int clientId,
    required String amount,
    required String paymentType,
    required String idempotencyKey,
    String? createdAt,
    String? externalReference,
    String? notes,
    CancelToken? cancelToken,
  }) async {
    cancelTokens.add(cancelToken);
    requests.add({
      'client': clientId,
      'amount': amount,
      'type': paymentType,
      'key': idempotencyKey,
      'date': createdAt,
      'reference': externalReference,
      'notes': notes,
    });
    final pending = next;
    next = null;
    if (pending != null) return pending.future;
    if (failNext) {
      failNext = false;
      throw const AppFailure(
        kind: FailureKind.timeout,
        code: 'SYNTHETIC_TIMEOUT',
        message: 'Synthetic timeout',
      );
    }
  }
}

Widget _app(_Receipts repository) => ProviderScope(
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
    home: ReceivableDetailScreen(clientId: 7, clientName: 'Synthetic customer'),
  ),
);
Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField).first, '25.00');
}

void main() {
  testWidgets(
    'invalid and excessive amounts stay local before a valid receipt',
    (tester) async {
      final repository = _Receipts();
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();
      await _open(tester);
      for (final amount in ['0', '101.00']) {
        await tester.enterText(find.byType(TextFormField).first, amount);
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();
        expect(repository.requests, isEmpty);
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      await tester.enterText(find.byType(TextFormField).first, '25.00');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(repository.requests, hasLength(1));
      expect(find.byType(AlertDialog), findsNothing);
    },
  );

  testWidgets(
    'an uncertain receipt retry retains its entire key and timestamp',
    (tester) async {
      final repository = _Receipts()..failNext = true;
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();
      await _open(tester);
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      final original = Map<String, Object?>.from(repository.requests.single);
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(repository.requests, hasLength(2));
      expect(repository.requests.last, original);
      expect(DateTime.tryParse(original['date'] as String), isNotNull);
      expect(find.byType(AlertDialog), findsNothing);
    },
  );

  testWidgets(
    'a fresh dialog after success creates a different receipt intention',
    (tester) async {
      final repository = _Receipts();
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();
      for (var i = 0; i < 2; i++) {
        await _open(tester);
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();
      }
      expect(repository.requests, hasLength(2));
      expect(
        repository.requests.first['key'],
        isNot(repository.requests.last['key']),
      );
    },
  );

  testWidgets(
    'captured repeated submit callbacks only send one pending receipt',
    (tester) async {
      final pending = Completer<void>();
      final repository = _Receipts()..next = pending;
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();
      await _open(tester);
      final submit = tester
          .widget<FilledButton>(find.byType(FilledButton))
          .onPressed!;
      submit();
      submit();
      await tester.pump();
      expect(repository.requests, hasLength(1));
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      pending.complete();
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    },
  );

  testWidgets('an old dialog never submits its key under the next session', (
    tester,
  ) async {
    final repository = _Receipts()..failNext = true;
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    await _open(tester);
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ReceivableDetailScreen)),
      listen: false,
    );
    container.read(sessionEpochProvider.notifier).rotate();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(repository.requests, hasLength(1));
    expect(find.textContaining('La session a changé'), findsOneWidget);
    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();
    await _open(tester);
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(repository.requests, hasLength(2));
    expect(
      repository.requests.first['key'],
      isNot(repository.requests.last['key']),
    );
  });

  testWidgets(
    'a completed old-session receipt does not close the current dialog as success',
    (tester) async {
      final pending = Completer<void>();
      final repository = _Receipts()..next = pending;
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();
      await _open(tester);
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(ReceivableDetailScreen)),
        listen: false,
      );
      container.read(sessionEpochProvider.notifier).rotate();
      pending.complete();
      await tester.pumpAndSettle();
      expect(repository.requests, hasLength(1));
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.textContaining('La session a changé'), findsOneWidget);
    },
  );
}
