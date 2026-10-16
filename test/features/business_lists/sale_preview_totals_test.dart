import 'package:app_alim_gen_mobile/features/business_lists/domain/sale_preview_totals.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calcule lignes, remise, TVA, encaissé et reste en centimes', () {
    final preview = SalePreviewTotals.calculate(
      lineTotalsCents: const [1200000, 110000],
      discount: '100.00',
      taxRate: '19.00',
      payFull: false,
    );

    expect(preview.subtotalCents, 1310000);
    expect(preview.taxCents, 248900);
    expect(preview.discountCents, 10000);
    expect(preview.totalCents, 1548900);
    expect(preview.paidCents, 0);
    expect(preview.dueCents, 1548900);
  });

  test('gère carton, paiement intégral et arrondi demi-supérieur', () {
    final preview = SalePreviewTotals.calculate(
      lineTotalsCents: [SalePreviewTotals.lineTotalCents('3', '4000.005')],
      discount: '0',
      taxRate: '0',
      payFull: true,
    );

    expect(preview.subtotalCents, 1200003);
    expect(preview.paidCents, preview.totalCents);
    expect(preview.dueCents, 0);
    expect(SalePreviewTotals.formatCents(preview.totalCents), '12000.03');
  });

  test('conserve les paiements existants pendant une modification', () {
    final preview = SalePreviewTotals.calculate(
      lineTotalsCents: const [2000000],
      discount: '0',
      taxRate: '0',
      payFull: false,
      existingPaid: '8000.00',
    );

    expect(preview.paidCents, 800000);
    expect(preview.dueCents, 1200000);
  });

  test('ajoute le paiement partiel à l encaissé existant', () {
    final preview = SalePreviewTotals.calculate(
      lineTotalsCents: const [2000000],
      discount: '0',
      taxRate: '0',
      payFull: false,
      existingPaid: '2000.00',
      amountReceived: '6000.00',
    );
    expect(preview.paidCents, 800000);
    expect(preview.dueCents, 1200000);
  });
}
