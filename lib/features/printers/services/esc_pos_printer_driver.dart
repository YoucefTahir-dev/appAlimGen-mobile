import 'dart:typed_data';
import 'package:app_alim_gen_mobile/features/printers/domain/printer_print_profile.dart';
import 'package:app_alim_gen_mobile/features/printers/domain/thermal_paper.dart';
import 'package:app_alim_gen_mobile/features/printers/services/printer_transport.dart';

class EscPosPrinterDriver implements PrinterDriver {
  Uint8List _encode(String text, PrinterPrintProfile profile) =>
      Uint8List.fromList([
        0x1b,
        0x40,
        0x1b, 0x7b, 0x00, // leave upside-down mode from any preceding job
        0x1b, 0x56, 0x00, // leave 90-degree character rotation
        ...text
            .replaceFirst(RegExp(r'\n+$'), '')
            .runes
            .map((rune) => rune <= 0xff ? rune : 0x3f),
        ...List.filled(profile.feedLines, 0x0a),
        if (profile.cutPaper) ...[0x1d, 0x56, 0x00],
      ]);

  @override
  Uint8List testTicket({
    required String printerName,
    required int paperWidth,
    required DateTime now,
    PrinterPrintProfile profile = const PrinterPrintProfile(),
  }) {
    profile.validate();
    final columns = ThermalPaperSpec.fromWidth(paperWidth).charactersPerLine;
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
    return _encode(text, profile);
  }

  @override
  Uint8List invoiceTicket({
    required Map<String, dynamic> data,
    required int paperWidth,
    PrinterPrintProfile profile = const PrinterPrintProfile(),
  }) {
    profile.validate();
    final columns = ThermalPaperSpec.fromWidth(paperWidth).charactersPerLine;
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
    List<String> wrap(String value) {
      final result = <String>[];
      for (final source in value.split('\n')) {
        var remaining = source;
        while (remaining.length > columns) {
          result.add(remaining.substring(0, columns));
          remaining = remaining.substring(columns);
        }
        result.add(remaining);
      }
      return result;
    }

    String pair(String left, String right) {
      if (left.length + right.length + 1 > columns) {
        return [...wrap(left), ...wrap(right)].join('\n');
      }
      final available = (columns - right.length - 1).clamp(1, columns);
      final safeLeft = left.length > available
          ? left.substring(0, available)
          : left;
      return '$safeLeft${' ' * (columns - safeLeft.length - right.length)}$right';
    }

    final showTicketInformation =
        data['show_ticket_information'] != false &&
        data['show_legal_information'] != false;
    if (!showTicketInformation) {
      throw StateError(
        'Un ticket sans informations doit utiliser le rendu raster partagé '
        'pour conserver le logo et le nom de son aperçu.',
      );
    }

    const showLegal = true;
    final lines = <String>[
      '=' * columns,
      fit(company['name_fr']?.toString() ?? 'EL AMINE'),
      if ((company['address']?.toString() ?? '').isNotEmpty)
        fit(company['address'].toString()),
      if ((company['phone']?.toString() ?? '').isNotEmpty)
        fit('Tel: ${company['phone']}'),
      if (showLegal && (company['tax_number']?.toString() ?? '').isNotEmpty)
        fit('NIF: ${company['tax_number']}'),
      if (showLegal && (company['nis']?.toString() ?? '').isNotEmpty)
        fit('NIS: ${company['nis']}'),
      if (showLegal && (company['rc_number']?.toString() ?? '').isNotEmpty)
        fit('RC: ${company['rc_number']}'),
      if (showLegal && (company['article_number']?.toString() ?? '').isNotEmpty)
        fit('AI: ${company['article_number']}'),
      '=' * columns,
      'FACTURE ${data['invoice_number'] ?? data['ticket_number'] ?? ''}',
      if ((data['issued_at']?.toString() ?? '').isNotEmpty)
        fit('Date: ${data['issued_at']}'),
      if (customer.isNotEmpty) fit('Client: ${customer['name'] ?? ''}'),
      if (showLegal && (customer['tax_number']?.toString() ?? '').isNotEmpty)
        fit('NIF client: ${customer['tax_number']}'),
      if (showLegal && (customer['nis']?.toString() ?? '').isNotEmpty)
        fit('NIS client: ${customer['nis']}'),
      if (showLegal &&
          (customer['trade_register_number']?.toString() ?? '').isNotEmpty)
        fit('RC client: ${customer['trade_register_number']}'),
      if (showLegal &&
          (customer['article_number']?.toString() ?? '').isNotEmpty)
        fit('AI client: ${customer['article_number']}'),
      '-' * columns,
      for (final item in items) ...[
        ...wrap(
          [
            item['name']?.toString() ?? '',
            if ((item['packaging']?.toString() ?? '').isNotEmpty)
              item['packaging'].toString(),
          ].join(' - '),
        ),
        pair(
          '${item['quantity'] ?? ''} x ${item['unit_price'] ?? ''}',
          item['total']?.toString() ?? '',
        ),
      ],
      '-' * columns,
      pair('Total HT', totals['total_ht']?.toString() ?? ''),
      pair('Remise', totals['discount']?.toString() ?? ''),
      pair(
        'TVA (${totals['tax_rate'] ?? '0'}%)',
        totals['tax_amount']?.toString() ?? '',
      ),
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
    return _encode(lines.join('\n'), profile);
  }

  @override
  Uint8List rasterTicket({
    required Uint8List rgba,
    required int width,
    required int height,
    PrinterPrintProfile profile = const PrinterPrintProfile(),
  }) {
    profile.validate();
    if (width < 1 || height < 1 || rgba.length < width * height * 4) {
      throw ArgumentError('Image raster invalide.');
    }
    final widthBytes = (width + 7) ~/ 8;
    // Copy each row immediately: the row buffer is reused. copy:false would
    // alias all rows and repeat the last row throughout the entire image.
    final output = BytesBuilder()
      ..add(const [0x1b, 0x40])
      ..add(const [0x1b, 0x7b, 0x00]) // normal (not upside-down) mode
      ..add(const [0x1d, 0x42, 0x00]); // normal (not reverse) mode
    final row = Uint8List(widthBytes);
    // Small bands avoid overflowing the raster buffer of compact 58/80 mm
    // printers. Each band is a complete GS v 0 image and is emitted in the
    // same order as the source rows, so no product can be dropped or moved.
    final bandHeight = profile.rasterBandRows;
    for (var bandStart = 0; bandStart < height; bandStart += bandHeight) {
      final currentHeight = (height - bandStart).clamp(0, bandHeight);
      output.add([
        0x1d,
        0x76,
        0x30,
        0x00,
        widthBytes & 0xff,
        (widthBytes >> 8) & 0xff,
        currentHeight & 0xff,
        (currentHeight >> 8) & 0xff,
      ]);
      for (var offset = 0; offset < currentHeight; offset++) {
        final y = bandStart + offset;
        row.fillRange(0, row.length, 0);
        for (var x = 0; x < width; x++) {
          final index = (y * width + x) * 4;
          final alpha = rgba[index + 3];
          final luminance =
              (rgba[index] * 299 +
                  rgba[index + 1] * 587 +
                  rgba[index + 2] * 114) ~/
              1000;
          if (alpha > 32 && luminance < 180) {
            row[x ~/ 8] |= 0x80 >> (x % 8);
          }
        }
        output.add(row);
      }
    }
    output.add(List.filled(profile.feedLines, 0x0a));
    if (profile.cutPaper) output.add(const [0x1d, 0x56, 0x00]);
    return output.toBytes();
  }
}
