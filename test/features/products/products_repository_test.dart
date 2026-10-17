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
    'unit_mode': 'carton_and_piece',
    'conditionnements': [
      {
        'id': 12,
        'name': 'Carton',
        'kind': 'carton',
        'conversion_factor': 24,
        'reference_purchase_price': '200.00',
        'super_wholesale_price': '230.00',
        'wholesale_price': '240.00',
        'retail_price': '260.00',
        'is_active': true,
      },
    ],
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
    final product = await repository.create(_request);
    expect(product.reference, 'PRD-2026-000007');
    expect(product.unitMode, 'carton_and_piece');
    expect(product.packagings.single.conversionFactor, 24);
  });
  test('creates a carton packaging via POST', () async {
    const carton = ProductPackagingWriteRequest(
      productId: 7,
      name: 'Carton',
      conversionFactor: 24,
      referencePurchasePrice: '200.00',
      superWholesalePrice: '230.00',
      wholesalePrice: '240.00',
      retailPrice: '260.00',
    );
    adapter.onPost(
      'packagings/',
      (server) => server.reply(201, {
        'success': true,
        'data': (_product()['data'] as Map)['conditionnements'][0],
      }),
      data: carton.toJson(),
    );

    final saved = await repository.saveCarton(carton);

    expect(saved.kind, 'carton');
    expect(saved.conversionFactor, 24);
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

  test(
    'prévisualise puis confirme une conversion de stock historique',
    () async {
      adapter.onGet(
        'products/7/historical-conversion-preview/',
        (server) => server.reply(200, {
          'success': true,
          'data': {
            'factor': 24,
            'depot_cartons_before': 7,
            'depot_pieces_after': 168,
            'minimum_cartons_before': 2,
            'minimum_pieces_after': 48,
            'eligible': true,
            'blockers': const [],
            'operator_locations': const [],
          },
        }),
        queryParameters: {'factor': 24},
      );
      adapter.onPost(
        'products/7/historical-conversion/',
        (server) => server.reply(201, {
          'success': true,
          'data': {
            'created': true,
            'conversion_id': 3,
            'product': _product()['data'],
          },
        }),
        data: {
          'factor': 24,
          'backup_reference': 'backup-2026-10-17',
          'confirm': true,
        },
      );

      final preview = await repository.previewHistoricalConversion(7, 24);
      expect(preview.eligible, isTrue);
      expect(preview.depotAfter, 168);
      final product = await repository.applyHistoricalConversion(
        productId: 7,
        factor: 24,
        backupReference: 'backup-2026-10-17',
      );
      expect(product.id, 7);
    },
  );

  test('transmet l’inventaire physique lors d’une correction', () async {
    adapter.onPost(
      'products/7/conditioning-correction/',
      (server) => server.reply(200, {
        'success': true,
        'data': {'correction_id': 4, 'product': _product()['data']},
      }),
      data: {
        'new_factor': 30,
        'reason': 'Comptage réel',
        'confirm': true,
        'physical_depot_quantity': 210,
        'physical_operator_quantities': {'9': 60},
      },
    );

    final product = await repository.correctConditioning(
      productId: 7,
      factor: 30,
      reason: 'Comptage réel',
      physicalDepotQuantity: 210,
      physicalOperatorQuantities: const {9: 60},
    );
    expect(product.id, 7);
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
