import 'package:app_alim_gen_mobile/core/errors/error_mapper.dart';
import 'package:app_alim_gen_mobile/core/network/api_envelope.dart';
import 'package:app_alim_gen_mobile/core/pagination/api_page_loader.dart';
import 'package:app_alim_gen_mobile/core/pagination/page_data.dart';
import 'package:app_alim_gen_mobile/features/loading_orders/domain/loading_order_summary.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

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

  Future<LoadingOrderSummary> get(int id) async {
    try {
      final r = await _dio.get<dynamic>('loading-orders/$id/');
      return LoadingOrderSummary.fromJson(ApiEnvelope.object(r.data));
    } catch (e) {
      throw _errors.map(e);
    }
  }

  Future<LoadingOrderSummary> create(
    LoadingOrderWriteRequest request,
    String key,
  ) async {
    try {
      final r = await _dio.post<dynamic>(
        'loading-orders/',
        data: request.toJson(),
        options: Options(headers: {'Idempotency-Key': key}),
      );
      return LoadingOrderSummary.fromJson(ApiEnvelope.object(r.data));
    } catch (e) {
      throw _errors.map(e);
    }
  }

  Future<LoadingOrderSummary> update(
    int id,
    LoadingOrderWriteRequest request,
  ) async {
    try {
      final r = await _dio.patch<dynamic>(
        'loading-orders/$id/',
        data: request.toJson(),
      );
      return LoadingOrderSummary.fromJson(ApiEnvelope.object(r.data));
    } catch (e) {
      throw _errors.map(e);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete<dynamic>('loading-orders/$id/');
    } catch (e) {
      throw _errors.map(e);
    }
  }

  Future<LoadingOrderSummary> validateLoadingOrder(int id, String key) =>
      _postAction(id, 'validate', key: key);

  Future<LoadingOrderSummary> cancelLoadingOrder(int id) =>
      _postAction(id, 'cancel');

  Future<LoadingOrderSummary> closeLoadingOrder(int id, String key) =>
      _postAction(id, 'close', key: key);

  Future<LoadingOrderSummary> _postAction(
    int id,
    String action, {
    String? key,
  }) async {
    try {
      final r = await _dio.post<dynamic>(
        'loading-orders/$id/$action/',
        options: Options(
          headers: key == null ? null : {'Idempotency-Key': key},
        ),
      );
      return LoadingOrderSummary.fromJson(ApiEnvelope.object(r.data));
    } catch (e) {
      throw _errors.map(e);
    }
  }

  String newKey() => const Uuid().v4();
  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    try {
      final r = await _dio.get<dynamic>(
        'products/search/',
        queryParameters: {'q': query, 'context': 'loading_order'},
      );
      final d = ApiEnvelope.data(r.data);
      final raw = d is Map ? d['results'] : d;
      return (raw as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (e) {
      throw _errors.map(e);
    }
  }
}
