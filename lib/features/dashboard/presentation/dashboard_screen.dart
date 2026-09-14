import 'package:app_alim_gen_mobile/core/widgets/language_menu.dart';
import 'package:app_alim_gen_mobile/features/auth/presentation/auth_controller.dart';
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
    final user = ref.watch(authControllerProvider).user;
    final dashboard = ref.watch(dashboardProvider);
    final menu = <(String, NavigationDrawerDestination)>[
      if (user?.can('accounts.view_dashboard') ?? false)
        (
          '/dashboard',
          NavigationDrawerDestination(
            icon: const Icon(Icons.dashboard_outlined),
            label: Text(strings.dashboard),
          ),
        ),
      (
        '/profile',
        NavigationDrawerDestination(
          icon: const Icon(Icons.person_outline),
          label: Text(strings.profile),
        ),
      ),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.dashboard),
        actions: [
          const LanguageMenu(),
          IconButton(
            tooltip: strings.profile,
            onPressed: () => context.go('/profile'),
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      drawer: NavigationDrawer(
        onDestinationSelected: (index) {
          Navigator.pop(context);
          context.go(menu[index].$1);
        },
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              '${strings.welcome} ${user?.displayName ?? ''}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ...menu.map((item) => item.$2),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(dashboardProvider.future),
        child: dashboard.when(
          loading: () => ListView(
            key: const Key('dashboard-loading'),
            children: const [
              SizedBox(height: 240),
              Center(child: CircularProgressIndicator()),
            ],
          ),
          error: (error, _) => ListView(
            children: [
              const SizedBox(height: 180),
              Center(
                child: Column(
                  children: [
                    Text('Impossible de charger le tableau de bord.'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => ref.invalidate(dashboardProvider),
                      child: Text(strings.retry),
                    ),
                  ],
                ),
              ),
            ],
          ),
          data: (data) => data.isEmpty
              ? ListView(
                  key: const Key('dashboard-empty'),
                  children: [
                    const SizedBox(height: 220),
                    Center(child: Text(strings.empty)),
                  ],
                )
              : _DashboardGrid(data: data),
        ),
      ),
    );
  }
}

class _DashboardGrid extends StatelessWidget {
  const _DashboardGrid({required this.data});
  final DashboardSummary data;
  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final items = [
      (strings.revenue, '${data.revenue} DZD', Icons.payments_outlined),
      (strings.sales, '${data.salesCount}', Icons.receipt_long_outlined),
      (
        strings.basket,
        '${data.averageBasket} DZD',
        Icons.shopping_basket_outlined,
      ),
      (strings.netProfit, '${data.netProfit} DZD', Icons.trending_up),
      (strings.products, '${data.totalProducts}', Icons.inventory_2_outlined),
      (strings.clients, '${data.totalClients}', Icons.groups_outlined),
      (
        strings.suppliers,
        '${data.totalSuppliers}',
        Icons.local_shipping_outlined,
      ),
    ];
    return GridView.builder(
      key: const Key('dashboard-success'),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 280,
        mainAxisExtent: 180,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (_, index) {
        final item = items[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(item.$3),
                const Spacer(),
                Text(item.$1),
                Text(item.$2, style: Theme.of(context).textTheme.headlineSmall),
              ],
            ),
          ),
        );
      },
    );
  }
}
