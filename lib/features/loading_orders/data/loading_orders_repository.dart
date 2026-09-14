import 'package:app_alim_gen_mobile/core/errors/error_mapper.dart';
import 'package:app_alim_gen_mobile/core/network/api_envelope.dart';
import 'package:app_alim_gen_mobile/core/pagination/api_page_loader.dart';
import 'package:app_alim_gen_mobile/core/pagination/page_data.dart';
import 'package:app_alim_gen_mobile/features/loading_orders/domain/loading_order_summary.dart';
import 'package:dio/dio.dart';

class LoadingOrdersRepository {
  const LoadingOrdersRepository(this._dio, this._errors);
  final Dio _dio;
  final ErrorMapper _errors;
  Future<PageData<LoadingOrderSummary>> fetch({
    required int page,
    String query = '',
  }) => loadApiPage(
    dio: _dio,
    errors: _errors,
    path: 'loading-orders/',
    page: page,
    query: query,
    decode: LoadingOrderSummary.fromJson,
  );
  Future<LoadingOrderSummary?> current() async {
    try {
      final response = await _dio.get<dynamic>('loading-orders/current/');
      final data = ApiEnvelope.data(response.data);
      return data == null
          ? null
          : LoadingOrderSummary.fromJson(
              Map<String, dynamic>.from(data as Map),
            );
    } catch (error) {
      throw _errors.map(error);
    }
  }
}
