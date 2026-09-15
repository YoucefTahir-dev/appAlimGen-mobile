class AppPermissions {
  AppPermissions._();
  static const dashboard = 'accounts.view_dashboard';
  static const products = 'inventory.view_product';
  static const addProduct = 'inventory.add_product';
  static const changeProduct = 'inventory.change_product';
  static const deleteProduct = 'inventory.delete_product';
  static const productPricing = 'inventory.view_product_pricing';
  static const clients = 'inventory.view_client';
  static const addClient = 'inventory.add_client';
  static const changeClient = 'inventory.change_client';
  static const deleteClient = 'inventory.delete_client';
  static const suppliers = 'inventory.view_supplier';
  static const addSupplier = 'inventory.add_supplier';
  static const changeSupplier = 'inventory.change_supplier';
  static const deleteSupplier = 'inventory.delete_supplier';
  static const sales = 'commerce.view_sale';
  static const purchases = 'commerce.view_purchase';
  static const invoices = 'accounts.view_invoices';
  static const stock = 'accounts.view_stock';
  static const ownLoadingOrders = 'inventory.view_loadingorder';
  static const allLoadingOrders = 'inventory.view_all_loadingorders';
  static const expenses = 'expenses.view_expense';
  static const addExpense = 'expenses.add_expense';
  static const changeExpense = 'expenses.change_expense';
  static const deleteExpense = 'expenses.delete_expense';
  static const printers = 'printing.view_printerprofile';
  static const addPrinter = 'printing.add_printerprofile';
  static const changePrinter = 'printing.change_printerprofile';
  static const deletePrinter = 'printing.delete_printerprofile';
  static const testPrinter = 'printing.test_printerprofile';
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
