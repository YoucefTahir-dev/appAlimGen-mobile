import 'dart:async';

import 'package:app_alim_gen_mobile/core/network/api_envelope.dart';
import 'package:app_alim_gen_mobile/core/storage/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this._dio,
    required this._refreshDio,
    required this._storage,
    required this._onSessionExpired,
  });

  final Dio _dio;
  final Dio _refreshDio;
  final TokenStorage _storage;
  final void Function() _onSessionExpired;
  Future<String?>? _refreshInFlight;
  static const _retriedKey = 'auth_retried';

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_isPublicPath(options.path)) {
      handler.next(options);
      return;
    }
    final tokens = await _storage.read();
    if (tokens != null) {
      options.headers['Authorization'] = 'Bearer ${tokens.access}';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final request = err.requestOptions;
    if (err.response?.statusCode != 401 ||
        request.extra[_retriedKey] == true ||
        _isPublicPath(request.path)) {
      handler.next(err);
      return;
    }
    if (_apiErrorCode(err.response?.data) == 'TOKEN_REVOKED') {
      await _expireSession();
      handler.next(err);
      return;
    }

    String? access;
    try {
      access = await _singleFlightRefresh();
    } on DioException catch (refreshError) {
      // Un timeout de refresh est une panne réseau, pas une révocation. Il est
      // remonté au bootstrap sans supprimer les jetons locaux.
      handler.next(refreshError);
      return;
    }
    if (access == null) {
      handler.next(err);
      return;
    }
    try {
      request.extra[_retriedKey] = true;
      request.headers['Authorization'] = 'Bearer $access';
      handler.resolve(await _dio.fetch<dynamic>(request));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  Future<String?> _singleFlightRefresh() {
    final current = _refreshInFlight;
    if (current != null) {
      return current;
    }
    final future = _refresh();
    _refreshInFlight = future;
    return future.whenComplete(() => _refreshInFlight = null);
  }

  Future<String?> _refresh() async {
    final stored = await _storage.read();
    if (stored == null) {
      await _expireSession();
      return null;
    }
    try {
      _log('TOKEN_REFRESH');
      final response = await _refreshDio.post<dynamic>(
        'auth/refresh/',
        data: {'refresh': stored.refresh},
      );
      final data = ApiEnvelope.object(response.data);
      final access = data['access']?.toString();
      if (access == null || access.isEmpty) {
        throw const FormatException('Access token absent.');
      }
      final refresh = data['refresh']?.toString();
      await _storage.write(
        StoredTokens(
          access: access,
          refresh: refresh == null || refresh.isEmpty
              ? stored.refresh
              : refresh,
        ),
      );
      return access;
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      if (status == 400 || status == 401 || status == 403) {
        await _expireSession();
        return null;
      }
      rethrow;
    } on FormatException {
      await _expireSession();
      return null;
    }
  }

  Future<void> _expireSession() async {
    await _storage.clear();
    _onSessionExpired();
  }

  bool _isPublicPath(String path) =>
      path.endsWith('auth/login/') ||
      path.endsWith('auth/refresh/') ||
      path.endsWith('healthz/') ||
      path.endsWith('readyz/');

  void _log(String event) {
    if (kDebugMode) debugPrint('[AUTH] $event');
  }

  String? _apiErrorCode(dynamic body) {
    if (body is Map && body['error'] is Map) {
      return (body['error'] as Map)['code']?.toString();
    }
    return null;
  }
}
