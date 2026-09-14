import 'package:app_alim_gen_mobile/app/providers.dart';
import 'package:app_alim_gen_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LanguageMenu extends ConsumerWidget {
  const LanguageMenu({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => PopupMenuButton<String>(
    tooltip: AppLocalizations.of(context).language,
    icon: const Icon(Icons.language),
    onSelected: ref.read(localeProvider.notifier).select,
    itemBuilder: (_) => const [
      PopupMenuItem(value: 'fr', child: Text('Français')),
      PopupMenuItem(value: 'ar', child: Text('العربية')),
      PopupMenuItem(value: 'en', child: Text('English')),
    ],
  );
}
