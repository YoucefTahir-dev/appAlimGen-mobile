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

class ReceivableHistoryPage {
  const ReceivableHistoryPage({
    required this.page,
    required this.pages,
    required this.count,
    required this.pageSize,
  });
  final int page, pages, count, pageSize;
  bool get hasNext => page < pages;
  bool get hasPrevious => page > 1;

  factory ReceivableHistoryPage.fromJson(Map<String, dynamic> json) {
    int integer(String key, int minimum) {
      final value = json[key];
      if (value is! int || value < minimum) {
        throw const FormatException('Pagination invalide.');
      }
      return value;
    }

    final result = ReceivableHistoryPage(
      page: integer('page', 1),
      pages: integer('pages', 1),
      count: integer('count', 0),
      pageSize: integer('page_size', 1),
    );
    if (result.pageSize > 25 ||
        result.page > result.pages ||
        result.pages !=
            (result.count == 0 ? 1 : (result.count / result.pageSize).ceil()) ||
        json['has_next'] != result.hasNext ||
        json['has_previous'] != result.hasPrevious) {
      throw const FormatException('Pagination incohérente.');
    }
    return result;
  }
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
    this.invoicePage,
    this.paymentPage,
    this.openingPaymentPage,
  });
  final int clientId, unreconciledCount;
  final String clientName, totalInvoiced, totalPaid, balanceDue, openingBalance;
  final List<ReceivableInvoice> invoices;
  final List<ReceivablePayment> payments;
  final ReceivableHistoryPage? invoicePage, paymentPage, openingPaymentPage;

  factory ReceivableAccount.fromPagedJson(Map<String, dynamic> json) {
    if (json['contract'] != 'receivable-account-page-v1' ||
        json['pagination'] is! Map) {
      throw const FormatException('Contrat de compte paginé indisponible.');
    }
    final metadata = json['pagination'] as Map;
    ReceivableHistoryPage history(String key) {
      final raw = metadata[key];
      if (raw is! Map || json[key] is! List) {
        throw const FormatException('Historique paginé invalide.');
      }
      final page = ReceivableHistoryPage.fromJson(
        Map<String, dynamic>.from(raw),
      );
      final length = (json[key] as List).length;
      // Counts and rows may change between server queries during an operation.
      // Enforce the memory bound without rejecting a legitimate shorter page.
      if (length > page.pageSize) {
        throw const FormatException('Historique non borné.');
      }
      return page;
    }

    final invoices = history('invoices');
    final payments = history('payments');
    final opening = history('opening_balance_payments');
    final account = ReceivableAccount.fromJson(json);
    return ReceivableAccount(
      clientId: account.clientId,
      clientName: account.clientName,
      totalInvoiced: account.totalInvoiced,
      totalPaid: account.totalPaid,
      balanceDue: account.balanceDue,
      openingBalance: account.openingBalance,
      unreconciledCount: account.unreconciledCount,
      invoices: account.invoices,
      payments: account.payments,
      invoicePage: invoices,
      paymentPage: payments,
      openingPaymentPage: opening,
    );
  }

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
