import 'package:app_alim_gen_mobile/features/business_lists/domain/business_entities.dart';
import 'package:app_alim_gen_mobile/features/clients/domain/client_summary.dart';
import 'package:app_alim_gen_mobile/features/company_settings/domain/company_settings.dart';
import 'package:app_alim_gen_mobile/features/loading_orders/domain/loading_order_summary.dart';
import 'package:app_alim_gen_mobile/features/printers/domain/printer_summary.dart';
import 'package:app_alim_gen_mobile/features/products/domain/product_summary.dart';
import 'package:app_alim_gen_mobile/features/stock/domain/operator_stock_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('les modèles de listes suivent les serializers Django', () {
    final product = ProductSummary.fromJson({
      'id': 1,
      'name': 'Produit',
      'reference': 'PR-1',
      'quantity': 3,
      'stock_status': 'normal',
      // Les champs de prix peuvent être absents selon la permission.
    });
    final client = ClientSummary.fromJson({
      'id': 2,
      'name': 'Client',
      'phone': null,
      'address': null,
      'customer_type': 'retail',
    });
    final supplier = SupplierSummary.fromJson({
      'id': 3,
      'name': 'Fournisseur',
      'phone': null,
      'address': null,
    });
    final sale = SaleSummary.fromJson({
      'id': 4,
      'invoice_number': 'FAC-4',
      'client': null,
      'created_at': '2026-09-14T10:00:00Z',
      'total': '1200.50',
      'payment_status': 'partial',
    });
    final purchase = PurchaseSummary.fromJson({
      'id': 5,
      'reference': 'ACH-5',
      'supplier': 3,
      'created_at': '2026-09-14T10:00:00Z',
      'total': '900.00',
      'payment_status': 'paid',
    });
    final payment = PaymentSummary.fromJson({
      'id': 6,
      'reference': 'PAY-6',
      'amount': '100.00',
      'payment_type': 'cash',
      'created_at': '2026-09-14T10:00:00Z',
    });
    final expense = ExpenseSummary.fromJson({
      'id': 7,
      'number': 'CH-7',
      'date': '2026-09-14',
      'description': null,
      'amount': '42.10',
      'payment_method': 'cash',
    });

    expect(product.retailPrice, isNull);
    expect(client.phone, isEmpty);
    expect(supplier.address, isEmpty);
    expect(sale.clientId, isNull);
    expect(sale.total, '1200.50');
    expect(purchase.supplierId, 3);
    expect(payment.amount, '100.00');
    expect(expense.description, isEmpty);
  });

  test(
    'les contrats chargement, stock opérateur et imprimante sont exacts',
    () {
      final loading = LoadingOrderSummary.fromJson({
        'id': 1,
        'number': 'CHG-1',
        'operator_name': 'operateur',
        'status': 'in_progress',
        'created_at': '2026-09-14T10:00:00Z',
        'lines': [
          {
            'product': 9,
            'product_name': 'Butane',
            'quantity': 10,
            'sold_quantity': 3,
            'returned_quantity': 0,
          },
        ],
      });
      final stock = OperatorStockSummary.fromJson({
        'id': 2,
        'product': 9,
        'product_name': 'Butane',
        'quantity': 7,
        'updated_at': '2026-09-14T10:00:00Z',
      });
      final printer = PrinterSummary.fromJson({
        'id': 3,
        'name': 'RPP02N',
        'model_name': null,
        'connection_mode_display': 'Bluetooth',
        'paper_width': 58,
        'is_active': true,
        'is_default': true,
      });

      expect(loading.lines.single.loaded, 10);
      expect(loading.lines.single.sold, 3);
      expect(stock.remaining, 7);
      expect(printer.model, isEmpty);
      expect(printer.paperWidth, 58);
    },
  );

  test('les informations légales client et entreprise suivent l’API', () {
    final client = ClientDetails.fromJson({
      'id': 2,
      'name': 'Client légal',
      'phone': '',
      'address': '',
      'wilaya': '',
      'customer_type': 'RETAIL',
      'email': '',
      'tax_number': 'NIF-C',
      'nis': 'NIS-C',
      'article_number': 'AI-C',
      'trade_register_number': 'RC-C',
      'balance': '0.00',
      'notes': '',
    });
    final request = ClientWriteRequest(
      name: client.name,
      phone: '',
      address: '',
      wilaya: '',
      customerType: 'RETAIL',
      email: '',
      taxNumber: client.taxNumber,
      nis: client.nis,
      articleNumber: client.articleNumber,
      tradeRegisterNumber: client.tradeRegisterNumber,
      balance: '0.00',
      notes: '',
    );
    final company = CompanySettings.fromJson({
      'company_name': 'EL AMINE',
      'address': 'Alger',
      'phone': '0550',
      'email': 'contact@example.dz',
      'tax_number': 'NIF-E',
      'nis': 'NIS-E',
      'rc_number': 'RC-E',
      'article_number': 'AI-E',
      'tax_rate': '19.00',
    });

    expect(request.toJson()['trade_register_number'], 'RC-C');
    expect(request.toJson()['article_number'], 'AI-C');
    expect(company.toJson()['nis'], 'NIS-E');
    expect(company.toJson()['tax_rate'], '19.00');
  });
}
