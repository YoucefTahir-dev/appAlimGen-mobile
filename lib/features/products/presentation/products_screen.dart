import 'package:app_alim_gen_mobile/app/providers.dart';
import 'package:app_alim_gen_mobile/core/errors/app_failure.dart';
import 'package:app_alim_gen_mobile/core/navigation/module_scaffold.dart';
import 'package:app_alim_gen_mobile/core/permissions/permission_service.dart';
import 'package:app_alim_gen_mobile/core/pagination/page_data.dart';
import 'package:app_alim_gen_mobile/core/pagination/paged_list_body.dart';
import 'package:app_alim_gen_mobile/core/pagination/paged_list_controller.dart';
import 'package:app_alim_gen_mobile/core/utils/app_formats.dart';
import 'package:app_alim_gen_mobile/core/widgets/app_ui.dart';
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
        emptyIcon: Icons.inventory_2_outlined,
        itemBuilder: (context, product) => AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      product.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  _StockStatus(status: product.stockStatus),
                  if (canChange || canDelete)
                    IconButton(
                      tooltip: strings.text('more'),
                      onPressed: () => _showActions(
                        context,
                        ref,
                        product,
                        canChange: canChange,
                        canDelete: canDelete,
                      ),
                      icon: const Icon(Icons.more_vert),
                    ),
                ],
              ),
              if (product.reference.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  product.reference,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _ProductMetric(
                      label: strings.text('quantity'),
                      value: '${product.quantity}',
                    ),
                  ),
                  if (product.retailPrice != null)
                    Expanded(
                      child: _ProductMetric(
                        label: strings.text('price'),
                        value: AppFormats.money(product.retailPrice),
                        alignEnd: true,
                      ),
                    ),
                ],
              ),
            ],
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

  Future<void> _showActions(
    BuildContext context,
    WidgetRef ref,
    ProductSummary product, {
    required bool canChange,
    required bool canDelete,
  }) async {
    final crud = CrudStrings.of(context);
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  product.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (canChange)
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: Text(crud.text('edit')),
                  onTap: () => Navigator.pop(context, 'edit'),
                ),
              if (canDelete)
                ListTile(
                  leading: Icon(
                    Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(crud.text('delete')),
                  textColor: Theme.of(context).colorScheme.error,
                  onTap: () => Navigator.pop(context, 'delete'),
                ),
            ],
          ),
        ),
      ),
    );
    if (!context.mounted) return;
    if (action == 'edit') {
      final changed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => ProductFormScreen(productId: product.id),
        ),
      );
      if (changed == true) ref.read(productsProvider.notifier).refresh();
    } else if (action == 'delete') {
      await _deleteProduct(context, ref, product);
    }
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

class _ProductMetric extends StatelessWidget {
  const _ProductMetric({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });
  final String label;
  final String value;
  final bool alignEnd;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: alignEnd
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      Text(value, style: Theme.of(context).textTheme.titleMedium),
    ],
  );
}

class _StockStatus extends StatelessWidget {
  const _StockStatus({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final tone = switch (status) {
      'out_of_stock' => StatusTone.danger,
      'critical' || 'low' => StatusTone.warning,
      _ => StatusTone.success,
    };
    final key = switch (status) {
      'out_of_stock' => 'stockOut',
      'critical' => 'stockCritical',
      'low' => 'stockLow',
      _ => 'stockOk',
    };
    return StatusBadge(
      label: AppLocalizations.of(context).text(key),
      tone: tone,
      icon: Icons.circle,
    );
  }
}
