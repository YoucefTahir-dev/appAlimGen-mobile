import 'package:app_alim_gen_mobile/app/providers.dart';
import 'package:app_alim_gen_mobile/core/errors/app_failure.dart';
import 'package:app_alim_gen_mobile/core/navigation/module_scaffold.dart';
import 'package:app_alim_gen_mobile/core/permissions/permission_service.dart';
import 'package:app_alim_gen_mobile/core/pagination/page_data.dart';
import 'package:app_alim_gen_mobile/core/pagination/paged_list_body.dart';
import 'package:app_alim_gen_mobile/core/pagination/paged_list_controller.dart';
import 'package:app_alim_gen_mobile/features/products/domain/product_summary.dart';
import 'package:app_alim_gen_mobile/features/products/presentation/product_form_screen.dart';
import 'package:app_alim_gen_mobile/features/auth/presentation/auth_controller.dart';
import 'package:app_alim_gen_mobile/l10n/app_localizations.dart';
import 'package:app_alim_gen_mobile/l10n/crud_strings.dart';
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

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final crud = CrudStrings.of(context);
    final user = ref.watch(authControllerProvider).user;
    final canAdd = user?.can(AppPermissions.addProduct) ?? false;
    final canChange = user?.can(AppPermissions.changeProduct) ?? false;
    final canDelete = user?.can(AppPermissions.deleteProduct) ?? false;
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
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StockStatus(status: product.stockStatus),
                if (canChange || canDelete)
                  PopupMenuButton<String>(
                    onSelected: (action) async {
                      if (action == 'edit') {
                        final changed = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) =>
                                ProductFormScreen(productId: product.id),
                          ),
                        );
                        if (changed == true) {
                          ref.read(productsProvider.notifier).refresh();
                        }
                      } else if (action == 'delete') {
                        await _deleteProduct(context, ref, product);
                      }
                    },
                    itemBuilder: (_) => [
                      if (canChange)
                        PopupMenuItem(
                          value: 'edit',
                          child: Text(crud.text('edit')),
                        ),
                      if (canDelete)
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(crud.text('delete')),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
              onPressed: () async {
                final changed = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const ProductFormScreen()),
                );
                if (changed == true) {
                  ref.read(productsProvider.notifier).refresh();
                }
              },
              icon: const Icon(Icons.add),
              label: Text(crud.text('newProduct')),
            )
          : null,
    );
  }

  Future<void> _deleteProduct(
    BuildContext context,
    WidgetRef ref,
    ProductSummary product,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(CrudStrings.of(context).text('confirmDelete')),
        content: Text(product.name),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(CrudStrings.of(context).text('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(CrudStrings.of(context).text('delete')),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(productsRepositoryProvider).delete(product.id);
      await ref.read(productsProvider.notifier).refresh();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(CrudStrings.of(context).text('deleteSuccess')),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is AppFailure ? error.message : 'Suppression impossible.',
            ),
          ),
        );
      }
    }
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
