import 'package:app_alim_gen_mobile/core/errors/app_failure.dart';
import 'package:app_alim_gen_mobile/core/errors/error_mapper.dart';
import 'package:app_alim_gen_mobile/features/products/data/products_repository.dart';
import 'package:app_alim_gen_mobile/features/products/domain/product_summary.dart';
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

Map<String, dynamic> _product({String name = 'Produit test'}) => {
  'success': true,
  'data': {
    'id': 7,
    'reference': 'PRD-2026-000007',
    'barcode': 'BC-PRD-2026-000007',
    'name': name,
    'category': null,
    'brand': null,
    'unit': null,
    'purchase_price': '10.00',
    'super_wholesale_price': '11.00',
    'wholesale_price': '12.00',
    'retail_price': '13.00',
    'quantity': 2,
    'minimum_stock': 1,
    'description': '',
  },
};

const _request = ProductWriteRequest(
  name: 'Produit test',
  purchasePrice: '10.00',
  superWholesalePrice: '11.00',
  wholesalePrice: '12.00',
  retailPrice: '13.00',
  quantity: 2,
  minimumStock: 1,
  description: '',
);

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

  test('convertit un timeout en erreur structurée', () async {
    adapter.onGet(
      'products/',
      (server) => server.throws(
        0,
        DioException(
          requestOptions: RequestOptions(path: 'products/'),
          type: DioExceptionType.receiveTimeout,
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
          FailureKind.timeout,
        ),
      ),
    );
  });

  test('rejette un JSON qui ne respecte pas l’enveloppe paginée', () async {
    adapter.onGet(
      'products/',
      (server) => server.reply(200, {'unexpected': true}),
      queryParameters: {'page': 1, 'page_size': 25},
    );

    await expectLater(
      repository.fetch(page: 1),
      throwsA(
        isA<AppFailure>().having(
          (failure) => failure.kind,
          'kind',
          FailureKind.unknown,
        ),
      ),
    );
  });

  test('crée un produit via POST', () async {
    adapter.onPost(
      'products/',
      (server) => server.reply(201, _product()),
      data: _request.toJson(),
    );
    expect((await repository.create(_request)).reference, 'PRD-2026-000007');
  });
  test('modifie un produit via PATCH', () async {
    adapter.onPatch(
      'products/7/',
      (server) => server.reply(200, _product(name: 'Modifié')),
      data: _request.toJson(),
    );
    expect((await repository.update(7, _request)).name, 'Modifié');
  });
  test('supprime un produit via DELETE', () async {
    adapter.onDelete('products/7/', (server) => server.reply(204, null));
    await repository.delete(7);
  });
  test('expose les erreurs de validation champ par champ', () async {
    adapter.onPost(
      'products/',
      (server) => server.reply(400, {
        'success': false,
        'error': {
          'code': 'VALIDATION_ERROR',
          'message': 'Données invalides.',
          'details': {
            'name': ['Ce champ est obligatoire.'],
          },
        },
      }),
      data: _request.toJson(),
    );
    await expectLater(
      repository.create(_request),
      throwsA(
        isA<AppFailure>().having(
          (f) => f.fieldErrors['name'],
          'name',
          'Ce champ est obligatoire.',
        ),
      ),
    );
  });
  for (final entry in const [
    (403, FailureKind.permission),
    (404, FailureKind.notFound),
    (409, FailureKind.conflict),
    (500, FailureKind.server),
  ]) {
    test('mutation HTTP ${entry.$1} correctement typée', () async {
      adapter.onPost(
        'products/',
        (server) => server.reply(entry.$1, {
          'success': false,
          'error': {'code': 'ERROR', 'message': 'Refus'},
        }),
        data: _request.toJson(),
      );
      await expectLater(
        repository.create(_request),
        throwsA(isA<AppFailure>().having((f) => f.kind, 'kind', entry.$2)),
      );
    });
  }
  test('timeout de mutation correctement typé', () async {
    adapter.onPost(
      'products/',
      (server) => server.throws(
        0,
        DioException(
          requestOptions: RequestOptions(path: 'products/'),
          type: DioExceptionType.receiveTimeout,
        ),
      ),
      data: _request.toJson(),
    );
    await expectLater(
      repository.create(_request),
      throwsA(
        isA<AppFailure>().having((f) => f.kind, 'kind', FailureKind.timeout),
      ),
    );
  });
}
