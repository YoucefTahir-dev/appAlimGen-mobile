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
        '${_duration(err.requestOptions)}ms body=${_safeBody(err.response?.data)}',
      );
    }
    handler.next(err);
  }

  int _duration(RequestOptions options) {
    final startedAt = options.extra[_startedAtKey] as int?;
    if (startedAt == null) return 0;
    return ((DateTime.now().microsecondsSinceEpoch - startedAt) / 1000).round();
  }

  String _safeBody(Object? value) {
    Object? redact(Object? item) {
      if (item is Map) {
        return item.map((key, child) {
          final normalized = key.toString().toLowerCase();
          final sensitive =
              normalized.contains('token') ||
              normalized.contains('password') ||
              normalized.contains('authorization');
          return MapEntry(key, sensitive ? '[REDACTED]' : redact(child));
        });
      }
      if (item is List) return item.map(redact).toList(growable: false);
      return item;
    }

    final text = redact(value).toString();
    return text.length <= 1000 ? text : '${text.substring(0, 1000)}…';
  }
}
