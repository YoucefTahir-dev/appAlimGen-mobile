class SalePreviewTotals {
  const SalePreviewTotals({
    required this.subtotalCents,
    required this.taxCents,
    required this.discountCents,
    required this.totalCents,
    required this.paidCents,
    required this.dueCents,
  });

  final int subtotalCents;
  final int taxCents;
  final int discountCents;
  final int totalCents;
  final int paidCents;
  final int dueCents;

  factory SalePreviewTotals.calculate({
    required Iterable<int> lineTotalsCents,
    required String discount,
    required String taxRate,
    required bool payFull,
    String existingPaid = '0',
    String amountReceived = '0',
  }) {
    final subtotal = lineTotalsCents.fold<int>(0, (sum, value) => sum + value);
    final discountCents = parseMoneyCents(discount);
    final taxBasisPoints = parsePercentBasisPoints(taxRate);
    final taxNumerator = subtotal * taxBasisPoints;
    final taxCents = taxNumerator >= 0
        ? (taxNumerator + 5000) ~/ 10000
        : (taxNumerator - 5000) ~/ 10000;
    final total = subtotal + taxCents - discountCents;
    final previousPaid = parseMoneyCents(existingPaid);
    final paid = payFull
        ? _nonNegative(total)
        : previousPaid + parseMoneyCents(amountReceived);
    return SalePreviewTotals(
      subtotalCents: subtotal,
      taxCents: taxCents,
      discountCents: discountCents,
      totalCents: total,
      paidCents: paid,
      dueCents: _nonNegative(total - paid),
    );
  }

  static int lineTotalCents(String quantity, String unitPrice) =>
      (int.tryParse(quantity.trim()) ?? 0) * parseMoneyCents(unitPrice);

  static int parseMoneyCents(String value) => _parseScaled(value, 2);

  static int parsePercentBasisPoints(String value) => _parseScaled(value, 2);

  static int _parseScaled(String value, int decimals) {
    final normalized = value.trim().replaceAll(',', '.');
    final match = RegExp(r'^(-?)(\d*)(?:\.(\d*))?$').firstMatch(normalized);
    if (match == null ||
        ((match.group(2) ?? '').isEmpty && (match.group(3) ?? '').isEmpty)) {
      return 0;
    }
    final negative = match.group(1) == '-';
    final whole = int.tryParse(match.group(2) ?? '') ?? 0;
    final fraction = '${match.group(3) ?? ''}${'0' * (decimals + 1)}';
    final scale = _pow10(decimals);
    var result = whole * scale + int.parse(fraction.substring(0, decimals));
    if (int.parse(fraction.substring(decimals, decimals + 1)) >= 5) result++;
    return negative ? -result : result;
  }

  static String formatCents(int cents) {
    final sign = cents < 0 ? '-' : '';
    final absolute = cents.abs();
    return '$sign${absolute ~/ 100}.${(absolute % 100).toString().padLeft(2, '0')}';
  }

  static int _pow10(int exponent) {
    var result = 1;
    for (var i = 0; i < exponent; i++) {
      result *= 10;
    }
    return result;
  }

  static int _nonNegative(int value) => value < 0 ? 0 : value;
}
