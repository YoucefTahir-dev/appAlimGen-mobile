import 'package:app_alim_gen_mobile/core/errors/error_mapper.dart';
import 'package:app_alim_gen_mobile/core/pagination/api_page_loader.dart';
import 'package:app_alim_gen_mobile/core/pagination/page_data.dart';
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
}
