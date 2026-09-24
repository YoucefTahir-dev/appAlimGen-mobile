import 'package:app_alim_gen_mobile/app/providers.dart';
import 'package:app_alim_gen_mobile/core/errors/app_failure.dart';
import 'package:app_alim_gen_mobile/core/navigation/module_scaffold.dart';
import 'package:app_alim_gen_mobile/core/permissions/permission_service.dart';
import 'package:app_alim_gen_mobile/core/pagination/page_data.dart';
import 'package:app_alim_gen_mobile/core/pagination/paged_list_body.dart';
import 'package:app_alim_gen_mobile/core/pagination/paged_list_controller.dart';
import 'package:app_alim_gen_mobile/core/widgets/app_ui.dart';
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
        emptyIcon: Icons.groups_outlined,
        itemBuilder: (context, client) => AppCard(
          onTap: canChange ? () => _editClient(context, ref, client.id) : null,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                child: Text(
                  client.name.trim().isEmpty
                      ? '?'
                      : client.name.trim().characters.first.toUpperCase(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    StatusBadge(
                      label: client.customerType,
                      tone: StatusTone.neutral,
                    ),
                    if (client.phone.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _ClientLine(
                        icon: Icons.phone_outlined,
                        value: client.phone,
                      ),
                    ],
                    if (client.address.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      _ClientLine(
                        icon: Icons.location_on_outlined,
                        value: client.address,
                      ),
                    ],
                  ],
                ),
              ),
              if (canChange || canDelete)
                IconButton(
                  tooltip: strings.text('more'),
                  onPressed: () => _showActions(
                    context,
                    ref,
                    client,
                    canChange: canChange,
                    canDelete: canDelete,
                  ),
                  icon: const Icon(Icons.more_vert),
                )
              else
                const Icon(Icons.chevron_right),
            ],
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

  Future<void> _editClient(BuildContext context, WidgetRef ref, int id) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ClientFormScreen(clientId: id)),
    );
    if (changed == true) ref.read(clientsProvider.notifier).refresh();
  }

  Future<void> _showActions(
    BuildContext context,
    WidgetRef ref,
    ClientSummary client, {
    required bool canChange,
    required bool canDelete,
  }) async {
    final crud = CrudStrings.of(context);
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  client.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (canChange)
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: Text(crud.text('edit')),
                  onTap: () => Navigator.pop(context, 'edit'),
                ),
              if (canDelete)
                ListTile(
                  leading: Icon(
                    Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(crud.text('delete')),
                  textColor: Theme.of(context).colorScheme.error,
                  onTap: () => Navigator.pop(context, 'delete'),
                ),
            ],
          ),
        ),
      ),
    );
    if (!context.mounted) return;
    if (action == 'edit') {
      await _editClient(context, ref, client.id);
    } else if (action == 'delete') {
      await _delete(context, ref, client);
    }
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(CrudStrings.of(context).text('deleteSuccess')),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is AppFailure
                  ? error.message
                  : AppLocalizations.of(context).text('apiError'),
            ),
          ),
        );
      }
    }
  }
}

class _ClientLine extends StatelessWidget {
  const _ClientLine({required this.icon, required this.value});
  final IconData icon;
  final String value;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(
        icon,
        size: 16,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      const SizedBox(width: 6),
      Expanded(
        child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    ],
  );
}
