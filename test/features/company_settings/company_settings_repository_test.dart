import 'package:app_alim_gen_mobile/core/errors/error_mapper.dart';
import 'package:app_alim_gen_mobile/features/company_settings/data/company_settings_repository.dart';
import 'package:app_alim_gen_mobile/features/company_settings/domain/company_settings.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

void main() {
  test(
    'charge et met à jour les informations légales de l’entreprise',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1/'));
      final adapter = DioAdapter(dio: dio);
      final repository = CompanySettingsRepository(dio, const ErrorMapper());
      const settings = CompanySettings(
        companyName: 'EL AMINE',
        address: 'Alger',
        phone: '0550',
        email: 'contact@example.dz',
        rcNumber: 'RC-1',
        taxNumber: 'NIF-1',
        nis: 'NIS-1',
        articleNumber: 'AI-1',
        taxRate: '19.00',
        shareCapital: '0.00',
      );

      adapter.onGet(
        'company-settings/',
        (server) =>
            server.reply(200, {'success': true, 'data': settings.toJson()}),
      );
      adapter.onPatch(
        'company-settings/',
        (server) =>
            server.reply(200, {'success': true, 'data': settings.toJson()}),
        data: settings.toJson(),
      );

      final loaded = await repository.get();
      expect(loaded.taxNumber, 'NIF-1');
      expect(loaded.supportsShareCapital, isTrue);
      final updated = await repository.update(settings);
      expect(updated.articleNumber, 'AI-1');
      expect(updated.shareCapital, '0.00');
      expect(updated.supportsShareCapital, isTrue);
    },
  );
  test('capital absent ou null reste absent, zéro reste une valeur', () {
    expect(CompanySettings.fromJson({}).shareCapital, isNull);
    expect(
      CompanySettings.fromJson({'share_capital': null}).shareCapital,
      isNull,
    );
    expect(
      CompanySettings.fromJson({'share_capital': '0.00'}).shareCapital,
      '0.00',
    );
    expect(CompanySettings.fromJson({}).supportsShareCapital, isFalse);
    expect(
      CompanySettings.fromJson({}).toJson().containsKey('share_capital'),
      isFalse,
    );
    final supported = CompanySettings.fromJson({'share_capital': null});
    expect(supported.supportsShareCapital, isTrue);
    expect(supported.toJson().containsKey('share_capital'), isTrue);
    expect(supported.toJson()['share_capital'], isNull);
  });

  test('ancien serveur : champ absent omis lors de la mise à jour', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1/'));
    final adapter = DioAdapter(dio: dio);
    final repository = CompanySettingsRepository(dio, const ErrorMapper());
    final legacy = const CompanySettings(
      companyName: 'Ancienne API',
      address: '',
      phone: '',
      email: '',
      rcNumber: '',
      taxNumber: '',
      nis: '',
      articleNumber: '',
      taxRate: '19.00',
    ).toJson()..remove('share_capital');
    adapter.onGet(
      'company-settings/',
      (server) => server.reply(200, {'success': true, 'data': legacy}),
    );
    adapter.onPatch(
      'company-settings/',
      (server) => server.reply(200, {'success': true, 'data': legacy}),
      data: legacy,
    );
    final loaded = await repository.get();
    expect(loaded.supportsShareCapital, isFalse);
    expect(loaded.toJson().containsKey('share_capital'), isFalse);
    final updated = await repository.update(loaded);
    expect(updated.supportsShareCapital, isFalse);
    expect(updated.toJson().containsKey('share_capital'), isFalse);
  });
}
