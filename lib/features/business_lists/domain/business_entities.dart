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
