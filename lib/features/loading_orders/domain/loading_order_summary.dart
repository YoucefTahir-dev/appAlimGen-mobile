class LoadingOrderSummary {
  const LoadingOrderSummary({
    required this.id,
    required this.number,
    required this.operatorName,
    required this.status,
    required this.createdAt,
    required this.lines,
  });
  final int id;
  final String number;
  final String operatorName;
  final String status;
  final String createdAt;
  final List<LoadingLineSummary> lines;
  factory LoadingOrderSummary.fromJson(Map<String, dynamic> json) =>
      LoadingOrderSummary(
        id: (json['id'] as num).toInt(),
        number: json['number']?.toString() ?? '',
        operatorName: json['operator_name']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        createdAt: json['created_at']?.toString() ?? '',
        lines: ((json['lines'] as List?) ?? const [])
            .map(
              (item) => LoadingLineSummary.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList(growable: false),
      );
}

class LoadingLineSummary {
  const LoadingLineSummary({
    required this.productId,
    required this.productName,
    required this.loaded,
    required this.sold,
    required this.returned,
  });
  final int productId;
  final String productName;
  final int loaded;
  final int sold;
  final int returned;
  factory LoadingLineSummary.fromJson(Map<String, dynamic> json) =>
      LoadingLineSummary(
        productId: (json['product'] as num).toInt(),
        productName: json['product_name']?.toString() ?? '',
        loaded: (json['quantity'] as num?)?.toInt() ?? 0,
        sold: (json['sold_quantity'] as num?)?.toInt() ?? 0,
        returned: (json['returned_quantity'] as num?)?.toInt() ?? 0,
      );
}
