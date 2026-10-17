import 'package:app_alim_gen_mobile/core/errors/error_mapper.dart';
import 'package:app_alim_gen_mobile/features/stock/data/stock_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

void main() {
  test('charge et décode le journal des mouvements de stock', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1/'));
    final adapter = DioAdapter(dio: dio);
    final repository = StockRepository(dio, const ErrorMapper());
    adapter.onGet(
      'stock/movements/',
      (server) => server.reply(200, {
        'success': true,
        'data': {
          'count': 1,
          'next': null,
          'previous': null,
          'results': [
            {
              'id': 12,
              'product_name': 'Produit A',
              'movement_type': 'purchase',
              'quantity': 24,
              'applied_delta': 24,
              'balance_before': 10,
              'balance_after': 34,
              'reason': 'Achat ACH-12',
              'created_by_name': 'Admin',
              'created_at': '2026-10-17T10:00:00Z',
            },
          ],
        },
      }),
      queryParameters: {'page': 1, 'page_size': 25},
    );

    final result = await repository.movements(page: 1);

    expect(result.count, 1);
    expect(result.items.single.productName, 'Produit A');
    expect(result.items.single.appliedDelta, 24);
    expect(result.items.single.balanceAfter, 34);
  });
}
