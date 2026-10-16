import 'package:app_alim_gen_mobile/app/providers.dart';
import 'package:app_alim_gen_mobile/core/errors/app_failure.dart';
import 'package:app_alim_gen_mobile/core/permissions/permission_service.dart';
import 'package:app_alim_gen_mobile/features/auth/presentation/auth_controller.dart';
import 'package:app_alim_gen_mobile/features/products/domain/product_summary.dart';
import 'package:app_alim_gen_mobile/core/widgets/app_ui.dart';
import 'package:app_alim_gen_mobile/l10n/app_localizations.dart';
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
  late final TextEditingController _cartonFactor;
  late final TextEditingController _cartonPurchase;
  late final TextEditingController _cartonSuperWholesale;
  late final TextEditingController _cartonWholesale;
  late final TextEditingController _cartonRetail;
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
  ProductPackagingDetails? _existingCarton;
  String _unitMode = 'piece_only';
  String _stockUnit = 'base';

  bool get _usesCarton =>
      _unitMode == 'carton_only' || _unitMode == 'carton_and_piece';

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
    _cartonFactor = TextEditingController(text: '1');
    _cartonPurchase = TextEditingController();
    _cartonSuperWholesale = TextEditingController();
    _cartonWholesale = TextEditingController();
    _cartonRetail = TextEditingController();
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
        _unitMode = product.unitMode;
        for (final packaging in product.packagings) {
          if (packaging.kind == 'carton') {
            _existingCarton = packaging;
            break;
          }
        }
        if (_existingCarton case final carton?) {
          _cartonFactor.text = '${carton.conversionFactor}';
          _cartonPurchase.text = carton.referencePurchasePrice;
          _cartonSuperWholesale.text = carton.superWholesalePrice;
          _cartonWholesale.text = carton.wholesalePrice;
          _cartonRetail.text = carton.retailPrice;
        }
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

  String? _cartonInteger(String? value) {
    final number = int.tryParse(value ?? '');
    return number == null || number < 2 ? _t('cartonFactorInvalid') : null;
  }

  Future<String?> _askCategoryName({String initial = ''}) async {
    final controller = TextEditingController(text: initial);
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(initial.isEmpty ? _t('newCategory') : _t('renameCategory')),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 120,
          decoration: InputDecoration(labelText: _t('name')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(_t('cancel')),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: Text(_t('save')),
          ),
        ],
      ),
    );
    controller.dispose();
    return value == null || value.isEmpty ? null : value;
  }

  Future<void> _createCategory() async {
    final name = await _askCategoryName();
    if (name == null) return;
    try {
      final category = await ref
          .read(productsRepositoryProvider)
          .createCategory(name);
      if (!mounted) return;
      setState(() {
        _categories = [..._categories, category]
          ..sort((a, b) => a.name.compareTo(b.name));
        _category = category.id;
      });
    } on AppFailure catch (failure) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
      }
    }
  }

  Future<void> _renameCategory(ReferenceOption category) async {
    final name = await _askCategoryName(initial: category.name);
    if (name == null) return;
    try {
      final updated = await ref
          .read(productsRepositoryProvider)
          .renameCategory(category.id, name);
      if (!mounted) return;
      setState(() {
        _categories =
            _categories
                .map((item) => item.id == updated.id ? updated : item)
                .toList()
              ..sort((a, b) => a.name.compareTo(b.name));
      });
    } on AppFailure catch (failure) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
      }
    }
  }

  Future<void> _deleteCategory(ReferenceOption category) async {
    int? replacement;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(_t('deleteCategory')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(category.name),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                initialValue: replacement,
                decoration: InputDecoration(
                  labelText: _t('replacementCategory'),
                ),
                items: _categories
                    .where((item) => item.id != category.id)
                    .map(
                      (item) => DropdownMenuItem<int?>(
                        value: item.id,
                        child: Text(item.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setDialogState(() => replacement = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(_t('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(_t('delete')),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    try {
      final repository = ref.read(productsRepositoryProvider);
      if (replacement == null) {
        await repository.deleteCategory(category.id);
      } else {
        await repository.reassignAndDeleteCategory(category.id, replacement!);
      }
      if (!mounted) return;
      setState(() {
        _categories = _categories
            .where((item) => item.id != category.id)
            .toList();
        if (_category == category.id) {
          _category = replacement;
        }
      });
    } on AppFailure catch (failure) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
      }
    }
  }

  Future<void> _manageCategories({
    required bool canRename,
    required bool canDelete,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, refreshSheet) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: Text(
                  _t('manageCategories'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              ..._categories.map(
                (category) => ListTile(
                  title: Text(category.name),
                  trailing: Wrap(
                    children: [
                      if (canRename)
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () async {
                            await _renameCategory(category);
                            refreshSheet(() {});
                          },
                        ),
                      if (canDelete)
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            await _deleteCategory(category);
                            refreshSheet(() {});
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _can(String permission) =>
      ref.read(authControllerProvider).user?.can(permission) ?? false;

  Future<void> _submit() async {
    setState(() => _fieldErrors = const {});
    if (!_formKey.currentState!.validate() || _submitting) return;
    setState(() => _submitting = true);
    final enteredQuantity = int.parse(_quantity.text);
    final factor = int.tryParse(_cartonFactor.text) ?? 1;
    final request = ProductWriteRequest(
      name: _name.text.trim(),
      category: _category,
      brand: _brand,
      unit: _unit,
      purchasePrice: _purchase.text.replaceAll(',', '.'),
      superWholesalePrice: _superWholesale.text.replaceAll(',', '.'),
      wholesalePrice: _wholesale.text.replaceAll(',', '.'),
      retailPrice: _retail.text.replaceAll(',', '.'),
      quantity: !_editing && _stockUnit == 'carton'
          ? enteredQuantity * factor
          : enteredQuantity,
      minimumStock: int.parse(_minimumStock.text),
      description: _description.text.trim(),
      unitMode: _unitMode,
    );
    try {
      final repository = ref.read(productsRepositoryProvider);
      final product = _editing
          ? await repository.update(widget.productId!, request)
          : await repository.create(request);
      if (_usesCarton) {
        await repository.saveCarton(
          ProductPackagingWriteRequest(
            productId: product.id,
            name: _t('carton'),
            conversionFactor: factor,
            referencePurchasePrice: _cartonPurchase.text.replaceAll(',', '.'),
            superWholesalePrice: _cartonSuperWholesale.text.replaceAll(
              ',',
              '.',
            ),
            wholesalePrice: _cartonWholesale.text.replaceAll(',', '.'),
            retailPrice: _cartonRetail.text.replaceAll(',', '.'),
          ),
          packagingId: _existingCarton?.id,
        );
      } else if (_existingCarton case final carton?) {
        await repository.disablePackaging(carton.id);
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
          SnackBar(
            content: Text(AppLocalizations.of(context).text('apiError')),
          ),
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
        ? const LoadingSkeleton(rows: 6)
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
                FormSectionHeader(title: _t('sectionInformation')),
                TextFormField(
                  controller: _name,
                  decoration: _decoration(_t('name'), 'name'),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                FormSectionHeader(title: _t('sectionClassification')),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _ReferenceDropdown(
                        label: _t('category'),
                        value: _category,
                        items: _categories,
                        error: _fieldErrors['category'],
                        onChanged: (v) => setState(() => _category = v),
                      ),
                    ),
                    if (_can(AppPermissions.addProduct))
                      IconButton(
                        tooltip: _t('newCategory'),
                        onPressed: _createCategory,
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    if (_can(AppPermissions.changeProduct) ||
                        _can(AppPermissions.deleteProduct))
                      IconButton(
                        tooltip: _t('manageCategories'),
                        onPressed: () => _manageCategories(
                          canRename: _can(AppPermissions.changeProduct),
                          canDelete: _can(AppPermissions.deleteProduct),
                        ),
                        icon: const Icon(Icons.settings_outlined),
                      ),
                  ],
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
                FormSectionHeader(title: _t('sectionPackaging')),
                DropdownButtonFormField<String>(
                  key: ValueKey(_unitMode),
                  initialValue: _unitMode,
                  decoration: _decoration(_t('unitMode'), 'unit_mode'),
                  items: [
                    DropdownMenuItem(
                      value: 'piece_only',
                      child: Text(_t('pieceOnly')),
                    ),
                    DropdownMenuItem(
                      value: 'carton_only',
                      child: Text(_t('cartonOnly')),
                    ),
                    DropdownMenuItem(
                      value: 'carton_and_piece',
                      child: Text(_t('cartonAndPiece')),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _unitMode = value ?? 'piece_only'),
                ),
                if (_usesCarton) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _cartonFactor,
                    decoration: _decoration(
                      _t('piecesPerCarton'),
                      'conversion_factor',
                    ),
                    keyboardType: TextInputType.number,
                    validator: _cartonInteger,
                    onChanged: (_) => setState(() {}),
                  ),
                  if ((int.tryParse(_cartonFactor.text) ?? 0) > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '1 ${_t('carton')} = ${_cartonFactor.text} ${_t('pieces')}',
                      ),
                    ),
                ],
                const SizedBox(height: 12),
                FormSectionHeader(title: _t('sectionPricing')),
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
                if (_usesCarton) ...[
                  const SizedBox(height: 16),
                  Text(
                    _t('cartonPrices'),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _cartonPurchase,
                    decoration: _decoration(
                      _t('cartonPurchasePrice'),
                      'reference_purchase_price',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: _decimal,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _cartonSuperWholesale,
                    decoration: _decoration(
                      _t('cartonSuperWholesalePrice'),
                      'super_wholesale_price',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: _decimal,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _cartonWholesale,
                    decoration: _decoration(
                      _t('cartonWholesalePrice'),
                      'wholesale_price',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: _decimal,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _cartonRetail,
                    decoration: _decoration(
                      _t('cartonRetailPrice'),
                      'retail_price',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: _decimal,
                  ),
                ],
                const SizedBox(height: 12),
                FormSectionHeader(title: _t('sectionStock')),
                if (!_editing && _usesCarton)
                  DropdownButtonFormField<String>(
                    initialValue: _stockUnit,
                    decoration: _decoration(_t('stockInputUnit'), 'stock_unit'),
                    items: [
                      DropdownMenuItem(
                        value: 'base',
                        child: Text(_t('pieces')),
                      ),
                      DropdownMenuItem(
                        value: 'carton',
                        child: Text(_t('carton')),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _stockUnit = value ?? 'base'),
                  ),
                if (!_editing && _usesCarton) const SizedBox(height: 12),
                TextFormField(
                  controller: _quantity,
                  decoration: _decoration(_t('quantity'), 'quantity'),
                  keyboardType: TextInputType.number,
                  validator: _integer,
                  onChanged: (_) => setState(() {}),
                ),
                if (!_editing && _stockUnit == 'carton' && _usesCarton)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${_t('canonicalStock')} : ${(int.tryParse(_quantity.text) ?? 0) * (int.tryParse(_cartonFactor.text) ?? 0)} ${_t('pieces')}',
                    ),
                  ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _minimumStock,
                  decoration: _decoration(_t('minimumStock'), 'minimum_stock'),
                  keyboardType: TextInputType.number,
                  validator: _integer,
                ),
                const SizedBox(height: 12),
                FormSectionHeader(title: _t('sectionAdditional')),
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
      _cartonFactor,
      _cartonPurchase,
      _cartonSuperWholesale,
      _cartonWholesale,
      _cartonRetail,
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
