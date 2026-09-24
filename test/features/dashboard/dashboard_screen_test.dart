import 'dart:async';

import 'package:app_alim_gen_mobile/features/auth/domain/auth_models.dart';
import 'package:app_alim_gen_mobile/features/auth/presentation/auth_controller.dart';
import 'package:app_alim_gen_mobile/features/dashboard/domain/dashboard_summary.dart';
import 'package:app_alim_gen_mobile/features/dashboard/presentation/dashboard_controller.dart';
import 'package:app_alim_gen_mobile/features/dashboard/presentation/dashboard_screen.dart';
import 'package:app_alim_gen_mobile/features/profile/presentation/profile_screen.dart';
import 'package:app_alim_gen_mobile/core/utils/app_formats.dart';
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
  permissions: {'accounts.view_dashboard'},
);

class _AuthenticatedController extends AuthController {
  static bool logoutCalled = false;
  @override
  AuthState build() => const AuthState.authenticated(_user);
  @override
  Future<void> logout() async {
    logoutCalled = true;
    state = const AuthState.unauthenticated();
  }
}

Widget _app(
  Future<DashboardSummary> Function(Ref) loader, {
  Locale locale = const Locale('fr'),
}) => ProviderScope(
  overrides: [
    authControllerProvider.overrideWith(_AuthenticatedController.new),
    dashboardProvider.overrideWith(loader),
  ],
  child: MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: const DashboardScreen(),
  ),
);

void main() {
  setUp(() => _AuthenticatedController.logoutCalled = false);
  testWidgets('affiche un état de chargement typé', (tester) async {
    final pending = Completer<DashboardSummary>();
    await tester.pumpWidget(_app((_) => pending.future));
    expect(find.byKey(const Key('dashboard-loading')), findsOneWidget);
  });

  testWidgets('affiche les KPI renvoyés par API', (tester) async {
    await tester.pumpWidget(
      _app(
        (_) async => const DashboardSummary(
          revenue: '1200.00',
          salesCount: 4,
          averageBasket: '300.00',
          netProfit: '500.00',
          totalProducts: 9,
          totalClients: 8,
          totalSuppliers: 2,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dashboard-success')), findsOneWidget);
    expect(find.text(AppFormats.money('1200.00')), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('le bouton profil déclenche la déconnexion', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_AuthenticatedController.new),
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
          home: ProfileScreen(),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('logout-button')));
    await tester.pump();
    expect(_AuthenticatedController.logoutCalled, isTrue);
  });

  testWidgets('le dashboard mobile expose la navigation et respecte le RTL', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(
        (_) async => const DashboardSummary(
          revenue: '1200.00',
          salesCount: 4,
          averageBasket: '300.00',
          netProfit: '500.00',
          totalProducts: 9,
          totalClients: 8,
          totalSuppliers: 2,
        ),
        locale: const Locale('ar'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('mobile-navigation')), findsOneWidget);
    expect(
      Directionality.of(
        tester.element(find.byKey(const Key('dashboard-success'))),
      ),
      TextDirection.rtl,
    );
  });
}
