import 'package:app_alim_gen_mobile/core/navigation/app_drawer.dart';
import 'package:app_alim_gen_mobile/core/permissions/permission_service.dart';
import 'package:app_alim_gen_mobile/features/auth/domain/auth_models.dart';
import 'package:app_alim_gen_mobile/features/auth/presentation/auth_controller.dart';
import 'package:app_alim_gen_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _UserController extends AuthController {
  _UserController(this.user);
  final UserProfile user;

  @override
  AuthState build() => AuthState.authenticated(user);
}

UserProfile _user(Set<String> permissions) => UserProfile(
  id: 1,
  username: 'youcef',
  firstName: 'Youcef',
  lastName: '',
  email: '',
  phone: '',
  role: 'Opérateur',
  permissions: permissions,
);

Widget _app({required UserProfile user, Locale locale = const Locale('fr')}) {
  final router = GoRouter(
    initialLocation: '/dashboard',
    routes: [
      GoRoute(
        path: '/dashboard',
        builder: (_, _) => Scaffold(
          appBar: AppBar(title: Text('ERP')),
          drawer: const AppDrawer(currentPath: '/dashboard'),
          body: const Text('dashboard-page'),
        ),
      ),
      GoRoute(
        path: '/products',
        builder: (_, _) => const Scaffold(body: Text('products-page')),
      ),
      GoRoute(
        path: '/profile',
        builder: (_, _) => const Scaffold(body: Text('profile-page')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(() => _UserController(user)),
    ],
    child: MaterialApp.router(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    ),
  );
}

Future<void> _openDrawer(WidgetTester tester) async {
  tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('affiche les modules autorisés et navigue vers Produits', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(user: _user({AppPermissions.dashboard, AppPermissions.products})),
    );
    await _openDrawer(tester);

    expect(find.byKey(const Key('drawer-products')), findsOneWidget);
    expect(find.byKey(const Key('drawer-clients')), findsNothing);
    await tester.tap(find.byKey(const Key('drawer-products')));
    await tester.pumpAndSettle();
    expect(find.text('products-page'), findsOneWidget);
  });

  testWidgets('un opérateur voit son stock mais pas le stock global', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        user: _user({
          AppPermissions.dashboard,
          AppPermissions.sales,
          AppPermissions.ownLoadingOrders,
        }),
      ),
    );
    await _openDrawer(tester);

    expect(find.byKey(const Key('drawer-operatorStock')), findsOneWidget);
    expect(find.byKey(const Key('drawer-loadingOrders')), findsOneWidget);
    expect(find.byKey(const Key('drawer-stock')), findsNothing);
  });

  testWidgets('le menu arabe utilise bien la direction RTL', (tester) async {
    await tester.pumpWidget(
      _app(
        user: _user({AppPermissions.dashboard, AppPermissions.products}),
        locale: const Locale('ar'),
      ),
    );
    await _openDrawer(tester);

    expect(
      Directionality.of(tester.element(find.byType(Drawer))),
      TextDirection.rtl,
    );
    expect(find.text('المنتجات'), findsOneWidget);
  });
}
