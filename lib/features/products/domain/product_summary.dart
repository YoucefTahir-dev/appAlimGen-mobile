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
  };
}
