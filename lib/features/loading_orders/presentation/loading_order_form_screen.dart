import 'package:app_alim_gen_mobile/app/providers.dart';
import 'package:app_alim_gen_mobile/core/errors/app_failure.dart';
import 'package:app_alim_gen_mobile/features/business_lists/domain/business_entities.dart';
import 'package:app_alim_gen_mobile/features/business_lists/presentation/transaction_form_screens.dart';
import 'package:app_alim_gen_mobile/features/loading_orders/domain/loading_order_summary.dart';
import 'package:app_alim_gen_mobile/l10n/crud_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoadingOrderFormScreen extends ConsumerStatefulWidget {
  const LoadingOrderFormScreen({super.key, this.orderId});
  final int? orderId;
  @override
  ConsumerState<LoadingOrderFormScreen> createState() => _State();
}

class _Line {
  TransactionOption? product;
  TransactionOption? packaging;
  List<TransactionOption> packagings = const [];
  final quantity = TextEditingController(text: '1');
  int get factor => (packaging?.meta['factor'] as num?)?.toInt() ?? 1;
  void dispose() => quantity.dispose();
}

class _State extends ConsumerState<LoadingOrderFormScreen> {
  final _form = GlobalKey<FormState>();
  final _operator = TextEditingController(), _notes = TextEditingController();
  final _lines = <_Line>[_Line()];
  bool _saving = false, _loading = false;
  String? _error;
  late final String _key;
  @override
  void initState() {
    super.initState();
    _key = ref.read(loadingOrdersRepositoryProvider).newKey();
    if (widget.orderId != null) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final o = await ref
          .read(loadingOrdersRepositoryProvider)
          .get(widget.orderId!);
      _operator.text = o.operatorId?.toString() ?? '';
      _notes.text = o.notes;
      for (final l in _lines) {
        l.dispose();
      }
      _lines.clear();
      for (final line in o.lines) {
        final l = _Line()
          ..product = TransactionOption(
            id: line.productId,
            label: line.productName,
          )
          ..quantity.text = line.loaded.toString();
        if (line.packagingId != null) {
          l.packaging = TransactionOption(
            id: line.packagingId!,
            label: line.packagingName,
            meta: {'factor': line.packagingFactor},
          );
          l.packagings = [l.packaging!];
        }
        _lines.add(l);
      }
    } catch (e) {
      _error = e is AppFailure ? e.message : e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _operator.dispose();
    _notes.dispose();
    for (final l in _lines) {
      l.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving ||
        !(_form.currentState?.validate() ?? false) ||
        _lines.any((l) => l.product == null)) {
      setState(() => _error = 'Sélectionnez tous les produits.');
      return;
    }
    setState(() => _saving = true);
    final request = LoadingOrderWriteRequest(
      operatorId: int.parse(_operator.text),
      notes: _notes.text,
      lines: _lines
          .map(
            (l) => LoadingOrderLineWrite(
              l.product!.id,
              int.parse(l.quantity.text),
              packagingId: l.packaging?.id,
            ),
          )
          .toList(),
    );
    try {
      if (widget.orderId == null) {
        await ref.read(loadingOrdersRepositoryProvider).create(request, _key);
      } else {
        await ref
            .read(loadingOrdersRepositoryProvider)
            .update(widget.orderId!, request);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = e is AppFailure ? e.message : e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.orderId == null
            ? 'Nouveau bon de chargement'
            : 'Modifier le brouillon',
      ),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  controller: _operator,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Identifiant opérateur',
                  ),
                  validator: (v) => int.tryParse(v ?? '') == null
                      ? 'Identifiant requis'
                      : null,
                ),
                TextFormField(
                  controller: _notes,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 3,
                ),
                ..._lines.asMap().entries.map((entry) {
                  final i = entry.key, l = entry.value;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          RemoteOptionField(
                            key: ValueKey('loading-product-$i'),
                            label: l.product?.label ?? 'Produit (recherche)',
                            search: (q) async =>
                                (await ref
                                        .read(loadingOrdersRepositoryProvider)
                                        .searchProducts(q))
                                    .map(
                                      (j) => TransactionOption(
                                        id: (j['id'] as num).toInt(),
                                        label: j['name']?.toString() ?? '',
                                        meta: j,
                                      ),
                                    )
                                    .toList(),
                            onSelected: (o) {
                              l.product = o;
                              l.packagings =
                                  (o.meta['loading_units'] as List? ?? const [])
                                      .whereType<Map>()
                                      .map((raw) {
                                        final item = Map<String, dynamic>.from(
                                          raw,
                                        );
                                        return TransactionOption(
                                          id:
                                              (item['id'] as num?)?.toInt() ??
                                              0,
                                          label: item['name']?.toString() ?? '',
                                          meta: item,
                                        );
                                      })
                                      .where((item) => item.id > 0)
                                      .toList(growable: false);
                              l.packaging = null;
                              setState(() {});
                            },
                          ),
                          if (l.packagings.isNotEmpty)
                            DropdownButtonFormField<TransactionOption?>(
                              initialValue: l.packaging,
                              decoration: InputDecoration(
                                labelText: CrudStrings.of(
                                  context,
                                ).text('unitMode'),
                              ),
                              items: [
                                DropdownMenuItem<TransactionOption?>(
                                  value: null,
                                  child: Text(
                                    CrudStrings.of(context).text('pieces'),
                                  ),
                                ),
                                ...l.packagings.map(
                                  (
                                    packaging,
                                  ) => DropdownMenuItem<TransactionOption?>(
                                    value: packaging,
                                    child: Text(
                                      '${packaging.label} (×${packaging.meta['factor'] ?? 1})',
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: (value) =>
                                  setState(() => l.packaging = value),
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
                                  validator: (v) =>
                                      (int.tryParse(v ?? '') ?? 0) < 1
                                      ? 'Quantité invalide'
                                      : null,
                                ),
                              ),
                              if (_lines.length > 1)
                                IconButton(
                                  onPressed: () => setState(
                                    () => _lines.removeAt(i).dispose(),
                                  ),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                            ],
                          ),
                          if (l.packaging != null)
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                '${int.tryParse(l.quantity.text) ?? 0} ${l.packaging!.label} = '
                                '${(int.tryParse(l.quantity.text) ?? 0) * l.factor} '
                                '${CrudStrings.of(context).text('pieces')}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
                TextButton.icon(
                  onPressed: () => setState(() => _lines.add(_Line())),
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter produit'),
                ),
                if (_error != null)
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                FilledButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const CircularProgressIndicator()
                      : const Text('Enregistrer le brouillon'),
                ),
              ],
            ),
          ),
  );
}
