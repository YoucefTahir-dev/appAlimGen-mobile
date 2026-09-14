class DashboardSummary {
  const DashboardSummary({
    required this.revenue,
    required this.salesCount,
    required this.averageBasket,
    required this.netProfit,
    required this.totalProducts,
    required this.totalClients,
    required this.totalSuppliers,
    this.period = 'today',
    this.startDate = '',
    this.endDate = '',
    this.salesToday = '0.00',
    this.grossProfit = '0.00',
    this.expensesTotal = '0.00',
    this.stockValue = '0.00',
    this.purchasesTotal = '0.00',
    this.productsSold = 0,
    this.productsPurchased = 0,
    this.outOfStock = 0,
    this.lowStock = 0,
    this.nearStockout = 0,
    this.unpaidInvoices = 0,
    this.pendingSupplierPayments = 0,
    this.importantExpenses = 0,
    this.notificationCount = 0,
    this.comparisons = const {},
    this.topProducts = const [],
    this.topClients = const [],
    this.canFilterUsers = false,
    this.selectedUserId,
    this.selectedUser,
  });

  final String period;
  final String startDate;
  final String endDate;
  final String salesToday;
  final String revenue;
  final int salesCount;
  final String averageBasket;
  final String grossProfit;
  final String expensesTotal;
  final String netProfit;
  final String stockValue;
  final String purchasesTotal;
  final int totalProducts;
  final int totalClients;
  final int totalSuppliers;
  final int productsSold;
  final int productsPurchased;
  final int outOfStock;
  final int lowStock;
  final int nearStockout;
  final int unpaidInvoices;
  final int pendingSupplierPayments;
  final int importantExpenses;
  final int notificationCount;
  final Map<String, DashboardComparison> comparisons;
  final List<DashboardRanking> topProducts;
  final List<DashboardRanking> topClients;
  final bool canFilterUsers;
  final int? selectedUserId;
  final String? selectedUser;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final comparisonJson = json['comparisons'];
    return DashboardSummary(
      period: json['period']?.toString() ?? 'today',
      startDate: json['start_date']?.toString() ?? '',
      endDate: json['end_date']?.toString() ?? '',
      salesToday: _decimal(json['sales_today']),
      revenue: _decimal(json['period_revenue']),
      salesCount: _integer(json['sales_count']),
      averageBasket: _decimal(json['average_basket']),
      grossProfit: _decimal(json['gross_profit']),
      expensesTotal: _decimal(json['expenses_total']),
      netProfit: _decimal(json['net_profit']),
      stockValue: _decimal(json['stock_value']),
      purchasesTotal: _decimal(json['purchases_total']),
      totalProducts: _integer(json['total_products']),
      totalClients: _integer(json['total_clients']),
      totalSuppliers: _integer(json['total_suppliers']),
      productsSold: _integer(json['products_sold']),
      productsPurchased: _integer(json['products_purchased']),
      outOfStock: _integer(json['out_of_stock']),
      lowStock: _integer(json['low_stock']),
      nearStockout: _integer(json['near_stockout']),
      unpaidInvoices: _integer(json['unpaid_invoices']),
      pendingSupplierPayments: _integer(json['pending_supplier_payments']),
      importantExpenses: _integer(json['important_expenses']),
      notificationCount: _integer(json['notification_count']),
      comparisons: comparisonJson is Map
          ? comparisonJson.map(
              (key, value) => MapEntry(
                key.toString(),
                DashboardComparison.fromJson(
                  Map<String, dynamic>.from(value as Map),
                ),
              ),
            )
          : const {},
      topProducts: _rankings(json['top_products'], 'product__name'),
      topClients: _rankings(json['top_clients'], 'client__name'),
      canFilterUsers: json['can_filter_users'] == true,
      selectedUserId: _nullableInteger(json['selected_user_id']),
      selectedUser: json['selected_user']?.toString(),
    );
  }

  static String _decimal(dynamic value) {
    if (value == null || value.toString().isEmpty) return '0.00';
    return value.toString();
  }

  static int _integer(dynamic value) =>
      value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;

  static int? _nullableInteger(dynamic value) => value == null
      ? null
      : value is num
      ? value.toInt()
      : int.tryParse(value.toString());

  static List<DashboardRanking> _rankings(dynamic value, String nameKey) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map(
          (item) => DashboardRanking.fromJson(
            Map<String, dynamic>.from(item),
            nameKey,
          ),
        )
        .toList(growable: false);
  }
}

class DashboardComparison {
  const DashboardComparison({
    required this.current,
    required this.previous,
    required this.percent,
    required this.direction,
  });

  final String current;
  final String previous;
  final String percent;
  final String direction;

  factory DashboardComparison.fromJson(Map<String, dynamic> json) =>
      DashboardComparison(
        current: json['current']?.toString() ?? '0.00',
        previous: json['previous']?.toString() ?? '0.00',
        percent: json['percent']?.toString() ?? '0.00',
        direction: json['direction']?.toString() ?? 'flat',
      );
}

class DashboardRanking {
  const DashboardRanking({
    required this.name,
    required this.total,
    required this.quantity,
    required this.count,
  });

  final String name;
  final String total;
  final int quantity;
  final int count;

  factory DashboardRanking.fromJson(
    Map<String, dynamic> json,
    String nameKey,
  ) => DashboardRanking(
    name: json[nameKey]?.toString() ?? '',
    total: json['total']?.toString() ?? '0.00',
    quantity: DashboardSummary._integer(json['quantity']),
    count: DashboardSummary._integer(json['count']),
  );
}
