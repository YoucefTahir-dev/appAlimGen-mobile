import 'dart:async';

import 'package:app_alim_gen_mobile/app/providers.dart';
import 'package:app_alim_gen_mobile/core/errors/app_failure.dart';
import 'package:app_alim_gen_mobile/core/errors/error_mapper.dart';
import 'package:app_alim_gen_mobile/core/session/session_boundary.dart';
import 'package:app_alim_gen_mobile/features/auth/domain/auth_models.dart';
import 'package:app_alim_gen_mobile/features/auth/presentation/auth_controller.dart';
import 'package:app_alim_gen_mobile/features/business_lists/data/business_repositories.dart';
import 'package:app_alim_gen_mobile/features/business_lists/domain/business_entities.dart';
import 'package:app_alim_gen_mobile/features/business_lists/presentation/invoice_detail_screen.dart';
import 'package:app_alim_gen_mobile/features/business_lists/presentation/transaction_form_screens.dart';
import 'package:app_alim_gen_mobile/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _sessionChanged = 'La session a changé. Rouvrez ce formulaire.';
const _user = UserProfile(
  id: 1,
  username: 'synthetic-session-A',
  firstName: '',
  lastName: '',
  email: '',
  phone: '',
  role: 'test',
  permissions: {
    'commerce.change_sale',
    'accounts.view_invoices',
    'accounts.print_invoice',
  },
);

final _sale = SaleDetails.fromJson({
  'id': 41,
  'invoice_number': 'SYNTHETIC-SESSION-A',
  'client_details': {'id': 2, 'name': 'Synthetic client'},
  'lines': [
    {
      'id': 1,
      'product': {'id': 4, 'name': 'Synthetic product'},
      'quantity': 1,
      'unit_price': '10.00',
    },
  ],
  'subtotal': '10.00',
  'discount': '0.00',
  'tax_rate': '0.00',
  'tax_amount': '0.00',
  'total': '10.00',
  'amount_paid': '0.00',
  'balance_due': '10.00',
  'payment_type': 'cash',
});
const _purchase = PurchaseDetails(
  id: 42,
  reference: 'SYNTHETIC-PURCHASE-A',
  supplierId: 3,
  supplierName: 'Synthetic supplier',
  taxRate: '0',
  total: '10.00',
  amountPaid: '0.00',
  balanceDue: '10.00',
  lines: [
    PurchaseLineDetails(
      productId: 4,
      productName: 'Synthetic product',
      quantity: 1,
      purchasePrice: '10.00',
    ),
  ],
);
const _purchaseSummary = PurchaseSummary(
  id: 42,
  reference: 'SYNTHETIC-PURCHASE-A',
  supplierId: 3,
  date: '2026-11-12',
  total: '10.00',
  paymentStatus: 'unpaid',
);
const _payment = PaymentSummary(
  id: 43,
  reference: 'SYNTHETIC-PAYMENT-A',
  amount: '10.00',
  paymentType: 'cash',
  date: '2026-11-12',
);

class _Auth extends AuthController {
  @override
  AuthState build() => const AuthState.authenticated(_user);
}

class _Call {
  const _Call(this.operation, this.payload, this.key, this.cancelToken);
  final String operation;
  final Map<String, dynamic> payload;
  final String key;
  final CancelToken? cancelToken;
}

// These fakes deliberately ignore cancellation while waiting. A cancelled
// transport alone must not let an old completion affect the replacement session.
class _Sales extends SalesRepository {
  _Sales() : super(Dio(), const ErrorMapper());
  final calls = <_Call>[];
  Completer<void>? pending;

  @override
  Future<List<TransactionOption>> searchClients(String query) async => [];
  @override
  Future<List<TransactionOption>> searchProducts(
    String query, {
    int? clientId,
  }) async => [];
  @override
  Future<Map<String, dynamic>> price(
    int productId,
    int clientId, {
    int? packagingId,
  }) async => {'unit_price': '10.00', 'packagings': []};

  Future<SaleDetails> _write(
    String operation,
    SaleWriteRequest request,
    String key,
    CancelToken? cancelToken,
  ) async {
    calls.add(_Call(operation, request.toJson(), key, cancelToken));
    if (pending != null) await pending!.future;
    return _sale;
  }

  @override
  Future<SaleDetails> create(
    SaleWriteRequest request,
    String idempotencyKey, {
    CancelToken? cancelToken,
  }) => _write('sale.create', request, idempotencyKey, cancelToken);
  @override
  Future<SaleDetails> update(
    int id,
    SaleWriteRequest request,
    String idempotencyKey, {
    CancelToken? cancelToken,
  }) => _write('sale.update', request, idempotencyKey, cancelToken);
}

class _Purchases extends PurchasesRepository {
  _Purchases() : super(Dio(), const ErrorMapper());
  final calls = <_Call>[];
  Completer<void>? pending;

  @override
  Future<List<TransactionOption>> searchSuppliers(String query) async => [];
  @override
  Future<List<TransactionOption>> searchProducts(String query) async => [];
  @override
  Future<PurchaseSummary> create(
    PurchaseWriteRequest request,
    String key, {
    CancelToken? cancelToken,
  }) async {
    calls.add(_Call('purchase.create', request.toJson(), key, cancelToken));
    if (pending != null) await pending!.future;
    return _purchaseSummary;
  }

  @override
  Future<PurchaseDetails> update(
    int id,
    PurchaseWriteRequest request,
    String key, {
    CancelToken? cancelToken,
  }) async {
    calls.add(_Call('purchase.update', request.toJson(), key, cancelToken));
    if (pending != null) await pending!.future;
    return _purchase;
  }
}

class _Payments extends PaymentsRepository {
  _Payments() : super(Dio(), const ErrorMapper());
  final calls = <_Call>[];
  Completer<void>? pending;

  @override
  Future<PaymentSummary> create(
    PaymentWriteRequest request,
    String key, {
    CancelToken? cancelToken,
  }) async {
    calls.add(_Call('payment.create', request.toJson(), key, cancelToken));
    if (pending != null) await pending!.future;
    return _payment;
  }
}

class _Navigation extends NavigatorObserver {
  int pushes = 0;
  int pops = 0;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushes++;
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pops++;
    super.didPop(route, previousRoute);
  }
}

enum _Flow { saleCreate, saleUpdate, purchaseCreate, purchaseUpdate, payment }

class _Harness {
  final sales = _Sales();
  final purchases = _Purchases();
  final payments = _Payments();
  final navigation = _Navigation();
  final navigator = GlobalKey<NavigatorState>();
  late final ProviderContainer container;

  List<_Call> get calls => [
    ...sales.calls,
    ...purchases.calls,
    ...payments.calls,
  ];

  Future<void> open(WidgetTester tester, _Flow flow) async {
    container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(_Auth.new),
        salesRepositoryProvider.overrideWithValue(sales),
        purchasesRepositoryProvider.overrideWithValue(purchases),
        paymentsRepositoryProvider.overrideWithValue(payments),
      ],
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          navigatorKey: navigator,
          navigatorObservers: [navigation],
          locale: const Locale('fr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const Scaffold(body: Text('Synthetic session host')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final Widget form = switch (flow) {
      _Flow.saleCreate => const SaleFormScreen(),
      _Flow.saleUpdate => SaleFormScreen(initial: _sale),
      _Flow.purchaseCreate => const PurchaseFormScreen(),
      _Flow.purchaseUpdate => const PurchaseFormScreen(initial: _purchase),
      _Flow.payment => const PaymentFormScreen(
        initialSaleId: 41,
        balanceDue: '10.00',
      ),
    };
    unawaited(
      navigator.currentState!.push<void>(
        MaterialPageRoute(builder: (_) => form),
      ),
    );
    await tester.pumpAndSettle();
    await _prepare(tester, flow);
  }

  void rotate() => container.read(sessionEpochProvider.notifier).rotate();
}

Future<void> _choose(
  WidgetTester tester,
  Finder finder,
  TransactionOption value,
) async {
  // onSelected updates the domain draft; text entry also makes the public
  // Autocomplete's TextFormField valid without opening an asynchronous overlay.
  await tester.enterText(
    find.descendant(of: finder, matching: find.byType(TextFormField)),
    value.label,
  );
  tester.widget<RemoteOptionField>(finder).onSelected(value);
  await tester.pumpAndSettle();
}

Future<void> _prepare(WidgetTester tester, _Flow flow) async {
  switch (flow) {
    case _Flow.saleCreate:
      await _choose(
        tester,
        find.byType(RemoteOptionField).first,
        const TransactionOption(id: 2, label: 'Synthetic client'),
      );
      await _choose(
        tester,
        find.byKey(const ValueKey('sale-product-0')),
        const TransactionOption(id: 4, label: 'Synthetic product'),
      );
      break;
    case _Flow.saleUpdate:
      // The existing draft is already complete. Re-selecting its client here
      // opens the manual-price notice, which would cover the submit button.
      break;
    case _Flow.purchaseCreate:
    case _Flow.purchaseUpdate:
      await _choose(
        tester,
        find.byType(RemoteOptionField).first,
        const TransactionOption(id: 3, label: 'Synthetic supplier'),
      );
      await tester.enterText(
        find.byWidgetPredicate(
          (widget) =>
              widget is TextField &&
              widget.decoration?.labelText == 'Référence',
        ),
        'SYNTHETIC-PURCHASE-A',
      );
      await _choose(
        tester,
        find.byKey(const ValueKey('purchase-product-0')),
        const TransactionOption(
          id: 4,
          label: 'Synthetic product',
          meta: {'purchase_price': '10.00'},
        ),
      );
      break;
    case _Flow.payment:
      break;
  }
  expect(tester.state<FormState>(find.byType(Form)).validate(), isTrue);
  await tester.pump();
  await tester.scrollUntilVisible(
    find.byType(FilledButton),
    350,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

Future<void> _submit(WidgetTester tester) async {
  await tester.tap(find.byType(FilledButton));
  // A pending request renders an indeterminate spinner, so do not settle yet.
  await tester.pump();
}

void _expectStaleForm(WidgetTester tester, _Harness harness, int pushes) {
  expect(find.text(_sessionChanged), findsOneWidget);
  expect(find.byType(AlertDialog), findsNothing);
  expect(find.byType(SnackBar), findsNothing);
  expect(harness.navigation.pushes, pushes);
  expect(harness.navigation.pops, 0);
  expect(find.byType(Form), findsOneWidget);
  expect(tester.takeException(), isNull);
}

void main() {
  for (final flow in _Flow.values) {
    testWidgets('${flow.name}: an open A intention cannot submit in B', (
      tester,
    ) async {
      final harness = _Harness();
      await harness.open(tester, flow);
      final pushes = harness.navigation.pushes;
      harness.rotate();
      await _submit(tester);
      await tester.pumpAndSettle();
      expect(harness.calls, isEmpty);
      _expectStaleForm(tester, harness, pushes);
    });
  }

  for (final flow in [_Flow.saleCreate, _Flow.purchaseCreate, _Flow.payment]) {
    for (final fail in [false, true]) {
      testWidgets(
        '${flow.name}: late ${fail ? 'error' : 'success'} from A stays out of B',
        (tester) async {
          final pending = Completer<void>();
          final harness = _Harness();
          switch (flow) {
            case _Flow.saleCreate:
              harness.sales.pending = pending;
              break;
            case _Flow.purchaseCreate:
              harness.purchases.pending = pending;
              break;
            case _Flow.payment:
              harness.payments.pending = pending;
              break;
            default:
              throw StateError('Unsupported late-completion test flow');
          }
          await harness.open(tester, flow);
          final pushes = harness.navigation.pushes;
          final tokenA = harness.container
              .read(sessionBoundaryProvider)
              .cancelToken;
          await _submit(tester);
          expect(harness.calls, hasLength(1));
          final sent = harness.calls.single;
          expect(sent.key, isNotEmpty);
          expect(sent.cancelToken, same(tokenA));
          expect(sent.cancelToken!.isCancelled, isFalse);
          harness.rotate();
          expect(tokenA.isCancelled, isTrue);
          expect(
            harness.container.read(sessionBoundaryProvider).cancelToken,
            isNot(same(tokenA)),
          );
          if (fail) {
            pending.completeError(
              const AppFailure(
                kind: FailureKind.timeout,
                code: 'SYNTHETIC_SESSION_A_TIMEOUT',
                message: 'Private error belonging to A',
              ),
            );
          } else {
            pending.complete();
          }
          await tester.pumpAndSettle();
          expect(harness.calls, hasLength(1));
          expect(find.text('Private error belonging to A'), findsNothing);
          _expectStaleForm(tester, harness, pushes);
        },
      );
    }
  }

  for (final action in ['Voir facture', 'Imprimer', 'Enregistrer paiement']) {
    testWidgets(
      'sale success dialog cannot open $action for A after rotation',
      (tester) async {
        final harness = _Harness();
        await harness.open(tester, _Flow.saleCreate);
        await _submit(tester);
        // Saving remains busy until this dialog closes. Finish its route
        // animation without waiting for the background spinner to settle.
        await tester.pump(const Duration(milliseconds: 350));
        expect(harness.calls.single.operation, 'sale.create');
        expect(find.byType(AlertDialog), findsOneWidget);
        final pushes = harness.navigation.pushes;
        harness.rotate();
        await tester.tap(find.text(action));
        await tester.pumpAndSettle();
        expect(harness.navigation.pushes, pushes);
        expect(harness.navigation.pops, 1); // Only the original dialog closes.
        expect(find.byType(SaleFormScreen), findsOneWidget);
        expect(find.byType(InvoiceDetailScreen), findsNothing);
        expect(find.byType(PaymentFormScreen), findsNothing);
        expect(find.byType(SnackBar), findsNothing);
        expect(harness.calls, hasLength(1));
        expect(tester.takeException(), isNull);
      },
    );
  }
}
