import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:app_alim_gen_mobile/app/providers.dart';
import 'package:app_alim_gen_mobile/features/business_lists/data/business_repositories.dart';
import 'package:app_alim_gen_mobile/features/business_lists/domain/business_entities.dart';
import 'package:app_alim_gen_mobile/features/business_lists/domain/invoice_document.dart';
import 'package:app_alim_gen_mobile/features/business_lists/presentation/invoice_document_view.dart';
import 'package:app_alim_gen_mobile/features/business_lists/presentation/invoice_logo_loader.dart';
import 'package:app_alim_gen_mobile/features/business_lists/presentation/invoice_preview_screen.dart';
import 'package:app_alim_gen_mobile/features/printers/data/printer_print_profile_store.dart';
import 'package:app_alim_gen_mobile/features/printers/domain/printer_print_profile.dart';
import 'package:app_alim_gen_mobile/features/printers/domain/printer_summary.dart';
import 'package:app_alim_gen_mobile/features/printers/services/esc_pos_printer_driver.dart';
import 'package:app_alim_gen_mobile/features/printers/services/printer_test_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/printing_fixtures.dart';

const _companyName =
    'Nom historique très long de l’entreprise fourni par les paramètres';
const _logoUrl = 'https://media.example.test/historical-logo.png';

ImageInfo _logoImage() {
  final recorder = ui.PictureRecorder();
  Canvas(
    recorder,
  ).drawRect(const Rect.fromLTWH(0, 0, 16, 16), Paint()..color = Colors.black);
  final picture = recorder.endRecording();
  final image = picture.toImageSync(16, 16);
  picture.dispose();
  return ImageInfo(image: image);
}

class _LogoLoader extends InvoiceLogoLoader {
  _LogoLoader(this.image);
  final ImageInfo? image;
  final requests = <String?>[];
  @override
  Future<ImageInfo?> load(String? value) async {
    requests.add(value);
    return image?.clone();
  }
}

class _DeferredLogoLoader extends InvoiceLogoLoader {
  final result = Completer<ImageInfo?>();
  @override
  Future<ImageInfo?> load(String? value) => result.future;
}

class _Invoices extends Mock implements InvoicesRepository {}

class _Profiles implements PrinterPrintProfileStore {
  @override
  Future<PrinterPrintProfile> read(PrinterDetails printer) async =>
      const PrinterPrintProfile(pauseMs: 0);
  @override
  Future<void> save(
    PrinterDetails printer,
    PrinterPrintProfile profile,
  ) async {}
}

class _Driver extends EscPosPrinterDriver {
  Uint8List? raster;
  int? rasterWidth;
  final rasterReady = Completer<void>();
  @override
  Uint8List rasterTicket({
    required Uint8List rgba,
    required int width,
    required int height,
    PrinterPrintProfile profile = const PrinterPrintProfile(),
  }) {
    rasterWidth = width;
    raster = super.rasterTicket(
      rgba: rgba,
      width: width,
      height: height,
      profile: profile,
    );
    rasterReady.complete();
    return raster!;
  }
}

Widget _app(Widget child) => MaterialApp(
  locale: const Locale('fr'),
  supportedLocales: const [Locale('fr')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  for (final count in [1, 4, 7, 20, 50]) {
    for (final paper in [InvoicePaper.mm58, InvoicePaper.mm80]) {
      for (final information in [false, true]) {
        testWidgets('all $count products and final total remain visible '
            '$paper / info $information', (tester) async {
          final sale = printingSale(count: count, information: information);
          await tester.pumpWidget(
            _app(
              InvoiceDocumentView(
                data: InvoiceDocumentData(sale: sale),
                paper: paper,
              ),
            ),
          );
          await tester.pumpAndSettle();
          var previousY = double.negativeInfinity;
          for (final line in sale.lines) {
            final name = find.textContaining(line.productName);
            expect(name, findsOneWidget);
            final y = tester.getTopLeft(name).dy;
            expect(y, greaterThan(previousY));
            previousY = y;
          }
          expect(
            tester.getTopLeft(find.text('TOTAL TTC')).dy,
            greaterThan(previousY),
          );
          final totalRow = find
              .ancestor(of: find.text('TOTAL TTC'), matching: find.byType(Row))
              .first;
          expect(
            find.descendant(
              of: totalRow,
              matching: find.text('${sale.total} DZD'),
            ),
            findsOneWidget,
          );
          if (!information) {
            expect(find.text('COMPANY-PRIVATE'), findsOneWidget);
            expect(find.textContaining('CLIENT-PRIVATE'), findsNothing);
          }
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  for (final paper in [InvoicePaper.mm58, InvoicePaper.mm80]) {
    for (final information in [false, true]) {
      for (final hasLogo in [false, true]) {
        testWidgets(
          'snapshot header $paper / info $information / logo $hasLogo',
          (tester) async {
            final image = hasLogo ? _logoImage() : null;
            final loader = _LogoLoader(image);
            final sale = printingSale(
              information: information,
              company: const SaleCompanyDetails(
                name: _companyName,
                logoUrl: _logoUrl,
                address: 'ADDRESS-SECRET',
                taxNumber: 'NIF-SECRET',
                shareCapital: '987654321.00',
              ),
            );
            await tester.pumpWidget(
              _app(
                InvoiceDocumentView(
                  data: InvoiceDocumentData(sale: sale),
                  paper: paper,
                  logoLoader: loader,
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(find.text(_companyName), findsOneWidget);
            expect(find.textContaining('Capital social'), findsNothing);
            expect(find.textContaining('987654321.00'), findsNothing);
            if (!information) {
              final name = find.byKey(const Key('invoice-company-name'));
              expect(tester.widget<Text>(name).textAlign, TextAlign.center);
              expect(
                tester.getTopLeft(name).dy,
                lessThan(
                  tester.getTopLeft(find.text(exampleProductNames.first)).dy,
                ),
              );
              expect(loader.requests, [_logoUrl]);
              expect(find.byType(Image), findsNothing);
              final logo = find.byKey(const Key('invoice-company-logo'));
              expect(logo, hasLogo ? findsOneWidget : findsNothing);
              if (hasLogo) {
                expect(
                  tester.getTopLeft(logo).dy,
                  lessThan(tester.getTopLeft(name).dy),
                );
                final receipt = find.byKey(Key('invoice-paper-${paper.name}'));
                expect(
                  tester.getCenter(logo).dx,
                  closeTo(tester.getCenter(receipt).dx, .01),
                );
              }
              for (final forbidden in [
                'ADDRESS-SECRET',
                'NIF-SECRET',
                'CLIENT-PRIVATE',
                'INVOICE-PRIVATE',
                'PAYMENT-PRIVATE',
                '2026-11-01',
              ]) {
                expect(find.textContaining(forbidden), findsNothing);
              }
            } else {
              expect(loader.requests, isEmpty);
              expect(find.textContaining('ADDRESS-SECRET'), findsOneWidget);
              expect(find.textContaining('NIF-SECRET'), findsOneWidget);
            }
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox());
            image?.dispose();
          },
        );
      }
    }

    testWidgets('missing snapshot identity has no invented fallback $paper', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          InvoiceDocumentView(
            data: InvoiceDocumentData(
              sale: printingSale(company: const SaleCompanyDetails()),
            ),
            paper: paper,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('invoice-company-name')), findsNothing);
      expect(find.byType(Image), findsNothing);
      expect(find.byType(RawImage), findsNothing);
      expect(find.textContaining('EL AMINE'), findsNothing);
      expect(find.text(exampleProductNames.first), findsOneWidget);
      expect(find.text('TOTAL TTC'), findsOneWidget);
    });
  }

  for (final capital in [null, '0.00', '125000.50']) {
    testWidgets('official A4 preserves nullable capital $capital', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          InvoiceDocumentView(
            data: InvoiceDocumentData(
              sale: printingSale(
                company: SaleCompanyDetails(
                  name: 'Entreprise historique',
                  shareCapital: capital,
                ),
              ),
            ),
            paper: InvoicePaper.a4,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Capital social'),
        capital == null ? findsNothing : findsOneWidget,
      );
      if (capital != null) {
        expect(find.text('Capital social : $capital DZD'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }

  test(
    'OFF payload allows only snapshot identity, ordered items and grand total',
    () {
      final sale = printingSale(
        company: const SaleCompanyDetails(
          name: _companyName,
          logoUrl: _logoUrl,
          address: 'ADDRESS-SECRET',
          shareCapital: '0.00',
        ),
      );
      final payload = InvoiceDocumentData(sale: sale).toTicketPayload();
      expect(payload['company'], {
        'name_fr': _companyName,
        'logo_url': _logoUrl,
      });
      expect(payload['totals'], {'total_ttc': sale.total});
      expect(
        payload.keys,
        unorderedEquals([
          'show_ticket_information',
          'show_legal_information',
          'company',
          'items',
          'totals',
        ]),
      );
      expect(
        (payload['items'] as List).map((dynamic item) => item['name']),
        exampleProductNames,
      );
    },
  );

  test(
    'company snapshot decodes logo and missing/null/zero capital without defaults',
    () {
      expect(SaleCompanyDetails.fromJson({}).shareCapital, isNull);
      expect(
        SaleCompanyDetails.fromJson({'share_capital': null}).shareCapital,
        isNull,
      );
      final company = SaleCompanyDetails.fromJson({
        'company_name': _companyName,
        'logo_url': _logoUrl,
        'share_capital': '0.00',
      });
      expect(company.name, _companyName);
      expect(company.logoUrl, _logoUrl);
      expect(company.shareCapital, '0.00');
    },
  );

  test('media image provider never forwards API authorization headers', () {
    final provider =
        const InvoiceLogoLoader().imageProvider(Uri.parse(_logoUrl))
            as ResizeImage;
    expect((provider.imageProvider as NetworkImage).headers, isNull);
    expect(provider.width, 256);
    expect(provider.height, 256);
  });

  for (final width in [58, 80]) {
    testWidgets(
      'OFF printing waits for snapshot logo before raster Bluetooth send $width',
      (tester) async {
        final loader = _DeferredLogoLoader();
        final repository = _Invoices();
        when(
          () => repository.printData(37, width: width, language: 'fr'),
        ).thenAnswer((_) async => {});
        final transport = RecordingPrinterTransport();
        final driver = _Driver();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              invoicesRepositoryProvider.overrideWithValue(repository),
              invoiceLogoLoaderProvider.overrideWithValue(loader),
              printerPrintProfileStoreProvider.overrideWithValue(_Profiles()),
              printerTestServiceProvider.overrideWithValue(
                PrinterTestService(transport, driver),
              ),
            ],
            child: MaterialApp(
              locale: const Locale('fr'),
              supportedLocales: const [Locale('fr')],
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              home: InvoicePreviewScreen(
                sale: printingSale(
                  company: const SaleCompanyDetails(
                    name: _companyName,
                    logoUrl: _logoUrl,
                  ),
                ),
                canPrint: true,
                canViewPdf: false,
                initialPrinter: printingPrinter(width),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('preview-print-action')));
        await tester.pump();
        expect(transport.stream, isEmpty);
        expect(driver.raster, isNull);
        loader.result.complete(_logoImage());
        for (var i = 0; i < 100 && driver.raster == null; i++) {
          await tester.pump(const Duration(milliseconds: 16));
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)),
          );
        }
        expect(driver.raster, isNotNull);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('invoice-company-logo')), findsOneWidget);
        expect(driver.rasterWidth, width == 58 ? 384 : 576);
        expect(driver.raster, isNotNull);
        expect(transport.stream, orderedEquals(driver.raster!));
        expect(transport.maxConcurrentWrites, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
