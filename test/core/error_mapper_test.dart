import 'package:app_alim_gen_mobile/core/errors/app_failure.dart';
import 'package:app_alim_gen_mobile/core/errors/error_mapper.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = ErrorMapper();
  test('préserve le code stable TOKEN_REVOKED', () {
    final request = RequestOptions(path: '/auth/me/');
    final failure = mapper.map(
      DioException(
        requestOptions: request,
        response: Response(
          requestOptions: request,
          statusCode: 401,
          data: {
            'success': false,
            'error': {'code': 'TOKEN_REVOKED', 'message': 'Révoqué'},
          },
        ),
      ),
    );
    expect(failure.kind, FailureKind.authentication);
    expect(failure.isTokenRevoked, isTrue);
  });

  test('différencie réseau et délai dépassé', () {
    final request = RequestOptions(path: '/dashboard/');
    expect(
      mapper
          .map(
            DioException(
              requestOptions: request,
              type: DioExceptionType.connectionError,
            ),
          )
          .kind,
      FailureKind.network,
    );
    expect(
      mapper
          .map(
            DioException(
              requestOptions: request,
              type: DioExceptionType.receiveTimeout,
            ),
          )
          .kind,
      FailureKind.timeout,
    );
  });

  test('distingue les principaux statuts HTTP', () {
    const expected = <int, FailureKind>{
      400: FailureKind.validation,
      401: FailureKind.authentication,
      403: FailureKind.permission,
      404: FailureKind.notFound,
      405: FailureKind.methodNotAllowed,
      409: FailureKind.conflict,
      500: FailureKind.server,
      503: FailureKind.server,
    };
    for (final entry in expected.entries) {
      final request = RequestOptions(path: '/sales/8/');
      final failure = mapper.map(
        DioException(
          requestOptions: request,
          response: Response(requestOptions: request, statusCode: entry.key),
        ),
      );
      expect(failure.kind, entry.value, reason: 'HTTP ${entry.key}');
      expect(failure.statusCode, entry.key);
    }
  });

  test('ne confond plus erreur interne et indisponibilité temporaire', () {
    AppFailure failureFor(int status) {
      final request = RequestOptions(path: '/sales/8/');
      return mapper.map(
        DioException(
          requestOptions: request,
          response: Response(requestOptions: request, statusCode: status),
        ),
      );
    }

    expect(
      failureFor(500).message,
      'Une erreur interne du serveur est survenue.',
    );
    expect(
      failureFor(503).message,
      'Le serveur est momentanément indisponible.',
    );
  });
}
