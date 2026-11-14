import 'dart:async';

import 'package:app_alim_gen_mobile/app/providers.dart';
import 'package:app_alim_gen_mobile/core/errors/error_mapper.dart';
import 'package:app_alim_gen_mobile/features/business_lists/data/business_repositories.dart';
import 'package:app_alim_gen_mobile/features/business_lists/domain/business_entities.dart';
import 'package:app_alim_gen_mobile/features/business_lists/presentation/sale_stock_notice.dart';
import 'package:app_alim_gen_mobile/features/business_lists/presentation/transaction_form_screens.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

TransactionOption _product(Object? stock, {int id = 1}) => TransactionOption(
  id: id,
  label: 'Produit synthétique $id',
  meta: {'stock': stock},
);

Widget _app(Widget child, {String language = 'fr'}) => MaterialApp(
  locale: Locale(language),
  supportedLocales: const [Locale('fr'), Locale('en'), Locale('ar')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  home: Scaffold(body: child),
);

class _Sales extends SalesRepository {
  _Sales() : super(Dio(), const ErrorMapper());
  final pending = <int, Completer<Map<String, dynamic>>>{};
  final requests = <int>[];

  @override
  Future<Map<String, dynamic>> price(
    int productId,
    int clientId, {
    int? packagingId,
  }) {
    requests.add(productId);
    return pending.putIfAbsent(productId, Completer.new).future;
  }
}

const _price = <String, dynamic>{
  'price': '10.00',
  // The price response is depot stock, not necessarily the seller's stock.
  'stock': 9999,
  'packagings': [
    {'id': 3, 'name': 'Carton', 'conversion_factor': 6},
  ],
};

Future<void> _openForm(WidgetTester tester, _Sales sales) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [salesRepositoryProvider.overrideWithValue(sales)],
      child: _app(const SaleFormScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void _chooseProduct(WidgetTester tester, TransactionOption product) {
  tester
      .widget<RemoteOptionField>(find.byKey(const ValueKey('sale-product-0')))
      .onSelected(product);
}

void main() {
  for (final stock in [12, 12.0, '12', ' 12 ']) {
    testWidgets('affiche le stock entier $stock (${stock.runtimeType})', (
      tester,
    ) async {
      await tester.pumpWidget(_app(SaleStockNotice(product: _product(stock))));
      expect(find.text('Stock disponible : 12 unités de base'), findsOneWidget);
    });
  }

  for (final stock in [
    null,
    -1,
    1.5,
    double.nan,
    double.infinity,
    'abc',
    true,
  ]) {
    testWidgets('stock absent ou invalide $stock ne devient pas zéro', (
      tester,
    ) async {
      await tester.pumpWidget(_app(SaleStockNotice(product: _product(stock))));
      expect(find.text('Stock non renseigné'), findsOneWidget);
      expect(find.textContaining('Stock disponible : 0'), findsNothing);
    });
  }

  testWidgets('stock nul connu affiché et signalé, sans bloquer la vente', (
    tester,
  ) async {
    await tester.pumpWidget(_app(SaleStockNotice(product: _product(0))));
    final text = tester.widget<Text>(
      find.text('Stock disponible : 0 unités de base'),
    );
    final context = tester.element(find.byType(SaleStockNotice));
    expect(text.style?.color, Theme.of(context).colorScheme.error);
  });

  testWidgets('convertit les cartons complets et garde le reste en unités', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        SaleStockNotice(
          product: _product(20),
          packaging: const TransactionOption(
            id: 3,
            label: 'Carton',
            meta: {'conversion_factor': 6},
          ),
        ),
      ),
    );
    expect(
      find.text(
        'Stock disponible : 20 unités de base (3 Carton + 2 unités de base)',
      ),
      findsOneWidget,
    );
    expect(
      find.byTooltip(
        'Stock à la sélection du produit, non réservé. Vérifié à l’enregistrement.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('ne divise pas par un facteur inconnu ou nul', (tester) async {
    for (final factor in [null, 0, -2, 2.5]) {
      await tester.pumpWidget(
        _app(
          SaleStockNotice(
            product: _product(20),
            packaging: TransactionOption(
              id: 3,
              label: 'Carton',
              meta: {'conversion_factor': factor},
            ),
          ),
        ),
      );
      expect(find.text('Stock disponible : 20 unités de base'), findsOneWidget);
    }
  });

  for (final entry in {
    'en': 'Available stock : 12 base units',
    'ar': 'المخزون المتاح : 12 وحدات أساسية',
  }.entries) {
    testWidgets('traduit le stock en ${entry.key}', (tester) async {
      await tester.pumpWidget(
        _app(SaleStockNotice(product: _product(12)), language: entry.key),
      );
      expect(find.text(entry.value), findsOneWidget);
    });
  }

  testWidgets('le texte se replie sur petit écran avec police agrandie', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: SizedBox(
            width: 260,
            child: SaleStockNotice(product: _product(123456)),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('stock visible dès la sélection sans client ni requête ajoutée', (
    tester,
  ) async {
    final sales = _Sales();
    await _openForm(tester, sales);
    expect(find.byType(SaleStockNotice), findsNothing);
    _chooseProduct(tester, _product(17));
    await tester.pump();
    expect(find.text('Stock disponible : 17 unités de base'), findsOneWidget);
    expect(sales.requests, isEmpty);
  });

  testWidgets('le prix différé ne remplace pas le stock vendeur par le dépôt', (
    tester,
  ) async {
    final sales = _Sales();
    await _openForm(tester, sales);
    tester
        .widget<RemoteOptionField>(find.byType(RemoteOptionField).first)
        .onSelected(
          const TransactionOption(id: 2, label: 'Client synthétique'),
        );
    await tester.pump();
    _chooseProduct(tester, _product(17));
    await tester.pump();
    expect(find.text('Stock disponible : 17 unités de base'), findsOneWidget);
    sales.pending[1]!.complete(_price);
    await tester.pumpAndSettle();
    expect(find.text('Stock disponible : 17 unités de base'), findsOneWidget);
    expect(find.textContaining('9999'), findsNothing);
    await tester.tap(find.byType(DropdownButtonFormField<TransactionOption?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Carton').last);
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Stock disponible : 17 unités de base (2 Carton + 5 unités de base)',
      ),
      findsOneWidget,
    );
    await tester.tap(find.byType(DropdownButtonFormField<TransactionOption?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unité').last);
    await tester.pumpAndSettle();
    expect(find.text('Stock disponible : 17 unités de base'), findsOneWidget);
  });

  testWidgets('un ancien produit ne remplace pas la nouvelle sélection', (
    tester,
  ) async {
    final sales = _Sales();
    await _openForm(tester, sales);
    tester
        .widget<RemoteOptionField>(find.byType(RemoteOptionField).first)
        .onSelected(
          const TransactionOption(id: 2, label: 'Client synthétique'),
        );
    await tester.pump();
    _chooseProduct(tester, _product(17));
    _chooseProduct(tester, _product(30, id: 2));
    await tester.pump();
    sales.pending[1]!.complete(_price);
    await tester.pumpAndSettle();
    expect(find.text('Stock disponible : 30 unités de base'), findsOneWidget);
    expect(
      find.byType(DropdownButtonFormField<TransactionOption?>),
      findsNothing,
    );
    sales.pending[2]!.complete(_price);
    await tester.pumpAndSettle();
    expect(find.text('Stock disponible : 30 unités de base'), findsOneWidget);
  });

  testWidgets('réponse tardive après fermeture du formulaire ignorée', (
    tester,
  ) async {
    final sales = _Sales();
    await _openForm(tester, sales);
    tester
        .widget<RemoteOptionField>(find.byType(RemoteOptionField).first)
        .onSelected(
          const TransactionOption(id: 2, label: 'Client synthétique'),
        );
    await tester.pump();
    _chooseProduct(tester, _product(17));
    await tester.pumpWidget(const SizedBox.shrink());
    sales.pending[1]!.complete(_price);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
