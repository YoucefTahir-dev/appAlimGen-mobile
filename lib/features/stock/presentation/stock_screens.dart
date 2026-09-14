import 'package:app_alim_gen_mobile/app/providers.dart';
import 'package:app_alim_gen_mobile/core/navigation/module_scaffold.dart';
import 'package:app_alim_gen_mobile/core/pagination/page_data.dart';
import 'package:app_alim_gen_mobile/core/pagination/paged_list_body.dart';
import 'package:app_alim_gen_mobile/core/pagination/paged_list_controller.dart';
import 'package:app_alim_gen_mobile/features/products/domain/product_summary.dart';
import 'package:app_alim_gen_mobile/features/stock/domain/operator_stock_summary.dart';
import 'package:app_alim_gen_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StockController extends PagedListController<ProductSummary> {
  @override
  Future<PageData<ProductSummary>> fetchPage({
    required int page,
    required String query,
  }) => ref.read(stockRepositoryProvider).fetch(page: page, query: query);
}

class OperatorStockController
    extends PagedListController<OperatorStockSummary> {
  @override
  Future<PageData<OperatorStockSummary>> fetchPage({
    required int page,
    required String query,
  }) =>
      ref.read(operatorStockRepositoryProvider).fetch(page: page, query: query);
}

final stockProvider =
    NotifierProvider<StockController, PagedListState<ProductSummary>>(
      StockController.new,
    );
final operatorStockProvider =
    NotifierProvider<
      OperatorStockController,
      PagedListState<OperatorStockSummary>
    >(OperatorStockController.new);

class StockScreen extends StatelessWidget {
  const StockScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return ModuleScaffold(
      title: s.text('stock'),
      path: '/stock',
      body: PagedListBody<ProductSummary, StockController>(
        provider: stockProvider,
        searchable: true,
        itemBuilder: (_, item) => Card(
          child: ListTile(
            leading: const Icon(Icons.warehouse_outlined),
            title: Text(item.name),
            subtitle: Text('${s.text('reference')}: ${item.reference}'),
            trailing: Text(
              '${item.quantity}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
      ),
    );
  }
}

class OperatorStockScreen extends StatelessWidget {
  const OperatorStockScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return ModuleScaffold(
      title: s.text('operatorStock'),
      path: '/operator-stock',
      body: PagedListBody<OperatorStockSummary, OperatorStockController>(
        provider: operatorStockProvider,
        itemBuilder: (_, item) => Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 20,
                  runSpacing: 8,
                  children: [
                    if (item.loaded != null)
                      _Metric(s.text('loaded'), item.loaded!),
                    if (item.sold != null) _Metric(s.text('sold'), item.sold!),
                    _Metric(s.text('remaining'), item.remaining),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value);
  final String label;
  final int value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelMedium),
      Text('$value', style: Theme.of(context).textTheme.titleLarge),
    ],
  );
}
