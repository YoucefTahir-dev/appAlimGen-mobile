import 'package:app_alim_gen_mobile/features/business_lists/domain/business_entities.dart';
import 'package:app_alim_gen_mobile/features/business_lists/domain/invoice_document.dart';
import 'package:app_alim_gen_mobile/features/business_lists/presentation/business_list_screens.dart';
import 'package:app_alim_gen_mobile/features/business_lists/presentation/invoice_document_view.dart';
import 'package:app_alim_gen_mobile/features/business_lists/presentation/invoice_preview_screen.dart';
import 'package:app_alim_gen_mobile/core/utils/app_formats.dart';
import 'package:app_alim_gen_mobile/features/printers/domain/printer_summary.dart';
import 'package:app_alim_gen_mobile/features/printers/domain/thermal_paper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _capabilities = SaleCapabilities(
  canUpdate: true,
  canDelete: false,
  canViewInvoice: true,
  canViewPdf: true,
  canPrint: true,
  canAddPayment: true,
  canCancel: false,
);

SaleDetails _sale({
  String status = 'partial',
  int lineCount = 2,
}) => SaleDetails(
  id: 7,
  number: 'FAC-2026-000007',
  ticketNumber: 'TCK-2026-000007',
  date: '2026-09-24T13:35:00Z',
  client: const SaleClientDetails(
    id: 2,
    name: 'Alimentation Exemple avec un nom très long pour le rendu',
    phone: '0550 00 00 00',
    address: '1 rue Exemple, Alger',
    customerType: 'Détail',
  ),
  lines: List.generate(
    lineCount,
    (index) => SaleLineDetails(
      id: index + 1,
      productId: index + 10,
      productName:
          'Produit alimentaire avec une désignation particulièrement longue ${index + 1}',
      packagingId: null,
      packagingName: 'Carton de 24 unités',
      quantity: index + 1,
      stockQuantity: index + 1,
      unitPrice: '12345.67',
      total: '12345.67',
    ),
  ),
  subtotal: '24691.34',
  discount: '100.00',
  taxRate: '19.00',
  taxAmount: '4691.35',
  total: '29282.69',
  amountPaid: status == 'paid' ? '29282.69' : '10000.00',
  balanceDue: status == 'paid' ? '0.00' : '19282.69',
  paymentType: 'Espèces',
  paymentTypeCode: 'cash',
  paymentStatus: status,
  payments: const [],
  capabilities: _capabilities,
);

const _printer80 = PrinterDetails(
  id: 1,
  name: 'RPP02N',
  description: '',
  printerType: 'thermal',
  manufacturer: 'Rongta',
  modelName: 'RPP02N',
  connectionMode: 'bluetooth',
  localIdentifier: '',
  bluetoothName: 'RPP02N',
  bluetoothAddress: 'AA:BB:CC:DD:EE:FF',
  ipAddress: '',
  networkPort: null,
  paperWidth: 80,
  protocol: 'generic_escpos',
  charactersPerLine: 48,
  encoding: 'cp858',
  autoPrint: false,
  printInvoices: true,
  printReceipts: true,
  isDefault: true,
  isActive: true,
);

Widget _app(Widget home, {Locale locale = const Locale('fr')}) => ProviderScope(
  child: MaterialApp(
    locale: locale,
    supportedLocales: const [Locale('fr'), Locale('ar'), Locale('en')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: home,
  ),
);

void main() {
  test(
    'centralise les largeurs thermiques en millimètres, points et colonnes',
    () {
      expect(ThermalPaperSpec.mm58.dots, 384);
      expect(ThermalPaperSpec.mm58.charactersPerLine, 32);
      expect(ThermalPaperSpec.mm80.dots, 576);
      expect(ThermalPaperSpec.mm80.charactersPerLine, 48);
      expect(InvoicePaperSpec.fromPrinterWidth(80), InvoicePaper.mm80);
    },
  );

  testWidgets(
    'les aperçus 58, 80 et A4 ont des largeurs réellement différentes',
    (tester) async {
      final data = InvoiceDocumentData(sale: _sale());
      await tester.pumpWidget(
        _app(
          SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InvoiceDocumentView(data: data, paper: InvoicePaper.mm58),
                  InvoiceDocumentView(data: data, paper: InvoicePaper.mm80),
                  InvoiceDocumentView(data: data, paper: InvoicePaper.a4),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.getSize(find.byKey(const Key('invoice-paper-mm58'))).width,
        264,
      );
      expect(
        tester.getSize(find.byKey(const Key('invoice-paper-mm80'))).width,
        360,
      );
      expect(
        tester.getSize(find.byKey(const Key('invoice-paper-a4'))).width,
        720,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('le profil RPP02N 80 mm présélectionne 80 puis permet 58 et A4', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        InvoicePreviewScreen(
          sale: _sale(lineCount: 12),
          canPrint: false,
          canViewPdf: false,
          initialPrinter: _printer80,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('invoice-paper-mm80')), findsOneWidget);
    expect(find.byKey(const Key('default-printer-label')), findsOneWidget);

    await tester.tap(find.text('58 mm'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('invoice-paper-mm58')), findsOneWidget);

    await tester.tap(find.text('A4'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('invoice-paper-a4')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('l’aperçu arabe utilise RTL sans couper les actions de format', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        InvoicePreviewScreen(
          sale: _sale(),
          canPrint: false,
          canViewPdf: false,
          initialPrinter: _printer80,
        ),
        locale: const Locale('ar'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      Directionality.of(tester.element(find.byType(Scaffold))),
      TextDirection.rtl,
    );
    expect(find.text('تنسيق الطباعة'), findsOneWidget);
    expect(find.byKey(const Key('invoice-paper-mm80')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('le sélecteur et le document sont traduits en français', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        InvoicePreviewScreen(
          sale: _sale(),
          canPrint: false,
          canViewPdf: false,
          initialPrinter: _printer80,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text("Format d'impression"), findsOneWidget);
    expect(find.text('Merci pour votre confiance'), findsOneWidget);
  });

  testWidgets('le sélecteur et le document sont traduits en anglais', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        InvoicePreviewScreen(
          sale: _sale(),
          canPrint: false,
          canViewPdf: false,
          initialPrinter: _printer80,
        ),
        locale: const Locale('en'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Print format'), findsOneWidget);
    expect(find.text('Thank you for your trust'), findsOneWidget);
  });

  testWidgets('la carte facture affiche client, montants et statut payé', (
    tester,
  ) async {
    final summary = InvoiceSummary(
      id: 1,
      number: 'FAC-1',
      clientId: 2,
      date: '2026-09-24T13:35:00Z',
      total: '640.00',
      paymentStatus: 'paid',
      clientName: 'SARL Exemple',
      amountPaid: '640.00',
      balanceDue: '0.00',
    );
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: InvoiceCard(invoice: summary, onOpen: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('FAC-1'), findsOneWidget);
    expect(find.text('SARL Exemple'), findsOneWidget);
    expect(find.byKey(const Key('invoice-list-status-paid')), findsOneWidget);
    expect(find.text(AppFormats.money('640.00')), findsNWidgets(2));
  });

  testWidgets('les badges distinguent payée, partielle et impayée', (
    tester,
  ) async {
    InvoiceSummary summary(String status, int id) => InvoiceSummary(
      id: id,
      number: 'FAC-$id',
      clientId: id,
      date: '2026-09-24T13:35:00Z',
      total: '100.00',
      paymentStatus: status,
      clientName: 'Client $id',
      amountPaid: status == 'paid' ? '100.00' : '0.00',
      balanceDue: status == 'paid' ? '0.00' : '100.00',
    );
    await tester.pumpWidget(
      _app(
        SingleChildScrollView(
          child: Column(
            children: [
              InvoiceCard(invoice: summary('paid', 1), onOpen: () {}),
              InvoiceCard(invoice: summary('partial', 2), onOpen: () {}),
              InvoiceCard(invoice: summary('unpaid', 3), onOpen: () {}),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('invoice-list-status-paid')), findsOneWidget);
    expect(
      find.byKey(const Key('invoice-list-status-partial')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('invoice-list-status-unpaid')), findsOneWidget);
  });
}
