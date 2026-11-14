import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:app_alim_gen_mobile/core/errors/app_failure.dart';
import 'package:app_alim_gen_mobile/core/errors/error_mapper.dart';
import 'package:app_alim_gen_mobile/core/network/api_client.dart';
import 'package:app_alim_gen_mobile/core/network/session_events.dart';
import 'package:app_alim_gen_mobile/core/session/session_boundary.dart';
import 'package:app_alim_gen_mobile/core/storage/token_storage.dart';
import 'package:app_alim_gen_mobile/features/business_lists/data/business_repositories.dart';
import 'package:app_alim_gen_mobile/features/business_lists/domain/business_entities.dart';
import 'package:app_alim_gen_mobile/features/loading_orders/data/loading_orders_repository.dart';
import 'package:app_alim_gen_mobile/features/receivables/data/receivables_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter({this.expireFirst = false, this.refreshResponse = false});
  final bool expireFirst;
  final bool refreshResponse;
  final requests = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (expireFirst && requests.length == 1) {
      return ResponseBody.fromString(
        jsonEncode({
          'success': false,
          'error': {'code': 'TOKEN_EXPIRED'},
        }),
        401,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    if (refreshResponse) {
      return ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'data': {
            'access': 'synthetic-user-A-refreshed',
            'refresh': 'synthetic-refresh-A-renewed',
          },
        }),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    return ResponseBody.fromString(
      jsonEncode({
        'success': true,
        'data': {
          'id': 7,
          'number': 'SYNTHETIC-7',
          'status': 'in_progress',
          'created_at': '2026-11-12T10:30:00Z',
          'client': 2,
          'supplier': 3,
          'reference': 'SYNTHETIC',
          'invoice_number': 'SYNTHETIC',
          'amount': '25.00',
          'payment_type': 'cash',
          'total': '100.00',
          'payment_status': 'unpaid',
          'payments': const [],
          'lines': const [],
        },
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _DelayedStorage extends MemoryTokenStorage {
  final entered = Completer<void>();
  final release = Completer<void>();
  @override
  Future<StoredTokens?> read() async {
    entered.complete();
    await release.future;
    return value;
  }
}

Future<dynamic> _request(String action, Dio dio, CancelToken token) {
  final orders = LoadingOrdersRepository(dio, const ErrorMapper());
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
  return switch (action) {
    'sale-create' => SalesRepository(
      dio,
      const ErrorMapper(),
    ).create(sale, 'synthetic-intent', cancelToken: token),
    'sale-update' => SalesRepository(
      dio,
      const ErrorMapper(),
    ).update(7, sale, 'synthetic-intent', cancelToken: token),
    'purchase-create' => PurchasesRepository(
      dio,
      const ErrorMapper(),
    ).create(purchase, 'synthetic-intent', cancelToken: token),
    'purchase-update' => PurchasesRepository(
      dio,
      const ErrorMapper(),
    ).update(7, purchase, 'synthetic-intent', cancelToken: token),
    'payment-create' => PaymentsRepository(dio, const ErrorMapper()).create(
      const PaymentWriteRequest(
        saleId: 2,
        amount: '25.00',
        paymentType: 'cash',
      ),
      'synthetic-intent',
      cancelToken: token,
    ),
    'validate' => orders.validateLoadingOrder(
      7,
      'synthetic-intent',
      cancelToken: token,
    ),
    'close' => orders.closeLoadingOrder(
      7,
      'synthetic-intent',
      cancelToken: token,
    ),
    'cancel' => orders.cancelLoadingOrder(7, cancelToken: token),
    _ => ReceivablesRepository(dio, const ErrorMapper()).allocatePayment(
      clientId: 2,
      amount: '25.00',
      paymentType: 'cash',
      idempotencyKey: 'synthetic-intent',
      cancelToken: token,
    ),
  };
}

void main() {
  test(
    'transparent token refresh preserves the financial intention session',
    () async {
      final adapter = _Adapter(expireFirst: true);
      final refreshAdapter = _Adapter(refreshResponse: true);
      final dio = Dio(BaseOptions(baseUrl: 'https://synthetic.invalid/api/v1/'))
        ..httpClientAdapter = adapter;
      final refresh = Dio(
        BaseOptions(baseUrl: 'https://synthetic.invalid/api/v1/'),
      )..httpClientAdapter = refreshAdapter;
      final boundary = SessionBoundary();
      final originalEpoch = boundary.generation;
      final originalToken = boundary.cancelToken;
      final events = SessionEvents();
      final storage = MemoryTokenStorage()
        ..value = const StoredTokens(
          access: 'synthetic-user-A',
          refresh: 'synthetic-refresh-A',
        );
      ApiClient(
        dio: dio,
        refreshDio: refresh,
        storage: storage,
        sessionEvents: events,
        sessionBoundary: boundary,
      );
      await _request('sale-create', dio, originalToken);
      expect(adapter.requests, hasLength(2));
      expect(refreshAdapter.requests, hasLength(1));
      expect(boundary.generation, originalEpoch);
      expect(identical(boundary.cancelToken, originalToken), isTrue);
      expect(originalToken.isCancelled, isFalse);
      expect(
        adapter.requests.map((request) => request.cancelToken),
        everyElement(same(originalToken)),
      );
      expect(
        adapter.requests.map((request) => request.headers['Idempotency-Key']),
        everyElement('synthetic-intent'),
      );
      expect(
        adapter.requests.map(
          (request) => request.headers['Idempotency-Policy'],
        ),
        everyElement('required-v1'),
      );
      expect(adapter.requests.first.data, adapter.requests.last.data);
      expect(storage.value?.access, 'synthetic-user-A-refreshed');
      dio.close(force: true);
      refresh.close(force: true);
      events.dispose();
    },
  );

  const actions = [
    'validate',
    'close',
    'cancel',
    'allocate',
    'sale-create',
    'sale-update',
    'purchase-create',
    'purchase-update',
    'payment-create',
  ];
  for (final action in actions) {
    test(
      '$action never sends an old body if the session rotates during token storage read',
      () async {
        final adapter = _Adapter();
        final dio = Dio(
          BaseOptions(baseUrl: 'https://synthetic.invalid/api/v1/'),
        )..httpClientAdapter = adapter;
        final refresh = Dio()..httpClientAdapter = adapter;
        final boundary = SessionBoundary();
        final events = SessionEvents();
        final storage = _DelayedStorage()
          ..value = const StoredTokens(
            access: 'synthetic-user-A',
            refresh: 'synthetic-refresh-A',
          );
        ApiClient(
          dio: dio,
          refreshDio: refresh,
          storage: storage,
          sessionEvents: events,
          sessionBoundary: boundary,
        );
        final originalToken = boundary.cancelToken;
        final response = _request(action, dio, originalToken);
        final result = expectLater(response, throwsA(isA<AppFailure>()));
        await storage.entered.future;
        boundary.rotate();
        storage.value = const StoredTokens(
          access: 'synthetic-user-B',
          refresh: 'synthetic-refresh-B',
        );
        storage.release.complete();
        await result;
        await Future<void>.delayed(Duration.zero);
        expect(originalToken.isCancelled, isTrue);
        expect(adapter.requests, isEmpty);
        dio.close(force: true);
        refresh.close(force: true);
        events.dispose();
      },
    );
  }
  for (final action in actions) {
    test(
      '$action pins the original token before the asynchronous auth interceptor',
      () async {
        final adapter = _Adapter();
        final dio = Dio(
          BaseOptions(baseUrl: 'https://synthetic.invalid/api/v1/'),
        )..httpClientAdapter = adapter;
        final refresh = Dio()..httpClientAdapter = adapter;
        final boundary = SessionBoundary();
        final events = SessionEvents();
        final storage = MemoryTokenStorage()
          ..value = const StoredTokens(
            access: 'synthetic-user-A',
            refresh: 'synthetic-refresh-A',
          );
        ApiClient(
          dio: dio,
          refreshDio: refresh,
          storage: storage,
          sessionEvents: events,
          sessionBoundary: boundary,
        );
        final entered = Completer<void>();
        final release = Completer<void>();
        dio.interceptors.insert(
          0,
          InterceptorsWrapper(
            onRequest: (options, handler) async {
              entered.complete();
              await release.future;
              handler.next(options);
            },
          ),
        );
        final originalToken = boundary.cancelToken;
        final response = _request(action, dio, originalToken);
        final result = expectLater(response, throwsA(isA<AppFailure>()));
        await entered.future;
        boundary.rotate();
        storage.value = const StoredTokens(
          access: 'synthetic-user-B',
          refresh: 'synthetic-refresh-B',
        );
        release.complete();
        await result;
        await Future<void>.delayed(Duration.zero);
        expect(originalToken.isCancelled, isTrue);
        expect(
          adapter.requests,
          isEmpty,
          reason:
              'An old intent must never reach the transport with the next user token.',
        );
        dio.close(force: true);
        refresh.close(force: true);
        events.dispose();
      },
    );
  }

  test(
    'a current-session control reaches only the synthetic transport normally',
    () async {
      final adapter = _Adapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://synthetic.invalid/api/v1/'))
        ..httpClientAdapter = adapter;
      final refresh = Dio()..httpClientAdapter = adapter;
      final boundary = SessionBoundary();
      final events = SessionEvents();
      final storage = MemoryTokenStorage()
        ..value = const StoredTokens(
          access: 'synthetic-user-A',
          refresh: 'synthetic-refresh-A',
        );
      ApiClient(
        dio: dio,
        refreshDio: refresh,
        storage: storage,
        sessionEvents: events,
        sessionBoundary: boundary,
      );
      for (final action in actions) {
        await _request(action, dio, boundary.cancelToken);
      }
      expect(adapter.requests, hasLength(actions.length));
      expect(
        adapter.requests.map((request) => request.headers['Authorization']),
        everyElement('Bearer synthetic-user-A'),
      );
      dio.close(force: true);
      refresh.close(force: true);
      events.dispose();
    },
  );
}
