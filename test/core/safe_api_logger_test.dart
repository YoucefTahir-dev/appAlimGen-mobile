import 'dart:convert';
import 'package:app_alim_gen_mobile/core/network/safe_api_logger.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

class _Adapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    jsonEncode({
      'access': 'server-access-secret',
      'data': {'id': 8},
    }),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}

void main() {
  test('journalise le diagnostic sans aucun credential', () async {
    final lines = <String>[];
    final previous = debugPrint;
    debugPrint = (message, {wrapWidth}) {
      if (message != null) lines.add(message);
    };
    addTearDown(() => debugPrint = previous);
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1/'))
      ..httpClientAdapter = _Adapter()
      ..interceptors.add(SafeApiLogger());

    await dio.patch<dynamic>(
      'sales/8/?ignored=secret-query',
      data: const {
        'password': 'plain-password',
        'refresh': 'refresh-secret',
        'access': 'access-secret',
        'items': [
          {'product_id': 4, 'quantity': 3},
        ],
      },
      options: Options(
        headers: const {
          'Authorization': 'Bearer jwt-secret',
          'Idempotency-Key': 'operation-key',
        },
      ),
    );

    final output = lines.join('\n');
    expect(output, contains('PATCH https://example.test/api/v1/sales/8/'));
    expect(output, contains('idempotency=true'));
    expect(output, contains('product_id: 4'));
    expect(output, contains('quantity: 3'));
    expect(output, contains('body={access: [REDACTED]'));
    expect(output, isNot(contains('plain-password')));
    expect(output, isNot(contains('refresh-secret')));
    expect(output, isNot(contains('access-secret')));
    expect(output, isNot(contains('server-access-secret')));
    expect(output, isNot(contains('jwt-secret')));
    expect(output, isNot(contains('secret-query')));
  });
}
