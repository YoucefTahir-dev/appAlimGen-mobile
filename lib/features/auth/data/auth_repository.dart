import 'package:app_alim_gen_mobile/core/errors/app_failure.dart';
import 'package:app_alim_gen_mobile/core/errors/error_mapper.dart';
import 'package:app_alim_gen_mobile/core/network/api_envelope.dart';
import 'package:app_alim_gen_mobile/core/storage/token_storage.dart';
import 'package:app_alim_gen_mobile/features/auth/data/session_repository.dart';
import 'package:app_alim_gen_mobile/features/auth/domain/auth_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class AuthRepository {
  AuthRepository({
    required this._dio,
    required this._session,
    ErrorMapper errorMapper = const ErrorMapper(),
  }) : _errors = errorMapper;
  final Dio _dio;
  final SessionRepository _session;
  final ErrorMapper _errors;

  Future<LoginResult> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        'auth/login/',
        data: {'username': username.trim(), 'password': password},
      );
      final data = ApiEnvelope.object(response.data);
      final access = data['access']?.toString() ?? '';
      final refresh = data['refresh']?.toString() ?? '';
      if (access.isEmpty || refresh.isEmpty) {
        throw const FormatException('Tokens absents.');
      }
      final tokens = StoredTokens(access: access, refresh: refresh);
      await _session.save(tokens);
      try {
        final user = await me();
        return LoginResult(tokens: tokens, user: user);
      } catch (error) {
        await _session.clear();
        rethrow;
      }
    } catch (error) {
      if (error is AppFailure) rethrow;
      throw _errors.map(error);
    }
  }

  Future<UserProfile> me() async {
    try {
      if (kDebugMode) debugPrint('[AUTH] AUTH_ME');
      final response = await _dio.get<dynamic>('auth/me/');
      return UserProfile.fromJson(ApiEnvelope.object(response.data));
    } catch (error) {
      throw _errors.map(error);
    }
  }

  Future<void> logout() async {
    final refresh = (await _session.restore())?.refresh;
    try {
      if (refresh != null) {
        await _dio.post<dynamic>('auth/logout/', data: {'refresh': refresh});
      }
    } catch (_) {
      // Logout is deliberately best effort; local credentials are always erased.
    } finally {
      await _session.clear();
    }
  }
}
