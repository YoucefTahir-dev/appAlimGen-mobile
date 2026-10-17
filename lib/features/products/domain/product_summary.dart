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

class ReferenceOption {
  const ReferenceOption({required this.id, required this.name});
  final int id;
  final String name;
  factory ReferenceOption.fromJson(Map<String, dynamic> json) =>
      ReferenceOption(
        id: (json['id'] as num).toInt(),
        name: json['name']?.toString() ?? '',
      );
}

class ProductDetails {
  const ProductDetails({
    required this.id,
    required this.reference,
    required this.barcode,
    required this.name,
    required this.purchasePrice,
    required this.superWholesalePrice,
    required this.wholesalePrice,
    required this.retailPrice,
    required this.quantity,
    required this.minimumStock,
    required this.description,
    required this.unitMode,
    required this.conditioningStatus,
    required this.hasHistoricalConversion,
    required this.packagings,
    this.category,
    this.brand,
    this.unit,
  });

  final int id;
  final String reference;
  final String barcode;
  final String name;
  final int? category;
  final int? brand;
  final int? unit;
  final String purchasePrice;
  final String superWholesalePrice;
  final String wholesalePrice;
  final String retailPrice;
  final int quantity;
  final int minimumStock;
  final String description;
  final String unitMode;
  final String conditioningStatus;
  final bool hasHistoricalConversion;
  final List<ProductPackagingDetails> packagings;

  factory ProductDetails.fromJson(Map<String, dynamic> json) => ProductDetails(
    id: (json['id'] as num).toInt(),
    reference: json['reference']?.toString() ?? '',
    barcode: json['barcode']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    category: (json['category'] as num?)?.toInt(),
    brand: (json['brand'] as num?)?.toInt(),
    unit: (json['unit'] as num?)?.toInt(),
    purchasePrice: json['purchase_price']?.toString() ?? '',
    superWholesalePrice: json['super_wholesale_price']?.toString() ?? '',
    wholesalePrice: json['wholesale_price']?.toString() ?? '',
    retailPrice: json['retail_price']?.toString() ?? '',
    quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    minimumStock: (json['minimum_stock'] as num?)?.toInt() ?? 0,
    description: json['description']?.toString() ?? '',
    unitMode: json['unit_mode']?.toString() ?? 'legacy',
    conditioningStatus:
        json['conditioning_status']?.toString() ?? 'unclassified',
    hasHistoricalConversion: json['has_historical_conversion'] == true,
    packagings: (json['conditionnements'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (item) =>
              ProductPackagingDetails.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList(growable: false),
  );
}

class ProductPackagingDetails {
  const ProductPackagingDetails({
    required this.id,
    required this.name,
    required this.kind,
    required this.conversionFactor,
    required this.referencePurchasePrice,
    required this.superWholesalePrice,
    required this.wholesalePrice,
    required this.retailPrice,
    required this.isActive,
  });

  final int id, conversionFactor;
  final String name, kind;
  final String referencePurchasePrice, superWholesalePrice;
  final String wholesalePrice, retailPrice;
  final bool isActive;

  factory ProductPackagingDetails.fromJson(Map<String, dynamic> json) =>
      ProductPackagingDetails(
        id: (json['id'] as num).toInt(),
        name: json['name']?.toString() ?? '',
        kind: json['kind']?.toString() ?? 'other',
        conversionFactor: (json['conversion_factor'] as num?)?.toInt() ?? 1,
        referencePurchasePrice:
            json['reference_purchase_price']?.toString() ?? '',
        superWholesalePrice: json['super_wholesale_price']?.toString() ?? '',
        wholesalePrice: json['wholesale_price']?.toString() ?? '',
        retailPrice: json['retail_price']?.toString() ?? '',
        isActive: json['is_active'] != false,
      );
}

class ProductWriteRequest {
  const ProductWriteRequest({
    required this.name,
    required this.purchasePrice,
    required this.superWholesalePrice,
    required this.wholesalePrice,
    required this.retailPrice,
    required this.quantity,
    required this.minimumStock,
    required this.description,
    this.unitMode = 'piece_only',
    this.category,
    this.brand,
    this.unit,
  });
  final String name;
  final int? category;
  final int? brand;
  final int? unit;
  final String purchasePrice;
  final String superWholesalePrice;
  final String wholesalePrice;
  final String retailPrice;
  final int quantity;
  final int minimumStock;
  final String description;
  final String unitMode;

  Map<String, dynamic> toJson() => {
    'name': name,
    'category': category,
    'brand': brand,
    'unit': unit,
    'purchase_price': purchasePrice,
    'super_wholesale_price': superWholesalePrice,
    'wholesale_price': wholesalePrice,
    'retail_price': retailPrice,
    'quantity': quantity,
    'minimum_stock': minimumStock,
    'description': description,
    'unit_mode': unitMode,
  };
}

class ProductPackagingWriteRequest {
  const ProductPackagingWriteRequest({
    required this.productId,
    required this.name,
    required this.conversionFactor,
    required this.referencePurchasePrice,
    required this.superWholesalePrice,
    required this.wholesalePrice,
    required this.retailPrice,
    this.isActive = true,
  });

  final int productId, conversionFactor;
  final String name, referencePurchasePrice, superWholesalePrice;
  final String wholesalePrice, retailPrice;
  final bool isActive;

  Map<String, dynamic> toJson() => {
    'product': productId,
    'name': name,
    'kind': 'carton',
    'conversion_factor': conversionFactor,
    'default_sale_price': retailPrice,
    'reference_purchase_price': referencePurchasePrice,
    'super_wholesale_price': superWholesalePrice,
    'wholesale_price': wholesalePrice,
    'retail_price': retailPrice,
    'purchase_enabled': true,
    'sale_enabled': true,
    'is_active': isActive,
  };
}

class HistoricalConversionLocation {
  const HistoricalConversionLocation({
    required this.operatorId,
    required this.operatorName,
    required this.currentQuantity,
    this.targetQuantity,
  });

  final int operatorId, currentQuantity;
  final int? targetQuantity;
  final String operatorName;

  factory HistoricalConversionLocation.fromJson(Map<String, dynamic> json) =>
      HistoricalConversionLocation(
        operatorId: (json['operator_id'] as num).toInt(),
        operatorName: json['operator_name']?.toString() ?? '',
        currentQuantity:
            (json['current_quantity'] as num?)?.toInt() ??
            (json['cartons_before'] as num?)?.toInt() ??
            0,
        targetQuantity:
            (json['target_quantity'] as num?)?.toInt() ??
            (json['pieces_after'] as num?)?.toInt(),
      );
}

class HistoricalConversionPreview {
  const HistoricalConversionPreview({
    required this.factor,
    required this.depotBefore,
    required this.depotAfter,
    required this.minimumBefore,
    required this.minimumAfter,
    required this.eligible,
    required this.blockers,
    required this.operatorLocations,
  });

  final int factor, depotBefore, depotAfter, minimumBefore, minimumAfter;
  final bool eligible;
  final List<String> blockers;
  final List<HistoricalConversionLocation> operatorLocations;

  factory HistoricalConversionPreview.fromJson(Map<String, dynamic> json) =>
      HistoricalConversionPreview(
        factor: (json['factor'] as num).toInt(),
        depotBefore: (json['depot_cartons_before'] as num?)?.toInt() ?? 0,
        depotAfter: (json['depot_pieces_after'] as num?)?.toInt() ?? 0,
        minimumBefore: (json['minimum_cartons_before'] as num?)?.toInt() ?? 0,
        minimumAfter: (json['minimum_pieces_after'] as num?)?.toInt() ?? 0,
        eligible: json['eligible'] == true,
        blockers: (json['blockers'] as List? ?? const [])
            .map((item) => item.toString())
            .toList(growable: false),
        operatorLocations: (json['operator_locations'] as List? ?? const [])
            .whereType<Map>()
            .map(
              (item) => HistoricalConversionLocation.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList(growable: false),
      );
}

class ConditioningCorrectionPreview {
  const ConditioningCorrectionPreview({
    required this.requiresPhysicalInventory,
    required this.currentDepotQuantity,
    this.depotTarget,
    required this.operatorLocations,
  });

  final bool requiresPhysicalInventory;
  final int currentDepotQuantity;
  final int? depotTarget;
  final List<HistoricalConversionLocation> operatorLocations;

  factory ConditioningCorrectionPreview.fromJson(Map<String, dynamic> json) =>
      ConditioningCorrectionPreview(
        requiresPhysicalInventory: json['requires_physical_inventory'] == true,
        currentDepotQuantity:
            (json['current_depot_quantity'] as num?)?.toInt() ?? 0,
        depotTarget: (json['depot_target'] as num?)?.toInt(),
        operatorLocations: (json['operator_locations'] as List? ?? const [])
            .whereType<Map>()
            .map(
              (item) => HistoricalConversionLocation.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList(growable: false),
      );
}
