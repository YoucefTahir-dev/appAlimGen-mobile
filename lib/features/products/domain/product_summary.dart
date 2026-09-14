class ProductSummary {
  const ProductSummary({
    required this.id,
    required this.name,
    required this.reference,
    required this.quantity,
    required this.stockStatus,
    this.retailPrice,
  });
  final int id;
  final String name;
  final String reference;
  final int quantity;
  final String stockStatus;
  final String? retailPrice;
  factory ProductSummary.fromJson(Map<String, dynamic> json) => ProductSummary(
    id: (json['id'] as num).toInt(),
    name: json['name']?.toString() ?? '',
    reference: json['reference']?.toString() ?? '',
    quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    stockStatus: json['stock_status']?.toString() ?? '',
    retailPrice: json['retail_price']?.toString(),
  );
}
