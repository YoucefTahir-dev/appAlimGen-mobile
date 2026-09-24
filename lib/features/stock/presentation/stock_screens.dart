import 'package:app_alim_gen_mobile/app/providers.dart';
import 'package:app_alim_gen_mobile/core/navigation/module_scaffold.dart';
import 'package:app_alim_gen_mobile/core/pagination/page_data.dart';
import 'package:app_alim_gen_mobile/core/pagination/paged_list_body.dart';
import 'package:app_alim_gen_mobile/core/pagination/paged_list_controller.dart';
import 'package:app_alim_gen_mobile/core/widgets/app_ui.dart';
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
        emptyIcon: Icons.warehouse_outlined,
        itemBuilder: (_, item) => AppCard(
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (item.reference.isNotEmpty)
                      Text(
                        item.reference,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${item.quantity}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    s.text('remaining'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
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
        emptyIcon: Icons.inventory_outlined,
        itemBuilder: (_, item) => AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.productName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  StatusBadge(
                    label: s.text(
                      item.remaining <= 0
                          ? 'stockOut'
                          : item.remaining <= 5
                          ? 'stockLow'
                          : 'stockOk',
                    ),
                    tone: item.remaining <= 0
                        ? StatusTone.danger
                        : item.remaining <= 5
                        ? StatusTone.warning
                        : StatusTone.success,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (item.loaded != null)
                    _Metric(s.text('loaded'), item.loaded!),
                  if (item.sold != null) _Metric(s.text('sold'), item.sold!),
                  _Metric(
                    s.text('remaining'),
                    item.remaining,
                    emphasized: true,
                  ),
                ],
              ),
              if (item.loaded != null && item.loaded! > 0) ...[
                const SizedBox(height: 14),
                LinearProgressIndicator(
                  value: (item.remaining / item.loaded!).clamp(0, 1).toDouble(),
                  minHeight: 7,
                  borderRadius: BorderRadius.circular(99),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, {this.emphasized = false});
  final String label;
  final int value;
  final bool emphasized;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelMedium),
      Text(
        '$value',
        style:
            (emphasized
                    ? Theme.of(context).textTheme.headlineSmall
                    : Theme.of(context).textTheme.titleLarge)
                ?.copyWith(
                  color: emphasized
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
      ),
    ],
  );
}
