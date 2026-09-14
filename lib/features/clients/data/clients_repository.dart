import 'package:app_alim_gen_mobile/core/errors/error_mapper.dart';
import 'package:app_alim_gen_mobile/core/pagination/api_page_loader.dart';
import 'package:app_alim_gen_mobile/core/pagination/page_data.dart';
import 'package:app_alim_gen_mobile/features/clients/domain/client_summary.dart';
import 'package:dio/dio.dart';

class ClientsRepository {
  const ClientsRepository(this._dio, this._errors);
  final Dio _dio;
  final ErrorMapper _errors;
  Future<PageData<ClientSummary>> fetch({
    required int page,
    String query = '',
  }) => loadApiPage(
    dio: _dio,
    errors: _errors,
    path: 'clients/',
    page: page,
    query: query,
    decode: ClientSummary.fromJson,
  );
}
