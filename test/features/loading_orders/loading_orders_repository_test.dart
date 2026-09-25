import 'dart:convert';
import 'dart:typed_data';

import 'package:app_alim_gen_mobile/core/errors/app_failure.dart';
import 'package:app_alim_gen_mobile/core/errors/error_mapper.dart';
import 'package:app_alim_gen_mobile/features/loading_orders/data/loading_orders_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

Map<String, dynamic> _order(String status) => {
  'success': true,
  'data': {
    'id': 7,
    'number': 'CHG-0007',
    'operator': 2,
    'operator_name': 'Opérateur test',
    'status': status,
    'created_at': '2026-09-25T08:00:00Z',
    'notes': '',
    'lines': const [],
  },
};

void main() {
  test(
    'utilise POST et les URL exactes pour valider, annuler et clôturer',
    () async {
      final adapter = _CapturingAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1/'))
        ..httpClientAdapter = adapter;
      final repository = LoadingOrdersRepository(dio, const ErrorMapper());

      expect(
        (await repository.validateLoadingOrder(7, 'validate-key')).status,
        'in_progress',
      );
      expect((await repository.cancelLoadingOrder(7)).status, 'cancelled');
      expect(
        (await repository.closeLoadingOrder(7, 'close-key')).status,
        'closed',
      );

      expect(
        adapter.requests.map((request) => request.method),
        everyElement('POST'),
      );
      expect(adapter.requests.map((request) => request.uri.path), [
        '/api/v1/loading-orders/7/validate/',
        '/api/v1/loading-orders/7/cancel/',
        '/api/v1/loading-orders/7/close/',
      ]);
      expect(adapter.requests[0].headers['Idempotency-Key'], 'validate-key');
      expect(adapter.requests[1].headers['Idempotency-Key'], isNull);
      expect(adapter.requests[2].headers['Idempotency-Key'], 'close-key');
    },
  );

  for (final entry in const [
    (401, FailureKind.authentication),
    (403, FailureKind.permission),
    (405, FailureKind.methodNotAllowed),
    (409, FailureKind.conflict),
    (500, FailureKind.server),
  ]) {
    test('convertit HTTP ${entry.$1} pendant une action', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1/'));
      final adapter = DioAdapter(dio: dio);
      final repository = LoadingOrdersRepository(dio, const ErrorMapper());
      adapter.onPost(
        'loading-orders/7/cancel/',
        (server) => server.reply(entry.$1, {
          'success': false,
          'error': {'code': 'ACTION_FAILED', 'message': 'Action refusée'},
        }),
      );

      await expectLater(
        repository.cancelLoadingOrder(7),
        throwsA(
          isA<AppFailure>()
              .having((failure) => failure.kind, 'kind', entry.$2)
              .having((failure) => failure.statusCode, 'status', entry.$1),
        ),
      );
    });
  }

  test('convertit un timeout pendant une action', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1/'));
    final adapter = DioAdapter(dio: dio);
    final repository = LoadingOrdersRepository(dio, const ErrorMapper());
    adapter.onPost(
      'loading-orders/7/cancel/',
      (server) => server.throws(
        0,
        DioException(
          requestOptions: RequestOptions(path: 'loading-orders/7/cancel/'),
          type: DioExceptionType.receiveTimeout,
        ),
      ),
    );

    await expectLater(
      repository.cancelLoadingOrder(7),
      throwsA(
        isA<AppFailure>().having(
          (failure) => failure.kind,
          'kind',
          FailureKind.timeout,
        ),
      ),
    );
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
    final status = options.path.endsWith('/validate/')
        ? 'in_progress'
        : options.path.endsWith('/cancel/')
        ? 'cancelled'
        : 'closed';
    return ResponseBody.fromString(
      jsonEncode(_order(status)),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
