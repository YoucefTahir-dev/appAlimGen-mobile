import 'package:app_alim_gen_mobile/app/providers.dart';
import 'package:app_alim_gen_mobile/core/errors/app_failure.dart';
import 'package:app_alim_gen_mobile/core/navigation/module_scaffold.dart';
import 'package:app_alim_gen_mobile/core/permissions/permission_service.dart';
import 'package:app_alim_gen_mobile/features/auth/presentation/auth_controller.dart';
import 'package:app_alim_gen_mobile/features/business_lists/domain/business_entities.dart';
import 'package:app_alim_gen_mobile/features/receivables/domain/receivable.dart';
import 'package:app_alim_gen_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class ReceivablesScreen extends ConsumerStatefulWidget {
  const ReceivablesScreen({super.key});
  @override
  ConsumerState<ReceivablesScreen> createState() => _ReceivablesScreenState();
}

class _ReceivablesScreenState extends ConsumerState<ReceivablesScreen> {
  final _search = TextEditingController();
  String _status = 'debtors';
  bool _loading = true;
  Object? _error;
  List<ReceivableSummary> _items = const [];

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await ref
          .read(receivablesRepositoryProvider)
          .fetch(query: _search.text.trim(), status: _status);
      if (mounted) setState(() => _items = items);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return ModuleScaffold(
      title: t.text('receivables'),
      path: '/receivables',
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      labelText: t.text('searchClient'),
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _load(),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _status,
                  items: [
                    DropdownMenuItem(
                      value: 'debtors',
                      child: Text(t.text('debtors')),
                    ),
                    DropdownMenuItem(
                      value: 'settled',
                      child: Text(t.text('settledAccounts')),
                    ),
                    DropdownMenuItem(
                      value: 'all',
                      child: Text(t.text('allClients')),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _status = value);
                    _load();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              _Message(
                icon: Icons.cloud_off,
                text: _error is AppFailure
                    ? (_error! as AppFailure).message
                    : t.text('apiError'),
                action: _load,
              )
            else if (_items.isEmpty)
              _Message(
                icon: Icons.account_balance_wallet_outlined,
                text: t.empty,
              )
            else
              ..._items.map(
                (item) => Card(
                  child: ListTile(
                    onTap: () async {
                      await Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReceivableDetailScreen(
                            clientId: item.id,
                            clientName: item.name,
                          ),
                        ),
                      );
                      _load();
                    },
                    title: Text(item.name),
                    subtitle: Text(
                      '${t.text('invoiced')}: ${item.totalInvoiced} DZD\n'
                      '${t.text('paid')}: ${item.totalPaid} DZD · '
                      '${item.unpaidInvoiceCount} ${t.text('unpaidInvoices').toLowerCase()}',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${item.balanceDue} DZD',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(t.text('due')),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ReceivableDetailScreen extends ConsumerStatefulWidget {
  const ReceivableDetailScreen({
    super.key,
    required this.clientId,
    required this.clientName,
  });
  final int clientId;
  final String clientName;
  @override
  ConsumerState<ReceivableDetailScreen> createState() =>
      _ReceivableDetailScreenState();
}

class _ReceivableDetailScreenState
    extends ConsumerState<ReceivableDetailScreen> {
  ReceivableAccount? _account;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final account = await ref
          .read(receivablesRepositoryProvider)
          .getAccount(widget.clientId);
      if (mounted) setState(() => _account = account);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final user = ref.watch(authControllerProvider).user;
    final canAdd = user?.can(AppPermissions.addCustomerPayment) ?? false;
    return Scaffold(
      appBar: AppBar(title: Text(widget.clientName)),
      floatingActionButton:
          canAdd && _account != null && _account!.invoices.any((e) => !e.isPaid)
          ? FloatingActionButton.extended(
              onPressed: _addPayment,
              icon: const Icon(Icons.add_card),
              label: Text(t.text('newPayment')),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _Message(
              icon: Icons.cloud_off,
              text: _error is AppFailure
                  ? (_error! as AppFailure).message
                  : t.text('apiError'),
              action: _load,
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: _accountBody(context, _account!),
            ),
    );
  }

  Widget _accountBody(BuildContext context, ReceivableAccount account) {
    final t = AppLocalizations.of(context);
    final canCancel =
        ref
            .watch(authControllerProvider)
            .user
            ?.can(AppPermissions.cancelCustomerPayment) ??
        false;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: _TotalCard(t.text('invoiced'), account.totalInvoiced),
            ),
            Expanded(child: _TotalCard(t.text('paid'), account.totalPaid)),
            Expanded(
              child: _TotalCard(t.text('due'), account.balanceDue, alert: true),
            ),
          ],
        ),
        if (account.unreconciledCount > 0)
          Card(
            color: Colors.amber.shade50,
            child: ListTile(
              leading: const Icon(Icons.warning_amber),
              title: Text(
                '${account.unreconciledCount} ${t.text('unreconciledInvoices')}',
              ),
            ),
          ),
        const SizedBox(height: 16),
        Text(t.text('invoices'), style: Theme.of(context).textTheme.titleLarge),
        ...account.invoices.map(
          (invoice) => ListTile(
            leading: Icon(
              invoice.isPaid ? Icons.check_circle : Icons.receipt_long,
            ),
            title: Text(invoice.number),
            subtitle: Text('${t.text('paid')}: ${invoice.paid} DZD'),
            trailing: Text('${invoice.balance} DZD'),
          ),
        ),
        const Divider(),
        Text(t.text('payments'), style: Theme.of(context).textTheme.titleLarge),
        ...account.payments.map(
          (payment) => ListTile(
            enabled: !payment.cancelled,
            leading: Icon(payment.cancelled ? Icons.cancel : Icons.payments),
            title: Text('${payment.reference} · ${payment.amount} DZD'),
            subtitle: Text(
              payment.cancelled
                  ? '${t.text('cancelled')}: ${payment.cancellationReason}'
                  : payment.externalReference,
            ),
            trailing: canCancel && !payment.cancelled
                ? IconButton(
                    icon: const Icon(Icons.cancel_outlined),
                    tooltip: t.text('cancelPayment'),
                    onPressed: () => _cancelPayment(payment),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 96),
      ],
    );
  }

  Future<void> _addPayment() async {
    final account = _account!;
    final invoices = account.invoices.where((item) => !item.isPaid).toList();
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _PaymentDialog(invoices: invoices),
    );
    if (saved == true) await _load();
  }

  Future<void> _cancelPayment(ReceivablePayment payment) async {
    final t = AppLocalizations.of(context);
    final reason = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.text('cancelPayment')),
        content: TextField(
          controller: reason,
          decoration: InputDecoration(labelText: t.text('cancellationReason')),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(t.text('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(t.text('confirm')),
          ),
        ],
      ),
    );
    if (confirmed == true && reason.text.trim().isNotEmpty) {
      await ref
          .read(paymentsRepositoryProvider)
          .cancel(payment.id, reason.text.trim());
      await _load();
    }
    reason.dispose();
  }
}

class _PaymentDialog extends ConsumerStatefulWidget {
  const _PaymentDialog({required this.invoices});
  final List<ReceivableInvoice> invoices;
  @override
  ConsumerState<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends ConsumerState<_PaymentDialog> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _reference = TextEditingController();
  final _notes = TextEditingController();
  late int _invoiceId = widget.invoices.first.id;
  String _type = 'cash';
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(paymentsRepositoryProvider)
          .create(
            PaymentWriteRequest(
              saleId: _invoiceId,
              amount: _amount.text,
              paymentType: _type,
              createdAt: DateTime.now().toIso8601String(),
              externalReference: _reference.text.trim(),
              notes: _notes.text.trim(),
            ),
            const Uuid().v4(),
          );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is AppFailure ? error.message : error.toString(),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(t.text('newPayment')),
      content: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: _invoiceId,
                decoration: InputDecoration(labelText: t.text('invoice')),
                items: widget.invoices
                    .map(
                      (item) => DropdownMenuItem(
                        value: item.id,
                        child: Text('${item.number} — ${item.balance} DZD'),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) => _invoiceId = value ?? _invoiceId,
              ),
              TextFormField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(labelText: t.text('amount')),
                validator: (value) => (double.tryParse(value ?? '') ?? 0) > 0
                    ? null
                    : t.text('invalidAmount'),
              ),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: InputDecoration(labelText: t.text('paymentMethod')),
                items: ['cash', 'cheque', 'transfer']
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(t.text(value)),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) => _type = value ?? _type,
              ),
              TextField(
                controller: _reference,
                decoration: InputDecoration(
                  labelText: t.text('externalReference'),
                ),
              ),
              TextField(
                controller: _notes,
                decoration: InputDecoration(labelText: t.text('notes')),
              ),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: Text(t.text('cancel')),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const CircularProgressIndicator()
              : Text(t.text('save')),
        ),
      ],
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard(this.label, this.value, {this.alert = false});
  final String label, value;
  final bool alert;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Text(label, textAlign: TextAlign.center),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: alert ? Theme.of(context).colorScheme.error : null,
            ),
          ),
        ],
      ),
    ),
  );
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.action});
  final IconData icon;
  final String text;
  final Future<void> Function()? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(
      children: [
        Icon(icon, size: 48),
        const SizedBox(height: 8),
        Text(text, textAlign: TextAlign.center),
        if (action != null)
          TextButton(onPressed: action, child: const Text('Réessayer')),
      ],
    ),
  );
}
