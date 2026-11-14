Map<String, dynamic> accountPageFixture({
  int page = 1,
  int paymentsPage = 1,
  int openingPage = 1,
  bool openingOnly = false,
}) {
  Map<String, dynamic> metadata(int number, int count) => {
    'page': number,
    'pages': count == 0 ? 1 : (count / 25).ceil(),
    'count': count,
    'page_size': 25,
    'has_next': number * 25 < count,
    'has_previous': number > 1,
  };
  List<Map<String, dynamic>> rows(
    int number,
    int count, {
    bool invoice = false,
  }) => List.generate(((count - (number - 1) * 25).clamp(0, 25)), (index) {
    final id = (number - 1) * 25 + index + 1;
    return invoice
        ? {
            'id': id,
            'invoice_number': 'SYNTH-INVOICE-$id',
            'created_at': '2026-11-14T00:00:00Z',
            'total': '100.00',
            'amount_paid': '100.00',
            'balance_due': '0.00',
            'payment_status': 'paid',
          }
        : {
            'id': id,
            'reference': 'SYNTH-PAYMENT-$id',
            'amount': '100.00',
            'is_cancelled': false,
            'created_at': '2026-11-14T00:00:00Z',
          };
  });
  return {
    'contract': 'receivable-account-page-v1',
    'client': {'id': 7, 'name': 'Synthetic client'},
    'total_invoiced': '10000.00',
    'total_paid': '1000.00',
    'balance_due': '9000.00',
    'opening_balance': '9000.00',
    'unreconciled_invoice_count': 0,
    'invoices': rows(page, openingOnly ? 0 : 26, invoice: true),
    'payments': rows(paymentsPage, 51),
    'opening_balance_payments': rows(openingPage, 26),
    'pagination': {
      'invoices': metadata(page, openingOnly ? 0 : 26),
      'payments': metadata(paymentsPage, 51),
      'opening_balance_payments': metadata(openingPage, 26),
    },
  };
}
