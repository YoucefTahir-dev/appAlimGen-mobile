import 'package:app_alim_gen_mobile/app/providers.dart';
import 'package:app_alim_gen_mobile/core/errors/app_failure.dart';
import 'package:app_alim_gen_mobile/core/permissions/permission_service.dart';
import 'package:app_alim_gen_mobile/features/auth/presentation/auth_controller.dart';
import 'package:app_alim_gen_mobile/features/business_lists/domain/business_entities.dart';
import 'package:app_alim_gen_mobile/features/business_lists/domain/invoice_document.dart';
import 'package:app_alim_gen_mobile/features/business_lists/presentation/invoice_preview_screen.dart';
import 'package:app_alim_gen_mobile/features/business_lists/presentation/sales_strings.dart';
import 'package:app_alim_gen_mobile/features/business_lists/presentation/transaction_form_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InvoiceDetailScreen extends ConsumerStatefulWidget {
  const InvoiceDetailScreen({
    super.key,
    required this.invoiceId,
    this.autoPrint = false,
  });
  final int invoiceId;
  final bool autoPrint;

  @override
  ConsumerState<InvoiceDetailScreen> createState() =>
      _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends ConsumerState<InvoiceDetailScreen> {
  late Future<SaleDetails> _invoice;
  bool _autoPrintStarted = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() =>
      _invoice = ref.read(invoicesRepositoryProvider).get(widget.invoiceId);
  String _message(Object error) =>
      error is AppFailure ? error.message : error.toString();
  bool _has(String permission) =>
      ref.read(authControllerProvider).user?.can(permission) ?? false;
  bool _canPrint(SaleDetails sale) =>
      sale.capabilities.canPrint && _has(AppPermissions.printInvoice);
  bool _canPdf(SaleDetails sale) =>
      sale.capabilities.canViewPdf && _has(AppPermissions.downloadInvoicePdf);
  bool _canEdit(SaleDetails sale) =>
      sale.capabilities.canUpdate && _has(AppPermissions.changeSale);
  bool _canPay(SaleDetails sale) =>
      sale.capabilities.canAddPayment &&
      _has(AppPermissions.changeSale) &&
      (double.tryParse(sale.balanceDue) ?? 0) > 0;

  Future<void> _preview(
    SaleDetails sale, {
    bool autoPrint = false,
    InvoicePaper? initialPaper,
  }) => Navigator.push<void>(
    context,
    MaterialPageRoute(
      builder: (_) => InvoicePreviewScreen(
        sale: sale,
        canPrint: _canPrint(sale),
        canViewPdf: _canPdf(sale),
        autoPrint: autoPrint,
        initialPaper: initialPaper,
      ),
    ),
  );

  Future<void> _edit(SaleDetails sale) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => SaleFormScreen(initial: sale)),
    );
    if (changed == true && mounted) setState(_reload);
  }

  Future<void> _addPayment(SaleDetails sale) async {
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

  String _status(BuildContext context, String value) => switch (value) {
    'paid' => SalesStrings.of(context)('paidStatus'),
    'partial' => SalesStrings.of(context)('partialStatus'),
    'unpaid' => SalesStrings.of(context)('unpaidStatus'),
    'unreconciled' => SalesStrings.of(context)('unreconciledStatus'),
    _ => value,
  };

  Color _statusColor(BuildContext context, String value) => switch (value) {
    'paid' => Colors.green.shade700,
    'partial' => Colors.orange.shade800,
    'unpaid' => Theme.of(context).colorScheme.error,
    _ => Colors.blueGrey.shade700,
  };

  @override
  Widget build(BuildContext context) {
    final t = SalesStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t('invoice'))),
      body: FutureBuilder<SaleDetails>(
        future: _invoice,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _message(snapshot.error!),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => setState(_reload),
                      child: Text(t('retry')),
                    ),
                  ],
                ),
              ),
            );
          }
          final sale = snapshot.data!;
          if (widget.autoPrint && _canPrint(sale) && !_autoPrintStarted) {
            _autoPrintStarted = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _preview(sale, autoPrint: true);
            });
          }
          return RefreshIndicator(
            onRefresh: () async {
              setState(_reload);
              await _invoice;
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                _InvoiceHeader(
                  sale: sale,
                  status: _status(context, sale.paymentStatus),
                  statusColor: _statusColor(context, sale.paymentStatus),
                ),
                const SizedBox(height: 12),
                _TotalsSummary(sale: sale),
                const SizedBox(height: 12),
                _ClientCard(sale: sale),
                const SizedBox(height: 12),
                _ProductsCard(sale: sale),
                const SizedBox(height: 12),
                _PreviewCard(
                  onPreview: () => _preview(sale),
                  onPrint: _canPrint(sale)
                      ? () => _preview(sale, autoPrint: true)
                      : null,
                ),
                const SizedBox(height: 14),
                _ActionBar(
                  canEdit: _canEdit(sale),
                  canPay: _canPay(sale),
                  canPdf: _canPdf(sale),
                  onEdit: () => _edit(sale),
                  onPayment: () => _addPayment(sale),
                  onPdf: () => _preview(sale, initialPaper: InvoicePaper.a4),
                ),
                const SizedBox(height: 20),
                _PaymentsCard(sale: sale),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InvoiceHeader extends StatelessWidget {
  const _InvoiceHeader({
    required this.sale,
    required this.status,
    required this.statusColor,
  });
  final SaleDetails sale;
  final String status;
  final Color statusColor;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: const Icon(Icons.receipt_long_outlined),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sale.number,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  _date(sale.date),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            key: Key('invoice-status-${sale.paymentStatus}'),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: statusColor.withValues(alpha: .35)),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _TotalsSummary extends StatelessWidget {
  const _TotalsSummary({required this.sale});
  final SaleDetails sale;
  @override
  Widget build(BuildContext context) {
    final t = SalesStrings.of(context);
    return Row(
      children: [
        Expanded(
          child: _Metric(
            label: t('total'),
            value: sale.total,
            emphasized: true,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Metric(label: t('paidShort'), value: sale.amountPaid),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Metric(label: t('dueShort'), value: sale.balanceDue),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    this.emphasized = false,
  });
  final String label, value;
  final bool emphasized;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
    decoration: BoxDecoration(
      color: emphasized
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            '$value DZD',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );
}

class _ClientCard extends StatelessWidget {
  const _ClientCard({required this.sale});
  final SaleDetails sale;
  @override
  Widget build(BuildContext context) {
    final t = SalesStrings.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: const Icon(Icons.person_outline),
        title: Text(
          sale.client.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          [
            if (sale.client.phone.isNotEmpty)
              '${t('phone')} : ${sale.client.phone}',
            if (sale.client.address.isNotEmpty) sale.client.address,
            if (sale.client.customerType.isNotEmpty) sale.client.customerType,
          ].join('\n'),
        ),
      ),
    );
  }
}

class _ProductsCard extends StatelessWidget {
  const _ProductsCard({required this.sale});
  final SaleDetails sale;
  @override
  Widget build(BuildContext context) {
    final t = SalesStrings.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t('products'),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            for (var index = 0; index < sale.lines.length; index++) ...[
              if (index > 0) const Divider(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sale.lines[index].productName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${sale.lines[index].packagingName} · ${sale.lines[index].quantity} × ${sale.lines[index].unitPrice} DZD',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${sale.lines[index].total} DZD',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.onPreview, this.onPrint});
  final VoidCallback onPreview;
  final VoidCallback? onPrint;
  @override
  Widget build(BuildContext context) {
    final t = SalesStrings.of(context);
    return Card(
      margin: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black12),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 5),
                ],
              ),
              child: const Icon(
                Icons.description_outlined,
                color: Colors.black54,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t('documentPreview'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const Text(
                    '58 mm · 80 mm · A4',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      FilledButton.tonalIcon(
                        key: const Key('invoice-preview-action'),
                        onPressed: onPreview,
                        icon: const Icon(Icons.visibility_outlined),
                        label: Text(t('preview')),
                      ),
                      if (onPrint != null)
                        FilledButton.icon(
                          key: const Key('invoice-print-action'),
                          onPressed: onPrint,
                          icon: const Icon(Icons.print_outlined),
                          label: Text(t('print')),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.canEdit,
    required this.canPay,
    required this.canPdf,
    required this.onEdit,
    required this.onPayment,
    required this.onPdf,
  });
  final bool canEdit, canPay, canPdf;
  final VoidCallback onEdit, onPayment, onPdf;
  @override
  Widget build(BuildContext context) {
    final t = SalesStrings.of(context);
    if (!canEdit && !canPay && !canPdf) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (canPay)
          FilledButton.tonalIcon(
            key: const Key('invoice-payment-action'),
            onPressed: onPayment,
            icon: const Icon(Icons.add_card_outlined),
            label: Text(t('addPayment')),
          ),
        if (canEdit)
          OutlinedButton.icon(
            key: const Key('invoice-edit-action'),
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
            label: Text(t('edit')),
          ),
        if (canPdf)
          OutlinedButton.icon(
            key: const Key('invoice-pdf-action'),
            onPressed: onPdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: Text(t('viewPdf')),
          ),
      ],
    );
  }
}

class _PaymentsCard extends StatelessWidget {
  const _PaymentsCard({required this.sale});
  final SaleDetails sale;
  @override
  Widget build(BuildContext context) {
    final t = SalesStrings.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t('payments'),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (sale.payments.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(t('noPayment')),
              )
            else
              for (final payment in sale.payments)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.payments_outlined),
                  title: Text('${payment.amount} DZD · ${payment.paymentType}'),
                  subtitle: Text(
                    '${payment.reference}\n${_date(payment.date)}',
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

String _date(String value) {
  final parsed = DateTime.tryParse(value)?.toLocal();
  if (parsed == null) return value;
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(parsed.day)}/${two(parsed.month)}/${parsed.year} · ${two(parsed.hour)}:${two(parsed.minute)}';
}
