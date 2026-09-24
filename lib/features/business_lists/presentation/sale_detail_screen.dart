import 'package:app_alim_gen_mobile/app/providers.dart';
import 'package:app_alim_gen_mobile/core/errors/app_failure.dart';
import 'package:app_alim_gen_mobile/core/permissions/permission_service.dart';
import 'package:app_alim_gen_mobile/features/auth/presentation/auth_controller.dart';
import 'package:app_alim_gen_mobile/features/business_lists/domain/business_entities.dart';
import 'package:app_alim_gen_mobile/features/business_lists/presentation/invoice_detail_screen.dart';
import 'package:app_alim_gen_mobile/features/business_lists/presentation/sales_strings.dart';
import 'package:app_alim_gen_mobile/features/business_lists/presentation/transaction_form_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SaleDetailScreen extends ConsumerStatefulWidget {
  const SaleDetailScreen({super.key, required this.saleId});
  final int saleId;

  @override
  ConsumerState<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends ConsumerState<SaleDetailScreen> {
  late Future<SaleDetails> _sale;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _sale = ref.read(salesRepositoryProvider).get(widget.saleId);
  }

  String _error(Object error) =>
      error is AppFailure ? error.message : error.toString();

  Future<void> _edit(SaleDetails sale) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => SaleFormScreen(initial: sale)),
    );
    if (changed == true && mounted) setState(_reload);
  }

  Future<void> _payment(SaleDetails sale) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentFormScreen(
          initialSaleId: sale.id,
          total: sale.total,
          amountPaid: sale.amountPaid,
          balanceDue: sale.balanceDue,
        ),
      ),
    );
    if (changed == true && mounted) setState(_reload);
  }

  Future<void> _delete() async {
    final t = SalesStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t('deleteSaleTitle')),
        content: Text(t('deleteSaleWarning')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(t('no')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(t('delete')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(salesRepositoryProvider).delete(widget.saleId);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_error(error))));
    }
  }

  String _status(String value) => switch (value) {
    'paid' => SalesStrings.of(context)('paidStatus'),
    'partial' => SalesStrings.of(context)('partialStatus'),
    'unpaid' => SalesStrings.of(context)('unpaidStatus'),
    'unreconciled' => SalesStrings.of(context)('unreconciledStatus'),
    _ => value,
  };

  @override
  Widget build(BuildContext context) {
    final t = SalesStrings.of(context);
    final user = ref.watch(authControllerProvider).user;
    return Scaffold(
      appBar: AppBar(title: Text(t('saleDetail'))),
      body: FutureBuilder<SaleDetails>(
        future: _sale,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error(snapshot.error!)),
                  FilledButton(
                    onPressed: () => setState(_reload),
                    child: Text(t('retry')),
                  ),
                ],
              ),
            );
          }
          final sale = snapshot.data!;
          final canUpdate =
              sale.capabilities.canUpdate &&
              (user?.can(AppPermissions.changeSale) ?? false);
          final canInvoice =
              sale.capabilities.canViewInvoice &&
              (user?.can(AppPermissions.invoices) ?? false);
          final canPrint =
              sale.capabilities.canPrint &&
              (user?.can(AppPermissions.printInvoice) ?? false);
          final canPay =
              sale.capabilities.canAddPayment &&
              (user?.can(AppPermissions.changeSale) ?? false) &&
              (double.tryParse(sale.balanceDue) ?? 0) > 0;
          final canDelete =
              sale.capabilities.canDelete &&
              (user?.can(AppPermissions.deleteSale) ?? false);
          return RefreshIndicator(
            onRefresh: () async {
              setState(_reload);
              await _sale;
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  sale.number,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text('${t('date')} : ${sale.date}'),
                Text('${t('status')} : ${_status(sale.paymentStatus)}'),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(sale.client.name),
                    subtitle: Text(
                      [
                        sale.client.phone,
                        sale.client.address,
                        sale.client.customerType,
                      ].where((value) => value.isNotEmpty).join('\n'),
                    ),
                  ),
                ),
                Text(
                  t('products'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                for (final line in sale.lines)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(line.productName),
                    subtitle: Text(
                      '${line.packagingName} · ${line.quantity} × ${line.unitPrice} DZD',
                    ),
                    trailing: Text('${line.total} DZD'),
                  ),
                const Divider(height: 28),
                _SaleAmount(label: t('subtotal'), value: sale.subtotal),
                _SaleAmount(label: t('discount'), value: sale.discount),
                _SaleAmount(label: t('tax'), value: sale.taxAmount),
                _SaleAmount(
                  label: t('totalTtc'),
                  value: sale.total,
                  strong: true,
                ),
                _SaleAmount(label: t('paid'), value: sale.amountPaid),
                _SaleAmount(label: t('due'), value: sale.balanceDue),
                Text('${t('paymentMethod')} : ${sale.paymentType}'),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (canUpdate)
                      OutlinedButton.icon(
                        key: const Key('sale-edit-action'),
                        onPressed: () => _edit(sale),
                        icon: const Icon(Icons.edit_outlined),
                        label: Text(t('edit')),
                      ),
                    if (canPrint)
                      FilledButton.icon(
                        key: const Key('sale-print-action'),
                        onPressed: () => Navigator.push<void>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => InvoiceDetailScreen(
                              invoiceId: sale.id,
                              autoPrint: true,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.print_outlined),
                        label: Text(t('print')),
                      ),
                    if (canPay)
                      FilledButton.tonalIcon(
                        key: const Key('sale-payment-action'),
                        onPressed: () => _payment(sale),
                        icon: const Icon(Icons.payments_outlined),
                        label: Text(t('payment')),
                      ),
                    if (canInvoice)
                      OutlinedButton.icon(
                        onPressed: () => Navigator.push<void>(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                InvoiceDetailScreen(invoiceId: sale.id),
                          ),
                        ),
                        icon: const Icon(Icons.receipt_long_outlined),
                        label: Text(t('invoice')),
                      ),
                  ],
                ),
                if (canDelete)
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton.icon(
                      onPressed: _delete,
                      icon: const Icon(Icons.delete_outline),
                      label: Text(t('delete')),
                    ),
                  ),
                const SizedBox(height: 20),
                Text(
                  t('payments'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (sale.payments.isEmpty)
                  Text(t('noPayment'))
                else
                  for (final payment in sale.payments)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        '${payment.amount} DZD · ${payment.paymentType}',
                      ),
                      subtitle: Text('${payment.reference}\n${payment.date}'),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SaleAmount extends StatelessWidget {
  const _SaleAmount({
    required this.label,
    required this.value,
    this.strong = false,
  });
  final String label, value;
  final bool strong;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label),
      Text(
        '$value DZD',
        style: strong ? const TextStyle(fontWeight: FontWeight.bold) : null,
      ),
    ],
  );
}
