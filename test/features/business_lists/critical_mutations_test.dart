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

  test('modification vente conserve sa clé et toutes les lignes', () async {
    final adapter = _CapturingAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1/'))
      ..httpClientAdapter = adapter;
    const key = 'stable-sale-update';

    await SalesRepository(dio, const ErrorMapper()).update(
      8,
      const SaleWriteRequest(
        clientId: 2,
        discount: '5.00',
        taxRate: '19.00',
        paymentType: 'cheque',
        payFull: false,
        items: [
          TransactionLineRequest(
            productId: 4,
            packagingId: 6,
            quantity: 2,
            unitPrice: '120.00',
          ),
          TransactionLineRequest(productId: 5, quantity: 1, unitPrice: '80.00'),
        ],
      ),
      key,
    );

    final request = adapter.requests.single;
    expect(request.method, 'PATCH');
    expect(request.path, endsWith('sales/8/'));
    expect(request.headers['Idempotency-Key'], key);
    final body = Map<String, dynamic>.from(request.data as Map);
    expect(body['items'], hasLength(2));
    expect((body['items'] as List).first['packaging_id'], 6);
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
      final path when path.endsWith('/sales/8/') => {
        ...common,
        'invoice_number': 'FAC-8',
        'ticket_number': 'TCK-8',
        'client': 2,
        'client_details': {'id': 2, 'name': 'Client'},
        'lines': const [],
        'payments': const [],
        'capabilities': const {},
      },
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
