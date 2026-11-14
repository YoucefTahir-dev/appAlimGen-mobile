import 'package:app_alim_gen_mobile/features/business_lists/domain/business_entities.dart';
import 'package:app_alim_gen_mobile/features/business_lists/presentation/sales_strings.dart';
import 'package:flutter/material.dart';

/// Search stock is already scoped by the server to the seller's stock source.
/// Do not replace it with the price endpoint's depot quantity.
class SaleStockNotice extends StatelessWidget {
  const SaleStockNotice({super.key, required this.product, this.packaging});

  final TransactionOption product;
  final TransactionOption? packaging;

  static int? _wholeNumber(Object? value) {
    if (value is int) return value >= 0 ? value : null;
    if (value is num) {
      return value.isFinite && value >= 0 && value == value.truncateToDouble()
          ? value.toInt()
          : null;
    }
    if (value is String) {
      final number = int.tryParse(value.trim());
      return number != null && number >= 0 ? number : null;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final t = SalesStrings.of(context);
    final stock = _wholeNumber(product.meta['stock']);
    final factor = _wholeNumber(packaging?.meta['conversion_factor']);
    final baseUnits = t('stockBaseUnits');
    String? packaged;
    if (stock != null && factor != null && factor > 1 && packaging != null) {
      final remainder = stock % factor;
      packaged = '${stock ~/ factor} ${packaging!.label}';
      if (remainder > 0) packaged += ' + $remainder $baseUnits';
    }
    final label = stock == null
        ? t('stockUnknown')
        : '${t('availableStock')} : $stock $baseUnits'
              '${packaged == null ? '' : ' ($packaged)'}';
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Tooltip(
        message: t('stockSnapshotHint'),
        child: Semantics(
          liveRegion: true,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: stock == 0 ? Theme.of(context).colorScheme.error : null,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
