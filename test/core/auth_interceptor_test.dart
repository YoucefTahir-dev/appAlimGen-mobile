import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:app_alim_gen_mobile/core/network/api_client.dart';
import 'package:app_alim_gen_mobile/core/network/session_events.dart';
import 'package:app_alim_gen_mobile/core/storage/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.handler);
  final Future<ResponseBody> Function(RequestOptions) handler;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => handler(options);
  @override
  void close({bool force = false}) {}
}

ResponseBody _json(int status, Map<String, dynamic> body) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

void main() {
  test(
    'deux 401 simultanés déclenchent un seul refresh puis un seul retry',
    () async {
      final storage = MemoryTokenStorage()
        ..value = const StoredTokens(access: 'old', refresh: 'refresh');
      final events = SessionEvents();
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1/'));
      final refreshDio = Dio(
        BaseOptions(baseUrl: 'https://example.test/api/v1/'),
      );
      var refreshCalls = 0;
      dio.httpClientAdapter = _Adapter((options) async {
        if (options.headers['Authorization'] == 'Bearer new') {
          return _json(200, {
            'success': true,
            'data': {'ok': true},
          });
        }
        return _json(401, {
          'success': false,
          'error': {'code': 'AUTHENTICATION_REQUIRED', 'message': 'Expired'},
        });
      });
      refreshDio.httpClientAdapter = _Adapter((_) async {
        refreshCalls++;
        await Future<void>.delayed(const Duration(milliseconds: 30));
        return _json(200, {
          'success': true,
          'data': {'access': 'new', 'refresh': 'rotated'},
        });
      });
      ApiClient(
        storage: storage,
        sessionEvents: events,
        dio: dio,
        refreshDio: refreshDio,
      );

      final responses = await Future.wait([
        dio.get<dynamic>('first/'),
        dio.get<dynamic>('second/'),
      ]);
      expect(responses.every((response) => response.statusCode == 200), isTrue);
      expect(refreshCalls, 1);
      expect(storage.value?.refresh, 'rotated');
      events.dispose();
    },
  );

  test('TOKEN_REVOKED purge les jetons et publie l’expiration', () async {
    final storage = MemoryTokenStorage()
      ..value = const StoredTokens(access: 'old', refresh: 'refresh');
    final events = SessionEvents();
    final expired = Completer<void>();
    events.expired.listen((_) => expired.complete());
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1/'));
    final refreshDio = Dio(
      BaseOptions(baseUrl: 'https://example.test/api/v1/'),
    );
    dio.httpClientAdapter = _Adapter(
      (_) async => _json(401, {
        'success': false,
        'error': {'code': 'TOKEN_REVOKED', 'message': 'Revoked'},
      }),
    );
    ApiClient(
      storage: storage,
      sessionEvents: events,
      dio: dio,
      refreshDio: refreshDio,
    );

    await expectLater(
      dio.get<dynamic>('dashboard/'),
      throwsA(isA<DioException>()),
    );
    await expired.future;
    expect(await storage.read(), isNull);
    events.dispose();
  });

  test('un refresh invalide efface la session et ne boucle pas', () async {
    final storage = MemoryTokenStorage()
      ..value = const StoredTokens(access: 'expired', refresh: 'invalid');
    final events = SessionEvents();
    final expired = Completer<void>();
    events.expired.listen((_) => expired.complete());
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1/'));
    final refreshDio = Dio(
      BaseOptions(baseUrl: 'https://example.test/api/v1/'),
    );
    var refreshCalls = 0;
    dio.httpClientAdapter = _Adapter(
      (_) async => _json(401, {
        'success': false,
        'error': {'code': 'AUTHENTICATION_REQUIRED', 'message': 'Expired'},
      }),
    );
    refreshDio.httpClientAdapter = _Adapter((_) async {
      refreshCalls++;
      return _json(401, {
        'success': false,
        'error': {'code': 'TOKEN_REVOKED', 'message': 'Revoked'},
      });
    });
    ApiClient(
      storage: storage,
      sessionEvents: events,
      dio: dio,
      refreshDio: refreshDio,
    );

    await expectLater(
      dio.get<dynamic>('products/'),
      throwsA(isA<DioException>()),
    );
    await expired.future;
    expect(refreshCalls, 1);
    expect(await storage.read(), isNull);
    events.dispose();
  });

  test(
    'un timeout de refresh conserve les jetons et ne publie pas expiration',
    () async {
      final storage = MemoryTokenStorage()
        ..value = const StoredTokens(access: 'expired', refresh: 'still-valid');
      final events = SessionEvents();
      var expired = false;
      events.expired.listen((_) => expired = true);
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1/'));
      final refreshDio = Dio(
        BaseOptions(baseUrl: 'https://example.test/api/v1/'),
      );
      var refreshCalls = 0;
      dio.httpClientAdapter = _Adapter(
        (_) async => _json(401, {
          'success': false,
          'error': {'code': 'AUTHENTICATION_REQUIRED', 'message': 'Expired'},
        }),
      );
      refreshDio.httpClientAdapter = _Adapter((options) async {
        refreshCalls++;
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.receiveTimeout,
        );
      });
      ApiClient(
        storage: storage,
        sessionEvents: events,
        dio: dio,
        refreshDio: refreshDio,
      );

      await expectLater(
        dio.get<dynamic>('auth/me/'),
        throwsA(
          isA<DioException>().having(
            (error) => error.type,
            'type',
            DioExceptionType.receiveTimeout,
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(refreshCalls, 1);
      expect(expired, isFalse);
      expect((await storage.read())?.refresh, 'still-valid');
      events.dispose();
    },
  );

  test('ajoute Bearer aux routes protégées mais jamais au login', () async {
    final storage = MemoryTokenStorage()
      ..value = const StoredTokens(access: 'secret-access', refresh: 'refresh');
    final events = SessionEvents();
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1/'));
    final refreshDio = Dio(
      BaseOptions(baseUrl: 'https://example.test/api/v1/'),
    );
    final headers = <String, Object?>{};
    dio.httpClientAdapter = _Adapter((options) async {
      headers[options.path] = options.headers['Authorization'];
      return _json(200, {
        'success': true,
        'data': {'ok': true},
      });
    });
    ApiClient(
      storage: storage,
      sessionEvents: events,
      dio: dio,
      refreshDio: refreshDio,
    );

    await dio.get<dynamic>('products/');
    await dio.post<dynamic>('auth/login/', data: const {});

    expect(headers['products/'], 'Bearer secret-access');
    expect(headers['auth/login/'], isNull);
    events.dispose();
  });
}
