import 'package:app_alim_gen_mobile/app/providers.dart';
import 'package:app_alim_gen_mobile/core/navigation/module_scaffold.dart';
import 'package:app_alim_gen_mobile/core/errors/app_failure.dart';
import 'package:app_alim_gen_mobile/core/permissions/permission_service.dart';
import 'package:app_alim_gen_mobile/core/pagination/page_data.dart';
import 'package:app_alim_gen_mobile/core/pagination/paged_list_body.dart';
import 'package:app_alim_gen_mobile/core/pagination/paged_list_controller.dart';
import 'package:app_alim_gen_mobile/features/loading_orders/domain/loading_order_summary.dart';
import 'package:app_alim_gen_mobile/features/loading_orders/presentation/loading_order_form_screen.dart';
import 'package:app_alim_gen_mobile/features/auth/presentation/auth_controller.dart';
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

class LoadingOrdersScreen extends ConsumerWidget {
  const LoadingOrdersScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context);
    final user = ref.watch(authControllerProvider).user;
    final canAdd = user?.can(AppPermissions.addLoadingOrder) ?? false;
    final canChange = user?.can(AppPermissions.changeLoadingOrder) ?? false;
    final canDelete = user?.can(AppPermissions.deleteLoadingOrder) ?? false;
    final canValidate = user?.can(AppPermissions.validateLoadingOrder) ?? false;
    final canClose = user?.can(AppPermissions.closeLoadingOrder) ?? false;
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
            children: [
              ...order.lines.map(
                (line) => ListTile(
                  dense: true,
                  title: Text(line.productName),
                  subtitle: Text(
                    '${s.text('loaded')}: ${line.loaded} • ${s.text('sold')}: ${line.sold} • ${s.text('returned')}: ${line.returned}',
                  ),
                ),
              ),
              if (order.status == 'draft')
                Wrap(
                  spacing: 8,
                  children: [
                    if (canChange)
                      TextButton.icon(
                        onPressed: () async {
                          final changed = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  LoadingOrderFormScreen(orderId: order.id),
                            ),
                          );
                          if (changed == true) {
                            ref.read(loadingOrdersProvider.notifier).refresh();
                          }
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Modifier'),
                      ),
                    if (canValidate)
                      FilledButton(
                        onPressed: () =>
                            _action(context, ref, order, 'validate'),
                        child: const Text('Valider'),
                      ),
                    if (canDelete)
                      OutlinedButton(
                        onPressed: () => _action(context, ref, order, 'cancel'),
                        child: const Text('Annuler'),
                      ),
                  ],
                ),
              if ((order.status == 'validated' ||
                      order.status == 'in_progress') &&
                  canClose)
                FilledButton(
                  onPressed: () => _action(context, ref, order, 'close'),
                  child: const Text('Clôturer'),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
              onPressed: () async {
                final changed = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LoadingOrderFormScreen(),
                  ),
                );
                if (changed == true) {
                  ref.read(loadingOrdersProvider.notifier).refresh();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Nouveau bon'),
            )
          : null,
    );
  }

  Future<void> _action(
    BuildContext context,
    WidgetRef ref,
    LoadingOrderSummary order,
    String action,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Confirmer : $action ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final key = (action == 'validate' || action == 'close')
          ? ref.read(loadingOrdersRepositoryProvider).newKey()
          : null;
      await ref
          .read(loadingOrdersRepositoryProvider)
          .action(order.id, action, key: key);
      await ref.read(loadingOrdersProvider.notifier).refresh();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is AppFailure ? e.message : e.toString())),
        );
      }
    }
  }
}
