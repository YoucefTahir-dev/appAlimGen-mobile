import 'package:app_alim_gen_mobile/app/providers.dart';
import 'package:app_alim_gen_mobile/core/errors/app_failure.dart';
import 'package:app_alim_gen_mobile/features/clients/domain/client_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:app_alim_gen_mobile/l10n/crud_strings.dart';

class ClientFormScreen extends ConsumerStatefulWidget {
  const ClientFormScreen({super.key, this.clientId});
  final int? clientId;

  @override
  ConsumerState<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends ConsumerState<ClientFormScreen> {
  final _key = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _fields;
  String _customerType = 'RETAIL';
  bool _loading = false;
  bool _submitting = false;
  bool _locating = false;
  Map<String, String> _errors = const {};
  double? _latitude, _longitude, _accuracy;
  String? _formattedAddress, _placeId;

  bool get _editing => widget.clientId != null;

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
        'tax_number',
        'balance',
        'notes',
      ])
        name: TextEditingController(text: name == 'balance' ? '0.00' : ''),
    };
    if (_editing) {
      _loading = true;
      Future.microtask(_load);
    }
  }

  Future<void> _load() async {
    try {
      final client = await ref
          .read(clientsRepositoryProvider)
          .get(widget.clientId!);
      _fields['name']!.text = client.name;
      _fields['phone']!.text = client.phone;
      _fields['address']!.text = client.address;
      _fields['wilaya']!.text = client.wilaya;
      _fields['email']!.text = client.email;
      _fields['tax_number']!.text = client.taxNumber;
      _fields['balance']!.text = client.balance;
      _fields['notes']!.text = client.notes;
      _customerType = client.customerType;
      _latitude = client.latitude;
      _longitude = client.longitude;
      _accuracy = client.locationAccuracy;
      _formattedAddress = client.formattedAddress;
      _placeId = client.placeId;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_message(error))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _locate() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Activez la localisation du téléphone.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Autorisation de localisation refusée.');
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      final places = await Geocoding().placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      final place = places.isEmpty ? null : places.first;
      final address = place == null
          ? '${position.latitude}, ${position.longitude}'
          : [place.street, place.postalCode, place.locality, place.country]
                .whereType<String>()
                .where((value) => value.trim().isNotEmpty)
                .join(', ');
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _accuracy = position.accuracy;
        _formattedAddress = address;
        _placeId = null;
        _fields['address']!.text = address;
        if (_fields['wilaya']!.text.isEmpty &&
            place?.administrativeArea != null) {
          _fields['wilaya']!.text = place!.administrativeArea!;
        }
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_message(error))));
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _submit() async {
    setState(() => _errors = const {});
    if (!_key.currentState!.validate() || _submitting) return;
    setState(() => _submitting = true);
    final request = ClientWriteRequest(
      name: _value('name'),
      phone: _value('phone'),
      address: _value('address'),
      wilaya: _value('wilaya'),
      customerType: _customerType,
      email: _value('email'),
      taxNumber: _value('tax_number'),
      balance: _value('balance').replaceAll(',', '.'),
      notes: _value('notes'),
      latitude: _latitude,
      longitude: _longitude,
      locationAccuracy: _accuracy,
      formattedAddress: _formattedAddress,
      placeId: _placeId,
    );
    try {
      final repository = ref.read(clientsRepositoryProvider);
      if (_editing) {
        await repository.update(widget.clientId!, request);
      } else {
        await repository.create(request);
      }
      if (mounted) Navigator.pop(context, true);
    } on AppFailure catch (failure) {
      if (!mounted) return;
      setState(() => _errors = failure.fieldErrors);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message)));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_message(error))));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _value(String name) => _fields[name]!.text.trim();
  String _t(String key) => CrudStrings.of(context).text(key);
  String _message(Object error) => error is AppFailure
      ? error.message
      : error.toString().replaceFirst('Exception: ', '');
  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? _t('required') : null;
  InputDecoration _decoration(String label, String field, {Widget? suffix}) =>
      InputDecoration(
        labelText: label,
        errorText: _errors[field],
        border: const OutlineInputBorder(),
        suffixIcon: suffix,
      );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_editing ? _t('editClient') : _t('newClient'))),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : Form(
            key: _key,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _text('name', _t('name'), validator: _required),
                _text('phone', _t('phone'), keyboard: TextInputType.phone),
                _text(
                  'address',
                  _t('address'),
                  suffix: IconButton(
                    onPressed: _locating ? null : _locate,
                    icon: _locating
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location),
                  ),
                ),
                if (_accuracy != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      '${_t('gpsAccuracy')} : ${_accuracy!.round()} m',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                _text('wilaya', _t('wilaya')),
                DropdownButtonFormField<String>(
                  initialValue: _customerType,
                  decoration: _decoration(_t('customerType'), 'customer_type'),
                  items: const [
                    DropdownMenuItem(
                      value: 'SUPER_WHOLESALE',
                      child: Text('Super Gros'),
                    ),
                    DropdownMenuItem(value: 'WHOLESALE', child: Text('Gros')),
                    DropdownMenuItem(value: 'RETAIL', child: Text('Détail')),
                  ],
                  onChanged: (value) =>
                      setState(() => _customerType = value ?? 'RETAIL'),
                ),
                const SizedBox(height: 12),
                _text(
                  'email',
                  _t('email'),
                  keyboard: TextInputType.emailAddress,
                ),
                _text('tax_number', _t('taxNumber')),
                _text(
                  'balance',
                  _t('balance'),
                  keyboard: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) =>
                      double.tryParse((value ?? '').replaceAll(',', '.')) ==
                          null
                      ? 'Nombre invalide.'
                      : null,
                ),
                _text('notes', _t('notes'), maxLines: 3),
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
    String name,
    String label, {
    String? Function(String?)? validator,
    TextInputType? keyboard,
    int maxLines = 1,
    Widget? suffix,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: _fields[name],
      decoration: _decoration(label, name, suffix: suffix),
      validator: validator,
      keyboardType: keyboard,
      maxLines: maxLines,
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
