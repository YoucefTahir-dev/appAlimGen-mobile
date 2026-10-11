import 'dart:async';

import 'package:app_alim_gen_mobile/core/network/api_envelope.dart';
import 'package:app_alim_gen_mobile/core/session/session_boundary.dart';
import 'package:app_alim_gen_mobile/core/storage/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this._dio,
    required this._refreshDio,
    required this._storage,
    required this._sessionBoundary,
    required this._onSessionExpired,
  });

  final Dio _dio;
  final Dio _refreshDio;
  final TokenStorage _storage;
  final SessionBoundary _sessionBoundary;
  final void Function() _onSessionExpired;
  Future<String?>? _refreshInFlight;
  int? _refreshGeneration;
  static const _retriedKey = 'auth_retried';
  static const _sessionGenerationKey = 'auth_session_generation';

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.extra[_sessionGenerationKey] = _sessionBoundary.generation;
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
    final requestGeneration =
        request.extra[_sessionGenerationKey] as int? ?? -1;
    if (!_sessionBoundary.isCurrent(requestGeneration)) {
      handler.next(err);
      return;
    }
    if (err.response?.statusCode != 401 ||
        request.extra[_retriedKey] == true ||
        _isPublicPath(request.path)) {
      handler.next(err);
      return;
    }
    if (_apiErrorCode(err.response?.data) == 'TOKEN_REVOKED') {
      await _expireSession(requestGeneration);
      handler.next(err);
      return;
    }

    String? access;
    try {
      access = await _singleFlightRefresh(requestGeneration);
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

  Future<String?> _singleFlightRefresh(int sessionGeneration) {
    final current = _refreshInFlight;
    if (current != null && _refreshGeneration == sessionGeneration) {
      return current;
    }
    final future = _refresh(sessionGeneration);
    _refreshInFlight = future;
    _refreshGeneration = sessionGeneration;
    return future.whenComplete(() {
      if (identical(_refreshInFlight, future)) {
        _refreshInFlight = null;
        _refreshGeneration = null;
      }
    });
  }

  Future<String?> _refresh(int sessionGeneration) async {
    if (!_sessionBoundary.isCurrent(sessionGeneration)) return null;
    final stored = await _storage.read();
    if (stored == null) {
      await _expireSession(sessionGeneration);
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
      if (!_sessionBoundary.isCurrent(sessionGeneration)) return null;
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
        await _expireSession(sessionGeneration);
        return null;
      }
      rethrow;
    } on FormatException {
      await _expireSession(sessionGeneration);
      return null;
    }
  }

  Future<void> _expireSession(int sessionGeneration) async {
    if (!_sessionBoundary.isCurrent(sessionGeneration)) return;
    await _storage.clear();
    if (!_sessionBoundary.isCurrent(sessionGeneration)) return;
    _onSessionExpired();
  }

  bool _isPublicPath(String path) =>
      path.endsWith('auth/login/') ||
      path.endsWith('auth/refresh/') ||
      path.endsWith('auth/password-reset/request/') ||
      path.endsWith('auth/password-reset/confirm/') ||
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
