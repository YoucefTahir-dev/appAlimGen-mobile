class OperatorStockSummary {
  const OperatorStockSummary({
    required this.id,
    required this.productId,
    required this.productName,
    required this.remaining,
    required this.updatedAt,
    this.loaded,
    this.sold,
  });
  final int id;
  final int productId;
  final String productName;
  final int remaining;
  final String updatedAt;
  final int? loaded;
  final int? sold;
  OperatorStockSummary copyWithActivity({int? loaded, int? sold}) =>
      OperatorStockSummary(
        id: id,
        productId: productId,
        productName: productName,
        remaining: remaining,
        updatedAt: updatedAt,
        loaded: loaded,
        sold: sold,
      );
  factory OperatorStockSummary.fromJson(Map<String, dynamic> json) =>
      OperatorStockSummary(
        id: (json['id'] as num).toInt(),
        productId: (json['product'] as num).toInt(),
        productName: json['product_name']?.toString() ?? '',
        remaining: (json['quantity'] as num?)?.toInt() ?? 0,
        updatedAt: json['updated_at']?.toString() ?? '',
      );
}
