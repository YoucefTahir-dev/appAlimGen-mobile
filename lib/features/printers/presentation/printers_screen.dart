import 'package:app_alim_gen_mobile/app/providers.dart';
import 'package:app_alim_gen_mobile/core/errors/app_failure.dart';
import 'package:app_alim_gen_mobile/core/navigation/module_scaffold.dart';
import 'package:app_alim_gen_mobile/core/pagination/page_data.dart';
import 'package:app_alim_gen_mobile/core/pagination/paged_list_body.dart';
import 'package:app_alim_gen_mobile/core/pagination/paged_list_controller.dart';
import 'package:app_alim_gen_mobile/core/permissions/permission_service.dart';
import 'package:app_alim_gen_mobile/features/auth/presentation/auth_controller.dart';
import 'package:app_alim_gen_mobile/features/printers/domain/printer_summary.dart';
import 'package:app_alim_gen_mobile/features/printers/presentation/printer_form_screen.dart';
import 'package:app_alim_gen_mobile/l10n/app_localizations.dart';
import 'package:app_alim_gen_mobile/l10n/crud_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PrintersController extends PagedListController<PrinterSummary> {
  @override
  Future<PageData<PrinterSummary>> fetchPage({
    required int page,
    required String query,
  }) => ref.read(printersRepositoryProvider).fetch(page: page, query: query);
}

final printersProvider =
    NotifierProvider<PrintersController, PagedListState<PrinterSummary>>(
      PrintersController.new,
    );
final defaultPrinterProvider = FutureProvider<PrinterSummary?>(
  (ref) => ref.watch(printersRepositoryProvider).getDefault(),
);

class PrintersScreen extends ConsumerWidget {
  const PrintersScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context);
    final crud = CrudStrings.of(context);
    final user = ref.watch(authControllerProvider).user;
    final add = user?.can(AppPermissions.addPrinter) ?? false,
        change = user?.can(AppPermissions.changePrinter) ?? false,
        remove = user?.can(AppPermissions.deletePrinter) ?? false,
        test = user?.can(AppPermissions.testPrinter) ?? false;
    return ModuleScaffold(
      title: s.text('printers'),
      path: '/printers',
      body: PagedListBody<PrinterSummary, PrintersController>(
        provider: printersProvider,
        searchable: true,
        itemBuilder: (context, item) => Card(
          child: ListTile(
            leading: Icon(
              Icons.print_outlined,
              color: item.isActive ? Colors.green : Colors.grey,
            ),
            title: Text(item.name),
            subtitle: Text(
              '${item.model}\n${item.connection} • ${item.paperWidth} mm${item.isDefault ? ' • Par défaut' : ''}',
            ),
            isThreeLine: true,
            trailing: change || remove || test
                ? PopupMenuButton<String>(
                    onSelected: (action) => _action(context, ref, item, action),
                    itemBuilder: (_) => [
                      if (change)
                        PopupMenuItem(
                          value: 'edit',
                          child: Text(crud.text('edit')),
                        ),
                      if (change && !item.isDefault)
                        PopupMenuItem(
                          value: 'default',
                          child: Text(crud.text('setDefault')),
                        ),
                      if (test)
                        PopupMenuItem(
                          value: 'test',
                          child: Text(crud.text('testConfig')),
                        ),
                      if (remove)
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(crud.text('delete')),
                        ),
                    ],
                  )
                : null,
          ),
        ),
      ),
      floatingActionButton: add
          ? FloatingActionButton.extended(
              onPressed: () async {
                final changed = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const PrinterFormScreen()),
                );
                if (changed == true) {
                  ref.read(printersProvider.notifier).refresh();
                }
              },
              icon: const Icon(Icons.add),
              label: Text(crud.text('newPrinter')),
            )
          : null,
    );
  }

  Future<void> _action(
    BuildContext context,
    WidgetRef ref,
    PrinterSummary item,
    String action,
  ) async {
    try {
      if (action == 'edit') {
        final changed = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => PrinterFormScreen(printerId: item.id),
          ),
        );
        if (changed == true) {
          await ref.read(printersProvider.notifier).refresh();
        }
        return;
      }
      if (action == 'default') {
        await ref.read(printersRepositoryProvider).setDefault(item.id);
        await ref.read(printersProvider.notifier).refresh();
      }
      if (action == 'test') {
        final data = await ref
            .read(printersRepositoryProvider)
            .testPayload(item.id);
        if (context.mounted) {
          showDialog<void>(
            context: context,
            builder: (c) => AlertDialog(
              title: Text(CrudStrings.of(context).text('configReady')),
              content: Text(
                'Transport : ${data['transport']}\nProtocole : ${data['protocol']}\nLe test physique doit être envoyé localement par Android.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(c),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
      if (action == 'delete') {
        if (!context.mounted) return;
        final ok = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: Text(CrudStrings.of(context).text('confirmDelete')),
            content: Text(item.name),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: Text(CrudStrings.of(context).text('cancel')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(c, true),
                child: Text(CrudStrings.of(context).text('delete')),
              ),
            ],
          ),
        );
        if (ok == true) {
          await ref.read(printersRepositoryProvider).delete(item.id);
          await ref.read(printersProvider.notifier).refresh();
        }
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is AppFailure ? error.message : 'Opération impossible.',
            ),
          ),
        );
      }
    }
  }
}
