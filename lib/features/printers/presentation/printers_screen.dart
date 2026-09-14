import 'package:app_alim_gen_mobile/app/providers.dart';
import 'package:app_alim_gen_mobile/core/navigation/module_scaffold.dart';
import 'package:app_alim_gen_mobile/features/printers/domain/printer_summary.dart';
import 'package:app_alim_gen_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final defaultPrinterProvider = FutureProvider<PrinterSummary?>(
  (ref) => ref.watch(printersRepositoryProvider).getDefault(),
);

class PrintersScreen extends ConsumerWidget {
  const PrintersScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context);
    final printer = ref.watch(defaultPrinterProvider);
    return ModuleScaffold(
      title: s.text('printers'),
      path: '/printers',
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(defaultPrinterProvider.future),
        child: printer.when(
          loading: () => ListView(
            children: const [
              SizedBox(height: 220),
              Center(child: CircularProgressIndicator()),
            ],
          ),
          error: (error, _) => ListView(
            children: [
              const SizedBox(height: 180),
              Center(
                child: Column(
                  children: [
                    Text(s.text('apiError')),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => ref.invalidate(defaultPrinterProvider),
                      child: Text(s.retry),
                    ),
                  ],
                ),
              ),
            ],
          ),
          data: (item) => item == null
              ? ListView(
                  children: [
                    const SizedBox(height: 200),
                    Center(child: Text(s.text('noDefaultPrinter'))),
                  ],
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.print_outlined, size: 36),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    item.name,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 32),
                            _Row(s.text('model'), item.model),
                            _Row(s.text('connection'), item.connection),
                            _Row(s.text('paperWidth'), '${item.paperWidth} mm'),
                            _Row(
                              s.text('status'),
                              item.isActive
                                  ? s.text('configured')
                                  : s.text('notConfigured'),
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
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}
