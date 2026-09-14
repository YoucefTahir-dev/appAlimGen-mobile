class DashboardSummary {
  const DashboardSummary({
    required this.revenue,
    required this.salesCount,
    required this.averageBasket,
    required this.netProfit,
    required this.totalProducts,
    required this.totalClients,
    required this.totalSuppliers,
  });
  final String revenue;
  final int salesCount;
  final String averageBasket;
  final String netProfit;
  final int totalProducts;
  final int totalClients;
  final int totalSuppliers;

  bool get isEmpty =>
      salesCount == 0 &&
      totalProducts == 0 &&
      totalClients == 0 &&
      totalSuppliers == 0;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) =>
      DashboardSummary(
        revenue: json['period_revenue']?.toString() ?? '0.00',
        salesCount: _integer(json['sales_count']),
        averageBasket: json['average_basket']?.toString() ?? '0.00',
        netProfit: json['net_profit']?.toString() ?? '0.00',
        totalProducts: _integer(json['total_products']),
        totalClients: _integer(json['total_clients']),
        totalSuppliers: _integer(json['total_suppliers']),
      );

  static int _integer(dynamic value) =>
      value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;
}
