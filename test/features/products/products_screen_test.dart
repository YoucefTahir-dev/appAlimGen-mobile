import 'package:app_alim_gen_mobile/core/errors/app_failure.dart';
import 'package:app_alim_gen_mobile/core/pagination/page_data.dart';
import 'package:app_alim_gen_mobile/core/utils/app_formats.dart';
import 'package:app_alim_gen_mobile/features/auth/domain/auth_models.dart';
import 'package:app_alim_gen_mobile/features/auth/presentation/auth_controller.dart';
import 'package:app_alim_gen_mobile/features/products/domain/product_summary.dart';
import 'package:app_alim_gen_mobile/features/products/presentation/products_screen.dart';
import 'package:app_alim_gen_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _user = UserProfile(
  id: 1,
  username: 'admin',
  firstName: 'Admin',
  lastName: '',
  email: '',
  phone: '',
  role: 'Administrateur',
  permissions: {'inventory.view_product'},
);

class _AuthController extends AuthController {
  @override
  AuthState build() => const AuthState.authenticated(_user);
}

class _ProductsController extends ProductsController {
  _ProductsController(this.initial);
  final PagedListState<ProductSummary> initial;

  @override
  PagedListState<ProductSummary> build() => initial;
}

Widget _app(PagedListState<ProductSummary> state) => ProviderScope(
  overrides: [
    authControllerProvider.overrideWith(_AuthController.new),
    productsProvider.overrideWith(() => _ProductsController(state)),
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
    home: ProductsScreen(),
  ),
);

const _crudUser = UserProfile(
  id: 2,
  username: 'manager',
  firstName: '',
  lastName: '',
  email: '',
  phone: '',
  role: 'Gestionnaire',
  permissions: {
    'inventory.view_product',
    'inventory.add_product',
    'inventory.change_product',
    'inventory.delete_product',
  },
);

class _CrudAuthController extends AuthController {
  @override
  AuthState build() => const AuthState.authenticated(_crudUser);
}

Widget _crudApp(PagedListState<ProductSummary> state) => ProviderScope(
  overrides: [
    authControllerProvider.overrideWith(_CrudAuthController.new),
    productsProvider.overrideWith(() => _ProductsController(state)),
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
    home: ProductsScreen(),
  ),
);

void main() {
  testWidgets('le loader produits est réservé à l’état loading', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const PagedListState()));
    expect(find.byKey(const Key('loading-skeleton')), findsOneWidget);
  });

  testWidgets('une réponse vide termine le chargement', (tester) async {
    await tester.pumpWidget(
      _app(const PagedListState(isInitialLoading: false)),
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Aucun résultat'), findsOneWidget);
  });

  testWidgets('une réponse valide affiche les produits réels', (tester) async {
    await tester.pumpWidget(
      _app(
        const PagedListState(
          isInitialLoading: false,
          items: [
            ProductSummary(
              id: 1,
              name: 'Butane 13 kg',
              reference: 'B13',
              quantity: 7,
              stockStatus: 'normal',
              retailPrice: '1500.00',
            ),
          ],
        ),
      ),
    );
    expect(find.text('Butane 13 kg'), findsOneWidget);
    expect(find.text(AppFormats.money('1500.00')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('une erreur API termine le loader et permet de réessayer', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const PagedListState(
          isInitialLoading: false,
          error: AppFailure(
            kind: FailureKind.server,
            code: 'API_ERROR',
            message: 'Serveur indisponible',
          ),
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Serveur indisponible'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);
  });

  testWidgets('masque le bouton créer sans permission', (tester) async {
    await tester.pumpWidget(
      _app(const PagedListState(isInitialLoading: false)),
    );
    expect(find.text('Nouveau produit'), findsNothing);
  });

  testWidgets('affiche les actions CRUD avec permissions', (tester) async {
    await tester.pumpWidget(
      _crudApp(
        const PagedListState(
          isInitialLoading: false,
          items: [
            ProductSummary(
              id: 1,
              name: 'Test',
              reference: 'P1',
              quantity: 1,
              stockStatus: 'normal',
            ),
          ],
        ),
      ),
    );
    expect(find.text('Nouveau produit'), findsOneWidget);
    expect(find.byIcon(Icons.more_vert), findsOneWidget);
  });
}
