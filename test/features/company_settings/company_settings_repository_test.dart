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

      expect((await repository.get()).taxNumber, 'NIF-1');
      expect((await repository.update(settings)).articleNumber, 'AI-1');
    },
  );
}
