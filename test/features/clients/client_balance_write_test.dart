import 'dart:convert';
import 'dart:typed_data';

import 'package:app_alim_gen_mobile/app/providers.dart';
import 'package:app_alim_gen_mobile/core/errors/error_mapper.dart';
import 'package:app_alim_gen_mobile/features/clients/data/clients_repository.dart';
import 'package:app_alim_gen_mobile/features/clients/domain/client_summary.dart';
import 'package:app_alim_gen_mobile/features/clients/presentation/client_form_screen.dart';
import 'package:app_alim_gen_mobile/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _request = ClientWriteRequest(
  name: 'Synthetic customer',
  phone: '0000',
  address: 'Synthetic address',
  wilaya: '',
  customerType: 'RETAIL',
  email: '',
  taxNumber: '',
  balance: '150.00',
  notes: 'Synthetic profile',
);
const _details = ClientDetails(
  id: 7,
  name: 'Synthetic customer',
  phone: '0000',
  address: 'Synthetic address',
  wilaya: '',
  customerType: 'RETAIL',
  email: '',
  taxNumber: '',
  balance: '150.00',
  notes: 'Synthetic profile',
);

class _Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode({
        'success': true,
        'data': {'id': 7, ..._request.toJson()},
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _Clients extends ClientsRepository {
  _Clients() : super(Dio(), const ErrorMapper());
  @override
  Future<ClientDetails> get(int id) async => _details;
}

Widget _app({int? clientId}) => ProviderScope(
  overrides: [clientsRepositoryProvider.overrideWithValue(_Clients())],
  child: MaterialApp(
    locale: const Locale('fr'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: ClientFormScreen(clientId: clientId),
  ),
);
Finder _balance(String value) => find.byWidgetPredicate(
  (widget) => widget is TextFormField && widget.controller?.text == value,
);

void main() {
  test(
    'the initial balance remains part of the creation payload only',
    () async {
      final adapter = _Adapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://synthetic.invalid/api/v1/'))
        ..httpClientAdapter = adapter;
      final repository = ClientsRepository(dio, const ErrorMapper());
      await repository.create(_request);
      await repository.update(7, _request);
      expect(adapter.requests.map((request) => request.method), [
        'POST',
        'PATCH',
      ]);
      final created = Map<String, dynamic>.from(
        adapter.requests.first.data as Map,
      );
      final updated = Map<String, dynamic>.from(
        adapter.requests.last.data as Map,
      );
      expect(created['balance'], '150.00');
      expect(updated, isNot(contains('balance')));
      expect(updated['name'], 'Synthetic customer');
      expect(updated['notes'], 'Synthetic profile');
      expect(_request.toJson()['balance'], '150.00');
      expect(_request.toJson(includeBalance: false), updated);
    },
  );

  testWidgets('editing displays the current debt as read only', (tester) async {
    await tester.pumpWidget(_app(clientId: 7));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      _balance('150.00'),
      350,
      scrollable: find.byType(Scrollable).first,
    );
    final field = tester.widget<TextField>(
      find.descendant(of: _balance('150.00'), matching: find.byType(TextField)),
    );
    expect(field.readOnly, isTrue);
    expect(field.controller!.text, '150.00');
  });

  testWidgets('creation still allows entering the agreed initial debt', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      _balance('0.00'),
      350,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      tester
          .widget<TextField>(
            find.descendant(
              of: _balance('0.00'),
              matching: find.byType(TextField),
            ),
          )
          .readOnly,
      isFalse,
    );
    await tester.enterText(_balance('0.00'), '150.00');
    expect(_balance('150.00'), findsOneWidget);
  });
}
