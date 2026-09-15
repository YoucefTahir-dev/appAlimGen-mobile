import 'package:app_alim_gen_mobile/app/providers.dart';
import 'package:app_alim_gen_mobile/core/errors/app_failure.dart';
import 'package:app_alim_gen_mobile/features/printers/domain/printer_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_alim_gen_mobile/l10n/crud_strings.dart';

class PrinterFormScreen extends ConsumerStatefulWidget {
  const PrinterFormScreen({super.key, this.printerId});
  final int? printerId;
  @override
  ConsumerState<PrinterFormScreen> createState() => _PrinterFormScreenState();
}

class _PrinterFormScreenState extends ConsumerState<PrinterFormScreen> {
  final _key = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _f;
  String _type = 'thermal',
      _connection = 'bluetooth',
      _protocol = 'generic_escpos';
  int _width = 80;
  bool _auto = false,
      _invoices = true,
      _receipts = true,
      _active = true,
      _loading = false,
      _submitting = false;
  Map<String, String> _errors = const {};
  bool get _editing => widget.printerId != null;
  @override
  void initState() {
    super.initState();
    _f = {
      for (final k in [
        'name',
        'description',
        'manufacturer',
        'model_name',
        'local_identifier',
        'bluetooth_name',
        'bluetooth_address',
        'ip_address',
        'network_port',
        'characters_per_line',
        'encoding',
      ])
        k: TextEditingController(
          text: k == 'characters_per_line'
              ? '48'
              : k == 'encoding'
              ? 'cp858'
              : '',
        ),
    };
    if (_editing) {
      _loading = true;
      Future.microtask(_load);
    }
  }

  Future<void> _load() async {
    try {
      final p = await ref
          .read(printersRepositoryProvider)
          .get(widget.printerId!);
      final values = {
        'name': p.name,
        'description': p.description,
        'manufacturer': p.manufacturer,
        'model_name': p.modelName,
        'local_identifier': p.localIdentifier,
        'bluetooth_name': p.bluetoothName,
        'bluetooth_address': p.bluetoothAddress,
        'ip_address': p.ipAddress,
        'network_port': p.networkPort?.toString() ?? '',
        'characters_per_line': p.charactersPerLine.toString(),
        'encoding': p.encoding,
      };
      values.forEach((k, v) => _f[k]!.text = v);
      _type = p.printerType;
      _connection = p.connectionMode;
      _protocol = p.protocol;
      _width = p.paperWidth;
      _auto = p.autoPrint;
      _invoices = p.printInvoices;
      _receipts = p.printReceipts;
      _active = p.isActive;
    } catch (e) {
      if (mounted) {
        _show(e is AppFailure ? e.message : 'Impossible de charger.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    setState(() => _errors = const {});
    if (!_key.currentState!.validate() || _submitting) return;
    setState(() => _submitting = true);
    final port = int.tryParse(_v('network_port'));
    final request = PrinterWriteRequest({
      'name': _v('name'),
      'description': _v('description'),
      'printer_type': _type,
      'manufacturer': _v('manufacturer'),
      'model_name': _v('model_name'),
      'connection_mode': _connection,
      'local_identifier': _v('local_identifier'),
      'bluetooth_name': _v('bluetooth_name'),
      'bluetooth_address': _v('bluetooth_address'),
      'ip_address': _v('ip_address').isEmpty ? null : _v('ip_address'),
      'network_port': port,
      'paper_width': _width,
      'protocol': _protocol,
      'characters_per_line': int.parse(_v('characters_per_line')),
      'encoding': _v('encoding'),
      'auto_print': _auto,
      'print_invoices': _invoices,
      'print_receipts': _receipts,
      'is_active': _active,
    });
    try {
      final r = ref.read(printersRepositoryProvider);
      if (_editing) {
        await r.update(widget.printerId!, request);
      } else {
        await r.create(request);
      }
      if (mounted) Navigator.pop(context, true);
    } on AppFailure catch (f) {
      if (mounted) {
        setState(() => _errors = f.fieldErrors);
        _show(f.message);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _v(String k) => _f[k]!.text.trim();
  String _t(String key) => CrudStrings.of(context).text(key);
  void _show(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  InputDecoration _d(String l, String k) => InputDecoration(
    labelText: l,
    errorText: _errors[k],
    border: const OutlineInputBorder(),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(_editing ? _t('editPrinter') : _t('newPrinter')),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : Form(
            key: _key,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _text('name', _t('internalName'), required: true),
                _text('description', _t('description'), lines: 3),
                _drop(_t('printerType'), _type, const {
                  'thermal': 'Thermique',
                  'inkjet': 'Jet d’encre',
                  'laser': 'Laser',
                  'other': 'Autre',
                }, (v) => setState(() => _type = v)),
                _text('manufacturer', _t('manufacturer')),
                _text('model_name', _t('model')),
                _drop(
                  _t('connectionMode'),
                  _connection,
                  const {
                    'bluetooth': 'Bluetooth',
                    'usb': 'USB',
                    'network': 'Réseau TCP/IP',
                    'windows': 'Windows',
                    'android': 'Android Print Service',
                    'other': 'Autre',
                  },
                  (v) => setState(() => _connection = v),
                ),
                _text('local_identifier', _t('localIdentifier')),
                _text('bluetooth_name', _t('bluetoothName')),
                _text('bluetooth_address', _t('bluetoothAddress')),
                if (_connection == 'network') ...[
                  _text('ip_address', _t('ipAddress'), required: true),
                  _text(
                    'network_port',
                    _t('networkPort'),
                    required: true,
                    keyboard: TextInputType.number,
                  ),
                ],
                _dropInt(_t('paperWidth'), _width, const {
                  58: '58 mm',
                  80: '80 mm',
                }, (v) => setState(() => _width = v)),
                _drop(_t('protocol'), _protocol, const {
                  'generic_escpos': 'Generic ESC/POS',
                  'epson_escpos': 'Epson ESC/POS',
                  'xprinter': 'XPrinter',
                  'sunmi': 'Sunmi',
                  'star': 'Star',
                  'posiflex': 'Posiflex',
                  'gp': 'GP',
                  'custom': 'Autre',
                }, (v) => setState(() => _protocol = v)),
                _text(
                  'characters_per_line',
                  _t('charactersPerLine'),
                  required: true,
                  keyboard: TextInputType.number,
                ),
                _text('encoding', _t('encoding'), required: true),
                SwitchListTile(
                  value: _auto,
                  onChanged: (v) => setState(() => _auto = v),
                  title: Text(_t('autoPrint')),
                ),
                SwitchListTile(
                  value: _invoices,
                  onChanged: (v) => setState(() => _invoices = v),
                  title: Text(_t('printInvoices')),
                ),
                SwitchListTile(
                  value: _receipts,
                  onChanged: (v) => setState(() => _receipts = v),
                  title: Text(_t('printReceipts')),
                ),
                SwitchListTile(
                  value: _active,
                  onChanged: (v) => setState(() => _active = v),
                  title: Text(_t('active')),
                ),
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
  Widget _text(
    String k,
    String l, {
    bool required = false,
    int lines = 1,
    TextInputType? keyboard,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: _f[k],
      maxLines: lines,
      keyboardType: keyboard,
      decoration: _d(l, k),
      validator: required
          ? (v) => v == null || v.trim().isEmpty
                ? _t('required')
                : (keyboard == TextInputType.number && int.tryParse(v) == null
                      ? 'Nombre invalide.'
                      : null)
          : null,
    ),
  );
  Widget _drop(
    String l,
    String v,
    Map<String, String> values,
    ValueChanged<String> change,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<String>(
      initialValue: v,
      decoration: _d(l, ''),
      items: values.entries
          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
          .toList(),
      onChanged: (x) {
        if (x != null) change(x);
      },
    ),
  );
  Widget _dropInt(
    String l,
    int v,
    Map<int, String> values,
    ValueChanged<int> change,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<int>(
      initialValue: v,
      decoration: _d(l, ''),
      items: values.entries
          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
          .toList(),
      onChanged: (x) {
        if (x != null) change(x);
      },
    ),
  );
  @override
  void dispose() {
    for (final c in _f.values) {
      c.dispose();
    }
    super.dispose();
  }
}
