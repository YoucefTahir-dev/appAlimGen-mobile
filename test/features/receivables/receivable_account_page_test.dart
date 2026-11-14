import 'package:app_alim_gen_mobile/core/errors/app_failure.dart';
import 'package:app_alim_gen_mobile/core/errors/error_mapper.dart';
import 'package:app_alim_gen_mobile/features/receivables/data/receivables_repository.dart';
import 'package:app_alim_gen_mobile/features/receivables/domain/receivable.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

import 'receivable_page_fixture.dart';

void main() {
  test(
    'three independent pages use a single bounded request with global totals',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid/api/v1/'));
      final adapter = DioAdapter(dio: dio);
      var calls = 0;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            calls++;
            expect(request.path, 'receivables/7/account-page/');
            handler.next(request);
          },
        ),
      );
      adapter.onGet(
        'receivables/7/account-page/',
        (server) => server.reply(200, {
          'success': true,
          'data': accountPageFixture(page: 2, paymentsPage: 3, openingPage: 2),
        }),
        queryParameters: {
          'page': 2,
          'payments_page': 3,
          'opening_page': 2,
          'page_size': 25,
        },
      );
      final account = await ReceivablesRepository(
        dio,
        const ErrorMapper(),
      ).getAccount(7, page: 2, paymentsPage: 3, openingPage: 2);
      expect(calls, 1);
      expect(account.invoices.single.number, 'SYNTH-INVOICE-26');
      expect(account.payments, hasLength(2));
      expect(account.payments.last.openingBalance, isTrue);
      expect(account.totalInvoiced, '10000.00');
      expect(account.balanceDue, '9000.00');
      expect(account.invoicePage!.hasNext, isFalse);
      expect(account.paymentPage!.page, 3);
      expect(account.openingPaymentPage!.page, 2);
    },
  );

  test(
    'unknown contract, unbounded histories and invalid metadata fail closed',
    () {
      final invalid = <Map<String, dynamic>>[
        {...accountPageFixture(), 'contract': null},
        {...accountPageFixture(), 'pagination': null},
        {
          ...accountPageFixture(),
          'invoices': List.filled(26, {'id': 1}),
        },
      ];
      for (final payload in invalid) {
        expect(
          () => ReceivableAccount.fromPagedJson(payload),
          throwsFormatException,
        );
      }
      final payload = accountPageFixture();
      ((payload['pagination'] as Map)['invoices'] as Map)['has_next'] = false;
      expect(
        () => ReceivableAccount.fromPagedJson(payload),
        throwsFormatException,
      );
    },
  );

  test(
    'shorter pages tolerate concurrent changes without losing global totals',
    () {
      final payload = accountPageFixture();
      payload['payments'] = <dynamic>[];
      final account = ReceivableAccount.fromPagedJson(payload);
      expect(
        account.payments.where((payment) => !payment.openingBalance),
        isEmpty,
      );
      expect(account.paymentPage!.count, 51);
      expect(account.paymentPage!.hasNext, isTrue);
      expect(account.balanceDue, '9000.00');
    },
  );

  test(
    'old servers and forbidden accounts never trigger legacy retrieval',
    () async {
      for (final status in [401, 403, 404, 405, 500]) {
        final dio = Dio(
          BaseOptions(baseUrl: 'https://example.invalid/api/v1/'),
        );
        final adapter = DioAdapter(dio: dio);
        final paths = <String>[];
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (request, handler) {
              paths.add(request.path);
              handler.next(request);
            },
          ),
        );
        adapter.onGet(
          'receivables/7/account-page/',
          (server) => server.reply(status, {}),
          queryParameters: {
            'page': 1,
            'payments_page': 1,
            'opening_page': 1,
            'page_size': 25,
          },
        );
        await expectLater(
          ReceivablesRepository(dio, const ErrorMapper()).getAccount(7),
          throwsA(
            isA<AppFailure>().having(
              (error) => error.statusCode,
              'status',
              status,
            ),
          ),
        );
        expect(paths, ['receivables/7/account-page/']);
      }
    },
  );

  test('invalid requested pages perform no network I/O', () async {
    final dio = Dio();
    var calls = 0;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          calls++;
          handler.reject(DioException(requestOptions: request));
        },
      ),
    );
    await expectLater(
      ReceivablesRepository(dio, const ErrorMapper()).getAccount(7, page: 0),
      throwsA(isA<AppFailure>()),
    );
    expect(calls, 0);
  });
}
