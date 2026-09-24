import 'package:app_alim_gen_mobile/app/providers.dart';
import 'package:app_alim_gen_mobile/core/errors/app_failure.dart';
import 'package:app_alim_gen_mobile/core/navigation/module_scaffold.dart';
import 'package:app_alim_gen_mobile/core/permissions/permission_service.dart';
import 'package:app_alim_gen_mobile/core/pagination/page_data.dart';
import 'package:app_alim_gen_mobile/core/pagination/paged_list_body.dart';
import 'package:app_alim_gen_mobile/core/pagination/paged_list_controller.dart';
import 'package:app_alim_gen_mobile/features/business_lists/domain/business_entities.dart';
import 'package:app_alim_gen_mobile/features/business_lists/presentation/supplier_form_screen.dart';
import 'package:app_alim_gen_mobile/features/business_lists/presentation/expense_form_screen.dart';
import 'package:app_alim_gen_mobile/features/business_lists/presentation/transaction_form_screens.dart';
import 'package:app_alim_gen_mobile/features/business_lists/presentation/invoice_detail_screen.dart';
import 'package:app_alim_gen_mobile/features/business_lists/presentation/sale_detail_screen.dart';
import 'package:app_alim_gen_mobile/features/auth/presentation/auth_controller.dart';
import 'package:app_alim_gen_mobile/l10n/app_localizations.dart';
import 'package:app_alim_gen_mobile/l10n/crud_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InvoicesController extends PagedListController<InvoiceSummary> {
  @override
  Future<PageData<InvoiceSummary>> fetchPage({
    required int page,
    required String query,
  }) => ref.read(invoicesRepositoryProvider).fetch(page: page, query: query);
}

class SuppliersController extends PagedListController<SupplierSummary> {
  @override
  Future<PageData<SupplierSummary>> fetchPage({
    required int page,
    required String query,
  }) => ref.read(suppliersRepositoryProvider).fetch(page: page, query: query);
}

class SalesController extends PagedListController<SaleSummary> {
  @override
  Future<PageData<SaleSummary>> fetchPage({
    required int page,
    required String query,
  }) => ref.read(salesRepositoryProvider).fetch(page: page, query: query);
}

class PurchasesController extends PagedListController<PurchaseSummary> {
  @override
  Future<PageData<PurchaseSummary>> fetchPage({
    required int page,
    required String query,
  }) => ref.read(purchasesRepositoryProvider).fetch(page: page, query: query);
}

class ExpensesController extends PagedListController<ExpenseSummary> {
  @override
  Future<PageData<ExpenseSummary>> fetchPage({
    required int page,
    required String query,
  }) => ref.read(expensesRepositoryProvider).fetch(page: page, query: query);
}

class PaymentsController extends PagedListController<PaymentSummary> {
  @override
  Future<PageData<PaymentSummary>> fetchPage({
    required int page,
    required String query,
  }) => ref.read(paymentsRepositoryProvider).fetch(page: page, query: query);
}

final invoicesProvider =
    NotifierProvider<InvoicesController, PagedListState<InvoiceSummary>>(
      InvoicesController.new,
    );
final suppliersProvider =
    NotifierProvider<SuppliersController, PagedListState<SupplierSummary>>(
      SuppliersController.new,
    );
final salesProvider =
    NotifierProvider<SalesController, PagedListState<SaleSummary>>(
      SalesController.new,
    );
final purchasesProvider =
    NotifierProvider<PurchasesController, PagedListState<PurchaseSummary>>(
      PurchasesController.new,
    );
final expensesProvider =
    NotifierProvider<ExpensesController, PagedListState<ExpenseSummary>>(
      ExpensesController.new,
    );
final paymentsProvider =
    NotifierProvider<PaymentsController, PagedListState<PaymentSummary>>(
      PaymentsController.new,
    );

String _date(String value) =>
    value.length >= 10 ? value.substring(0, 10) : value;
Widget _recordCard(
  BuildContext context, {
  required IconData icon,
  required String title,
  required List<String> details,
  required String amount,
  VoidCallback? onTap,
}) => Card(
  child: ListTile(
    leading: Icon(icon),
    title: Text(title.isEmpty ? '—' : title),
    subtitle: Text(details.where((value) => value.isNotEmpty).join('\n')),
    trailing: Text(amount, style: Theme.of(context).textTheme.titleMedium),
    isThreeLine: details.length > 1,
    onTap: onTap,
  ),
);

class InvoicesScreen extends ConsumerWidget {
  const InvoicesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context);
    return ModuleScaffold(
      title: s.text('invoices'),
      path: '/invoices',
      body: PagedListBody<InvoiceSummary, InvoicesController>(
        provider: invoicesProvider,
        searchable: true,
        itemBuilder: (context, item) => _recordCard(
          context,
          icon: Icons.receipt_long_outlined,
          title: item.number,
          details: [
            '${s.text('client')}: #${item.clientId ?? '—'}',
            '${s.text('date')}: ${_date(item.date)}',
            '${s.text('status')}: ${item.paymentStatus}',
          ],
          amount: '${item.total} DZD',
          onTap: () => Navigator.push<void>(
            context,
            MaterialPageRoute(
              builder: (_) => InvoiceDetailScreen(invoiceId: item.id),
            ),
          ),
        ),
      ),
    );
  }
}

class SuppliersScreen extends ConsumerWidget {
  const SuppliersScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context);
    final crud = CrudStrings.of(context);
    final user = ref.watch(authControllerProvider).user;
    final canAdd = user?.can(AppPermissions.addSupplier) ?? false;
    final canChange = user?.can(AppPermissions.changeSupplier) ?? false;
    final canDelete = user?.can(AppPermissions.deleteSupplier) ?? false;
    return ModuleScaffold(
      title: s.suppliers,
      path: '/suppliers',
      body: PagedListBody<SupplierSummary, SuppliersController>(
        provider: suppliersProvider,
        searchable: true,
        itemBuilder: (context, item) => Card(
          child: ListTile(
            leading: const Icon(Icons.local_shipping_outlined),
            title: Text(item.name),
            subtitle: Text(
              [
                if (item.phone.isNotEmpty) '${s.text('phone')}: ${item.phone}',
                if (item.address.isNotEmpty)
                  '${s.text('address')}: ${item.address}',
              ].join('\n'),
            ),
            trailing: canChange || canDelete
                ? PopupMenuButton<String>(
                    onSelected: (action) async {
                      if (action == 'edit') {
                        final changed = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) =>
                                SupplierFormScreen(supplierId: item.id),
                          ),
                        );
                        if (changed == true) {
                          ref.read(suppliersProvider.notifier).refresh();
                        }
                      } else {
                        await _deleteSupplier(context, ref, item);
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
                  )
                : null,
          ),
        ),
      ),
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
              onPressed: () async {
                final changed = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const SupplierFormScreen()),
                );
                if (changed == true) {
                  ref.read(suppliersProvider.notifier).refresh();
                }
              },
              icon: const Icon(Icons.add),
              label: Text(crud.text('newSupplier')),
            )
          : null,
    );
  }

  Future<void> _deleteSupplier(
    BuildContext context,
    WidgetRef ref,
    SupplierSummary item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(CrudStrings.of(context).text('confirmDelete')),
        content: Text(item.name),
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
      await ref.read(suppliersRepositoryProvider).delete(item.id);
      await ref.read(suppliersProvider.notifier).refresh();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Suppression réussie.')));
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

class SalesScreen extends ConsumerWidget {
  const SalesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context);
    final user = ref.watch(authControllerProvider).user;
    final canAdd = user?.can(AppPermissions.addSale) ?? false;
    final canDelete = user?.can(AppPermissions.deleteSale) ?? false;
    return ModuleScaffold(
      title: s.sales,
      path: '/sales',
      body: PagedListBody<SaleSummary, SalesController>(
        provider: salesProvider,
        itemBuilder: (context, item) => Card(
          child: ListTile(
            onTap: () async {
              final changed = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => SaleDetailScreen(saleId: item.id),
                ),
              );
              if (changed == true) ref.read(salesProvider.notifier).refresh();
            },
            leading: const Icon(Icons.point_of_sale_outlined),
            title: Text(item.number),
            subtitle: Text(
              '${s.text('client')}: ${item.clientName.isEmpty ? '#${item.clientId ?? '—'}' : item.clientName}\n${s.text('date')}: ${_date(item.date)}\n${s.text('status')}: ${item.paymentStatus}',
            ),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${item.total} DZD'),
                PopupMenuButton<String>(
                  onSelected: (action) async {
                    if (action == 'view') {
                      final changed = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SaleDetailScreen(saleId: item.id),
                        ),
                      );
                      if (changed == true) {
                        ref.read(salesProvider.notifier).refresh();
                      }
                    } else if (action == 'delete') {
                      await _deleteSale(context, ref, item.id);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'view', child: Text('Voir')),
                    if (canDelete)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Supprimer'),
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
                final changed = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const SaleFormScreen()),
                );
                if (changed == true) ref.read(salesProvider.notifier).refresh();
              },
              icon: const Icon(Icons.add),
              label: const Text('Nouvelle vente'),
            )
          : null,
    );
  }

  Future<void> _deleteSale(BuildContext context, WidgetRef ref, int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Confirmer la suppression ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(salesRepositoryProvider).delete(id);
      await ref.read(salesProvider.notifier).refresh();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is AppFailure ? e.message : e.toString())),
        );
      }
    }
  }
}

class PurchasesScreen extends ConsumerWidget {
  const PurchasesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context);
    final user = ref.watch(authControllerProvider).user;
    final canAdd = user?.can(AppPermissions.addPurchase) ?? false;
    final canDelete = user?.can(AppPermissions.deletePurchase) ?? false;
    return ModuleScaffold(
      title: s.text('purchases'),
      path: '/purchases',
      body: PagedListBody<PurchaseSummary, PurchasesController>(
        provider: purchasesProvider,
        itemBuilder: (context, item) => Card(
          child: ListTile(
            leading: const Icon(Icons.shopping_cart_checkout_outlined),
            title: Text(item.reference),
            subtitle: Text(
              '${s.text('supplier')}: #${item.supplierId ?? '—'}\n${s.text('date')}: ${_date(item.date)}\n${s.text('status')}: ${item.paymentStatus}',
            ),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${item.total} DZD'),
                if (canDelete)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _deletePurchase(context, ref, item.id),
                  ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
              onPressed: () async {
                final changed = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const PurchaseFormScreen()),
                );
                if (changed == true) {
                  ref.read(purchasesProvider.notifier).refresh();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Nouvel achat'),
            )
          : null,
    );
  }

  Future<void> _deletePurchase(
    BuildContext context,
    WidgetRef ref,
    int id,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Confirmer la suppression ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(purchasesRepositoryProvider).delete(id);
      await ref.read(purchasesProvider.notifier).refresh();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is AppFailure ? e.message : e.toString())),
        );
      }
    }
  }
}

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context);
    final crud = CrudStrings.of(context);
    final user = ref.watch(authControllerProvider).user;
    final canAdd = user?.can(AppPermissions.addExpense) ?? false;
    final canChange = user?.can(AppPermissions.changeExpense) ?? false;
    final canDelete = user?.can(AppPermissions.deleteExpense) ?? false;
    return ModuleScaffold(
      title: s.text('expenses'),
      path: '/expenses',
      body: PagedListBody<ExpenseSummary, ExpensesController>(
        provider: expensesProvider,
        itemBuilder: (context, item) => Card(
          child: ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: Text(item.number),
            subtitle: Text(
              '${item.description}\n${s.text('date')}: ${_date(item.date)}\n${item.paymentMethod}',
            ),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${item.amount} DZD'),
                if (canChange || canDelete)
                  PopupMenuButton<String>(
                    onSelected: (action) async {
                      if (action == 'edit') {
                        final changed = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) =>
                                ExpenseFormScreen(expenseId: item.id),
                          ),
                        );
                        if (changed == true) {
                          ref.read(expensesProvider.notifier).refresh();
                        }
                      } else {
                        await _deleteExpense(context, ref, item);
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
                  MaterialPageRoute(builder: (_) => const ExpenseFormScreen()),
                );
                if (changed == true) {
                  ref.read(expensesProvider.notifier).refresh();
                }
              },
              icon: const Icon(Icons.add),
              label: Text(crud.text('newExpense')),
            )
          : null,
    );
  }

  Future<void> _deleteExpense(
    BuildContext context,
    WidgetRef ref,
    ExpenseSummary item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(CrudStrings.of(context).text('confirmDelete')),
        content: Text(item.number),
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
      await ref.read(expensesRepositoryProvider).delete(item.id);
      await ref.read(expensesProvider.notifier).refresh();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Suppression réussie.')));
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

class PaymentsScreen extends ConsumerWidget {
  const PaymentsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context);
    final user = ref.watch(authControllerProvider).user;
    final canCreate =
        (user?.can(AppPermissions.changeSale) ?? false) ||
        (user?.can(AppPermissions.changePurchase) ?? false);
    return ModuleScaffold(
      title: s.text('payments'),
      path: '/payments',
      body: PagedListBody<PaymentSummary, PaymentsController>(
        provider: paymentsProvider,
        itemBuilder: (context, item) => _recordCard(
          context,
          icon: Icons.payments_outlined,
          title: item.reference,
          details: ['${s.text('date')}: ${_date(item.date)}', item.paymentType],
          amount: '${item.amount} DZD',
        ),
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () async {
                final changed = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const PaymentFormScreen()),
                );
                if (changed == true) {
                  ref.read(paymentsProvider.notifier).refresh();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Nouveau paiement'),
            )
          : null,
    );
  }
}
