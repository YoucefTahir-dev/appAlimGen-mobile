import 'dart:convert';
import 'dart:typed_data';

import 'package:app_alim_gen_mobile/app/providers.dart';
import 'package:app_alim_gen_mobile/core/errors/error_mapper.dart';
import 'package:app_alim_gen_mobile/features/auth/domain/auth_models.dart';
import 'package:app_alim_gen_mobile/features/auth/presentation/auth_controller.dart';
import 'package:app_alim_gen_mobile/features/business_lists/data/business_repositories.dart';
import 'package:app_alim_gen_mobile/features/business_lists/presentation/sale_detail_screen.dart';
import 'package:app_alim_gen_mobile/l10n/app_localizations.dart';
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
    ..httpClientAdapter = _DetailAdapter(capabilities);
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
      salesRepositoryProvider.overrideWithValue(
        SalesRepository(dio, const ErrorMapper()),
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
      home: SaleDetailScreen(saleId: 7),
    ),
  );
}

void main() {
  const allCapabilities = {
    'can_update': true,
    'can_delete': true,
    'can_view_invoice': true,
    'can_view_pdf': true,
    'can_print': true,
    'can_add_payment': true,
    'can_cancel': false,
  };

  testWidgets('masque les actions refusées par les permissions locales', (
    tester,
  ) async {
    await tester.pumpWidget(_app({'commerce.view_sale'}, allCapabilities));
    await tester.pumpAndSettle();

    expect(find.text('FAC-2026-000007'), findsOneWidget);
    expect(find.byKey(const Key('sale-edit-action')), findsNothing);
    expect(find.byKey(const Key('sale-print-action')), findsNothing);
    expect(find.byKey(const Key('sale-payment-action')), findsNothing);
  });

  testWidgets(
    'affiche seulement les actions autorisées par API et utilisateur',
    (tester) async {
      await tester.pumpWidget(
        _app({
          'commerce.view_sale',
          'commerce.change_sale',
          'accounts.view_invoices',
          'accounts.print_invoice',
        }, allCapabilities),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('sale-edit-action')), findsOneWidget);
      expect(find.byKey(const Key('sale-print-action')), findsOneWidget);
      expect(find.byKey(const Key('sale-payment-action')), findsOneWidget);
      expect(find.text('Facture'), findsOneWidget);
    },
  );
}

class _DetailAdapter implements HttpClientAdapter {
  _DetailAdapter(this.capabilities);
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
