import 'package:app_alim_gen_mobile/core/errors/error_mapper.dart';
import 'package:app_alim_gen_mobile/core/pagination/api_page_loader.dart';
import 'package:app_alim_gen_mobile/core/pagination/page_data.dart';
import 'package:app_alim_gen_mobile/core/network/api_envelope.dart';
import 'package:app_alim_gen_mobile/core/network/crud_repository.dart';
import 'package:app_alim_gen_mobile/features/products/domain/product_summary.dart';
import 'package:dio/dio.dart';

class ProductsRepository {
  ProductsRepository(this._dio, this._errors, {this.path = 'products/'});
  final Dio _dio;
  final ErrorMapper _errors;
  final String path;
  CancelToken? _activeFirstPage;

  Future<PageData<ProductSummary>> fetch({
    required int page,
    String query = '',
  }) async {
    CancelToken? cancelToken;
    if (page == 1) {
      _activeFirstPage?.cancel('Recherche remplacée');
      cancelToken = CancelToken();
      _activeFirstPage = cancelToken;
    }
    try {
      return await loadApiPage(
        dio: _dio,
        errors: _errors,
        path: path,
        page: page,
        query: query,
        cancelToken: cancelToken,
        decode: ProductSummary.fromJson,
      );
    } finally {
      if (identical(_activeFirstPage, cancelToken)) {
        _activeFirstPage = null;
      }
    }
  }

  CrudRepository get _crud => CrudRepository(_dio, _errors);

  Future<ProductDetails> get(int id) async =>
      ProductDetails.fromJson(await _crud.getObject('$path$id/'));

  Future<ProductDetails> create(ProductWriteRequest request) async =>
      ProductDetails.fromJson(await _crud.create(path, request.toJson()));

  Future<ProductDetails> update(int id, ProductWriteRequest request) async =>
      ProductDetails.fromJson(await _crud.patch('$path$id/', request.toJson()));

  Future<void> delete(int id) => _crud.delete('$path$id/');

  Future<List<ReferenceOption>> references(String resource) async {
    try {
      final response = await _dio.get<dynamic>('$resource/');
      final data = ApiEnvelope.data(response.data);
      if (data is! List) throw const FormatException('Liste invalide.');
      return data
          .map(
            (item) => ReferenceOption.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false);
    } catch (error) {
      throw _errors.map(error);
    }
  }
}
