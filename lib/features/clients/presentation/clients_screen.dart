import 'package:app_alim_gen_mobile/app/providers.dart';
import 'package:app_alim_gen_mobile/core/errors/app_failure.dart';
import 'package:app_alim_gen_mobile/core/navigation/module_scaffold.dart';
import 'package:app_alim_gen_mobile/core/permissions/permission_service.dart';
import 'package:app_alim_gen_mobile/core/pagination/page_data.dart';
import 'package:app_alim_gen_mobile/core/pagination/paged_list_body.dart';
import 'package:app_alim_gen_mobile/core/pagination/paged_list_controller.dart';
import 'package:app_alim_gen_mobile/features/clients/domain/client_summary.dart';
import 'package:app_alim_gen_mobile/features/clients/presentation/client_form_screen.dart';
import 'package:app_alim_gen_mobile/features/auth/presentation/auth_controller.dart';
import 'package:app_alim_gen_mobile/l10n/app_localizations.dart';
import 'package:app_alim_gen_mobile/l10n/crud_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ClientsController extends PagedListController<ClientSummary> {
  @override
  Future<PageData<ClientSummary>> fetchPage({
    required int page,
    required String query,
  }) => ref.read(clientsRepositoryProvider).fetch(page: page, query: query);
}

final clientsProvider =
    NotifierProvider<ClientsController, PagedListState<ClientSummary>>(
      ClientsController.new,
    );

class ClientsScreen extends ConsumerWidget {
  const ClientsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final crud = CrudStrings.of(context);
    final user = ref.watch(authControllerProvider).user;
    final canAdd = user?.can(AppPermissions.addClient) ?? false;
    final canChange = user?.can(AppPermissions.changeClient) ?? false;
    final canDelete = user?.can(AppPermissions.deleteClient) ?? false;
    return ModuleScaffold(
      title: strings.clients,
      path: '/clients',
      body: PagedListBody<ClientSummary, ClientsController>(
        provider: clientsProvider,
        searchable: true,
        itemBuilder: (context, client) => Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person_outline)),
            title: Text(client.name),
            subtitle: Text(
              [
                if (client.phone.isNotEmpty)
                  '${strings.text('phone')}: ${client.phone}',
                if (client.address.isNotEmpty)
                  '${strings.text('address')}: ${client.address}',
                '${strings.text('customerType')}: ${client.customerType}',
              ].join('\n'),
            ),
            isThreeLine: true,
            trailing: canChange || canDelete
                ? PopupMenuButton<String>(
                    onSelected: (action) async {
                      if (action == 'edit') {
                        final changed = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) =>
                                ClientFormScreen(clientId: client.id),
                          ),
                        );
                        if (changed == true) {
                          ref.read(clientsProvider.notifier).refresh();
                        }
                      } else {
                        await _delete(context, ref, client);
                      }
                    },
                    itemBuilder: (_) => [
                      if (canChange)
                        PopupMenuItem(
                          value: 'edit',
                          child: Text(crud.text('edit')),
                        ),
                      if (canDelete)
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
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
              onPressed: () async {
                final changed = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const ClientFormScreen()),
                );
                if (changed == true) {
                  ref.read(clientsProvider.notifier).refresh();
                }
              },
              icon: const Icon(Icons.person_add_alt_1),
              label: Text(crud.text('newClient')),
            )
          : null,
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    ClientSummary client,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(CrudStrings.of(context).text('confirmDelete')),
        content: Text(client.name),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(CrudStrings.of(context).text('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(CrudStrings.of(context).text('delete')),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(clientsRepositoryProvider).delete(client.id);
      await ref.read(clientsProvider.notifier).refresh();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Suppression réussie.')));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is AppFailure ? error.message : 'Suppression impossible.',
            ),
          ),
        );
      }
    }
  }
}
