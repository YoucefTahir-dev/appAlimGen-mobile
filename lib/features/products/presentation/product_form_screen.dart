import 'package:app_alim_gen_mobile/app/providers.dart';
import 'package:app_alim_gen_mobile/core/errors/app_failure.dart';
import 'package:app_alim_gen_mobile/features/products/domain/product_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_alim_gen_mobile/l10n/crud_strings.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  const ProductFormScreen({super.key, this.productId});
  final int? productId;

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _purchase;
  late final TextEditingController _superWholesale;
  late final TextEditingController _wholesale;
  late final TextEditingController _retail;
  late final TextEditingController _quantity;
  late final TextEditingController _minimumStock;
  late final TextEditingController _description;
  bool _loading = true;
  bool _submitting = false;
  Object? _loadError;
  Map<String, String> _fieldErrors = const {};
  int? _category;
  int? _brand;
  int? _unit;
  List<ReferenceOption> _categories = const [];
  List<ReferenceOption> _brands = const [];
  List<ReferenceOption> _units = const [];
  ProductDetails? _initial;

  bool get _editing => widget.productId != null;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _purchase = TextEditingController();
    _superWholesale = TextEditingController();
    _wholesale = TextEditingController();
    _retail = TextEditingController();
    _quantity = TextEditingController(text: '0');
    _minimumStock = TextEditingController(text: '0');
    _description = TextEditingController();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    try {
      final repository = ref.read(productsRepositoryProvider);
      final values = await Future.wait<dynamic>([
        repository.references('categories'),
        repository.references('brands'),
        repository.references('units'),
        if (_editing) repository.get(widget.productId!),
      ]);
      _categories = values[0] as List<ReferenceOption>;
      _brands = values[1] as List<ReferenceOption>;
      _units = values[2] as List<ReferenceOption>;
      if (_editing) {
        _initial = values[3] as ProductDetails;
        final product = _initial!;
        _name.text = product.name;
        _purchase.text = product.purchasePrice;
        _superWholesale.text = product.superWholesalePrice;
        _wholesale.text = product.wholesalePrice;
        _retail.text = product.retailPrice;
        _quantity.text = '${product.quantity}';
        _minimumStock.text = '${product.minimumStock}';
        _description.text = product.description;
        _category = product.category;
        _brand = product.brand;
        _unit = product.unit;
      }
    } catch (error) {
      _loadError = error;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? _t('required') : null;

  String? _decimal(String? value) {
    final required = _required(value);
    if (required != null) return required;
    final number = double.tryParse(value!.replaceAll(',', '.'));
    return number == null || number < 0 ? _t('positive') : null;
  }

  String? _integer(String? value) {
    final number = int.tryParse(value ?? '');
    return number == null || number < 0 ? _t('integer') : null;
  }

  Future<void> _submit() async {
    setState(() => _fieldErrors = const {});
    if (!_formKey.currentState!.validate() || _submitting) return;
    setState(() => _submitting = true);
    final request = ProductWriteRequest(
      name: _name.text.trim(),
      category: _category,
      brand: _brand,
      unit: _unit,
      purchasePrice: _purchase.text.replaceAll(',', '.'),
      superWholesalePrice: _superWholesale.text.replaceAll(',', '.'),
      wholesalePrice: _wholesale.text.replaceAll(',', '.'),
      retailPrice: _retail.text.replaceAll(',', '.'),
      quantity: int.parse(_quantity.text),
      minimumStock: int.parse(_minimumStock.text),
      description: _description.text.trim(),
    );
    try {
      final repository = ref.read(productsRepositoryProvider);
      if (_editing) {
        await repository.update(widget.productId!, request);
      } else {
        await repository.create(request);
      }
      if (mounted) Navigator.of(context).pop(true);
    } on AppFailure catch (failure) {
      if (!mounted) return;
      setState(() => _fieldErrors = failure.fieldErrors);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message)));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d’enregistrer.')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  InputDecoration _decoration(String label, String field) => InputDecoration(
    labelText: label,
    errorText: _fieldErrors[field],
    border: const OutlineInputBorder(),
  );
  String _t(String key) => CrudStrings.of(context).text(key);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(_editing ? _t('editProduct') : _t('newProduct')),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _loadError != null
        ? Center(
            child: FilledButton(
              onPressed: () {
                setState(() {
                  _loading = true;
                  _loadError = null;
                });
                _load();
              },
              child: Text(_t('retry')),
            ),
          )
        : Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_initial != null)
                  Text(
                    '${_t('reference')} : ${_initial!.reference}\n${_t('barcode')} : ${_initial!.barcode}',
                  ),
                if (_initial != null) const SizedBox(height: 16),
                TextFormField(
                  controller: _name,
                  decoration: _decoration(_t('name'), 'name'),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                _ReferenceDropdown(
                  label: _t('category'),
                  value: _category,
                  items: _categories,
                  error: _fieldErrors['category'],
                  onChanged: (v) => setState(() => _category = v),
                ),
                const SizedBox(height: 12),
                _ReferenceDropdown(
                  label: _t('brand'),
                  value: _brand,
                  items: _brands,
                  error: _fieldErrors['brand'],
                  onChanged: (v) => setState(() => _brand = v),
                ),
                const SizedBox(height: 12),
                _ReferenceDropdown(
                  label: _t('unit'),
                  value: _unit,
                  items: _units,
                  error: _fieldErrors['unit'],
                  onChanged: (v) => setState(() => _unit = v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _purchase,
                  decoration: _decoration(
                    _t('purchasePrice'),
                    'purchase_price',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _decimal,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _superWholesale,
                  decoration: _decoration(
                    _t('superWholesalePrice'),
                    'super_wholesale_price',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _decimal,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _wholesale,
                  decoration: _decoration(
                    _t('wholesalePrice'),
                    'wholesale_price',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _decimal,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _retail,
                  decoration: _decoration(_t('retailPrice'), 'retail_price'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _decimal,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _quantity,
                  decoration: _decoration(_t('quantity'), 'quantity'),
                  keyboardType: TextInputType.number,
                  validator: _integer,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _minimumStock,
                  decoration: _decoration(_t('minimumStock'), 'minimum_stock'),
                  keyboardType: TextInputType.number,
                  validator: _integer,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _description,
                  decoration: _decoration(_t('description'), 'description'),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_t('save')),
                ),
              ],
            ),
          ),
  );

  @override
  void dispose() {
    for (final controller in [
      _name,
      _purchase,
      _superWholesale,
      _wholesale,
      _retail,
      _quantity,
      _minimumStock,
      _description,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }
}

class _ReferenceDropdown extends StatelessWidget {
  const _ReferenceDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.error,
  });
  final String label;
  final int? value;
  final List<ReferenceOption> items;
  final ValueChanged<int?> onChanged;
  final String? error;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<int>(
    initialValue: items.any((item) => item.id == value) ? value : null,
    decoration: InputDecoration(
      labelText: label,
      errorText: error,
      border: const OutlineInputBorder(),
    ),
    items: items
        .map((item) => DropdownMenuItem(value: item.id, child: Text(item.name)))
        .toList(),
    onChanged: onChanged,
  );
}
