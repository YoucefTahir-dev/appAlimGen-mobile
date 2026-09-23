import 'package:app_alim_gen_mobile/app/providers.dart';
import 'package:app_alim_gen_mobile/core/errors/app_failure.dart';
import 'package:app_alim_gen_mobile/features/business_lists/domain/business_entities.dart';
import 'package:app_alim_gen_mobile/core/permissions/permission_service.dart';
import 'package:app_alim_gen_mobile/features/auth/presentation/auth_controller.dart';
import 'package:app_alim_gen_mobile/features/products/presentation/product_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class RemoteOptionField extends StatefulWidget {
  const RemoteOptionField({
    super.key,
    required this.label,
    required this.search,
    required this.onSelected,
  });
  final String label;
  final Future<List<TransactionOption>> Function(String) search;
  final ValueChanged<TransactionOption> onSelected;
  @override
  State<RemoteOptionField> createState() => _RemoteOptionFieldState();
}

class _RemoteOptionFieldState extends State<RemoteOptionField> {
  @override
  Widget build(BuildContext context) => Autocomplete<TransactionOption>(
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
  _LineDraft();
  TransactionOption? product;
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
  const SaleFormScreen({super.key});
  @override
  ConsumerState<SaleFormScreen> createState() => _SaleFormScreenState();
}

class _SaleFormScreenState extends ConsumerState<SaleFormScreen> {
  final _form = GlobalKey<FormState>();
  final _discount = TextEditingController(text: '0');
  final _tax = TextEditingController(text: '0');
  final _lines = <_LineDraft>[_LineDraft()];
  TransactionOption? _client;
  bool _payFull = true, _saving = false;
  String? _error;
  final _key = const Uuid().v4();
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
        line.price.text = (p['unit_price'] ?? p['price'] ?? '').toString();
      } catch (e) {
        if (mounted) {
          setState(() => _error = e is AppFailure ? e.message : e.toString());
        }
      }
    }
    setState(() {});
  }

  Future<void> _selectClient(TransactionOption client) async {
    setState(() => _client = client);
    for (final line in _lines.where((line) => line.product != null)) {
      try {
        final price = await ref
            .read(salesRepositoryProvider)
            .price(line.product!.id, client.id);
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
      setState(() => _error = 'Sélectionnez le client et tous les produits.');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(salesRepositoryProvider)
          .create(
            SaleWriteRequest(
              clientId: _client!.id,
              discount: _discount.text,
              taxRate: _tax.text,
              paymentType: 'cash',
              payFull: _payFull,
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
    appBar: AppBar(title: const Text('Nouvelle vente')),
    body: Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          RemoteOptionField(
            label: 'Client (recherche)',
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
                      label: 'Produit (recherche)',
                      search: (q) =>
                          ref.read(salesRepositoryProvider).searchProducts(q),
                      onSelected: (o) => _selectProduct(l, o),
                    ),
                    const SizedBox(height: 8),
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
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Prix serveur',
                            ),
                            validator: (v) => double.tryParse(v ?? '') == null
                                ? 'Prix invalide'
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
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _discount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Remise'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _tax,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'TVA (%)'),
                ),
              ),
            ],
          ),
          SwitchListTile(
            value: _payFull,
            onChanged: (v) => setState(() => _payFull = v),
            title: const Text('Régler intégralement'),
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
  const PaymentFormScreen({super.key});
  @override
  ConsumerState<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends ConsumerState<PaymentFormScreen> {
  final _form = GlobalKey<FormState>();
  final _document = TextEditingController(), _amount = TextEditingController();
  bool _sale = true, _saving = false;
  String? _error;
  final _key = const Uuid().v4();
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
              paymentType: 'cash',
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
    appBar: AppBar(title: const Text('Nouveau paiement')),
    body: Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Vente')),
              ButtonSegment(value: false, label: Text('Achat')),
            ],
            selected: {_sale},
            onSelectionChanged: (v) => setState(() => _sale = v.first),
          ),
          TextFormField(
            controller: _document,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: _sale ? 'ID vente' : 'ID achat',
            ),
            validator: (v) =>
                int.tryParse(v ?? '') == null ? 'Identifiant invalide' : null,
          ),
          TextFormField(
            controller: _amount,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Montant'),
            validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0
                ? 'Montant invalide'
                : null,
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
