import 'package:app_alim_gen_mobile/app/providers.dart';
import 'package:app_alim_gen_mobile/core/navigation/module_scaffold.dart';
import 'package:app_alim_gen_mobile/core/pagination/page_data.dart';
import 'package:app_alim_gen_mobile/core/pagination/paged_list_body.dart';
import 'package:app_alim_gen_mobile/core/pagination/paged_list_controller.dart';
import 'package:app_alim_gen_mobile/features/products/domain/product_summary.dart';
import 'package:app_alim_gen_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProductsController extends PagedListController<ProductSummary> {
  @override
  Future<PageData<ProductSummary>> fetchPage({
    required int page,
    required String query,
  }) => ref.read(productsRepositoryProvider).fetch(page: page, query: query);
}

final productsProvider =
    NotifierProvider<ProductsController, PagedListState<ProductSummary>>(
      ProductsController.new,
    );

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return ModuleScaffold(
      title: strings.products,
      path: '/products',
      body: PagedListBody<ProductSummary, ProductsController>(
        provider: productsProvider,
        searchable: true,
        itemBuilder: (context, product) => Card(
          child: ListTile(
            leading: CircleAvatar(child: Text('${product.quantity}')),
            title: Text(product.name),
            subtitle: Text(
              '${strings.text('reference')}: ${product.reference}\n${strings.text('quantity')}: ${product.quantity}${product.retailPrice == null ? '' : '\n${strings.text('price')}: ${product.retailPrice} DZD'}',
            ),
            isThreeLine: product.retailPrice != null,
            trailing: _StockStatus(status: product.stockStatus),
          ),
        ),
      ),
    );
  }
}

class _StockStatus extends StatelessWidget {
  const _StockStatus({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'out_of_stock' => Colors.red,
      'critical' => Colors.deepOrange,
      'low' => Colors.amber.shade800,
      _ => Colors.green,
    };
    return Icon(Icons.circle, size: 12, color: color);
  }
}
