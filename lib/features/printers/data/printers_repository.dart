import 'package:app_alim_gen_mobile/core/errors/error_mapper.dart';
import 'package:app_alim_gen_mobile/core/network/api_envelope.dart';
import 'package:app_alim_gen_mobile/features/printers/domain/printer_summary.dart';
import 'package:dio/dio.dart';
import 'package:app_alim_gen_mobile/core/network/crud_repository.dart';
import 'package:app_alim_gen_mobile/core/pagination/api_page_loader.dart';
import 'package:app_alim_gen_mobile/core/pagination/page_data.dart';

class PrintersRepository {
  const PrintersRepository(this._dio, this._errors);
  final Dio _dio;
  final ErrorMapper _errors;
  CrudRepository get _crud => CrudRepository(_dio, _errors);
  Future<PageData<PrinterSummary>> fetch({
    required int page,
    String query = '',
  }) => loadApiPage(
    dio: _dio,
    errors: _errors,
    path: 'printers/',
    page: page,
    query: query,
    decode: PrinterSummary.fromJson,
  );
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

  Future<PrinterDetails> get(int id) async =>
      PrinterDetails.fromJson(await _crud.getObject('printers/$id/'));
  Future<PrinterDetails> create(PrinterWriteRequest request) async =>
      PrinterDetails.fromJson(
        await _crud.create('printers/', request.toJson()),
      );
  Future<PrinterDetails> update(int id, PrinterWriteRequest request) async =>
      PrinterDetails.fromJson(
        await _crud.patch('printers/$id/', request.toJson()),
      );
  Future<void> delete(int id) => _crud.delete('printers/$id/');
  Future<PrinterDetails> setDefault(int id) async => PrinterDetails.fromJson(
    await _crud.create('printers/$id/set-default/', const {}),
  );
  Future<Map<String, dynamic>> testPayload(int id) =>
      _crud.getObject('printers/$id/test-payload/');
}
