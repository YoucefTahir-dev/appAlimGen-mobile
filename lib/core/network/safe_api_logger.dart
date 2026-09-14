import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

class SafeApiLogger extends Interceptor {
  static const _startedAtKey = 'safe_log_started_at';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startedAtKey] = DateTime.now().microsecondsSinceEpoch;
    if (kDebugMode) {
      debugPrint('[API] ${options.method} ${options.uri.path}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
        '[API] ${response.requestOptions.method} '
        '${response.requestOptions.uri.path} ${response.statusCode} '
        '${_duration(response.requestOptions)}ms',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
        '[API] ${err.requestOptions.method} ${err.requestOptions.uri.path} '
        '${err.response?.statusCode ?? err.type.name} '
        '${_duration(err.requestOptions)}ms',
      );
    }
    handler.next(err);
  }

  int _duration(RequestOptions options) {
    final startedAt = options.extra[_startedAtKey] as int?;
    if (startedAt == null) return 0;
    return ((DateTime.now().microsecondsSinceEpoch - startedAt) / 1000).round();
  }
}
