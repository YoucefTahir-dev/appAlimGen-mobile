import 'dart:io';

import 'package:app_alim_gen_mobile/app/providers.dart';
import 'package:app_alim_gen_mobile/core/errors/app_failure.dart';
import 'package:app_alim_gen_mobile/core/permissions/permission_service.dart';
import 'package:app_alim_gen_mobile/features/auth/presentation/auth_controller.dart';
import 'package:app_alim_gen_mobile/features/business_lists/domain/business_entities.dart';
import 'package:app_alim_gen_mobile/features/business_lists/presentation/sales_strings.dart';
import 'package:app_alim_gen_mobile/features/business_lists/presentation/transaction_form_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

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
  bool _busy = false;
  bool _autoPrintStarted = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _invoice = ref.read(invoicesRepositoryProvider).get(widget.invoiceId);
  }

  String _message(Object error) =>
      error is AppFailure ? error.message : error.toString();

  Future<void> _openPdf() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final bytes = await ref
          .read(invoicesRepositoryProvider)
          .pdf(widget.invoiceId);
      if (bytes.isEmpty) throw StateError('Le PDF reçu est vide.');
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/facture_${widget.invoiceId}.pdf');
      await file.writeAsBytes(bytes, flush: true);
      await const MethodChannel(
        'com.elamine.erp/files',
      ).invokeMethod<void>('openPdf', {'path': file.path});
    } catch (error) {
      if (mounted) _showError(_message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _print() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final repository = ref.read(printersRepositoryProvider);
      final defaultSummary = await repository.getDefault();
      if (defaultSummary == null) {
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(SalesStrings.of(context)('noPrinter')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(SalesStrings.of(context)('later')),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  context.push('/printers');
                },
                child: Text(SalesStrings.of(context)('configurePrinter')),
              ),
            ],
          ),
        );
        return;
      }
      final printer = await repository.get(defaultSummary.id);
      if (printer.connectionMode != 'bluetooth') {
        throw StateError(
          "L'impression Android locale nécessite une imprimante Bluetooth.",
        );
      }
      final language = ref.read(localeProvider).languageCode;
      final data = await ref
          .read(invoicesRepositoryProvider)
          .printData(
            widget.invoiceId,
            width: printer.paperWidth,
            language: language,
          );
      final service = ref.read(printerTestServiceProvider);
      final bytes = service.driver.invoiceTicket(
        data: data,
        paperWidth: printer.paperWidth,
      );
      await service.send(printer: printer, bytes: bytes);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(SalesStrings.of(context)('sentToPrinter'))),
      );
    } catch (error) {
      if (!mounted) return;
      final retry = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(SalesStrings.of(context)('printFailed')),
          content: Text(
            "${SalesStrings.of(context)('salePreserved')}\n\n${_message(error)}",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(SalesStrings.of(context)('later')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(SalesStrings.of(context)('retry')),
            ),
          ],
        ),
      );
      if (retry == true && mounted) {
        setState(() => _busy = false);
        return _print();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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

  void _showError(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

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
      appBar: AppBar(title: Text(t('invoiceDetail'))),
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
                    Text(_message(snapshot.error!)),
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
          final canPdf =
              sale.capabilities.canViewPdf &&
              (user?.can(AppPermissions.downloadInvoicePdf) ?? false);
          final canPrint =
              sale.capabilities.canPrint &&
              (user?.can(AppPermissions.printInvoice) ?? false);
          final canPay =
              sale.capabilities.canAddPayment &&
              (user?.can(AppPermissions.changeSale) ?? false) &&
              (double.tryParse(sale.balanceDue) ?? 0) > 0;
          if (widget.autoPrint && canPrint && !_autoPrintStarted) {
            _autoPrintStarted = true;
            WidgetsBinding.instance.addPostFrameCallback((_) => _print());
          }
          return RefreshIndicator(
            onRefresh: () async {
              setState(_reload);
              await _invoice;
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  sale.number,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text('${t('ticket')} : ${sale.ticketNumber}'),
                Text('${t('date')} : ${sale.date}'),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
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
                const SizedBox(height: 12),
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
                const Divider(height: 32),
                _AmountRow(label: t('subtotal'), value: sale.subtotal),
                _AmountRow(label: t('discount'), value: sale.discount),
                _AmountRow(
                  label: '${t('tax')} (${sale.taxRate} %)',
                  value: sale.taxAmount,
                ),
                _AmountRow(
                  label: t('totalTtc'),
                  value: sale.total,
                  strong: true,
                ),
                _AmountRow(label: t('paidShort'), value: sale.amountPaid),
                _AmountRow(
                  label: t('dueShort'),
                  value: sale.balanceDue,
                  strong: true,
                ),
                Text('${t('paymentMethod')} : ${sale.paymentType}'),
                Text('${t('status')} : ${_status(sale.paymentStatus)}'),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    if (canPrint)
                      FilledButton.icon(
                        onPressed: _busy ? null : _print,
                        icon: const Icon(Icons.print_outlined),
                        label: Text(t('reprint')),
                      ),
                    if (canPay)
                      FilledButton.tonalIcon(
                        onPressed: _busy ? null : () => _addPayment(sale),
                        icon: const Icon(Icons.payments_outlined),
                        label: Text(t('payment')),
                      ),
                    if (canPdf)
                      OutlinedButton.icon(
                        onPressed: _busy ? null : _openPdf,
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: Text(t('viewPdf')),
                      ),
                    if (_busy) const CircularProgressIndicator(),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  t('payments'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (sale.payments.isEmpty)
                  ListTile(title: Text(t('noPayment')))
                else
                  for (final payment in sale.payments)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        '${payment.amount} DZD · ${payment.paymentType}',
                      ),
                      subtitle: Text('${payment.reference}\n${payment.date}'),
                      isThreeLine: true,
                    ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.value,
    this.strong = false,
  });
  final String label, value;
  final bool strong;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          '$value DZD',
          style: strong ? const TextStyle(fontWeight: FontWeight.bold) : null,
        ),
      ],
    ),
  );
}
