import 'package:app_alim_gen_mobile/core/config/app_config.dart';
import 'package:app_alim_gen_mobile/core/network/auth_interceptor.dart';
import 'package:app_alim_gen_mobile/core/network/session_events.dart';
import 'package:app_alim_gen_mobile/core/storage/token_storage.dart';
import 'package:dio/dio.dart';

class ApiClient {
  ApiClient({
    required TokenStorage storage,
    required SessionEvents sessionEvents,
    String Function()? languageCode,
    Dio? dio,
    Dio? refreshDio,
  }) : dio = dio ?? _newDio(),
       refreshDio = refreshDio ?? _newDio() {
    this.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers['Accept-Language'] = languageCode?.call() ?? 'fr';
          handler.next(options);
        },
      ),
    );
    this.dio.interceptors.add(
      AuthInterceptor(
        dio: this.dio,
        refreshDio: this.refreshDio,
        storage: storage,
        onSessionExpired: sessionEvents.notifyExpired,
      ),
    );
  }

  final Dio dio;
  final Dio refreshDio;

  static Dio _newDio() => Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUri.toString(),
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      headers: const {'Accept': 'application/json'},
    ),
  );
}
