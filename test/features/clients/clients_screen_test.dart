import 'package:app_alim_gen_mobile/core/pagination/page_data.dart';
import 'package:app_alim_gen_mobile/features/auth/domain/auth_models.dart';
import 'package:app_alim_gen_mobile/features/auth/presentation/auth_controller.dart';
import 'package:app_alim_gen_mobile/features/clients/domain/client_summary.dart';
import 'package:app_alim_gen_mobile/features/clients/presentation/clients_screen.dart';
import 'package:app_alim_gen_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _user = UserProfile(
  id: 1,
  username: 'operator',
  firstName: 'Youcef',
  lastName: '',
  email: '',
  phone: '',
  role: 'Opérateur',
  permissions: {'inventory.view_client'},
);

class _AuthController extends AuthController {
  @override
  AuthState build() => const AuthState.authenticated(_user);
}

class _ClientsController extends ClientsController {
  @override
  PagedListState<ClientSummary> build() => const PagedListState(
    isInitialLoading: false,
    items: [
      ClientSummary(
        id: 1,
        name: 'SARL El Baraka',
        phone: '0550 00 00 00',
        address: 'Bouira',
        customerType: 'Gros',
      ),
    ],
  );
}

Widget _app(Locale locale) => ProviderScope(
  overrides: [
    authControllerProvider.overrideWith(_AuthController.new),
    clientsProvider.overrideWith(_ClientsController.new),
  ],
  child: MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: const ClientsScreen(),
  ),
);

void main() {
  testWidgets('la carte client affiche les informations métier', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const Locale('fr')));

    expect(find.text('SARL El Baraka'), findsOneWidget);
    expect(find.text('Gros'), findsOneWidget);
    expect(find.text('0550 00 00 00'), findsOneWidget);
    expect(find.text('Bouira'), findsOneWidget);
  });

  testWidgets('la liste client reste directionnelle en arabe', (tester) async {
    await tester.pumpWidget(_app(const Locale('ar')));

    expect(
      Directionality.of(tester.element(find.text('SARL El Baraka'))),
      TextDirection.rtl,
    );
  });
}
