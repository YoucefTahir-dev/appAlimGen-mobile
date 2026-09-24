import 'package:app_alim_gen_mobile/app/providers.dart';
import 'package:app_alim_gen_mobile/core/errors/app_failure.dart';
import 'package:app_alim_gen_mobile/core/navigation/module_scaffold.dart';
import 'package:app_alim_gen_mobile/core/permissions/permission_service.dart';
import 'package:app_alim_gen_mobile/core/pagination/page_data.dart';
import 'package:app_alim_gen_mobile/core/pagination/paged_list_body.dart';
import 'package:app_alim_gen_mobile/core/pagination/paged_list_controller.dart';
import 'package:app_alim_gen_mobile/core/utils/app_formats.dart';
import 'package:app_alim_gen_mobile/core/widgets/app_ui.dart';
import 'package:app_alim_gen_mobile/features/business_lists/domain/business_entities.dart';
import 'package:app_alim_gen_mobile/features/business_lists/presentation/supplier_form_screen.dart';
import 'package:app_alim_gen_mobile/features/business_lists/presentation/expense_form_screen.dart';
import 'package:app_alim_gen_mobile/features/business_lists/presentation/transaction_form_screens.dart';
import 'package:app_alim_gen_mobile/features/business_lists/presentation/invoice_detail_screen.dart';
import 'package:app_alim_gen_mobile/features/business_lists/presentation/sale_detail_screen.dart';
import 'package:app_alim_gen_mobile/features/business_lists/presentation/sales_strings.dart';
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
String _paymentLabel(BuildContext context, String status) => switch (status) {
  'paid' => SalesStrings.of(context)('paidStatus'),
  'partial' => SalesStrings.of(context)('partialStatus'),
  'unpaid' => SalesStrings.of(context)('unpaidStatus'),
  'unreconciled' => SalesStrings.of(context)('unreconciledStatus'),
  _ => status,
};
StatusTone _paymentTone(String status) => switch (status) {
  'paid' => StatusTone.success,
  'partial' => StatusTone.warning,
  'unpaid' => StatusTone.danger,
  _ => StatusTone.neutral,
};
Widget _recordCard(
  BuildContext context, {
  required IconData icon,
  required String title,
  required List<String> details,
  required String amount,
  VoidCallback? onTap,
}) => AppCard(
  onTap: onTap,
  child: Row(
    children: [
      CircleAvatar(child: Icon(icon, size: 20)),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.isEmpty ? '—' : title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            ...details
                .where((value) => value.isNotEmpty)
                .map(
                  (value) => Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
          ],
        ),
      ),
      const SizedBox(width: 8),
      Text(amount, style: Theme.of(context).textTheme.titleMedium),
    ],
  ),
);

class InvoicesScreen extends ConsumerWidget {
  const InvoicesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ModuleScaffold(
      title: AppLocalizations.of(context).text('invoices'),
      path: '/invoices',
      body: PagedListBody<InvoiceSummary, InvoicesController>(
        provider: invoicesProvider,
        searchable: true,
        emptyIcon: Icons.receipt_long_outlined,
        itemBuilder: (context, item) => InvoiceCard(
          invoice: item,
          onOpen: () => Navigator.push<void>(
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

class InvoiceCard extends StatelessWidget {
  const InvoiceCard({super.key, required this.invoice, required this.onOpen});
  final InvoiceSummary invoice;
  final VoidCallback onOpen;

  String _status(BuildContext context) => switch (invoice.paymentStatus) {
    'paid' => SalesStrings.of(context)('paidStatus'),
    'partial' => SalesStrings.of(context)('partialStatus'),
    'unpaid' => SalesStrings.of(context)('unpaidStatus'),
    'unreconciled' => SalesStrings.of(context)('unreconciledStatus'),
    _ => invoice.paymentStatus,
  };

  Color _color(BuildContext context) => switch (invoice.paymentStatus) {
    'paid' => Colors.green.shade700,
    'partial' => Colors.orange.shade800,
    'unpaid' => Theme.of(context).colorScheme.error,
    _ => Colors.blueGrey.shade700,
  };

  @override
  Widget build(BuildContext context) {
    final t = SalesStrings.of(context);
    final color = _color(context);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 13, 10, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      invoice.number,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Container(
                    key: Key('invoice-list-status-${invoice.paymentStatus}'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .11),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _status(context),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                invoice.clientName.isEmpty
                    ? '${t('client')} #${invoice.clientId ?? '—'}'
                    : invoice.clientName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                _invoiceDate(invoice.date),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Divider(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _InvoiceListAmount(
                      label: t('total'),
                      value: invoice.total,
                      strong: true,
                    ),
                  ),
                  Expanded(
                    child: _InvoiceListAmount(
                      label: t('paidShort'),
                      value: invoice.amountPaid,
                    ),
                  ),
                  Expanded(
                    child: _InvoiceListAmount(
                      label: t('dueShort'),
                      value: invoice.balanceDue,
                    ),
                  ),
                  TextButton(onPressed: onOpen, child: Text(t('preview'))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InvoiceListAmount extends StatelessWidget {
  const _InvoiceListAmount({
    required this.label,
    required this.value,
    this.strong = false,
  });
  final String label, value;
  final bool strong;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelSmall),
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          AppFormats.money(value),
          style: TextStyle(
            fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    ],
  );
}

String _invoiceDate(String value) {
  final parsed = DateTime.tryParse(value)?.toLocal();
  if (parsed == null) return _date(value);
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(parsed.day)}/${two(parsed.month)}/${parsed.year} · ${two(parsed.hour)}:${two(parsed.minute)}';
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
        emptyIcon: Icons.local_shipping_outlined,
        itemBuilder: (context, item) => AppCard(
          child: Row(
            children: [
              CircleAvatar(
                child: Text(
                  item.name.isEmpty
                      ? '?'
                      : item.name.characters.first.toUpperCase(),
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
                    if (item.phone.isNotEmpty)
                      Text(
                        item.phone,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    if (item.address.isNotEmpty)
                      Text(
                        item.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              if (canChange || canDelete)
                PopupMenuButton<String>(
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
                ),
            ],
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
    final crud = CrudStrings.of(context);
    final user = ref.watch(authControllerProvider).user;
    final canAdd = user?.can(AppPermissions.addSale) ?? false;
    final canDelete = user?.can(AppPermissions.deleteSale) ?? false;
    return ModuleScaffold(
      title: s.sales,
      path: '/sales',
      body: PagedListBody<SaleSummary, SalesController>(
        provider: salesProvider,
        searchable: true,
        emptyIcon: Icons.point_of_sale_outlined,
        itemBuilder: (context, item) => AppCard(
          onTap: () async {
            final changed = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => SaleDetailScreen(saleId: item.id),
              ),
            );
            if (changed == true) ref.read(salesProvider.notifier).refresh();
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.number,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  StatusBadge(
                    label: _paymentLabel(context, item.paymentStatus),
                    tone: _paymentTone(item.paymentStatus),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.clientName.isEmpty
                    ? '#${item.clientId ?? '—'}'
                    : item.clientName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                _date(item.date),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Divider(height: 22),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      AppFormats.money(item.total),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
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
                      PopupMenuItem(
                        value: 'view',
                        child: Text(crud.text('view')),
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
            ],
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
              label: Text(s.text('newSale')),
            )
          : null,
    );
  }

  Future<void> _deleteSale(BuildContext context, WidgetRef ref, int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(CrudStrings.of(context).text('confirmDelete')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(CrudStrings.of(context).text('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(CrudStrings.of(context).text('delete')),
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
        searchable: true,
        emptyIcon: Icons.shopping_cart_checkout_outlined,
        itemBuilder: (context, item) => AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.reference,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  StatusBadge(
                    label: _paymentLabel(context, item.paymentStatus),
                    tone: _paymentTone(item.paymentStatus),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('${s.text('supplier')}: #${item.supplierId ?? '—'}'),
              Text(
                _date(item.date),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Divider(height: 22),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      AppFormats.money(item.total),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  if (canDelete)
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _deletePurchase(context, ref, item.id),
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
                final changed = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const PurchaseFormScreen()),
                );
                if (changed == true) {
                  ref.read(purchasesProvider.notifier).refresh();
                }
              },
              icon: const Icon(Icons.add),
              label: Text(s.text('newPurchase')),
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
        title: Text(CrudStrings.of(context).text('confirmDelete')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(CrudStrings.of(context).text('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(CrudStrings.of(context).text('delete')),
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
        searchable: true,
        emptyIcon: Icons.account_balance_wallet_outlined,
        itemBuilder: (context, item) => AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.number,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    AppFormats.money(item.amount),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (canChange || canDelete)
                    PopupMenuButton<String>(
                      onSelected: (action) async {
                        if (action == 'edit') {
                          final changed = await Navigator.of(context)
                              .push<bool>(
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
              if (item.description.isNotEmpty)
                Text(
                  item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 15),
                  const SizedBox(width: 5),
                  Text(
                    _date(item.date),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.paymentMethod,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
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
        searchable: true,
        emptyIcon: Icons.payments_outlined,
        itemBuilder: (context, item) => _recordCard(
          context,
          icon: Icons.payments_outlined,
          title: item.reference,
          details: ['${s.text('date')}: ${_date(item.date)}', item.paymentType],
          amount: AppFormats.money(item.amount),
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
              label: Text(s.text('newPayment')),
            )
          : null,
    );
  }
}
