import 'package:intl/intl.dart';

abstract final class AppFormats {
  static String money(Object? raw, {String currency = 'DZD'}) {
    final value = raw is num
        ? raw.toDouble()
        : double.tryParse(raw?.toString().replaceAll(',', '.') ?? '') ?? 0;
    final decimals = value == value.roundToDouble() ? 0 : 2;
    return '${NumberFormat.decimalPatternDigits(locale: 'fr', decimalDigits: decimals).format(value)} $currency';
  }

  static String shortDate(DateTime date, String locale) =>
      DateFormat('d MMM y', locale).format(date);
}
