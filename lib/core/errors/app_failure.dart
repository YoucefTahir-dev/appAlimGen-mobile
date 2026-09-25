enum FailureKind {
  validation,
  authentication,
  permission,
  notFound,
  methodNotAllowed,
  conflict,
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
  Map<String, String> get fieldErrors {
    final value = details;
    if (value is! Map) return const {};
    return value.map((key, messages) {
      final message = messages is List
          ? messages.map((item) => item.toString()).join(' ')
          : messages.toString();
      return MapEntry(key.toString(), message);
    });
  }

  @override
  String toString() => 'AppFailure($code, $kind)';
}
