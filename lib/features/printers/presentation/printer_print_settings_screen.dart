import 'package:app_alim_gen_mobile/app/providers.dart';
import 'package:app_alim_gen_mobile/features/printers/domain/printer_print_profile.dart';
import 'package:app_alim_gen_mobile/features/printers/domain/printer_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// These preferences belong to the device. No Django printer profile is changed.
class PrinterPrintSettingsScreen extends ConsumerStatefulWidget {
  const PrinterPrintSettingsScreen({super.key, required this.printer});
  final PrinterDetails printer;

  @override
  ConsumerState<PrinterPrintSettingsScreen> createState() =>
      _PrintSettingsState();
}

class _PrintSettingsState extends ConsumerState<PrinterPrintSettingsScreen> {
  final _key = GlobalKey<FormState>();
  final _chunk = TextEditingController();
  final _pause = TextEditingController();
  final _band = TextEditingController();
  final _feed = TextEditingController();
  bool _cut = true, _loading = true, _saving = false;
  bool _loadFailed = false;

  String t(String fr, String ar, String en) =>
      switch (Localizations.localeOf(context).languageCode) {
        'ar' => ar,
        'en' => en,
        _ => fr,
      };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final profile = await ref
          .read(printerPrintProfileStoreProvider)
          .read(widget.printer);
      if (!mounted) return;
      _chunk.text = '${profile.chunkBytes}';
      _pause.text = '${profile.pauseMs}';
      _band.text = '${profile.rasterBandRows}';
      _feed.text = '${profile.feedLines}';
      setState(() {
        _cut = profile.cutPaper;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  Future<void> _save() async {
    if (_saving || !_key.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(printerPrintProfileStoreProvider)
          .save(
            widget.printer,
            PrinterPrintProfile(
              chunkBytes: int.parse(_chunk.text),
              pauseMs: int.parse(_pause.text),
              rasterBandRows: int.parse(_band.text),
              feedLines: int.parse(_feed.text),
              cutPaper: _cut,
            ),
          );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget field(
    TextEditingController controller,
    String label,
    int min,
    int max,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label, helperText: '$min – $max'),
      validator: (value) {
        final number = int.tryParse(value ?? '');
        return number == null || number < min || number > max
            ? t(
                'Nombre attendu : $min à $max',
                'عدد بين $min و$max',
                'Enter $min to $max',
              )
            : null;
      },
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        t('Transmission Bluetooth', 'إرسال بلوتوث', 'Bluetooth transmission'),
      ),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _loadFailed
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t(
                    'Impossible de lire les réglages locaux.',
                    'تعذّر قراءة الإعدادات المحلية.',
                    'Could not read local settings.',
                  ),
                ),
                FilledButton(
                  onPressed: _load,
                  child: Text(t('Réessayer', 'إعادة المحاولة', 'Retry')),
                ),
              ],
            ),
          )
        : Form(
            key: _key,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  widget.printer.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  t(
                    'Réglages enregistrés uniquement sur ce téléphone pour cette imprimante. Les valeurs initiales conservent le profil existant. Adaptez-les après un essai papier ; la capacité du tampon n’est pas connue.',
                    'تُحفظ الإعدادات لهذا الهاتف وهذه الطابعة فقط. القيم الأولية تحافظ على الإعداد السابق. عدّلها بعد تجربة ورقية؛ سعة ذاكرة الطابعة غير معروفة.',
                    'Saved only on this phone for this printer. Initial values preserve the existing profile. Tune after a paper test; the receive-buffer capacity is unknown.',
                  ),
                ),
                const SizedBox(height: 16),
                field(
                  _chunk,
                  t(
                    'Octets maximum par bloc',
                    'أقصى بايت لكل كتلة',
                    'Maximum bytes per chunk',
                  ),
                  64,
                  4096,
                ),
                field(
                  _pause,
                  t(
                    'Pause entre blocs (ms)',
                    'فاصل بين الكتل (مللي ثانية)',
                    'Inter-chunk pause (ms)',
                  ),
                  0,
                  1000,
                ),
                field(
                  _band,
                  t(
                    'Hauteur des bandes image (points)',
                    'ارتفاع شرائح الصورة (نقاط)',
                    'Raster band height (dots)',
                  ),
                  1,
                  256,
                ),
                field(
                  _feed,
                  t(
                    'Avance papier finale (lignes)',
                    'تغذية الورق النهائية (أسطر)',
                    'Final paper feed (lines)',
                  ),
                  1,
                  10,
                ),
                SwitchListTile(
                  value: _cut,
                  onChanged: (value) => setState(() => _cut = value),
                  title: Text(
                    t(
                      'Commande de coupe',
                      'أمر قطع الورق',
                      'Paper cut command',
                    ),
                  ),
                  subtitle: Text(
                    t(
                      'Désactiver si l’imprimante n’a pas de coupe automatique.',
                      'عطّلها إن لم تدعم الطابعة القطع التلقائي.',
                      'Disable if the printer has no automatic cutter.',
                    ),
                  ),
                ),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(
                    t(
                      'Enregistrer sur ce téléphone',
                      'حفظ على هذا الهاتف',
                      'Save on this phone',
                    ),
                  ),
                ),
              ],
            ),
          ),
  );

  @override
  void dispose() {
    for (final controller in [_chunk, _pause, _band, _feed]) {
      controller.dispose();
    }
    super.dispose();
  }
}
