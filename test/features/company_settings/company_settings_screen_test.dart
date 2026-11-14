import 'package:app_alim_gen_mobile/app/providers.dart';
import 'package:app_alim_gen_mobile/core/errors/error_mapper.dart';
import 'package:app_alim_gen_mobile/core/permissions/permission_service.dart';
import 'package:app_alim_gen_mobile/features/auth/domain/auth_models.dart';
import 'package:app_alim_gen_mobile/features/auth/presentation/auth_controller.dart';
import 'package:app_alim_gen_mobile/features/company_settings/data/company_settings_repository.dart';
import 'package:app_alim_gen_mobile/features/company_settings/domain/company_settings.dart';
import 'package:app_alim_gen_mobile/features/company_settings/presentation/company_settings_screen.dart';
import 'package:app_alim_gen_mobile/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _settings = CompanySettings(
  companyName: 'Entreprise locale',
  address: '',
  phone: '',
  email: '',
  rcNumber: '',
  taxNumber: '',
  nis: '',
  articleNumber: '',
  taxRate: '19.00',
);

class _Repository extends CompanySettingsRepository {
  _Repository({this.initial = _settings, this.response})
    : super(Dio(), const ErrorMapper());
  final CompanySettings initial;
  final CompanySettings? response;
  CompanySettings? saved;
  @override
  Future<CompanySettings> get() async => initial;
  @override
  Future<CompanySettings> update(CompanySettings settings) async {
    saved = settings;
    return response ?? settings;
  }
}

class _Auth extends AuthController {
  @override
  AuthState build() => const AuthState.authenticated(
    UserProfile(
      id: 1,
      username: 'test',
      firstName: '',
      lastName: '',
      email: '',
      phone: '',
      role: 'Test',
      permissions: {AppPermissions.settings, AppPermissions.changeSettings},
    ),
  );
}

Widget _app(_Repository repository, {String language = 'fr'}) => ProviderScope(
  overrides: [
    authControllerProvider.overrideWith(_Auth.new),
    companySettingsRepositoryProvider.overrideWithValue(repository),
  ],
  child: MaterialApp(
    locale: Locale(language),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: const CompanySettingsScreen(),
  ),
);

void main() {
  final capital = find.widgetWithText(
    TextFormField,
    'Capital social (DZD, facultatif)',
  );
  final save = find.byKey(const Key('company-settings-save'));
  for (final value in ['', '0', '0,00', '125000,50']) {
    testWidgets('optional capital saves nonnegative money "$value"', (
      tester,
    ) async {
      final repository = _Repository();
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        capital,
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(capital, value);
      await tester.scrollUntilVisible(
        save,
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(repository.saved, isNotNull);
      expect(
        repository.saved!.shareCapital,
        value.isEmpty ? null : value.replaceAll(',', '.'),
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final value in ['-1', 'NaN', 'Infinity', '1e3', '1.234']) {
    testWidgets('capital rejects invalid money "$value"', (tester) async {
      final repository = _Repository();
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        capital,
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(capital, value);
      await tester.scrollUntilVisible(
        save,
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(repository.saved, isNull);
      expect(
        find.text(
          'Saisissez un montant positif ou nul, avec au plus 2 décimales.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  final legacy = CompanySettings.fromJson(
    _settings.toJson()..remove('share_capital'),
  );
  final updateRequired = find.byKey(
    const Key('share-capital-backend-update-required'),
  );
  for (final (language, notice, label) in const [
    (
      'fr',
      'Capital social indisponible : une mise à jour du serveur est nécessaire pour le saisir et l’enregistrer.',
      'Capital social (DZD, facultatif)',
    ),
    (
      'en',
      'Share capital is unavailable: update the server before entering and saving it.',
      'Share capital (DZD, optional)',
    ),
    (
      'ar',
      'رأس المال غير متاح: يلزم تحديث الخادم قبل إدخاله وحفظه.',
      'رأس المال (دج، اختياري)',
    ),
  ]) {
    testWidgets(
      'old API hides capital and explains backend update ($language)',
      (tester) async {
        final repository = _Repository(initial: legacy);
        await tester.pumpWidget(_app(repository, language: language));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          updateRequired,
          180,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text(notice), findsOneWidget);
        expect(find.widgetWithText(TextFormField, label), findsNothing);
        await tester.scrollUntilVisible(
          save,
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(repository.saved, isNotNull);
        expect(repository.saved!.supportsShareCapital, isFalse);
        expect(
          repository.saved!.toJson().containsKey('share_capital'),
          isFalse,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'current API null capital remains editable and saves known zero',
    (tester) async {
      final current = CompanySettings.fromJson(_settings.toJson());
      final repository = _Repository(initial: current);
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        capital,
        180,
        scrollable: find.byType(Scrollable).first,
      );
      expect(updateRequired, findsNothing);
      await tester.enterText(capital, '0.00');
      await tester.scrollUntilVisible(
        save,
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(repository.saved!.supportsShareCapital, isTrue);
      expect(repository.saved!.toJson()['share_capital'], '0.00');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'capability lost in save response warns instead of claiming capital saved',
    (tester) async {
      final repository = _Repository(response: legacy);
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        capital,
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(capital, '1250.00');
      await tester.scrollUntilVisible(
        save,
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(repository.saved!.supportsShareCapital, isTrue);
      expect(updateRequired, findsOneWidget);
      expect(capital, findsNothing);
      expect(
        find.text('Paramètres de l’entreprise enregistrés.'),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
