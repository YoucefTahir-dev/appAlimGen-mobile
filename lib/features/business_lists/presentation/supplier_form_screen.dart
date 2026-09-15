import 'package:app_alim_gen_mobile/app/providers.dart';
import 'package:app_alim_gen_mobile/core/errors/app_failure.dart';
import 'package:app_alim_gen_mobile/features/business_lists/domain/business_entities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_alim_gen_mobile/l10n/crud_strings.dart';

class SupplierFormScreen extends ConsumerStatefulWidget {
  const SupplierFormScreen({super.key, this.supplierId});
  final int? supplierId;
  @override
  ConsumerState<SupplierFormScreen> createState() => _SupplierFormScreenState();
}

class _SupplierFormScreenState extends ConsumerState<SupplierFormScreen> {
  final _key = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _fields;
  bool _loading = false, _submitting = false;
  Map<String, String> _errors = const {};
  bool get _editing => widget.supplierId != null;

  @override
  void initState() {
    super.initState();
    _fields = {
      for (final name in [
        'name',
        'phone',
        'address',
        'wilaya',
        'email',
        'rc_number',
        'tax_number',
        'notes',
      ])
        name: TextEditingController(),
    };
    if (_editing) {
      _loading = true;
      Future.microtask(_load);
    }
  }

  Future<void> _load() async {
    try {
      final item = await ref
          .read(suppliersRepositoryProvider)
          .get(widget.supplierId!);
      final values = {
        'name': item.name,
        'phone': item.phone,
        'address': item.address,
        'wilaya': item.wilaya,
        'email': item.email,
        'rc_number': item.rcNumber,
        'tax_number': item.taxNumber,
        'notes': item.notes,
      };
      values.forEach((key, value) => _fields[key]!.text = value);
    } catch (error) {
      if (mounted) _show(_message(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    setState(() => _errors = const {});
    if (!_key.currentState!.validate() || _submitting) return;
    setState(() => _submitting = true);
    final request = SupplierWriteRequest(
      name: _v('name'),
      phone: _v('phone'),
      address: _v('address'),
      wilaya: _v('wilaya'),
      email: _v('email'),
      rcNumber: _v('rc_number'),
      taxNumber: _v('tax_number'),
      notes: _v('notes'),
    );
    try {
      final repository = ref.read(suppliersRepositoryProvider);
      if (_editing) {
        await repository.update(widget.supplierId!, request);
      } else {
        await repository.create(request);
      }
      if (mounted) Navigator.pop(context, true);
    } on AppFailure catch (failure) {
      if (mounted) {
        setState(() => _errors = failure.fieldErrors);
        _show(failure.message);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _v(String key) => _fields[key]!.text.trim();
  String _t(String key) => CrudStrings.of(context).text(key);
  String _message(Object error) =>
      error is AppFailure ? error.message : 'Impossible de traiter la demande.';
  void _show(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(_editing ? _t('editSupplier') : _t('newSupplier')),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : Form(
            key: _key,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _field('name', _t('name'), required: true),
                _field('phone', _t('phone'), keyboard: TextInputType.phone),
                _field('address', _t('address')),
                _field('wilaya', _t('wilaya')),
                _field(
                  'email',
                  _t('email'),
                  keyboard: TextInputType.emailAddress,
                ),
                _field('rc_number', _t('rc')),
                _field('tax_number', _t('taxNumber')),
                _field('notes', _t('notes'), lines: 3),
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
  Widget _field(
    String key,
    String label, {
    bool required = false,
    TextInputType? keyboard,
    int lines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: _fields[key],
      keyboardType: keyboard,
      maxLines: lines,
      decoration: InputDecoration(
        labelText: label,
        errorText: _errors[key],
        border: const OutlineInputBorder(),
      ),
      validator: required
          ? (value) =>
                value == null || value.trim().isEmpty ? _t('required') : null
          : null,
    ),
  );
  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
