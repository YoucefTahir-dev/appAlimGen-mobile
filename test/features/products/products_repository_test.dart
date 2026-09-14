import 'package:app_alim_gen_mobile/core/errors/app_failure.dart';
import 'package:app_alim_gen_mobile/core/errors/error_mapper.dart';
import 'package:app_alim_gen_mobile/features/products/data/products_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

Map<String, dynamic> _page(List<Map<String, dynamic>> results, {String? next}) {
  return {
    'success': true,
    'data': {
      'count': results.length,
      'next': next,
      'previous': null,
      'results': results,
    },
  };
}

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late ProductsRepository repository;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1/'));
    adapter = DioAdapter(dio: dio);
    repository = ProductsRepository(dio, const ErrorMapper());
  });

  test('charge une page et transmet pagination et recherche', () async {
    adapter.onGet(
      'products/',
      (server) => server.reply(
        200,
        _page([
          {
            'id': 7,
            'name': 'Butane 13 kg',
            'reference': 'B13',
            'quantity': 12,
            'stock_status': 'available',
          },
        ], next: 'page=3'),
      ),
      queryParameters: {'page': 2, 'page_size': 25, 'search': 'butane'},
    );

    final page = await repository.fetch(page: 2, query: 'butane');

    expect(page.items.single.name, 'Butane 13 kg');
    expect(page.items.single.quantity, 12);
    expect(page.hasNext, isTrue);
  });

  test('accepte une page vide', () async {
    adapter.onGet(
      'products/',
      (server) => server.reply(200, _page([])),
      queryParameters: {'page': 1, 'page_size': 25},
    );

    final page = await repository.fetch(page: 1);
    expect(page.items, isEmpty);
    expect(page.hasNext, isFalse);
  });

  for (final entry in const [
    (401, FailureKind.authentication),
    (403, FailureKind.permission),
    (500, FailureKind.server),
  ]) {
    test('convertit HTTP ${entry.$1} en erreur ${entry.$2.name}', () async {
      adapter.onGet(
        'products/',
        (server) => server.reply(entry.$1, {
          'success': false,
          'error': {'code': 'API_ERROR', 'message': 'Erreur'},
        }),
        queryParameters: {'page': 1, 'page_size': 25},
      );

      await expectLater(
        repository.fetch(page: 1),
        throwsA(
          isA<AppFailure>().having((failure) => failure.kind, 'kind', entry.$2),
        ),
      );
    });
  }

  test('convertit une panne réseau en erreur structurée', () async {
    adapter.onGet(
      'products/',
      (server) => server.throws(
        0,
        DioException.connectionError(
          requestOptions: RequestOptions(path: 'products/'),
          reason: 'offline',
        ),
      ),
      queryParameters: {'page': 1, 'page_size': 25},
    );

    await expectLater(
      repository.fetch(page: 1),
      throwsA(
        isA<AppFailure>().having(
          (failure) => failure.kind,
          'kind',
          FailureKind.network,
        ),
      ),
    );
  });
}
