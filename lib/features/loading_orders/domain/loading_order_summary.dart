class LoadingOrderSummary {
  const LoadingOrderSummary({
    required this.id,
    required this.number,
    required this.operatorName,
    required this.status,
    required this.createdAt,
    required this.lines,
    this.operatorId,
    this.notes = '',
  });
  final int id;
  final String number;
  final String operatorName;
  final String status;
  final String createdAt;
  final List<LoadingLineSummary> lines;
  final int? operatorId;
  final String notes;
  factory LoadingOrderSummary.fromJson(Map<String, dynamic> json) =>
      LoadingOrderSummary(
        id: (json['id'] as num).toInt(),
        number: json['number']?.toString() ?? '',
        operatorName: json['operator_name']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        createdAt: json['created_at']?.toString() ?? '',
        operatorId: (json['operator'] as num?)?.toInt(),
        notes: json['notes']?.toString() ?? '',
        lines: ((json['lines'] as List?) ?? const [])
            .map(
              (item) => LoadingLineSummary.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList(growable: false),
      );
}

class LoadingOrderWriteRequest {
  const LoadingOrderWriteRequest({
    required this.operatorId,
    required this.notes,
    required this.lines,
  });
  final int operatorId;
  final String notes;
  final List<LoadingOrderLineWrite> lines;
  Map<String, dynamic> toJson() => {
    'operator': operatorId,
    'notes': notes,
    'lines': lines.map((e) => e.toJson()).toList(),
  };
}

class LoadingOrderLineWrite {
  const LoadingOrderLineWrite(this.productId, this.quantity);
  final int productId, quantity;
  Map<String, dynamic> toJson() => {'product': productId, 'quantity': quantity};
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
