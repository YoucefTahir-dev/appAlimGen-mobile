class ReceivableSummary {
  const ReceivableSummary({
    required this.id,
    required this.name,
    required this.phone,
    required this.totalInvoiced,
    required this.totalPaid,
    required this.balanceDue,
    required this.invoiceCount,
    required this.unpaidInvoiceCount,
    required this.unreconciledInvoiceCount,
  });

  final int id, invoiceCount, unpaidInvoiceCount, unreconciledInvoiceCount;
  final String name, phone, totalInvoiced, totalPaid, balanceDue;

  factory ReceivableSummary.fromJson(Map<String, dynamic> json) =>
      ReceivableSummary(
        id: (json['id'] as num).toInt(),
        name: json['name']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        totalInvoiced: json['total_invoiced']?.toString() ?? '0.00',
        totalPaid: json['total_paid']?.toString() ?? '0.00',
        balanceDue: json['balance_due']?.toString() ?? '0.00',
        invoiceCount: (json['invoice_count'] as num?)?.toInt() ?? 0,
        unpaidInvoiceCount:
            (json['unpaid_invoice_count'] as num?)?.toInt() ?? 0,
        unreconciledInvoiceCount:
            (json['unreconciled_invoice_count'] as num?)?.toInt() ?? 0,
      );
}

class ReceivableInvoice {
  const ReceivableInvoice({
    required this.id,
    required this.number,
    required this.date,
    required this.total,
    required this.paid,
    required this.balance,
    required this.status,
  });
  final int id;
  final String number, date, total, paid, balance, status;
  factory ReceivableInvoice.fromJson(Map<String, dynamic> json) =>
      ReceivableInvoice(
        id: (json['id'] as num).toInt(),
        number: json['invoice_number']?.toString() ?? '',
        date: json['created_at']?.toString() ?? '',
        total: json['total']?.toString() ?? '0.00',
        paid: json['amount_paid']?.toString() ?? '0.00',
        balance: json['balance_due']?.toString() ?? '0.00',
        status: json['payment_status']?.toString() ?? '',
      );
  bool get isPaid => double.tryParse(balance) == 0;
}

class ReceivablePayment {
  const ReceivablePayment({
    required this.id,
    required this.reference,
    required this.externalReference,
    required this.amount,
    required this.paymentType,
    required this.date,
    required this.cancelled,
    required this.cancellationReason,
    this.openingBalance = false,
  });
  final int id;
  final String reference, externalReference, amount, paymentType, date;
  final bool cancelled;
  final bool openingBalance;
  final String cancellationReason;
  factory ReceivablePayment.fromJson(
    Map<String, dynamic> json, {
    bool openingBalance = false,
  }) => ReceivablePayment(
    id: (json['id'] as num).toInt(),
    reference: json['reference']?.toString() ?? '',
    externalReference: json['external_reference']?.toString() ?? '',
    amount: json['amount']?.toString() ?? '0.00',
    paymentType: json['payment_type']?.toString() ?? '',
    date: json['created_at']?.toString() ?? '',
    cancelled: json['is_cancelled'] == true,
    cancellationReason: json['cancellation_reason']?.toString() ?? '',
    openingBalance: openingBalance,
  );
}

class ReceivableAccount {
  const ReceivableAccount({
    required this.clientId,
    required this.clientName,
    required this.totalInvoiced,
    required this.totalPaid,
    required this.balanceDue,
    required this.openingBalance,
    required this.unreconciledCount,
    required this.invoices,
    required this.payments,
  });
  final int clientId, unreconciledCount;
  final String clientName, totalInvoiced, totalPaid, balanceDue, openingBalance;
  final List<ReceivableInvoice> invoices;
  final List<ReceivablePayment> payments;

  factory ReceivableAccount.fromJson(Map<String, dynamic> json) {
    final client = Map<String, dynamic>.from(json['client'] as Map);
    return ReceivableAccount(
      clientId: (client['id'] as num).toInt(),
      clientName: client['name']?.toString() ?? '',
      totalInvoiced: json['total_invoiced']?.toString() ?? '0.00',
      totalPaid: json['total_paid']?.toString() ?? '0.00',
      balanceDue: json['balance_due']?.toString() ?? '0.00',
      openingBalance: json['opening_balance']?.toString() ?? '0.00',
      unreconciledCount:
          (json['unreconciled_invoice_count'] as num?)?.toInt() ?? 0,
      invoices: (json['invoices'] as List? ?? const [])
          .map(
            (item) => ReceivableInvoice.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false),
      payments: [
        ...(json['payments'] as List? ?? const []).map(
          (item) => ReceivablePayment.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        ),
        ...(json['opening_balance_payments'] as List? ?? const []).map(
          (item) => ReceivablePayment.fromJson(
            Map<String, dynamic>.from(item as Map),
            openingBalance: true,
          ),
        ),
      ],
    );
  }
}
