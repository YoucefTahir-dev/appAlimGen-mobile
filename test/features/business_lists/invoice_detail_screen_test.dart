import 'dart:convert';
import 'dart:typed_data';

import 'package:app_alim_gen_mobile/app/providers.dart';
import 'package:app_alim_gen_mobile/core/errors/error_mapper.dart';
import 'package:app_alim_gen_mobile/features/auth/domain/auth_models.dart';
import 'package:app_alim_gen_mobile/features/auth/presentation/auth_controller.dart';
import 'package:app_alim_gen_mobile/features/business_lists/data/business_repositories.dart';
import 'package:app_alim_gen_mobile/features/business_lists/presentation/invoice_detail_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _AuthController extends AuthController {
  _AuthController(this.user);
  final UserProfile user;
  @override
  AuthState build() => AuthState.authenticated(user);
}

Widget _app(Set<String> permissions, Map<String, dynamic> capabilities) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1/'))
    ..httpClientAdapter = _InvoiceAdapter(capabilities);
  final user = UserProfile(
    id: 1,
    username: 'tester',
    firstName: '',
    lastName: '',
    email: '',
    phone: '',
    role: 'test',
    permissions: permissions,
  );
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(() => _AuthController(user)),
      invoicesRepositoryProvider.overrideWithValue(
        InvoicesRepository(dio, const ErrorMapper()),
      ),
    ],
    child: const MaterialApp(
      locale: Locale('fr'),
      supportedLocales: [Locale('fr'), Locale('ar'), Locale('en')],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: InvoiceDetailScreen(invoiceId: 7),
    ),
  );
}

void main() {
  const capabilities = {
    'can_update': true,
    'can_delete': false,
    'can_view_invoice': true,
    'can_view_pdf': true,
    'can_print': true,
    'can_add_payment': true,
    'can_cancel': false,
  };

  testWidgets(
    'le détail masque impression, modification et paiement sans permission locale',
    (tester) async {
      await tester.pumpWidget(_app({'accounts.view_invoices'}, capabilities));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('invoice-preview-action')), findsOneWidget);
      expect(find.byKey(const Key('invoice-print-action')), findsNothing);
      expect(find.byKey(const Key('invoice-edit-action')), findsNothing);
      expect(find.byKey(const Key('invoice-payment-action')), findsNothing);
      expect(find.byKey(const Key('invoice-pdf-action')), findsNothing);
    },
  );

  testWidgets(
    'le détail affiche seulement les actions autorisées par API et permissions',
    (tester) async {
      await tester.pumpWidget(
        _app({
          'accounts.view_invoices',
          'accounts.print_invoice',
          'accounts.download_invoice_pdf',
          'commerce.change_sale',
        }, capabilities),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('invoice-print-action')), findsOneWidget);
      expect(find.byKey(const Key('invoice-edit-action')), findsOneWidget);
      expect(find.byKey(const Key('invoice-payment-action')), findsOneWidget);
      expect(find.byKey(const Key('invoice-pdf-action')), findsOneWidget);
    },
  );
}

class _InvoiceAdapter implements HttpClientAdapter {
  _InvoiceAdapter(this.capabilities);
  final Map<String, dynamic> capabilities;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    jsonEncode({
      'success': true,
      'data': {
        'id': 7,
        'invoice_number': 'FAC-2026-000007',
        'ticket_number': 'TCK-7',
        'client': 2,
        'client_details': {
          'id': 2,
          'name': 'Client test',
          'phone': '010203',
          'address': 'Adresse',
          'customer_type_display': 'Détail',
        },
        'created_at': '2026-09-24T09:00:00Z',
        'subtotal': '100.00',
        'discount': '0.00',
        'tax_rate': '0.00',
        'tax_amount': '0.00',
        'total': '100.00',
        'amount_paid': '20.00',
        'balance_due': '80.00',
        'payment_type': 'cash',
        'payment_type_display': 'Espèces',
        'payment_status': 'partial',
        'lines': [
          {
            'id': 1,
            'product': {'id': 3, 'name': 'Produit'},
            'packaging': null,
            'packaging_name': 'Unité',
            'packaging_quantity': 1,
            'quantity': 1,
            'unit_price': '100.00',
            'line_total': '100.00',
          },
        ],
        'payments': [],
        'capabilities': capabilities,
      },
    }),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
  @override
  void close({bool force = false}) {}
}
