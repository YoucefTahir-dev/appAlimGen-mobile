import 'package:app_alim_gen_mobile/core/errors/error_mapper.dart';
import 'package:app_alim_gen_mobile/core/pagination/api_page_loader.dart';
import 'package:app_alim_gen_mobile/core/pagination/page_data.dart';
import 'package:app_alim_gen_mobile/features/products/domain/product_summary.dart';
import 'package:dio/dio.dart';

class ProductsRepository {
  const ProductsRepository(this._dio, this._errors, {this.path = 'products/'});
  final Dio _dio;
  final ErrorMapper _errors;
  final String path;
  Future<PageData<ProductSummary>> fetch({
    required int page,
    String query = '',
  }) => loadApiPage(
    dio: _dio,
    errors: _errors,
    path: path,
    page: page,
    query: query,
    decode: ProductSummary.fromJson,
  );
}
