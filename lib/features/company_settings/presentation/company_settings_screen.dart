import 'package:app_alim_gen_mobile/app/providers.dart';
import 'package:app_alim_gen_mobile/core/errors/app_failure.dart';
import 'package:app_alim_gen_mobile/core/navigation/module_scaffold.dart';
import 'package:app_alim_gen_mobile/core/permissions/permission_service.dart';
import 'package:app_alim_gen_mobile/core/widgets/app_ui.dart';
import 'package:app_alim_gen_mobile/features/auth/presentation/auth_controller.dart';
import 'package:app_alim_gen_mobile/features/company_settings/domain/company_settings.dart';
import 'package:app_alim_gen_mobile/l10n/crud_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CompanySettingsScreen extends ConsumerStatefulWidget {
  const CompanySettingsScreen({super.key});

  @override
  ConsumerState<CompanySettingsScreen> createState() =>
      _CompanySettingsScreenState();
}

class _CompanySettingsScreenState extends ConsumerState<CompanySettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _fields = {
    for (final name in const [
      'company_name',
      'address',
      'phone',
      'email',
      'tax_number',
      'nis',
      'rc_number',
      'article_number',
      'tax_rate',
    ])
      name: TextEditingController(),
  };
  bool _loading = true;
  bool _saving = false;
  Map<String, String> _errors = const {};

  bool get _canEdit =>
      ref
          .read(authControllerProvider)
          .user
          ?.can(AppPermissions.changeSettings) ??
      false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    try {
      final settings = await ref.read(companySettingsRepositoryProvider).get();
      _fill(settings);
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _fill(CompanySettings value) {
    _fields['company_name']!.text = value.companyName;
    _fields['address']!.text = value.address;
    _fields['phone']!.text = value.phone;
    _fields['email']!.text = value.email;
    _fields['tax_number']!.text = value.taxNumber;
    _fields['nis']!.text = value.nis;
    _fields['rc_number']!.text = value.rcNumber;
    _fields['article_number']!.text = value.articleNumber;
    _fields['tax_rate']!.text = value.taxRate;
  }

  Future<void> _save() async {
    setState(() => _errors = const {});
    if (!_formKey.currentState!.validate() || _saving || !_canEdit) return;
    setState(() => _saving = true);
    try {
      final saved = await ref
          .read(companySettingsRepositoryProvider)
          .update(
            CompanySettings(
              companyName: _value('company_name'),
              address: _value('address'),
              phone: _value('phone'),
              email: _value('email'),
              rcNumber: _value('rc_number'),
              taxNumber: _value('tax_number'),
              nis: _value('nis'),
              articleNumber: _value('article_number'),
              taxRate: _value('tax_rate').replaceAll(',', '.'),
            ),
          );
      _fill(saved);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_text('saved'))));
      }
    } on AppFailure catch (failure) {
      if (mounted) {
        setState(() => _errors = failure.fieldErrors);
        _showError(failure);
      }
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _value(String name) => _fields[name]!.text.trim();
  String _text(String key) =>
      _strings[Localizations.localeOf(context).languageCode]?[key] ??
      _strings['fr']![key] ??
      key;

  void _showError(Object error) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(error is AppFailure ? error.message : error.toString()),
    ),
  );

  @override
  Widget build(BuildContext context) => ModuleScaffold(
    title: _text('title'),
    path: '/company-settings',
    body: _loading
        ? const LoadingSkeleton(rows: 7)
        : Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                FormSectionHeader(title: _text('identity')),
                _field('company_name', _text('companyName'), required: true),
                _field('address', _text('address'), maxLines: 2),
                _field('phone', _text('phone'), keyboard: TextInputType.phone),
                _field(
                  'email',
                  _text('email'),
                  keyboard: TextInputType.emailAddress,
                ),
                FormSectionHeader(
                  title: CrudStrings.of(context).text('sectionLegal'),
                ),
                _field('tax_number', 'NIF'),
                _field('nis', 'NIS'),
                _field('rc_number', 'RC'),
                _field('article_number', 'AI'),
                _field(
                  'tax_rate',
                  _text('taxRate'),
                  keyboard: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  required: true,
                  decimal: true,
                ),
                if (_canEdit)
                  FilledButton.icon(
                    key: const Key('company-settings-save'),
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_text('save')),
                  ),
              ],
            ),
          ),
  );

  Widget _field(
    String name,
    String label, {
    bool required = false,
    bool decimal = false,
    int maxLines = 1,
    TextInputType? keyboard,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: _fields[name],
      readOnly: !_canEdit,
      keyboardType: keyboard,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        errorText: _errors[name],
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        final text = value?.trim() ?? '';
        if (required && text.isEmpty) return _text('required');
        if (decimal && double.tryParse(text.replaceAll(',', '.')) == null) {
          return _text('invalidNumber');
        }
        return null;
      },
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

const _strings = <String, Map<String, String>>{
  'fr': {
    'title': 'Entreprise',
    'identity': 'Identité et coordonnées',
    'companyName': 'Nom de l’entreprise',
    'address': 'Adresse',
    'phone': 'Téléphone',
    'email': 'E-mail',
    'taxRate': 'TVA (%)',
    'save': 'Enregistrer',
    'saved': 'Paramètres de l’entreprise enregistrés.',
    'required': 'Ce champ est obligatoire.',
    'invalidNumber': 'Saisissez un nombre valide.',
  },
  'en': {
    'title': 'Company',
    'identity': 'Identity and contact details',
    'companyName': 'Company name',
    'address': 'Address',
    'phone': 'Phone',
    'email': 'Email',
    'taxRate': 'Tax rate (%)',
    'save': 'Save',
    'saved': 'Company settings saved.',
    'required': 'This field is required.',
    'invalidNumber': 'Enter a valid number.',
  },
  'ar': {
    'title': 'المؤسسة',
    'identity': 'الهوية وبيانات الاتصال',
    'companyName': 'اسم المؤسسة',
    'address': 'العنوان',
    'phone': 'الهاتف',
    'email': 'البريد الإلكتروني',
    'taxRate': 'نسبة الضريبة (%)',
    'save': 'حفظ',
    'saved': 'تم حفظ إعدادات المؤسسة.',
    'required': 'هذا الحقل مطلوب.',
    'invalidNumber': 'أدخل رقماً صالحاً.',
  },
};
