import 'package:app_alim_gen_mobile/core/errors/error_mapper.dart';
import 'package:app_alim_gen_mobile/core/pagination/api_page_loader.dart';
import 'package:app_alim_gen_mobile/core/pagination/page_data.dart';
import 'package:app_alim_gen_mobile/core/network/crud_repository.dart';
import 'package:app_alim_gen_mobile/features/clients/domain/client_summary.dart';
import 'package:dio/dio.dart';

class ClientsRepository {
  const ClientsRepository(this._dio, this._errors);
  final Dio _dio;
  final ErrorMapper _errors;
  CrudRepository get _crud => CrudRepository(_dio, _errors);
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

  Future<ClientDetails> get(int id) async =>
      ClientDetails.fromJson(await _crud.getObject('clients/$id/'));
  Future<ClientDetails> create(ClientWriteRequest request) async =>
      ClientDetails.fromJson(await _crud.create('clients/', request.toJson()));
  Future<ClientDetails> update(int id, ClientWriteRequest request) async =>
      ClientDetails.fromJson(
        await _crud.patch('clients/$id/', request.toJson()),
      );
  Future<void> delete(int id) => _crud.delete('clients/$id/');
}
