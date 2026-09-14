class AppPermissions {
  AppPermissions._();
  static const dashboard = 'accounts.view_dashboard';
  static const products = 'inventory.view_product';
  static const productPricing = 'inventory.view_product_pricing';
  static const clients = 'inventory.view_client';
  static const suppliers = 'inventory.view_supplier';
  static const sales = 'commerce.view_sale';
  static const purchases = 'commerce.view_purchase';
  static const invoices = 'accounts.view_invoices';
  static const stock = 'accounts.view_stock';
  static const ownLoadingOrders = 'inventory.view_loadingorder';
  static const allLoadingOrders = 'inventory.view_all_loadingorders';
  static const expenses = 'expenses.view_expense';
  static const printers = 'printing.view_printerprofile';
  static const settings = 'core.view_companysettings';
}

class PermissionService {
  const PermissionService(this.permissions);
  final Set<String> permissions;
  bool has(String permission) => permissions.contains(permission);
  bool any(Iterable<String> values) => values.any(has);

  bool get canViewOperatorStock => canViewLoadingOrders;
  bool get canViewLoadingOrders => any(const [
    AppPermissions.ownLoadingOrders,
    AppPermissions.allLoadingOrders,
  ]);
  bool get canViewPayments =>
      any(const [AppPermissions.sales, AppPermissions.purchases]);

  bool allowsPath(String path) => switch (path) {
    '/dashboard' => has(AppPermissions.dashboard),
    '/products' => has(AppPermissions.products),
    '/clients' => has(AppPermissions.clients),
    '/suppliers' => has(AppPermissions.suppliers),
    '/sales' => has(AppPermissions.sales),
    '/purchases' => has(AppPermissions.purchases),
    '/invoices' => has(AppPermissions.invoices),
    '/stock' => has(AppPermissions.stock),
    '/operator-stock' => canViewOperatorStock,
    '/loading-orders' => canViewLoadingOrders,
    '/payments' => canViewPayments,
    '/expenses' => has(AppPermissions.expenses),
    '/printers' => has(AppPermissions.printers),
    '/profile' || '/forbidden' => true,
    _ => false,
  };

  String landingPath() {
    for (final path in const [
      '/dashboard',
      '/products',
      '/clients',
      '/sales',
      '/operator-stock',
      '/profile',
    ]) {
      if (allowsPath(path)) return path;
    }
    return '/profile';
  }
}
