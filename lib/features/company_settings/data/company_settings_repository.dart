import 'package:app_alim_gen_mobile/core/errors/error_mapper.dart';
import 'package:app_alim_gen_mobile/core/network/crud_repository.dart';
import 'package:app_alim_gen_mobile/features/company_settings/domain/company_settings.dart';
import 'package:dio/dio.dart';

class CompanySettingsRepository {
  const CompanySettingsRepository(this._dio, this._errors);

  final Dio _dio;
  final ErrorMapper _errors;

  CrudRepository get _crud => CrudRepository(_dio, _errors);

  Future<CompanySettings> get() async =>
      CompanySettings.fromJson(await _crud.getObject('company-settings/'));

  Future<CompanySettings> update(CompanySettings settings) async =>
      CompanySettings.fromJson(
        await _crud.patch('company-settings/', settings.toJson()),
      );
}
