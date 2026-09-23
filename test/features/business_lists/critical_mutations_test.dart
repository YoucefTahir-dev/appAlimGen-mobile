import 'dart:convert';
import 'dart:typed_data';

import 'package:app_alim_gen_mobile/core/errors/error_mapper.dart';
import 'package:app_alim_gen_mobile/features/business_lists/data/business_repositories.dart';
import 'package:app_alim_gen_mobile/features/business_lists/domain/business_entities.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('vente, achat et paiement transmettent la même clé de retry', () async {
    final adapter = _CapturingAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1/'))
      ..httpClientAdapter = adapter;
    const errors = ErrorMapper();
    const key = 'stable-key-for-retry';

    await SalesRepository(dio, errors).create(
      const SaleWriteRequest(
        clientId: 2,
        discount: '0',
        taxRate: '0',
        paymentType: 'cash',
        payFull: true,
        items: [
          TransactionLineRequest(productId: 4, quantity: 1, unitPrice: '12.00'),
        ],
      ),
      key,
    );
    await PurchasesRepository(dio, errors).create(
      const PurchaseWriteRequest(
        supplierId: 3,
        reference: 'ACH-1',
        taxRate: '0',
        items: [
          TransactionLineRequest(productId: 4, quantity: 2, unitPrice: '8.00'),
        ],
      ),
      key,
    );
    await PaymentsRepository(dio, errors).create(
      const PaymentWriteRequest(
        saleId: 1,
        amount: '12.00',
        paymentType: 'cash',
      ),
      key,
    );

    expect(adapter.requests, hasLength(3));
    for (final request in adapter.requests) {
      expect(request.headers['Idempotency-Key'], key);
    }
  });
}

class _CapturingAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final common = {
      'id': 1,
      'created_at': '2026-09-23T12:00:00Z',
      'total': '12.00',
      'payment_status': 'paid',
    };
    final data = switch (options.path) {
      final path when path.endsWith('/sales/') => {
        ...common,
        'invoice_number': 'FAC-1',
        'client': 2,
      },
      final path when path.endsWith('/purchases/') => {
        ...common,
        'reference': 'ACH-1',
        'supplier': 3,
      },
      _ => {
        'id': 1,
        'reference': 'PAY-1',
        'amount': '12.00',
        'payment_type': 'cash',
        'created_at': '2026-09-23T12:00:00Z',
      },
    };
    return ResponseBody.fromString(
      jsonEncode({'success': true, 'data': data}),
      201,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
