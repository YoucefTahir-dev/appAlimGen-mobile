import 'package:app_alim_gen_mobile/app/providers.dart';
import 'package:app_alim_gen_mobile/core/navigation/module_scaffold.dart';
import 'package:app_alim_gen_mobile/core/pagination/page_data.dart';
import 'package:app_alim_gen_mobile/core/pagination/paged_list_body.dart';
import 'package:app_alim_gen_mobile/core/pagination/paged_list_controller.dart';
import 'package:app_alim_gen_mobile/features/business_lists/domain/business_entities.dart';
import 'package:app_alim_gen_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InvoicesController extends PagedListController<InvoiceSummary> {
  @override
  Future<PageData<InvoiceSummary>> fetchPage({
    required int page,
    required String query,
  }) => ref.read(invoicesRepositoryProvider).fetch(page: page, query: query);
}

class SuppliersController extends PagedListController<SupplierSummary> {
  @override
  Future<PageData<SupplierSummary>> fetchPage({
    required int page,
    required String query,
  }) => ref.read(suppliersRepositoryProvider).fetch(page: page, query: query);
}

class SalesController extends PagedListController<SaleSummary> {
  @override
  Future<PageData<SaleSummary>> fetchPage({
    required int page,
    required String query,
  }) => ref.read(salesRepositoryProvider).fetch(page: page, query: query);
}

class PurchasesController extends PagedListController<PurchaseSummary> {
  @override
  Future<PageData<PurchaseSummary>> fetchPage({
    required int page,
    required String query,
  }) => ref.read(purchasesRepositoryProvider).fetch(page: page, query: query);
}

class ExpensesController extends PagedListController<ExpenseSummary> {
  @override
  Future<PageData<ExpenseSummary>> fetchPage({
    required int page,
    required String query,
  }) => ref.read(expensesRepositoryProvider).fetch(page: page, query: query);
}

class PaymentsController extends PagedListController<PaymentSummary> {
  @override
  Future<PageData<PaymentSummary>> fetchPage({
    required int page,
    required String query,
  }) => ref.read(paymentsRepositoryProvider).fetch(page: page, query: query);
}

final invoicesProvider =
    NotifierProvider<InvoicesController, PagedListState<InvoiceSummary>>(
      InvoicesController.new,
    );
final suppliersProvider =
    NotifierProvider<SuppliersController, PagedListState<SupplierSummary>>(
      SuppliersController.new,
    );
final salesProvider =
    NotifierProvider<SalesController, PagedListState<SaleSummary>>(
      SalesController.new,
    );
final purchasesProvider =
    NotifierProvider<PurchasesController, PagedListState<PurchaseSummary>>(
      PurchasesController.new,
    );
final expensesProvider =
    NotifierProvider<ExpensesController, PagedListState<ExpenseSummary>>(
      ExpensesController.new,
    );
final paymentsProvider =
    NotifierProvider<PaymentsController, PagedListState<PaymentSummary>>(
      PaymentsController.new,
    );

String _date(String value) =>
    value.length >= 10 ? value.substring(0, 10) : value;
Widget _recordCard(
  BuildContext context, {
  required IconData icon,
  required String title,
  required List<String> details,
  required String amount,
}) => Card(
  child: ListTile(
    leading: Icon(icon),
    title: Text(title.isEmpty ? '—' : title),
    subtitle: Text(details.where((value) => value.isNotEmpty).join('\n')),
    trailing: Text(amount, style: Theme.of(context).textTheme.titleMedium),
    isThreeLine: details.length > 1,
  ),
);

class InvoicesScreen extends StatelessWidget {
  const InvoicesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return ModuleScaffold(
      title: s.text('invoices'),
      path: '/invoices',
      body: PagedListBody<InvoiceSummary, InvoicesController>(
        provider: invoicesProvider,
        searchable: true,
        itemBuilder: (context, item) => _recordCard(
          context,
          icon: Icons.receipt_long_outlined,
          title: item.number,
          details: [
            '${s.text('client')}: #${item.clientId ?? '—'}',
            '${s.text('date')}: ${_date(item.date)}',
            '${s.text('status')}: ${item.paymentStatus}',
          ],
          amount: '${item.total} DZD',
        ),
      ),
    );
  }
}

class SuppliersScreen extends StatelessWidget {
  const SuppliersScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return ModuleScaffold(
      title: s.suppliers,
      path: '/suppliers',
      body: PagedListBody<SupplierSummary, SuppliersController>(
        provider: suppliersProvider,
        searchable: true,
        itemBuilder: (context, item) => _recordCard(
          context,
          icon: Icons.local_shipping_outlined,
          title: item.name,
          details: [
            if (item.phone.isNotEmpty) '${s.text('phone')}: ${item.phone}',
            if (item.address.isNotEmpty)
              '${s.text('address')}: ${item.address}',
          ],
          amount: '',
        ),
      ),
    );
  }
}

class SalesScreen extends StatelessWidget {
  const SalesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return ModuleScaffold(
      title: s.sales,
      path: '/sales',
      body: PagedListBody<SaleSummary, SalesController>(
        provider: salesProvider,
        itemBuilder: (context, item) => _recordCard(
          context,
          icon: Icons.point_of_sale_outlined,
          title: item.number,
          details: [
            '${s.text('client')}: #${item.clientId ?? '—'}',
            '${s.text('date')}: ${_date(item.date)}',
            '${s.text('status')}: ${item.paymentStatus}',
          ],
          amount: '${item.total} DZD',
        ),
      ),
    );
  }
}

class PurchasesScreen extends StatelessWidget {
  const PurchasesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return ModuleScaffold(
      title: s.text('purchases'),
      path: '/purchases',
      body: PagedListBody<PurchaseSummary, PurchasesController>(
        provider: purchasesProvider,
        itemBuilder: (context, item) => _recordCard(
          context,
          icon: Icons.shopping_cart_checkout_outlined,
          title: item.reference,
          details: [
            '${s.text('supplier')}: #${item.supplierId ?? '—'}',
            '${s.text('date')}: ${_date(item.date)}',
            '${s.text('status')}: ${item.paymentStatus}',
          ],
          amount: '${item.total} DZD',
        ),
      ),
    );
  }
}

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return ModuleScaffold(
      title: s.text('expenses'),
      path: '/expenses',
      body: PagedListBody<ExpenseSummary, ExpensesController>(
        provider: expensesProvider,
        itemBuilder: (context, item) => _recordCard(
          context,
          icon: Icons.account_balance_wallet_outlined,
          title: item.number,
          details: [
            item.description,
            '${s.text('date')}: ${_date(item.date)}',
            item.paymentMethod,
          ],
          amount: '${item.amount} DZD',
        ),
      ),
    );
  }
}

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return ModuleScaffold(
      title: s.text('payments'),
      path: '/payments',
      body: PagedListBody<PaymentSummary, PaymentsController>(
        provider: paymentsProvider,
        itemBuilder: (context, item) => _recordCard(
          context,
          icon: Icons.payments_outlined,
          title: item.reference,
          details: ['${s.text('date')}: ${_date(item.date)}', item.paymentType],
          amount: '${item.amount} DZD',
        ),
      ),
    );
  }
}
