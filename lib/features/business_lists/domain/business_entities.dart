class InvoiceSummary {
  const InvoiceSummary({
    required this.id,
    required this.number,
    required this.clientId,
    required this.date,
    required this.total,
    required this.paymentStatus,
  });
  final int id;
  final String number;
  final int? clientId;
  final String date;
  final String total;
  final String paymentStatus;
  factory InvoiceSummary.fromJson(Map<String, dynamic> json) => InvoiceSummary(
    id: (json['id'] as num).toInt(),
    number: json['invoice_number']?.toString() ?? '',
    clientId: (json['client'] as num?)?.toInt(),
    date: json['created_at']?.toString() ?? '',
    total: json['total']?.toString() ?? '0.00',
    paymentStatus: json['payment_status']?.toString() ?? '',
  );
}

class SupplierSummary {
  const SupplierSummary({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
  });
  final int id;
  final String name;
  final String phone;
  final String address;
  factory SupplierSummary.fromJson(Map<String, dynamic> json) =>
      SupplierSummary(
        id: (json['id'] as num).toInt(),
        name: json['name']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        address: json['address']?.toString() ?? '',
      );
}

class SupplierDetails {
  const SupplierDetails({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.wilaya,
    required this.email,
    required this.rcNumber,
    required this.taxNumber,
    required this.notes,
  });
  final int id;
  final String name, phone, address, wilaya, email, rcNumber, taxNumber, notes;
  factory SupplierDetails.fromJson(Map<String, dynamic> json) =>
      SupplierDetails(
        id: (json['id'] as num).toInt(),
        name: json['name']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        address: json['address']?.toString() ?? '',
        wilaya: json['wilaya']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        rcNumber: json['rc_number']?.toString() ?? '',
        taxNumber: json['tax_number']?.toString() ?? '',
        notes: json['notes']?.toString() ?? '',
      );
}

class SupplierWriteRequest {
  const SupplierWriteRequest({
    required this.name,
    required this.phone,
    required this.address,
    required this.wilaya,
    required this.email,
    required this.rcNumber,
    required this.taxNumber,
    required this.notes,
  });
  final String name, phone, address, wilaya, email, rcNumber, taxNumber, notes;
  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'address': address,
    'wilaya': wilaya,
    'email': email,
    'rc_number': rcNumber,
    'tax_number': taxNumber,
    'notes': notes,
  };
}

class SaleSummary {
  const SaleSummary({
    required this.id,
    required this.number,
    required this.clientId,
    required this.date,
    required this.total,
    required this.paymentStatus,
    required this.clientName,
  });
  final int id;
  final String number;
  final int? clientId;
  final String date;
  final String total;
  final String paymentStatus;
  final String clientName;
  factory SaleSummary.fromJson(Map<String, dynamic> json) => SaleSummary(
    id: (json['id'] as num).toInt(),
    number:
        json['invoice_number']?.toString() ??
        json['ticket_number']?.toString() ??
        '',
    clientId: (json['client'] as num?)?.toInt(),
    date: json['created_at']?.toString() ?? '',
    total: json['total']?.toString() ?? '0.00',
    paymentStatus: json['payment_status']?.toString() ?? '',
    clientName: (json['client_details'] as Map?)?['name']?.toString() ?? '',
  );
}

class SaleClientDetails {
  const SaleClientDetails({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.customerType,
  });
  final int id;
  final String name, phone, address, customerType;
  factory SaleClientDetails.fromJson(Map<String, dynamic> json) =>
      SaleClientDetails(
        id: (json['id'] as num).toInt(),
        name: json['name']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        address: json['address']?.toString() ?? '',
        customerType:
            json['customer_type_display']?.toString() ??
            json['customer_type']?.toString() ??
            '',
      );
}

class SaleLineDetails {
  const SaleLineDetails({
    required this.id,
    required this.productId,
    required this.productName,
    required this.packagingId,
    required this.packagingName,
    required this.quantity,
    required this.stockQuantity,
    required this.unitPrice,
    required this.total,
  });
  final int id, productId, quantity, stockQuantity;
  final int? packagingId;
  final String productName, packagingName, unitPrice, total;
  factory SaleLineDetails.fromJson(Map<String, dynamic> json) {
    final product = Map<String, dynamic>.from(json['product'] as Map? ?? {});
    final quantity =
        (json['packaging_quantity'] as num?)?.toInt() ??
        (json['quantity'] as num?)?.toInt() ??
        0;
    final unitPrice = json['unit_price']?.toString() ?? '0.00';
    return SaleLineDetails(
      id: (json['id'] as num).toInt(),
      productId:
          (product['id'] as num?)?.toInt() ??
          (json['product_id'] as num?)?.toInt() ??
          0,
      productName: product['name']?.toString() ?? '',
      packagingId: (json['packaging'] as num?)?.toInt(),
      packagingName: json['packaging_name']?.toString() ?? '',
      quantity: quantity,
      stockQuantity: (json['quantity'] as num?)?.toInt() ?? quantity,
      unitPrice: unitPrice,
      total:
          json['line_total']?.toString() ??
          (quantity * (double.tryParse(unitPrice) ?? 0)).toStringAsFixed(2),
    );
  }
}

class SalePaymentDetails {
  const SalePaymentDetails({
    required this.id,
    required this.reference,
    required this.amount,
    required this.paymentType,
    required this.date,
  });
  final int id;
  final String reference, amount, paymentType, date;
  factory SalePaymentDetails.fromJson(Map<String, dynamic> json) =>
      SalePaymentDetails(
        id: (json['id'] as num).toInt(),
        reference: json['reference']?.toString() ?? '',
        amount: json['amount']?.toString() ?? '0.00',
        paymentType:
            json['payment_type_display']?.toString() ??
            json['payment_type']?.toString() ??
            '',
        date: json['created_at']?.toString() ?? '',
      );
}

class SaleCapabilities {
  const SaleCapabilities({
    required this.canUpdate,
    required this.canDelete,
    required this.canViewInvoice,
    required this.canViewPdf,
    required this.canPrint,
    required this.canAddPayment,
    required this.canCancel,
  });
  final bool canUpdate, canDelete, canViewInvoice, canViewPdf;
  final bool canPrint, canAddPayment, canCancel;
  factory SaleCapabilities.fromJson(Map<String, dynamic> json) =>
      SaleCapabilities(
        canUpdate: json['can_update'] == true,
        canDelete: json['can_delete'] == true,
        canViewInvoice: json['can_view_invoice'] == true,
        canViewPdf: json['can_view_pdf'] == true,
        canPrint: json['can_print'] == true,
        canAddPayment: json['can_add_payment'] == true,
        canCancel: json['can_cancel'] == true,
      );
}

class SaleDetails {
  const SaleDetails({
    required this.id,
    required this.number,
    required this.ticketNumber,
    required this.date,
    required this.client,
    required this.lines,
    required this.subtotal,
    required this.discount,
    required this.taxRate,
    required this.taxAmount,
    required this.total,
    required this.amountPaid,
    required this.balanceDue,
    required this.paymentType,
    required this.paymentTypeCode,
    required this.paymentStatus,
    required this.payments,
    required this.capabilities,
  });
  final int id;
  final String number, ticketNumber, date, subtotal, discount, taxRate;
  final String taxAmount, total, amountPaid, balanceDue, paymentType;
  final String paymentTypeCode;
  final String paymentStatus;
  final SaleClientDetails client;
  final List<SaleLineDetails> lines;
  final List<SalePaymentDetails> payments;
  final SaleCapabilities capabilities;
  factory SaleDetails.fromJson(Map<String, dynamic> json) {
    final clientJson = Map<String, dynamic>.from(
      json['client_details'] as Map? ?? {'id': json['client'] ?? 0, 'name': ''},
    );
    return SaleDetails(
      id: (json['id'] as num).toInt(),
      number: json['invoice_number']?.toString() ?? '',
      ticketNumber: json['ticket_number']?.toString() ?? '',
      date: json['created_at']?.toString() ?? '',
      client: SaleClientDetails.fromJson(clientJson),
      lines: (json['lines'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) => SaleLineDetails.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
      subtotal: json['subtotal']?.toString() ?? '0.00',
      discount: json['discount']?.toString() ?? '0.00',
      taxRate: json['tax_rate']?.toString() ?? '0.00',
      taxAmount: json['tax_amount']?.toString() ?? '0.00',
      total: json['total']?.toString() ?? '0.00',
      amountPaid: json['amount_paid']?.toString() ?? '0.00',
      balanceDue: json['balance_due']?.toString() ?? '0.00',
      paymentType:
          json['payment_type_display']?.toString() ??
          json['payment_type']?.toString() ??
          '',
      paymentTypeCode: json['payment_type']?.toString() ?? 'cash',
      paymentStatus: json['payment_status']?.toString() ?? '',
      payments: (json['payments'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                SalePaymentDetails.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
      capabilities: SaleCapabilities.fromJson(
        Map<String, dynamic>.from(json['capabilities'] as Map? ?? {}),
      ),
    );
  }
}

class PurchaseSummary {
  const PurchaseSummary({
    required this.id,
    required this.reference,
    required this.supplierId,
    required this.date,
    required this.total,
    required this.paymentStatus,
  });
  final int id;
  final String reference;
  final int? supplierId;
  final String date;
  final String total;
  final String paymentStatus;
  factory PurchaseSummary.fromJson(Map<String, dynamic> json) =>
      PurchaseSummary(
        id: (json['id'] as num).toInt(),
        reference: json['reference']?.toString() ?? '',
        supplierId: (json['supplier'] as num?)?.toInt(),
        date: json['created_at']?.toString() ?? '',
        total: json['total']?.toString() ?? '0.00',
        paymentStatus: json['payment_status']?.toString() ?? '',
      );
}

class ExpenseSummary {
  const ExpenseSummary({
    required this.id,
    required this.number,
    required this.date,
    required this.description,
    required this.amount,
    required this.paymentMethod,
  });
  final int id;
  final String number;
  final String date;
  final String description;
  final String amount;
  final String paymentMethod;
  factory ExpenseSummary.fromJson(Map<String, dynamic> json) => ExpenseSummary(
    id: (json['id'] as num).toInt(),
    number: json['number']?.toString() ?? '',
    date: json['date']?.toString() ?? '',
    description: json['description']?.toString() ?? '',
    amount: json['amount']?.toString() ?? '0.00',
    paymentMethod: json['payment_method']?.toString() ?? '',
  );
}

class ExpenseDetails {
  const ExpenseDetails({
    required this.id,
    required this.date,
    required this.category,
    required this.description,
    required this.amount,
    required this.paymentMethod,
    required this.observation,
    this.supplier,
  });
  final int id, category;
  final int? supplier;
  final String date, description, amount, paymentMethod, observation;
  factory ExpenseDetails.fromJson(Map<String, dynamic> json) => ExpenseDetails(
    id: (json['id'] as num).toInt(),
    date: json['date']?.toString() ?? '',
    category: (json['category'] as num).toInt(),
    supplier: (json['supplier'] as num?)?.toInt(),
    description: json['description']?.toString() ?? '',
    amount: json['amount']?.toString() ?? '',
    paymentMethod: json['payment_method']?.toString() ?? 'cash',
    observation: json['observation']?.toString() ?? '',
  );
}

class ExpenseWriteRequest {
  const ExpenseWriteRequest({
    required this.date,
    required this.category,
    required this.description,
    required this.amount,
    required this.paymentMethod,
    required this.observation,
    this.supplier,
  });
  final int category;
  final int? supplier;
  final String date, description, amount, paymentMethod, observation;
  Map<String, dynamic> toJson() => {
    'date': date,
    'category': category,
    'supplier': supplier,
    'description': description,
    'amount': amount,
    'payment_method': paymentMethod,
    'observation': observation,
  };
}

class BusinessOption {
  const BusinessOption({required this.id, required this.name});
  final int id;
  final String name;
  factory BusinessOption.fromJson(Map<String, dynamic> json) => BusinessOption(
    id: (json['id'] as num).toInt(),
    name: json['name']?.toString() ?? '',
  );
}

class PaymentSummary {
  const PaymentSummary({
    required this.id,
    required this.reference,
    required this.amount,
    required this.paymentType,
    required this.date,
  });
  final int id;
  final String reference;
  final String amount;
  final String paymentType;
  final String date;
  factory PaymentSummary.fromJson(Map<String, dynamic> json) => PaymentSummary(
    id: (json['id'] as num).toInt(),
    reference: json['reference']?.toString() ?? '',
    amount: json['amount']?.toString() ?? '0.00',
    paymentType: json['payment_type']?.toString() ?? '',
    date: json['created_at']?.toString() ?? '',
  );
}

class TransactionOption {
  const TransactionOption({
    required this.id,
    required this.label,
    this.meta = const {},
  });
  final int id;
  final String label;
  final Map<String, dynamic> meta;
}

class TransactionLineRequest {
  const TransactionLineRequest({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    this.packagingId,
  });
  final int productId, quantity;
  final int? packagingId;
  final String unitPrice;
  Map<String, dynamic> saleJson() => {
    'product_id': productId,
    'quantity': quantity,
    'unit_price': unitPrice,
    if (packagingId != null) 'packaging_id': packagingId,
  };
  Map<String, dynamic> purchaseJson() => {
    'product': productId,
    'quantity': quantity,
    'purchase_price': unitPrice,
  };
}

class SaleWriteRequest {
  const SaleWriteRequest({
    required this.clientId,
    required this.discount,
    required this.taxRate,
    required this.paymentType,
    required this.payFull,
    required this.items,
  });
  final int clientId;
  final String discount, taxRate, paymentType;
  final bool payFull;
  final List<TransactionLineRequest> items;
  Map<String, dynamic> toJson() => {
    'client': clientId,
    'discount': discount,
    'tax_rate': taxRate,
    'payment_type': paymentType,
    'pay_full': payFull,
    'items': items.map((line) => line.saleJson()).toList(),
  };
}

class PurchaseWriteRequest {
  const PurchaseWriteRequest({
    required this.supplierId,
    required this.reference,
    required this.taxRate,
    required this.items,
  });
  final int supplierId;
  final String reference, taxRate;
  final List<TransactionLineRequest> items;
  Map<String, dynamic> toJson() => {
    'supplier': supplierId,
    'reference': reference,
    'tax_rate': taxRate,
    'items': items.map((line) => line.purchaseJson()).toList(),
  };
}

class PaymentWriteRequest {
  const PaymentWriteRequest({
    this.saleId,
    this.purchaseId,
    required this.amount,
    required this.paymentType,
  });
  final int? saleId, purchaseId;
  final String amount, paymentType;
  Map<String, dynamic> toJson() => {
    if (saleId != null) 'sale': saleId,
    if (purchaseId != null) 'purchase': purchaseId,
    'amount': amount,
    'payment_type': paymentType,
  };
}
