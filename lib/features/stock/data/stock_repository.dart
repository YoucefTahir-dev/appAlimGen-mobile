import 'package:app_alim_gen_mobile/core/errors/error_mapper.dart';
import 'package:app_alim_gen_mobile/core/pagination/api_page_loader.dart';
import 'package:app_alim_gen_mobile/core/pagination/page_data.dart';
import 'package:app_alim_gen_mobile/features/loading_orders/data/loading_orders_repository.dart';
import 'package:app_alim_gen_mobile/features/loading_orders/domain/loading_order_summary.dart';
import 'package:app_alim_gen_mobile/features/products/domain/product_summary.dart';
import 'package:app_alim_gen_mobile/features/stock/domain/operator_stock_summary.dart';
import 'package:dio/dio.dart';

class StockRepository {
  const StockRepository(this._dio, this._errors);
  final Dio _dio;
  final ErrorMapper _errors;
  Future<PageData<ProductSummary>> fetch({
    required int page,
    String query = '',
  }) => loadApiPage(
    dio: _dio,
    errors: _errors,
    path: 'stock/',
    page: page,
    query: query,
    decode: ProductSummary.fromJson,
  );
}

class OperatorStockRepository {
  const OperatorStockRepository(this._dio, this._errors, this._loadingOrders);
  final Dio _dio;
  final ErrorMapper _errors;
  final LoadingOrdersRepository _loadingOrders;
  Future<PageData<OperatorStockSummary>> fetch({
    required int page,
    String query = '',
  }) async {
    final results = await Future.wait<dynamic>([
      loadApiPage<OperatorStockSummary>(
        dio: _dio,
        errors: _errors,
        path: 'operator-stock/',
        page: page,
        query: '',
        decode: OperatorStockSummary.fromJson,
      ),
      _loadingOrders.current(),
    ]);
    final stock = results[0] as PageData<OperatorStockSummary>;
    final current = results[1] as LoadingOrderSummary?;
    final activity = current == null
        ? const <int, LoadingLineSummary>{}
        : {for (final line in current.lines) line.productId: line};
    final enriched = stock.items
        .map((item) {
          final line = activity[item.productId];
          return line == null
              ? item
              : item.copyWithActivity(loaded: line.loaded, sold: line.sold);
        })
        .toList(growable: false);
    return PageData(
      items: enriched,
      count: stock.count,
      hasNext: stock.hasNext,
    );
  }
}
