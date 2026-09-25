import 'package:app_alim_gen_mobile/core/pagination/page_data.dart';
import 'package:app_alim_gen_mobile/features/auth/domain/auth_models.dart';
import 'package:app_alim_gen_mobile/features/auth/presentation/auth_controller.dart';
import 'package:app_alim_gen_mobile/features/loading_orders/domain/loading_order_summary.dart';
import 'package:app_alim_gen_mobile/features/loading_orders/presentation/loading_orders_screen.dart';
import 'package:app_alim_gen_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _user = UserProfile(
  id: 1,
  username: 'manager',
  firstName: '',
  lastName: '',
  email: '',
  phone: '',
  role: 'Gestionnaire',
  permissions: {
    'inventory.view_loadingorder',
    'inventory.change_loadingorder',
    'inventory.delete_loadingorder',
    'inventory.validate_loadingorder',
    'inventory.close_loadingorder',
  },
);

const _draft = LoadingOrderSummary(
  id: 7,
  number: 'CHG-0007',
  operatorName: 'Opérateur test',
  status: 'draft',
  createdAt: '2026-09-25T08:00:00Z',
  lines: [],
);

class _AuthController extends AuthController {
  @override
  AuthState build() => const AuthState.authenticated(_user);
}

class _OrdersController extends LoadingOrdersController {
  @override
  PagedListState<LoadingOrderSummary> build() =>
      const PagedListState(isInitialLoading: false, items: [_draft]);
}

class _ActionsController extends LoadingOrderActionController {
  @override
  LoadingOrderActionState build() => const LoadingOrderActionState();

  @override
  Future<LoadingOrderSummary> validateOrder(int id) async =>
      const LoadingOrderSummary(
        id: 7,
        number: 'CHG-0007',
        operatorName: 'Opérateur test',
        status: 'in_progress',
        createdAt: '2026-09-25T08:00:00Z',
        lines: [],
      );
}

Widget _app() => ProviderScope(
  overrides: [
    authControllerProvider.overrideWith(_AuthController.new),
    loadingOrdersProvider.overrideWith(_OrdersController.new),
    loadingOrderActionProvider.overrideWith(_ActionsController.new),
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
    home: LoadingOrdersScreen(),
  ),
);

void main() {
  testWidgets('un brouillon propose modifier, valider et annuler', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('CHG-0007'));
    await tester.pumpAndSettle();

    expect(find.text('Modifier'), findsOneWidget);
    expect(find.text('Valider'), findsOneWidget);
    expect(find.text('Annuler le bon'), findsOneWidget);
  });

  testWidgets('la confirmation de validation met à jour le statut', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('CHG-0007'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Valider ce bon transférera le stock du dépôt vers l’opérateur.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Confirmer'));
    await tester.pumpAndSettle();

    expect(find.text('En cours'), findsOneWidget);
    expect(find.text('Clôturer'), findsOneWidget);
    expect(find.text('Bon de chargement validé.'), findsOneWidget);
  });
}
