import 'package:app_alim_gen_mobile/core/errors/error_mapper.dart';
import 'package:app_alim_gen_mobile/core/network/api_envelope.dart';
import 'package:app_alim_gen_mobile/features/receivables/domain/receivable.dart';
import 'package:dio/dio.dart';

class ReceivablesRepository {
  const ReceivablesRepository(this._dio, this._errors);
  final Dio _dio;
  final ErrorMapper _errors;

  Future<List<ReceivableSummary>> fetch({
    String query = '',
    String status = 'debtors',
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        'receivables/',
        queryParameters: {'search': query, 'status': status, 'page_size': 100},
      );
      final data = ApiEnvelope.data(response.data);
      final raw = data is Map ? data['results'] : data;
      if (raw is! List) throw const FormatException('Liste invalide.');
      return raw
          .map(
            (item) => ReceivableSummary.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false);
    } catch (error) {
      throw _errors.map(error);
    }
  }

  Future<ReceivableAccount> getAccount(int clientId) async {
    try {
      final response = await _dio.get<dynamic>('receivables/$clientId/');
      return ReceivableAccount.fromJson(ApiEnvelope.object(response.data));
    } catch (error) {
      throw _errors.map(error);
    }
  }

  Future<void> allocatePayment({
    required int clientId,
    required String amount,
    required String paymentType,
    required String idempotencyKey,
    String? createdAt,
    String? externalReference,
    String? notes,
  }) async {
    try {
      final payload = <String, dynamic>{
        'amount': amount,
        'payment_type': paymentType,
      };
      if (createdAt != null) payload['created_at'] = createdAt;
      if (externalReference != null) {
        payload['external_reference'] = externalReference;
      }
      if (notes != null) payload['notes'] = notes;
      await _dio.post<dynamic>(
        'receivables/$clientId/allocate-payment/',
        data: payload,
        options: Options(headers: {'Idempotency-Key': idempotencyKey}),
      );
    } catch (error) {
      throw _errors.map(error);
    }
  }

  Future<void> cancelOpeningPayment({
    required int clientId,
    required int paymentId,
    required String reason,
  }) async {
    try {
      await _dio.post<dynamic>(
        'receivables/$clientId/cancel-opening-payment/',
        data: {'payment_id': paymentId, 'reason': reason},
      );
    } catch (error) {
      throw _errors.map(error);
    }
  }
}
