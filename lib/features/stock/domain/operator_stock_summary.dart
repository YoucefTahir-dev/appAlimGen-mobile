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

class StockMovementSummary {
  const StockMovementSummary({
    required this.id,
    required this.productName,
    required this.movementType,
    required this.quantity,
    required this.appliedDelta,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.reason,
    required this.createdBy,
    required this.createdAt,
  });

  final int id, quantity, appliedDelta, balanceBefore, balanceAfter;
  final String productName, movementType, reason, createdBy, createdAt;

  factory StockMovementSummary.fromJson(Map<String, dynamic> json) =>
      StockMovementSummary(
        id: (json['id'] as num).toInt(),
        productName: json['product_name']?.toString() ?? '',
        movementType: json['movement_type']?.toString() ?? '',
        quantity: (json['quantity'] as num?)?.toInt() ?? 0,
        appliedDelta: (json['applied_delta'] as num?)?.toInt() ?? 0,
        balanceBefore: (json['balance_before'] as num?)?.toInt() ?? 0,
        balanceAfter: (json['balance_after'] as num?)?.toInt() ?? 0,
        reason: json['reason']?.toString() ?? '',
        createdBy: json['created_by_name']?.toString() ?? '',
        createdAt: json['created_at']?.toString() ?? '',
      );
}
