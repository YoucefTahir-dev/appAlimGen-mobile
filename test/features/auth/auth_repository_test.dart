import 'package:app_alim_gen_mobile/core/errors/app_failure.dart';
import 'package:app_alim_gen_mobile/core/storage/token_storage.dart';
import 'package:app_alim_gen_mobile/features/auth/data/auth_repository.dart';
import 'package:app_alim_gen_mobile/features/auth/data/session_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

Map<String, dynamic> envelope(Map<String, dynamic> data) => {
  'success': true,
  'data': data,
};

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late MemoryTokenStorage storage;
  late AuthRepository repository;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1/'));
    adapter = DioAdapter(dio: dio);
    storage = MemoryTokenStorage();
    repository = AuthRepository(dio: dio, session: SessionRepository(storage));
  });

  test('login stocke les tokens puis charge /me', () async {
    adapter.onPost(
      'auth/login/',
      (server) =>
          server.reply(200, envelope({'access': 'a1', 'refresh': 'r1'})),
      data: {'username': 'admin', 'password': 'secret'},
    );
    adapter.onGet(
      'auth/me/',
      (server) => server.reply(
        200,
        envelope({
          'id': 1,
          'username': 'admin',
          'first_name': 'Admin',
          'last_name': '',
          'email': '',
          'phone': '',
          'role': 'Administrateur',
          'permissions': ['accounts.view_dashboard'],
        }),
      ),
    );
    final result = await repository.login(
      username: 'admin',
      password: 'secret',
    );
    expect(result.user.username, 'admin');
    expect((await storage.read())?.refresh, 'r1');
  });

  test('login invalide remonte une erreur typée et ne stocke rien', () async {
    adapter.onPost(
      'auth/login/',
      (server) => server.reply(401, {
        'success': false,
        'error': {
          'code': 'AUTHENTICATION_REQUIRED',
          'message': 'Identifiants invalides',
        },
      }),
    );
    await expectLater(
      repository.login(username: 'bad', password: 'bad'),
      throwsA(isA<AppFailure>()),
    );
    expect(await storage.read(), isNull);
  });

  test('logout efface toujours la session même si le réseau échoue', () async {
    await storage.write(const StoredTokens(access: 'a', refresh: 'r'));
    adapter.onPost(
      'auth/logout/',
      (server) => server.throws(
        503,
        DioException(requestOptions: RequestOptions(path: 'auth/logout/')),
      ),
    );
    await repository.logout();
    expect(await storage.read(), isNull);
  });

  test('me expose TOKEN_REVOKED comme erreur structurée', () async {
    adapter.onGet(
      'auth/me/',
      (server) => server.reply(401, {
        'success': false,
        'error': {'code': 'TOKEN_REVOKED', 'message': 'Session révoquée'},
      }),
    );
    await expectLater(
      repository.me(),
      throwsA(
        isA<AppFailure>().having(
          (error) => error.isTokenRevoked,
          'isTokenRevoked',
          isTrue,
        ),
      ),
    );
  });
}
