import 'package:app_alim_gen_mobile/core/errors/error_mapper.dart';
import 'package:app_alim_gen_mobile/features/dashboard/data/dashboard_repository.dart';
import 'package:app_alim_gen_mobile/features/dashboard/domain/dashboard_filter.dart';
import 'package:app_alim_gen_mobile/features/dashboard/presentation/dashboard_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

void main() {
  test('parse le contrat dashboard complet et transmet la période', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1/'));
    final adapter = DioAdapter(dio: dio);
    final repository = DashboardRepository(dio, const ErrorMapper());
    adapter.onGet(
      'dashboard/',
      (server) => server.reply(200, {
        'success': true,
        'data': {
          'period': 'month',
          'start_date': '2026-09-01',
          'end_date': '2026-09-14',
          'sales_today': '12.00',
          'period_revenue': '1200.50',
          'sales_count': 4,
          'average_basket': '300.125',
          'gross_profit': '500.00',
          'expenses_total': '100.00',
          'net_profit': '400.00',
          'stock_value': '7500.00',
          'purchases_total': '900.00',
          'total_products': 9,
          'total_clients': 8,
          'total_suppliers': 2,
          'products_sold': 11,
          'products_purchased': 20,
          'out_of_stock': 1,
          'low_stock': 2,
          'near_stockout': 3,
          'unpaid_invoices': 4,
          'pending_supplier_payments': 5,
          'important_expenses': 1,
          'notification_count': 16,
          'comparisons': {
            'revenue': {
              'current': '1200.50',
              'previous': '1000.00',
              'percent': '20.05',
              'direction': 'up',
            },
          },
          'top_products': [
            {'product__name': 'Butane', 'quantity': 7, 'total': '700.00'},
          ],
          'top_clients': [
            {'client__name': 'Client A', 'count': 2, 'total': '500.00'},
          ],
          'can_filter_users': true,
          'selected_user_id': null,
          'selected_user': null,
        },
      }),
      queryParameters: {'period': 'month'},
    );

    final result = await repository.load(
      filter: const DashboardFilter(period: 'month'),
    );

    expect(result.revenue, '1200.50');
    expect(result.grossProfit, '500.00');
    expect(result.notificationCount, 16);
    expect(result.comparisons['revenue']?.previous, '1000.00');
    expect(result.topProducts.single.name, 'Butane');
    expect(result.canFilterUsers, isTrue);
  });

  test('le contrôleur de filtre change réellement la période', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(dashboardFilterProvider.notifier).selectPeriod('year');

    expect(container.read(dashboardFilterProvider).period, 'year');
  });
}
