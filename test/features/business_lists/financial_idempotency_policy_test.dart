import 'dart:convert';
import 'dart:typed_data';

import 'package:app_alim_gen_mobile/core/errors/error_mapper.dart';
import 'package:app_alim_gen_mobile/features/business_lists/data/business_repositories.dart';
import 'package:app_alim_gen_mobile/features/business_lists/domain/business_entities.dart';
import 'package:app_alim_gen_mobile/features/loading_orders/data/loading_orders_repository.dart';
import 'package:app_alim_gen_mobile/features/loading_orders/domain/loading_order_summary.dart';
import 'package:app_alim_gen_mobile/features/receivables/data/receivables_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final data = {
      'id': 7,
      'number': 'SYNTHETIC-LOADING',
      'status': 'in_progress',
      'created_at': '2026-11-12T10:30:00Z',
      'total': '100.00',
      'payment_status': 'unpaid',
      'reference': 'SYNTHETIC-REFERENCE',
      'invoice_number': 'SYNTHETIC-INVOICE',
      'client': 2,
      'supplier': 3,
      'operator': 2,
      'amount': '25.00',
      'payment_type': 'cash',
      'lines': const [],
      'payments': const [],
    };
    return ResponseBody.fromString(
      jsonEncode({'success': true, 'data': data}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test(
    'only the nine supported keyed mutations explicitly opt in to required-v1',
    () async {
      final adapter = _Adapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://synthetic.invalid/api/v1/'))
        ..httpClientAdapter = adapter;
      const errors = ErrorMapper();
      const key = 'synthetic-required-policy';
      const sale = SaleWriteRequest(
        clientId: 2,
        discount: '0',
        taxRate: '0',
        paymentType: 'cash',
        payFull: false,
        items: [],
      );
      const purchase = PurchaseWriteRequest(
        supplierId: 3,
        reference: 'SYNTHETIC',
        taxRate: '0',
        items: [],
      );
      final sales = SalesRepository(dio, errors);
      final purchases = PurchasesRepository(dio, errors);
      final payments = PaymentsRepository(dio, errors);
      final loading = LoadingOrdersRepository(dio, errors);
      final receipts = ReceivablesRepository(dio, errors);
      await sales.create(sale, key);
      await sales.update(7, sale, key);
      await purchases.create(purchase, key);
      await purchases.update(7, purchase, key);
      await payments.create(
        const PaymentWriteRequest(
          saleId: 2,
          amount: '25.00',
          paymentType: 'cash',
        ),
        key,
      );
      await loading.create(
        const LoadingOrderWriteRequest(operatorId: 2, notes: '', lines: []),
        key,
      );
      await loading.validateLoadingOrder(7, key);
      await loading.closeLoadingOrder(7, key);
      await receipts.allocatePayment(
        clientId: 2,
        amount: '25.00',
        paymentType: 'cash',
        idempotencyKey: key,
      );
      expect(adapter.requests, hasLength(9));
      for (final request in adapter.requests) {
        expect(request.headers['Idempotency-Key'], key, reason: request.path);
        expect(
          request.headers['Idempotency-Policy'],
          'required-v1',
          reason: request.path,
        );
      }
      expect(dio.options.headers, isNot(contains('Idempotency-Policy')));
      adapter.requests.clear();
      await loading.update(
        7,
        const LoadingOrderWriteRequest(operatorId: 2, notes: '', lines: []),
      );
      await loading.cancelLoadingOrder(7);
      await loading.delete(7);
      await payments.cancel(7, 'Synthetic cancellation');
      await receipts.cancelOpeningPayment(
        clientId: 2,
        paymentId: 7,
        reason: 'Synthetic cancellation',
      );
      for (final request in adapter.requests) {
        expect(
          request.headers['Idempotency-Key'],
          isNull,
          reason: request.path,
        );
        expect(
          request.headers['Idempotency-Policy'],
          isNull,
          reason: request.path,
        );
      }
    },
  );
}
