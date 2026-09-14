enum FailureKind {
  validation,
  authentication,
  permission,
  notFound,
  rateLimit,
  network,
  timeout,
  server,
  unknown,
}

class AppFailure implements Exception {
  const AppFailure({
    required this.kind,
    required this.code,
    required this.message,
    this.statusCode,
    this.details,
  });
  final FailureKind kind;
  final String code;
  final String message;
  final int? statusCode;
  final Object? details;
  bool get isTokenRevoked => code == 'TOKEN_REVOKED';
  @override
  String toString() => 'AppFailure($code, $kind)';
}
