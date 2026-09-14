import 'package:app_alim_gen_mobile/core/errors/error_mapper.dart';
import 'package:app_alim_gen_mobile/core/network/api_envelope.dart';
import 'package:app_alim_gen_mobile/features/dashboard/domain/dashboard_filter.dart';
import 'package:app_alim_gen_mobile/features/dashboard/domain/dashboard_summary.dart';
import 'package:dio/dio.dart';

class DashboardRepository {
  const DashboardRepository(this._dio, this._errors);
  final Dio _dio;
  final ErrorMapper _errors;
  Future<DashboardSummary> load({
    DashboardFilter filter = const DashboardFilter(),
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        'dashboard/',
        queryParameters: filter.queryParameters,
      );
      return DashboardSummary.fromJson(ApiEnvelope.object(response.data));
    } catch (error) {
      throw _errors.map(error);
    }
  }
}
