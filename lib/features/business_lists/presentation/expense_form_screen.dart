import 'package:app_alim_gen_mobile/app/providers.dart';
import 'package:app_alim_gen_mobile/core/errors/app_failure.dart';
import 'package:app_alim_gen_mobile/features/business_lists/domain/business_entities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:app_alim_gen_mobile/l10n/crud_strings.dart';

class ExpenseFormScreen extends ConsumerStatefulWidget {
  const ExpenseFormScreen({super.key, this.expenseId});
  final int? expenseId;
  @override
  ConsumerState<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends ConsumerState<ExpenseFormScreen> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _date, _description, _amount, _observation;
  int? _category, _supplier;
  String _payment = 'cash';
  bool _loading = true, _submitting = false;
  Map<String, String> _errors = const {};
  List<BusinessOption> _categories = const [], _suppliers = const [];
  bool get _editing => widget.expenseId != null;
  @override
  void initState() {
    super.initState();
    _date = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    _description = TextEditingController();
    _amount = TextEditingController();
    _observation = TextEditingController();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    try {
      final repository = ref.read(expensesRepositoryProvider);
      final values = await Future.wait<dynamic>([
        repository.options('expense-categories/'),
        repository.options('suppliers/'),
        if (_editing) repository.get(widget.expenseId!),
      ]);
      _categories = values[0] as List<BusinessOption>;
      _suppliers = values[1] as List<BusinessOption>;
      if (_editing) {
        final item = values[2] as ExpenseDetails;
        _date.text = item.date;
        _description.text = item.description;
        _amount.text = item.amount;
        _observation.text = item.observation;
        _category = item.category;
        _supplier = item.supplier;
        _payment = item.paymentMethod;
      }
    } catch (error) {
      if (mounted) {
        _show(
          error is AppFailure
              ? error.message
              : 'Impossible de charger le formulaire.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    setState(() => _errors = const {});
    if (!_key.currentState!.validate() || _submitting) return;
    setState(() => _submitting = true);
    final request = ExpenseWriteRequest(
      date: _date.text,
      category: _category!,
      supplier: _supplier,
      description: _description.text.trim(),
      amount: _amount.text.replaceAll(',', '.'),
      paymentMethod: _payment,
      observation: _observation.text.trim(),
    );
    try {
      final repository = ref.read(expensesRepositoryProvider);
      if (_editing) {
        await repository.update(widget.expenseId!, request);
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

  void _show(String value) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(value)));
  InputDecoration _d(String label, String key) => InputDecoration(
    labelText: label,
    errorText: _errors[key],
    border: const OutlineInputBorder(),
  );
  String _t(String key) => CrudStrings.of(context).text(key);
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(_editing ? _t('editExpense') : _t('newExpense')),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : Form(
            key: _key,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  controller: _date,
                  readOnly: true,
                  decoration: _d(
                    _t('date'),
                    'date',
                  ).copyWith(suffixIcon: const Icon(Icons.calendar_today)),
                  onTap: () async {
                    final initial =
                        DateTime.tryParse(_date.text) ?? DateTime.now();
                    final value = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                      initialDate: initial,
                    );
                    if (value != null) {
                      _date.text = DateFormat('yyyy-MM-dd').format(value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _categories.any((e) => e.id == _category)
                      ? _category
                      : null,
                  decoration: _d(_t('category'), 'category'),
                  items: _categories
                      .map(
                        (e) =>
                            DropdownMenuItem(value: e.id, child: Text(e.name)),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _category = v),
                  validator: (v) => v == null ? _t('required') : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _description,
                  decoration: _d(_t('description'), 'description'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? _t('required') : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amount,
                  decoration: _d(_t('amount'), 'amount'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) {
                    final n = double.tryParse((v ?? '').replaceAll(',', '.'));
                    return n == null || n <= 0
                        ? 'Le montant doit être positif.'
                        : null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _payment,
                  decoration: _d(_t('paymentMethod'), 'payment_method'),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('Espèces')),
                    DropdownMenuItem(value: 'cheque', child: Text('Chèque')),
                    DropdownMenuItem(
                      value: 'transfer',
                      child: Text('Virement'),
                    ),
                    DropdownMenuItem(value: 'card', child: Text('Carte')),
                  ],
                  onChanged: (v) => setState(() => _payment = v ?? 'cash'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _suppliers.any((e) => e.id == _supplier)
                      ? _supplier
                      : null,
                  decoration: _d(_t('supplierOptional'), 'supplier'),
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text('Aucun'),
                    ),
                    ..._suppliers.map(
                      (e) => DropdownMenuItem(value: e.id, child: Text(e.name)),
                    ),
                  ],
                  onChanged: (v) => setState(() => _supplier = v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _observation,
                  maxLines: 3,
                  decoration: _d(_t('observation'), 'observation'),
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
    _date.dispose();
    _description.dispose();
    _amount.dispose();
    _observation.dispose();
    super.dispose();
  }
}
