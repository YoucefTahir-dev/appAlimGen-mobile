import 'package:app_alim_gen_mobile/app/providers.dart';
import 'package:app_alim_gen_mobile/core/navigation/module_scaffold.dart';
import 'package:app_alim_gen_mobile/core/pagination/page_data.dart';
import 'package:app_alim_gen_mobile/core/pagination/paged_list_body.dart';
import 'package:app_alim_gen_mobile/core/pagination/paged_list_controller.dart';
import 'package:app_alim_gen_mobile/features/loading_orders/domain/loading_order_summary.dart';
import 'package:app_alim_gen_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoadingOrdersController extends PagedListController<LoadingOrderSummary> {
  @override
  Future<PageData<LoadingOrderSummary>> fetchPage({
    required int page,
    required String query,
  }) =>
      ref.read(loadingOrdersRepositoryProvider).fetch(page: page, query: query);
}

final loadingOrdersProvider =
    NotifierProvider<
      LoadingOrdersController,
      PagedListState<LoadingOrderSummary>
    >(LoadingOrdersController.new);

class LoadingOrdersScreen extends StatelessWidget {
  const LoadingOrdersScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return ModuleScaffold(
      title: s.text('loadingOrders'),
      path: '/loading-orders',
      body: PagedListBody<LoadingOrderSummary, LoadingOrdersController>(
        provider: loadingOrdersProvider,
        searchable: true,
        itemBuilder: (_, order) => Card(
          child: ExpansionTile(
            leading: const Icon(Icons.local_shipping),
            title: Text(order.number),
            subtitle: Text(
              '${s.text('operator')}: ${order.operatorName}\n${s.text('status')}: ${order.status}',
            ),
            children: order.lines
                .map(
                  (line) => ListTile(
                    dense: true,
                    title: Text(line.productName),
                    subtitle: Text(
                      '${s.text('loaded')}: ${line.loaded} • ${s.text('sold')}: ${line.sold} • ${s.text('returned')}: ${line.returned}',
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}
