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
}
