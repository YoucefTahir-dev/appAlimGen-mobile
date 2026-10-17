import 'package:app_alim_gen_mobile/core/errors/error_mapper.dart';
import 'package:app_alim_gen_mobile/features/receivables/data/receivables_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

void main() {
  test('charge la liste et le compte client depuis le contrat API', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1/'));
    final adapter = DioAdapter(dio: dio);
    final repository = ReceivablesRepository(dio, const ErrorMapper());
    adapter.onGet(
      'receivables/',
      (server) => server.reply(200, {
        'success': true,
        'data': {
          'count': 1,
          'results': [
            {
              'id': 7,
              'name': 'Client A',
              'phone': '0550',
              'total_invoiced': '150.00',
              'total_paid': '40.00',
              'balance_due': '110.00',
              'invoice_count': 2,
              'unpaid_invoice_count': 2,
              'unreconciled_invoice_count': 1,
            },
          ],
        },
      }),
      queryParameters: {'search': '', 'status': 'debtors', 'page_size': 100},
    );
    adapter.onGet(
      'receivables/7/',
      (server) => server.reply(200, {
        'success': true,
        'data': {
          'client': {'id': 7, 'name': 'Client A'},
          'total_invoiced': '150.00',
          'total_paid': '40.00',
          'balance_due': '110.00',
          'unreconciled_invoice_count': 1,
          'invoices': [
            {
              'id': 10,
              'invoice_number': 'FAC-10',
              'created_at': '2026-10-16T10:00:00Z',
              'total': '100.00',
              'amount_paid': '40.00',
              'balance_due': '60.00',
              'payment_status': 'partial',
            },
          ],
          'payments': [
            {
              'id': 3,
              'reference': 'PAY-3',
              'external_reference': 'MOB-1',
              'amount': '40.00',
              'payment_type': 'cash',
              'created_at': '2026-10-16T10:00:00Z',
              'is_cancelled': false,
              'cancellation_reason': '',
            },
          ],
        },
      }),
    );

    final list = await repository.fetch();
    final account = await repository.getAccount(7);

    expect(list.single.balanceDue, '110.00');
    expect(list.single.unreconciledInvoiceCount, 1);
    expect(account.invoices.single.number, 'FAC-10');
    expect(account.payments.single.externalReference, 'MOB-1');
  });
}
