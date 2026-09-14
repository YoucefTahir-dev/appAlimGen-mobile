import 'package:app_alim_gen_mobile/core/errors/app_failure.dart';
import 'package:dio/dio.dart';

class ErrorMapper {
  const ErrorMapper();
  AppFailure map(Object error) {
    if (error is AppFailure) return error;
    if (error is DioException) return _fromDio(error);
    return const AppFailure(
      kind: FailureKind.unknown,
      code: 'UNKNOWN_ERROR',
      message: 'Une erreur inattendue est survenue.',
    );
  }

  AppFailure _fromDio(DioException error) {
    if ({
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
    }.contains(error.type)) {
      return const AppFailure(
        kind: FailureKind.timeout,
        code: 'TIMEOUT',
        message: 'Le serveur met trop de temps à répondre.',
      );
    }
    if (error.type == DioExceptionType.connectionError) {
      return const AppFailure(
        kind: FailureKind.network,
        code: 'NETWORK_ERROR',
        message: 'Connexion au serveur impossible.',
      );
    }
    final status = error.response?.statusCode;
    final body = error.response?.data;
    final apiError = body is Map ? body['error'] : null;
    return AppFailure(
      kind: switch (status) {
        400 => FailureKind.validation,
        401 => FailureKind.authentication,
        403 => FailureKind.permission,
        404 => FailureKind.notFound,
        429 => FailureKind.rateLimit,
        final value when value != null && value >= 500 => FailureKind.server,
        _ => FailureKind.unknown,
      },
      code: apiError is Map && apiError['code'] != null
          ? apiError['code'].toString()
          : _defaultCode(status),
      message: apiError is Map && apiError['message'] != null
          ? apiError['message'].toString()
          : _defaultMessage(status),
      statusCode: status,
      details: apiError is Map ? apiError['details'] : null,
    );
  }

  String _defaultCode(int? status) => switch (status) {
    400 => 'VALIDATION_ERROR',
    401 => 'AUTHENTICATION_REQUIRED',
    403 => 'PERMISSION_DENIED',
    404 => 'NOT_FOUND',
    429 => 'RATE_LIMITED',
    _ => 'API_ERROR',
  };
  String _defaultMessage(int? status) => switch (status) {
    401 => 'Votre session a expiré.',
    403 => 'Vous n’avez pas la permission nécessaire.',
    429 => 'Trop de demandes. Réessayez plus tard.',
    final value when value != null && value >= 500 =>
      'Le serveur est momentanément indisponible.',
    _ => 'La demande n’a pas pu être traitée.',
  };
}
