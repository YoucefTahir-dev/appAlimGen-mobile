import 'package:app_alim_gen_mobile/core/errors/error_mapper.dart';
import 'package:app_alim_gen_mobile/core/network/api_envelope.dart';
import 'package:app_alim_gen_mobile/features/printers/domain/printer_summary.dart';
import 'package:dio/dio.dart';

class PrintersRepository {
  const PrintersRepository(this._dio, this._errors);
  final Dio _dio;
  final ErrorMapper _errors;
  Future<PrinterSummary?> getDefault() async {
    try {
      final response = await _dio.get<dynamic>('printers/default/');
      return PrinterSummary.fromJson(ApiEnvelope.object(response.data));
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return null;
      throw _errors.map(error);
    } catch (error) {
      throw _errors.map(error);
    }
  }
}
