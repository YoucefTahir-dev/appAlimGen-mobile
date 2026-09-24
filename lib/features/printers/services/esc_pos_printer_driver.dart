import 'dart:typed_data';
import 'package:app_alim_gen_mobile/features/printers/services/printer_transport.dart';

class EscPosPrinterDriver implements PrinterDriver {
  Uint8List _encode(String text) => Uint8List.fromList([
    0x1b,
    0x40,
    ...text.runes.map((rune) => rune <= 0xff ? rune : 0x3f),
    0x1d,
    0x56,
    0x00,
  ]);

  @override
  Uint8List testTicket({
    required String printerName,
    required int paperWidth,
    required DateTime now,
  }) {
    final columns = paperWidth == 58 ? 32 : 48;
    String center(String text) {
      final left = ((columns - text.length) / 2).floor().clamp(0, columns);
      return '${' ' * left}$text';
    }

    final date =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final text = [
      '=' * columns,
      center('EL AMINE'),
      '=' * columns,
      '',
      center("TEST D'IMPRESSION"),
      '',
      'Imprimante : $printerName',
      'Largeur : $paperWidth mm',
      'Connexion : Bluetooth',
      'Date : $date',
      '',
      'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
      'abcdefghijklmnopqrstuvwxyz',
      '0123456789',
      '',
      'Alignement gauche',
      center('Centre'),
      '${' ' * (columns - 6)}Droite',
      '-' * columns,
      '',
      center('Test envoye'),
      '=' * columns,
      '',
      '',
      '',
    ].join('\n');
    return _encode(text);
  }

  @override
  Uint8List invoiceTicket({
    required Map<String, dynamic> data,
    required int paperWidth,
  }) {
    final columns = paperWidth == 58 ? 32 : 48;
    final company = Map<String, dynamic>.from(data['company'] as Map? ?? {});
    final customer = data['customer'] is Map
        ? Map<String, dynamic>.from(data['customer'] as Map)
        : const <String, dynamic>{};
    final totals = Map<String, dynamic>.from(data['totals'] as Map? ?? {});
    final items = (data['items'] as List? ?? const []).whereType<Map>().map(
      (item) => Map<String, dynamic>.from(item),
    );

    String fit(String value) => value.length <= columns
        ? value
        : '${value.substring(0, columns - 3)}...';
    String pair(String left, String right) {
      final available = (columns - right.length - 1).clamp(1, columns);
      final safeLeft = left.length > available
          ? left.substring(0, available)
          : left;
      return '$safeLeft${' ' * (columns - safeLeft.length - right.length)}$right';
    }

    final lines = <String>[
      '=' * columns,
      fit(company['name_fr']?.toString() ?? 'EL AMINE'),
      '=' * columns,
      'FACTURE ${data['invoice_number'] ?? data['ticket_number'] ?? ''}',
      if ((data['issued_at']?.toString() ?? '').isNotEmpty)
        fit('Date: ${data['issued_at']}'),
      if (customer.isNotEmpty) fit('Client: ${customer['name'] ?? ''}'),
      '-' * columns,
      for (final item in items) ...[
        fit(item['name']?.toString() ?? ''),
        pair(
          '${item['quantity'] ?? ''} x ${item['unit_price'] ?? ''}',
          item['total']?.toString() ?? '',
        ),
      ],
      '-' * columns,
      pair('Total HT', totals['total_ht']?.toString() ?? ''),
      pair('Remise', totals['discount']?.toString() ?? ''),
      pair('TVA', totals['tax_amount']?.toString() ?? ''),
      pair('TOTAL TTC', totals['total_ttc']?.toString() ?? ''),
      pair('Paye', totals['amount_paid']?.toString() ?? '0.00'),
      pair('Reste', totals['balance_due']?.toString() ?? '0.00'),
      if ((totals['payment_method']?.toString() ?? '').isNotEmpty)
        fit('Paiement: ${totals['payment_method']}'),
      '=' * columns,
      'Merci pour votre visite.',
      '',
      '',
      '',
    ];
    // Do not send native Arabic as mojibake. Raster Arabic and QR are a
    // separate capability that must be validated with the physical printer.
    return _encode(lines.join('\n'));
  }
}
