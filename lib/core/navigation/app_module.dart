import 'package:app_alim_gen_mobile/core/permissions/permission_service.dart';
import 'package:flutter/material.dart';

enum NavigationSection { home, commerce, operations, management, account }

class AppModule {
  const AppModule({
    required this.labelKey,
    required this.path,
    required this.icon,
    required this.section,
    required this.allowed,
  });
  final String labelKey;
  final String path;
  final IconData icon;
  final NavigationSection section;
  final bool Function(PermissionService) allowed;
}

final appModules = <AppModule>[
  AppModule(
    labelKey: 'dashboard',
    path: '/dashboard',
    icon: Icons.dashboard_outlined,
    section: NavigationSection.home,
    allowed: (p) => p.has(AppPermissions.dashboard),
  ),
  AppModule(
    labelKey: 'products',
    path: '/products',
    icon: Icons.inventory_2_outlined,
    section: NavigationSection.commerce,
    allowed: (p) => p.has(AppPermissions.products),
  ),
  AppModule(
    labelKey: 'clients',
    path: '/clients',
    icon: Icons.people_outline,
    section: NavigationSection.commerce,
    allowed: (p) => p.has(AppPermissions.clients),
  ),
  AppModule(
    labelKey: 'suppliers',
    path: '/suppliers',
    icon: Icons.local_shipping_outlined,
    section: NavigationSection.commerce,
    allowed: (p) => p.has(AppPermissions.suppliers),
  ),
  AppModule(
    labelKey: 'sales',
    path: '/sales',
    icon: Icons.point_of_sale_outlined,
    section: NavigationSection.operations,
    allowed: (p) => p.has(AppPermissions.sales),
  ),
  AppModule(
    labelKey: 'purchases',
    path: '/purchases',
    icon: Icons.shopping_cart_checkout_outlined,
    section: NavigationSection.operations,
    allowed: (p) => p.has(AppPermissions.purchases),
  ),
  AppModule(
    labelKey: 'invoices',
    path: '/invoices',
    icon: Icons.receipt_long_outlined,
    section: NavigationSection.operations,
    allowed: (p) => p.has(AppPermissions.invoices),
  ),
  AppModule(
    labelKey: 'payments',
    path: '/payments',
    icon: Icons.payments_outlined,
    section: NavigationSection.operations,
    allowed: (p) => p.canViewPayments,
  ),
  AppModule(
    labelKey: 'stock',
    path: '/stock',
    icon: Icons.warehouse_outlined,
    section: NavigationSection.operations,
    allowed: (p) => p.has(AppPermissions.stock),
  ),
  AppModule(
    labelKey: 'operatorStock',
    path: '/operator-stock',
    icon: Icons.inventory_outlined,
    section: NavigationSection.operations,
    allowed: (p) => p.canViewOperatorStock,
  ),
  AppModule(
    labelKey: 'loadingOrders',
    path: '/loading-orders',
    icon: Icons.local_shipping,
    section: NavigationSection.operations,
    allowed: (p) => p.canViewLoadingOrders,
  ),
  AppModule(
    labelKey: 'expenses',
    path: '/expenses',
    icon: Icons.account_balance_wallet_outlined,
    section: NavigationSection.management,
    allowed: (p) => p.has(AppPermissions.expenses),
  ),
  AppModule(
    labelKey: 'printers',
    path: '/printers',
    icon: Icons.print_outlined,
    section: NavigationSection.management,
    allowed: (p) => p.has(AppPermissions.printers),
  ),
  AppModule(
    labelKey: 'profile',
    path: '/profile',
    icon: Icons.person_outline,
    section: NavigationSection.account,
    allowed: (_) => true,
  ),
];
