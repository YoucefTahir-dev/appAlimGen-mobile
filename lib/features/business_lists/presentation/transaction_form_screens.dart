import 'package:app_alim_gen_mobile/app/providers.dart';
import 'package:app_alim_gen_mobile/core/errors/app_failure.dart';
import 'package:app_alim_gen_mobile/features/business_lists/domain/business_entities.dart';
import 'package:app_alim_gen_mobile/core/permissions/permission_service.dart';
import 'package:app_alim_gen_mobile/features/auth/presentation/auth_controller.dart';
import 'package:app_alim_gen_mobile/features/products/presentation/product_form_screen.dart';
import 'package:app_alim_gen_mobile/features/business_lists/presentation/invoice_detail_screen.dart';
import 'package:app_alim_gen_mobile/features/business_lists/presentation/sales_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class RemoteOptionField extends StatefulWidget {
  const RemoteOptionField({
    super.key,
    required this.label,
    required this.search,
    required this.onSelected,
    this.initial,
  });
  final String label;
  final Future<List<TransactionOption>> Function(String) search;
  final ValueChanged<TransactionOption> onSelected;
  final TransactionOption? initial;
  @override
  State<RemoteOptionField> createState() => _RemoteOptionFieldState();
}

class _RemoteOptionFieldState extends State<RemoteOptionField> {
  @override
  Widget build(BuildContext context) => Autocomplete<TransactionOption>(
    initialValue: TextEditingValue(text: widget.initial?.label ?? ''),
    displayStringForOption: (o) => o.label,
    optionsBuilder: (value) async => value.text.trim().length < 2
        ? const <TransactionOption>[]
        : widget.search(value.text.trim()),
    onSelected: widget.onSelected,
    fieldViewBuilder: (context, controller, focus, onSubmit) => TextFormField(
      controller: controller,
      focusNode: focus,
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.search),
      ),
      validator: (v) => (v ?? '').trim().isEmpty ? 'Champ obligatoire' : null,
    ),
    optionsViewBuilder: (context, onSelected, options) => Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 4,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 240, maxWidth: 500),
          child: ListView(
            shrinkWrap: true,
            children: options
                .map(
                  (o) => ListTile(
                    title: Text(o.label),
                    onTap: () => onSelected(o),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    ),
  );
}

class _LineDraft {
  _LineDraft({SaleLineDetails? initial}) {
    if (initial != null) {
      product = TransactionOption(
        id: initial.productId,
        label: initial.productName,
      );
      quantity.text = initial.quantity.toString();
      price.text = initial.unitPrice;
      if (initial.packagingId != null) {
        packaging = TransactionOption(
          id: initial.packagingId!,
          label: initial.packagingName,
        );
        packagings = [packaging!];
      }
    }
  }
  TransactionOption? product;
  TransactionOption? packaging;
  List<TransactionOption> packagings = const [];
  final quantity = TextEditingController(text: '1');
  final price = TextEditingController();
  double get total =>
      (int.tryParse(quantity.text) ?? 0) *
      (double.tryParse(price.text.replaceAll(',', '.')) ?? 0);
  void dispose() {
    quantity.dispose();
    price.dispose();
  }
}

class SaleFormScreen extends ConsumerStatefulWidget {
  const SaleFormScreen({super.key, this.initial});
  final SaleDetails? initial;
  @override
  ConsumerState<SaleFormScreen> createState() => _SaleFormScreenState();
}

class _SaleFormScreenState extends ConsumerState<SaleFormScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _discount;
  late final TextEditingController _tax;
  late final List<_LineDraft> _lines;
  TransactionOption? _client;
  late bool _payFull;
  bool _saving = false;
  String _paymentType = 'cash';
  String? _error;
  final _key = const Uuid().v4();
  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _discount = TextEditingController(text: initial?.discount ?? '0');
    _tax = TextEditingController(text: initial?.taxRate ?? '0');
    _lines = initial == null
        ? [_LineDraft()]
        : initial.lines.map((line) => _LineDraft(initial: line)).toList();
    if (_lines.isEmpty) _lines.add(_LineDraft());
    if (initial != null) {
      _client = TransactionOption(
        id: initial.client.id,
        label: initial.client.name,
      );
      _paymentType = initial.paymentTypeCode;
    }
    _payFull = initial == null;
  }

  @override
  void dispose() {
    _discount.dispose();
    _tax.dispose();
    for (final l in _lines) {
      l.dispose();
    }
    super.dispose();
  }

  Future<void> _selectProduct(
    _LineDraft line,
    TransactionOption product,
  ) async {
    line.product = product;
    if (_client != null) {
      try {
        final p = await ref
            .read(salesRepositoryProvider)
            .price(product.id, _client!.id);
        _applyPrice(line, p);
      } catch (e) {
        if (mounted) {
          setState(() => _error = e is AppFailure ? e.message : e.toString());
        }
      }
    }
    setState(() {});
  }

  void _applyPrice(_LineDraft line, Map<String, dynamic> data) {
    line.price.text = (data['unit_price'] ?? data['price'] ?? '').toString();
    line.packagings = (data['packagings'] as List? ?? const [])
        .whereType<Map>()
        .map((raw) {
          final item = Map<String, dynamic>.from(raw);
          return TransactionOption(
            id: (item['id'] as num).toInt(),
            label: item['name']?.toString() ?? '',
            meta: item,
          );
        })
        .toList(growable: false);
    line.packaging = null;
  }

  Future<void> _selectPackaging(
    _LineDraft line,
    TransactionOption? packaging,
  ) async {
    line.packaging = packaging;
    if (line.product == null || _client == null) return;
    try {
      final data = await ref
          .read(salesRepositoryProvider)
          .price(line.product!.id, _client!.id, packagingId: packaging?.id);
      line.price.text = (data['unit_price'] ?? data['price'] ?? '').toString();
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is AppFailure ? error.message : error.toString(),
        );
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _selectClient(TransactionOption client) async {
    setState(() => _client = client);
    for (final line in _lines.where((line) => line.product != null)) {
      try {
        final price = await ref
            .read(salesRepositoryProvider)
            .price(
              line.product!.id,
              client.id,
              packagingId: line.packaging?.id,
            );
        line.price.text = (price['unit_price'] ?? price['price'] ?? '')
            .toString();
      } catch (error) {
        if (mounted) {
          setState(
            () =>
                _error = error is AppFailure ? error.message : error.toString(),
          );
        }
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _submit() async {
    if (_saving ||
        !(_form.currentState?.validate() ?? false) ||
        _client == null ||
        _lines.any((l) => l.product == null)) {
      setState(() => _error = SalesStrings.of(context)('selectClientProducts'));
      return;
    }
    setState(() => _saving = true);
    try {
      final request = SaleWriteRequest(
        clientId: _client!.id,
        discount: _discount.text,
        taxRate: _tax.text,
        paymentType: _paymentType,
        payFull: _payFull,
        items: _lines
            .map(
              (l) => TransactionLineRequest(
                productId: l.product!.id,
                quantity: int.parse(l.quantity.text),
                unitPrice: l.price.text,
                packagingId: l.packaging?.id,
              ),
            )
            .toList(),
      );
      final repository = ref.read(salesRepositoryProvider);
      final result = widget.initial == null
          ? await repository.create(request, _key)
          : await repository.update(widget.initial!.id, request, _key);
      if (!mounted) return;
      if (widget.initial != null) {
        Navigator.pop(context, true);
      } else {
        await _showSuccess(result);
      }
    } catch (e) {
      setState(() => _error = e is AppFailure ? e.message : e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showSuccess(SaleDetails sale) async {
    final t = SalesStrings.of(context);
    final user = ref.read(authControllerProvider).user;
    final action = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(t('saleSaved')),
        content: Text('${t('invoice')} ${sale.number}'),
        actions: [
          if (user?.can(AppPermissions.invoices) ?? false)
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, 'invoice'),
              child: Text(t('viewInvoice')),
            ),
          if (user?.can(AppPermissions.printInvoice) ?? false)
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, 'print'),
              child: Text(t('print')),
            ),
          if (user?.can(AppPermissions.changeSale) ?? false)
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, 'payment'),
              child: Text(t('addPayment')),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 'list'),
            child: Text(t('backSales')),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (action == 'invoice' || action == 'print') {
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => InvoiceDetailScreen(
            invoiceId: sale.id,
            autoPrint: action == 'print',
          ),
        ),
      );
    } else if (action == 'payment') {
      await Navigator.push<bool>(
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
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final t = SalesStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initial == null ? t('newSale') : t('editSale')),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            RemoteOptionField(
              label: t('clientSearch'),
              initial: _client,
              search: (q) => ref.read(salesRepositoryProvider).searchClients(q),
              onSelected: _selectClient,
            ),
            const SizedBox(height: 16),
            ..._lines.asMap().entries.map((entry) {
              final i = entry.key, l = entry.value;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      RemoteOptionField(
                        key: ValueKey('sale-product-$i'),
                        label: t('productSearch'),
                        initial: l.product,
                        search: (q) => ref
                            .read(salesRepositoryProvider)
                            .searchProducts(q, clientId: _client?.id),
                        onSelected: (o) => _selectProduct(l, o),
                      ),
                      const SizedBox(height: 8),
                      if (l.packagings.isNotEmpty)
                        DropdownButtonFormField<TransactionOption?>(
                          initialValue: l.packaging,
                          decoration: InputDecoration(
                            labelText: t('packaging'),
                          ),
                          items: [
                            DropdownMenuItem<TransactionOption?>(
                              value: null,
                              child: Text(t('unit')),
                            ),
                            ...l.packagings.map(
                              (item) => DropdownMenuItem<TransactionOption?>(
                                value: item,
                                child: Text(item.label),
                              ),
                            ),
                          ],
                          onChanged: (value) => _selectPackaging(l, value),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: l.quantity,
                              onChanged: (_) => setState(() {}),
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: t('quantity'),
                              ),
                              validator: (v) => (int.tryParse(v ?? '') ?? 0) < 1
                                  ? t('invalidQuantity')
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: l.price,
                              onChanged: (_) => setState(() {}),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                labelText: t('serverPrice'),
                              ),
                              validator: (v) => double.tryParse(v ?? '') == null
                                  ? t('invalidPrice')
                                  : null,
                            ),
                          ),
                          if (_lines.length > 1)
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _lines.removeAt(i).dispose();
                                });
                              },
                              icon: const Icon(Icons.delete_outline),
                            ),
                        ],
                      ),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: Text(
                          '${t('lineTotal')} : ${l.total.toStringAsFixed(2)} DZD',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            TextButton.icon(
              onPressed: () => setState(() => _lines.add(_LineDraft())),
              icon: const Icon(Icons.add),
              label: Text(t('addProduct')),
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Text(
                '${t('displayedTotal')} : ${_lines.fold<double>(0, (sum, line) => sum + line.total).toStringAsFixed(2)} DZD',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _discount,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: t('discount')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _tax,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: '${t('tax')} (%)'),
                  ),
                ),
              ],
            ),
            SwitchListTile(
              value: _payFull,
              onChanged: (v) => setState(() => _payFull = v),
              title: Text(t('payFull')),
            ),
            DropdownButtonFormField<String>(
              initialValue: _paymentType,
              decoration: InputDecoration(labelText: t('paymentMethod')),
              items: [
                DropdownMenuItem(value: 'cash', child: Text(t('cash'))),
                DropdownMenuItem(value: 'cheque', child: Text(t('cheque'))),
                DropdownMenuItem(value: 'transfer', child: Text(t('transfer'))),
              ],
              onChanged: (value) =>
                  setState(() => _paymentType = value ?? 'cash'),
            ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const CircularProgressIndicator()
                  : Text(t('save')),
            ),
          ],
        ),
      ),
    );
  }
}

class PurchaseFormScreen extends ConsumerStatefulWidget {
  const PurchaseFormScreen({super.key});
  @override
  ConsumerState<PurchaseFormScreen> createState() => _PurchaseFormScreenState();
}

class _PurchaseFormScreenState extends ConsumerState<PurchaseFormScreen> {
  final _form = GlobalKey<FormState>();
  final _reference = TextEditingController(),
      _tax = TextEditingController(text: '0');
  final _lines = <_LineDraft>[_LineDraft()];
  TransactionOption? _supplier;
  bool _saving = false;
  String? _error;
  final _key = const Uuid().v4();
  @override
  void dispose() {
    _reference.dispose();
    _tax.dispose();
    for (final l in _lines) {
      l.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving ||
        !(_form.currentState?.validate() ?? false) ||
        _supplier == null ||
        _lines.any((l) => l.product == null)) {
      setState(
        () => _error = 'Sélectionnez le fournisseur et tous les produits.',
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(purchasesRepositoryProvider)
          .create(
            PurchaseWriteRequest(
              supplierId: _supplier!.id,
              reference: _reference.text,
              taxRate: _tax.text,
              items: _lines
                  .map(
                    (l) => TransactionLineRequest(
                      productId: l.product!.id,
                      quantity: int.parse(l.quantity.text),
                      unitPrice: l.price.text,
                    ),
                  )
                  .toList(),
            ),
            _key,
          );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = e is AppFailure ? e.message : e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Nouvel achat')),
    body: Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          RemoteOptionField(
            label: 'Fournisseur (recherche)',
            search: (q) =>
                ref.read(purchasesRepositoryProvider).searchSuppliers(q),
            onSelected: (o) => setState(() => _supplier = o),
          ),
          TextFormField(
            controller: _reference,
            decoration: const InputDecoration(labelText: 'Référence'),
            validator: (v) =>
                (v ?? '').trim().isEmpty ? 'Champ obligatoire' : null,
          ),
          TextFormField(
            controller: _tax,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'TVA (%)'),
          ),
          if (ref
                  .watch(authControllerProvider)
                  .user
                  ?.can(AppPermissions.addProduct) ??
              false)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: _saving
                    ? null
                    : () async {
                        final created = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProductFormScreen(),
                          ),
                        );
                        if (created == true && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Produit créé. Il est maintenant disponible dans la recherche.',
                              ),
                            ),
                          );
                        }
                      },
                icon: const Icon(Icons.add_box_outlined),
                label: const Text('Nouveau produit'),
              ),
            ),
          ..._lines.asMap().entries.map((entry) {
            final i = entry.key, l = entry.value;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    RemoteOptionField(
                      key: ValueKey('purchase-product-$i'),
                      label: 'Produit (recherche)',
                      search: (q) => ref
                          .read(purchasesRepositoryProvider)
                          .searchProducts(q),
                      onSelected: (o) => setState(() => l.product = o),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: l.quantity,
                            onChanged: (_) => setState(() {}),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Quantité',
                            ),
                            validator: (v) => (int.tryParse(v ?? '') ?? 0) < 1
                                ? 'Quantité invalide'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: l.price,
                            onChanged: (_) => setState(() {}),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Prix achat',
                            ),
                            validator: (v) => double.tryParse(v ?? '') == null
                                ? 'Prix invalide'
                                : null,
                          ),
                        ),
                        if (_lines.length > 1)
                          IconButton(
                            onPressed: () =>
                                setState(() => _lines.removeAt(i).dispose()),
                            icon: const Icon(Icons.delete_outline),
                          ),
                      ],
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Text(
                        'Total ligne : ${l.total.toStringAsFixed(2)} DZD',
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          TextButton.icon(
            onPressed: () => setState(() => _lines.add(_LineDraft())),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter produit'),
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Text(
              'Total affiché : ${_lines.fold<double>(0, (sum, line) => sum + line.total).toStringAsFixed(2)} DZD',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          FilledButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const CircularProgressIndicator()
                : const Text('Enregistrer'),
          ),
        ],
      ),
    ),
  );
}

class PaymentFormScreen extends ConsumerStatefulWidget {
  const PaymentFormScreen({
    super.key,
    this.initialSaleId,
    this.total,
    this.amountPaid,
    this.balanceDue,
  });
  final int? initialSaleId;
  final String? total, amountPaid, balanceDue;
  @override
  ConsumerState<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends ConsumerState<PaymentFormScreen> {
  final _form = GlobalKey<FormState>();
  final _document = TextEditingController(), _amount = TextEditingController();
  bool _sale = true, _saving = false;
  String _paymentType = 'cash';
  String? _error;
  final _key = const Uuid().v4();
  @override
  void initState() {
    super.initState();
    if (widget.initialSaleId != null) {
      _document.text = widget.initialSaleId.toString();
      _amount.text = widget.balanceDue ?? '';
    }
  }

  @override
  void dispose() {
    _document.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || !(_form.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(paymentsRepositoryProvider)
          .create(
            PaymentWriteRequest(
              saleId: _sale ? int.parse(_document.text) : null,
              purchaseId: _sale ? null : int.parse(_document.text),
              amount: _amount.text,
              paymentType: _paymentType,
            ),
            _key,
          );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = e is AppFailure ? e.message : e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = SalesStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t('newPayment'))),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: true, label: Text(t('sale'))),
                ButtonSegment(value: false, label: Text(t('purchase'))),
              ],
              selected: {_sale},
              onSelectionChanged: widget.initialSaleId == null
                  ? (v) => setState(() => _sale = v.first)
                  : null,
            ),
            if (widget.total != null) ...[
              const SizedBox(height: 12),
              Text('${t('totalTtc')} : ${widget.total} DZD'),
              Text('${t('paid')} : ${widget.amountPaid} DZD'),
              Text('${t('due')} : ${widget.balanceDue} DZD'),
            ],
            TextFormField(
              controller: _document,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText:
                    '${t('documentId')} ${_sale ? t('sale') : t('purchase')}',
              ),
              readOnly: widget.initialSaleId != null,
              validator: (v) =>
                  int.tryParse(v ?? '') == null ? t('invalidIdentifier') : null,
            ),
            TextFormField(
              controller: _amount,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: t('amount')),
              validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0
                  ? t('invalidAmount')
                  : null,
            ),
            DropdownButtonFormField<String>(
              initialValue: _paymentType,
              decoration: InputDecoration(labelText: t('paymentMethod')),
              items: [
                DropdownMenuItem(value: 'cash', child: Text(t('cash'))),
                DropdownMenuItem(value: 'cheque', child: Text(t('cheque'))),
                DropdownMenuItem(value: 'transfer', child: Text(t('transfer'))),
              ],
              onChanged: (value) =>
                  setState(() => _paymentType = value ?? 'cash'),
            ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const CircularProgressIndicator()
                  : Text(t('save')),
            ),
          ],
        ),
      ),
    );
  }
}
