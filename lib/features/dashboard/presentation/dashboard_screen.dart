import 'package:app_alim_gen_mobile/app/theme/app_colors.dart';
import 'package:app_alim_gen_mobile/app/theme/app_tokens.dart';
import 'package:app_alim_gen_mobile/core/navigation/module_scaffold.dart';
import 'package:app_alim_gen_mobile/core/permissions/permission_service.dart';
import 'package:app_alim_gen_mobile/core/utils/app_formats.dart';
import 'package:app_alim_gen_mobile/core/widgets/app_ui.dart';
import 'package:app_alim_gen_mobile/features/auth/presentation/auth_controller.dart';
import 'package:app_alim_gen_mobile/features/business_lists/presentation/business_list_screens.dart';
import 'package:app_alim_gen_mobile/features/business_lists/presentation/transaction_form_screens.dart';
import 'package:app_alim_gen_mobile/features/clients/presentation/client_form_screen.dart';
import 'package:app_alim_gen_mobile/features/clients/presentation/clients_screen.dart';
import 'package:app_alim_gen_mobile/features/dashboard/domain/dashboard_filter.dart';
import 'package:app_alim_gen_mobile/features/dashboard/domain/dashboard_summary.dart';
import 'package:app_alim_gen_mobile/features/dashboard/presentation/dashboard_controller.dart';
import 'package:app_alim_gen_mobile/features/loading_orders/presentation/loading_order_form_screen.dart';
import 'package:app_alim_gen_mobile/features/loading_orders/presentation/loading_orders_screen.dart';
import 'package:app_alim_gen_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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
              _WelcomeHeader(filter: filter),
              const SizedBox(height: 8),
              const SizedBox(height: 520, child: LoadingSkeleton(rows: 4)),
            ],
          ),
          error: (error, _) => ListView(
            key: const Key('dashboard-error'),
            children: [
              _WelcomeHeader(filter: filter),
              const SizedBox(height: 80),
              AppErrorState(
                title: strings.text('loadErrorTitle'),
                message: strings.text('dashboardLoadError'),
                retryLabel: strings.retry,
                onRetry: () => ref.invalidate(dashboardProvider),
              ),
            ],
          ),
          data: (data) => _DashboardContent(data: data, filter: filter),
        ),
      ),
    );
  }
}

class _WelcomeHeader extends ConsumerWidget {
  const _WelcomeHeader({required this.filter});
  final DashboardFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final user = ref.watch(authControllerProvider).user;
    final language = Localizations.localeOf(context).languageCode;
    final name = user?.firstName.trim().isNotEmpty == true
        ? user!.firstName
        : user?.displayName ?? '';
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${strings.text('goodMorning')} $name 👋',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            DateFormat('EEEE d MMMM', language).format(DateTime.now()),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.md),
          _PeriodFilter(filter: filter),
        ],
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
    return DropdownButtonFormField<String>(
      key: const Key('dashboard-period'),
      initialValue: filter.period,
      decoration: InputDecoration(
        labelText: strings.text('period'),
        prefixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
        constraints: const BoxConstraints(maxWidth: 300),
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
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  const _DashboardContent({required this.data, required this.filter});
  final DashboardSummary data;
  final DashboardFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final items = <_Kpi>[
      _Kpi(
        strings.text('salesCount'),
        '${data.salesCount}',
        Icons.receipt_long,
      ),
      _Kpi(
        strings.basket,
        AppFormats.money(data.averageBasket),
        Icons.shopping_basket_outlined,
      ),
      _Kpi(
        strings.text('grossProfit'),
        AppFormats.money(data.grossProfit),
        Icons.trending_up,
      ),
      _Kpi(
        strings.text('expensesTotal'),
        AppFormats.money(data.expensesTotal),
        Icons.account_balance_wallet_outlined,
      ),
      _Kpi(
        strings.text('netProfit'),
        AppFormats.money(data.netProfit),
        Icons.insights_outlined,
      ),
      _Kpi(
        strings.text('stockValue'),
        AppFormats.money(data.stockValue),
        Icons.warehouse_outlined,
      ),
    ];

    return ListView(
      key: const Key('dashboard-success'),
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      children: [
        _WelcomeHeader(filter: filter),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: _RevenueHero(data: data),
        ),
        const SizedBox(height: AppSpacing.lg),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: SectionHeader(title: strings.text('overview')),
        ),
        GridView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 230,
            mainAxisExtent: 132,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
          ),
          itemCount: items.length,
          itemBuilder: (_, index) => _KpiCard(item: items[index]),
        ),
        _QuickActions(ref: ref),
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

class _RevenueHero extends StatelessWidget {
  const _RevenueHero({required this.data});
  final DashboardSummary data;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final comparison = data.comparisons['revenue'];
    final down = comparison?.direction == 'down';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  strings.text('periodRevenue'),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (data.notificationCount > 0)
                Badge(
                  label: Text('${data.notificationCount}'),
                  child: const Icon(
                    Icons.notifications_none,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppFormats.money(data.revenue),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontSize: 32,
            ),
          ),
          if (comparison != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(
                  down ? Icons.trending_down : Icons.trending_up,
                  size: 18,
                  color: Colors.white,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    '${comparison.percent}% • ${strings.text('previousPeriod')}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Kpi {
  const _Kpi(this.label, this.value, this.icon);
  final String label;
  final String value;
  final IconData icon;
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.item});
  final _Kpi item;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(item.icon, size: 20, color: AppColors.primary),
        ),
        const Spacer(),
        Text(
          item.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
        ),
        const SizedBox(height: 2),
        Text(
          item.value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ],
    ),
  );
}

class _QuickActions extends ConsumerWidget {
  const _QuickActions({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef _) {
    final strings = AppLocalizations.of(context);
    final user = ref.watch(authControllerProvider).user;
    final actions = <Widget>[];

    void add(
      bool allowed,
      String label,
      IconData icon,
      Widget page,
      VoidCallback refresh,
    ) {
      if (!allowed) return;
      actions.add(
        FilledButton.tonalIcon(
          onPressed: () async {
            final changed = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => page),
            );
            if (changed == true) refresh();
          },
          icon: Icon(icon),
          label: Text(label),
        ),
      );
    }

    add(
      user?.can(AppPermissions.addSale) ?? false,
      strings.text('newSale'),
      Icons.add_shopping_cart,
      const SaleFormScreen(),
      () => ref.invalidate(salesProvider),
    );
    add(
      user?.can(AppPermissions.addClient) ?? false,
      strings.text('newClient'),
      Icons.person_add_alt_1,
      const ClientFormScreen(),
      () => ref.invalidate(clientsProvider),
    );
    add(
      user?.can(AppPermissions.addPurchase) ?? false,
      strings.text('newPurchase'),
      Icons.shopping_cart_checkout,
      const PurchaseFormScreen(),
      () => ref.invalidate(purchasesProvider),
    );
    add(
      user?.can(AppPermissions.addLoadingOrder) ?? false,
      strings.text('newLoadingOrder'),
      Icons.local_shipping_outlined,
      const LoadingOrderFormScreen(),
      () => ref.invalidate(loadingOrdersProvider),
    );
    if (actions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: strings.text('quickActions')),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: actions,
          ),
        ],
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
      (strings.products, data.totalProducts, Icons.inventory_2_outlined),
      (strings.clients, data.totalClients, Icons.groups_outlined),
      (strings.suppliers, data.totalSuppliers, Icons.local_shipping_outlined),
      (
        strings.text('outOfStock'),
        data.outOfStock,
        Icons.warning_amber_rounded,
      ),
      (strings.text('lowStock'), data.lowStock, Icons.inventory_outlined),
      (
        strings.text('unpaidInvoices'),
        data.unpaidInvoices,
        Icons.receipt_long_outlined,
      ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      child: AppCard(
        child: Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.md,
          children: rows
              .map(
                (row) => SizedBox(
                  width: 135,
                  child: Row(
                    children: [
                      Icon(row.$3, size: 20, color: AppColors.primary),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${row.$2}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              row.$1,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.muted),
                            ),
                          ],
                        ),
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
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.md,
      0,
      AppSpacing.md,
      AppSpacing.md,
    ),
    child: AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: title),
          const SizedBox(height: AppSpacing.sm),
          ...items
              .take(5)
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        item.quantity > 0
                            ? '${item.quantity}'
                            : AppFormats.money(item.total),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    ),
  );
}
