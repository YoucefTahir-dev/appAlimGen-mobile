import 'package:app_alim_gen_mobile/app/providers.dart';
import 'package:app_alim_gen_mobile/core/navigation/module_scaffold.dart';
import 'package:app_alim_gen_mobile/core/pagination/page_data.dart';
import 'package:app_alim_gen_mobile/core/pagination/paged_list_body.dart';
import 'package:app_alim_gen_mobile/core/pagination/paged_list_controller.dart';
import 'package:app_alim_gen_mobile/features/clients/domain/client_summary.dart';
import 'package:app_alim_gen_mobile/l10n/app_localizations.dart';
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

class ClientsScreen extends StatelessWidget {
  const ClientsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
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
          ),
        ),
      ),
    );
  }
}
