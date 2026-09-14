import 'package:app_alim_gen_mobile/core/navigation/module_scaffold.dart';
import 'package:app_alim_gen_mobile/features/dashboard/domain/dashboard_filter.dart';
import 'package:app_alim_gen_mobile/features/dashboard/domain/dashboard_summary.dart';
import 'package:app_alim_gen_mobile/features/dashboard/presentation/dashboard_controller.dart';
import 'package:app_alim_gen_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final dashboard = ref.watch(dashboardProvider);
    final filter = ref.watch(dashboardFilterProvider);
    return ModuleScaffold(
      title: strings.dashboard,
      path: '/dashboard',
      actions: [
        IconButton(
          tooltip: strings.profile,
          onPressed: () => context.go('/profile'),
          icon: const Icon(Icons.account_circle_outlined),
        ),
      ],
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(dashboardProvider.future),
        child: dashboard.when(
          loading: () => ListView(
            key: const Key('dashboard-loading'),
            children: [
              _PeriodFilter(filter: filter),
              const SizedBox(height: 180),
              const Center(child: CircularProgressIndicator()),
            ],
          ),
          error: (error, _) => ListView(
            key: const Key('dashboard-error'),
            children: [
              _PeriodFilter(filter: filter),
              const SizedBox(height: 120),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        strings.text('dashboardLoadError'),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => ref.invalidate(dashboardProvider),
                        child: Text(strings.retry),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          data: (data) => _DashboardContent(data: data, filter: filter),
        ),
      ),
    );
  }
}

class _PeriodFilter extends ConsumerWidget {
  const _PeriodFilter({required this.filter});
  final DashboardFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: DropdownButtonFormField<String>(
        key: const Key('dashboard-period'),
        initialValue: filter.period,
        decoration: InputDecoration(
          labelText: strings.text('period'),
          prefixIcon: const Icon(Icons.date_range_outlined),
        ),
        items: const ['today', 'yesterday', 'week', 'month', 'year', 'custom']
            .map(
              (period) => DropdownMenuItem(
                value: period,
                child: Text(strings.text('period_$period')),
              ),
            )
            .toList(growable: false),
        onChanged: (period) async {
          if (period == null || period == filter.period) return;
          if (period != 'custom') {
            ref.read(dashboardFilterProvider.notifier).selectPeriod(period);
            return;
          }
          final now = DateTime.now();
          final range = await showDateRangePicker(
            context: context,
            firstDate: DateTime(now.year - 5),
            lastDate: now,
            initialDateRange: DateTimeRange(
              start: filter.startDate ?? now,
              end: filter.endDate ?? now,
            ),
          );
          if (range != null) {
            ref
                .read(dashboardFilterProvider.notifier)
                .selectCustom(range.start, range.end);
          }
        },
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.data, required this.filter});
  final DashboardSummary data;
  final DashboardFilter filter;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final items = <_Kpi>[
      _Kpi(strings.text('salesToday'), '${data.salesToday} DZD', Icons.today),
      _Kpi(
        strings.text('periodRevenue'),
        '${data.revenue} DZD',
        Icons.payments_outlined,
        data.comparisons['revenue'],
      ),
      _Kpi(
        strings.text('salesCount'),
        '${data.salesCount}',
        Icons.receipt_long,
      ),
      _Kpi(strings.basket, '${data.averageBasket} DZD', Icons.shopping_basket),
      _Kpi(
        strings.text('grossProfit'),
        '${data.grossProfit} DZD',
        Icons.trending_up,
        data.comparisons['gross_profit'],
      ),
      _Kpi(
        strings.text('expensesTotal'),
        '${data.expensesTotal} DZD',
        Icons.account_balance_wallet_outlined,
        data.comparisons['expenses'],
      ),
      _Kpi(
        strings.text('netProfit'),
        '${data.netProfit} DZD',
        Icons.insights_outlined,
        data.comparisons['net_profit'],
      ),
      _Kpi(
        strings.text('stockValue'),
        '${data.stockValue} DZD',
        Icons.warehouse,
      ),
      _Kpi(
        strings.products,
        '${data.totalProducts}',
        Icons.inventory_2_outlined,
      ),
      _Kpi(strings.clients, '${data.totalClients}', Icons.groups_outlined),
      _Kpi(strings.suppliers, '${data.totalSuppliers}', Icons.local_shipping),
      _Kpi(
        strings.text('purchasesTotal'),
        '${data.purchasesTotal} DZD',
        Icons.shopping_cart_checkout,
      ),
    ];

    return ListView(
      key: const Key('dashboard-success'),
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _PeriodFilter(filter: filter),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${data.startDate} — ${data.endDate}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              if (data.notificationCount > 0)
                Chip(
                  avatar: const Icon(Icons.notifications_outlined, size: 18),
                  label: Text('${data.notificationCount}'),
                ),
            ],
          ),
        ),
        GridView.builder(
          padding: const EdgeInsets.all(12),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 240,
            mainAxisExtent: 158,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: items.length,
          itemBuilder: (_, index) => _KpiCard(item: items[index]),
        ),
        _OperationalSummary(data: data),
        if (data.topProducts.isNotEmpty)
          _RankingSection(
            title: strings.text('topProducts'),
            items: data.topProducts,
          ),
        if (data.topClients.isNotEmpty)
          _RankingSection(
            title: strings.text('topClients'),
            items: data.topClients,
          ),
      ],
    );
  }
}

class _Kpi {
  const _Kpi(this.label, this.value, this.icon, [this.comparison]);
  final String label;
  final String value;
  final IconData icon;
  final DashboardComparison? comparison;
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.item});
  final _Kpi item;

  @override
  Widget build(BuildContext context) {
    final comparison = item.comparison;
    final comparisonColor = switch (comparison?.direction) {
      'up' => Colors.green,
      'down' => Colors.red,
      _ => Theme.of(context).colorScheme.onSurfaceVariant,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(item.icon, size: 22),
            const Spacer(),
            Text(item.label, maxLines: 2, overflow: TextOverflow.ellipsis),
            Text(
              item.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (comparison != null)
              Text(
                '${AppLocalizations.of(context).text('previousPeriod')}: '
                '${comparison.previous} • ${comparison.percent}%',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: comparisonColor),
              ),
          ],
        ),
      ),
    );
  }
}

class _OperationalSummary extends StatelessWidget {
  const _OperationalSummary({required this.data});
  final DashboardSummary data;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final rows = [
      (strings.text('productsSold'), data.productsSold),
      (strings.text('productsPurchased'), data.productsPurchased),
      (strings.text('outOfStock'), data.outOfStock),
      (strings.text('lowStock'), data.lowStock),
      (strings.text('nearStockout'), data.nearStockout),
      (strings.text('unpaidInvoices'), data.unpaidInvoices),
      (strings.text('pendingSupplierPayments'), data.pendingSupplierPayments),
    ];
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 24,
          runSpacing: 14,
          children: rows
              .map(
                (row) => SizedBox(
                  width: 135,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.$1,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      Text(
                        '${row.$2}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}

class _RankingSection extends StatelessWidget {
  const _RankingSection({required this.title, required this.items});
  final String title;
  final List<DashboardRanking> items;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const Divider(),
          ...items
              .take(5)
              .map(
                (item) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.name),
                  trailing: Text(
                    item.quantity > 0
                        ? '${item.quantity}'
                        : '${item.total} DZD',
                  ),
                ),
              ),
        ],
      ),
    ),
  );
}
