import 'package:app_alim_gen_mobile/core/permissions/permission_service.dart';
import 'package:app_alim_gen_mobile/features/auth/domain/auth_models.dart';
import 'package:app_alim_gen_mobile/features/auth/presentation/auth_controller.dart';
import 'package:app_alim_gen_mobile/features/business_lists/domain/business_entities.dart';
import 'package:app_alim_gen_mobile/features/business_lists/presentation/transaction_form_screens.dart';
import 'package:app_alim_gen_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _basePermissions = {AppPermissions.changeSale, AppPermissions.sales};

const _seller = UserProfile(
  id: 1,
  username: 'seller',
  firstName: '',
  lastName: '',
  email: '',
  phone: '',
  role: 'seller',
  permissions: _basePermissions,
);

const _priceManager = UserProfile(
  id: 2,
  username: 'price-manager',
  firstName: '',
  lastName: '',
  email: '',
  phone: '',
  role: 'manager',
  permissions: {..._basePermissions, AppPermissions.overrideSalePrice},
);

final _sale = SaleDetails.fromJson({
  'id': 41,
  'invoice_number': 'FAC-TEST-PRICE',
  'client_details': {'id': 2, 'name': 'Client test'},
  'lines': [
    {
      'id': 1,
      'product': {'id': 4, 'name': 'Produit test'},
      'quantity': 1,
      'unit_price': '100.00',
    },
  ],
  'subtotal': '100.00',
  'discount': '0.00',
  'tax_rate': '0.00',
  'tax_amount': '0.00',
  'total': '100.00',
  'amount_paid': '0.00',
  'balance_due': '100.00',
  'payment_type': 'cash',
});

class _SellerAuth extends AuthController {
  @override
  AuthState build() => const AuthState.authenticated(_seller);
}

class _PriceManagerAuth extends AuthController {
  @override
  AuthState build() => const AuthState.authenticated(_priceManager);
}

Future<void> _pump(WidgetTester tester, AuthController Function() auth) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authControllerProvider.overrideWith(auth)],
      child: MaterialApp(
        locale: const Locale('fr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: SaleFormScreen(initial: _sale),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('le prix est en lecture seule sans permission de dérogation', (
    tester,
  ) async {
    await _pump(tester, _SellerAuth.new);

    final field = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const ValueKey('sale-price-0')),
        matching: find.byType(TextField),
      ),
    );
    expect(field.readOnly, isTrue);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
  });

  testWidgets('le prix est modifiable avec la permission de dérogation', (
    tester,
  ) async {
    await _pump(tester, _PriceManagerAuth.new);

    final field = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const ValueKey('sale-price-0')),
        matching: find.byType(TextField),
      ),
    );
    expect(field.readOnly, isFalse);
    expect(find.byIcon(Icons.lock_outline), findsNothing);
  });
}
