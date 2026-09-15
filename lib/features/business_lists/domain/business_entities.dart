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
  });
  final int id;
  final String number;
  final int? clientId;
  final String date;
  final String total;
  final String paymentStatus;
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
  );
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
