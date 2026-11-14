import 'dart:convert';

import 'package:app_alim_gen_mobile/features/printers/domain/printer_print_profile.dart';
import 'package:app_alim_gen_mobile/features/printers/domain/printer_summary.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class PrinterPrintProfileStore {
  Future<PrinterPrintProfile> read(PrinterDetails printer);
  Future<void> save(PrinterDetails printer, PrinterPrintProfile profile);
}

class LocalPrinterPrintProfileStore implements PrinterPrintProfileStore {
  const LocalPrinterPrintProfileStore(this.storage);
  final FlutterSecureStorage storage;

  String _key(PrinterDetails printer) =>
      'printing.profile.v1.${printer.bluetoothAddress.trim().isEmpty ? 'id-${printer.id}' : printer.bluetoothAddress.trim().toUpperCase()}';

  @override
  Future<PrinterPrintProfile> read(PrinterDetails printer) async {
    final encoded = await storage.read(key: _key(printer));
    if (encoded == null) return const PrinterPrintProfile();
    try {
      return PrinterPrintProfile.fromJson(
        Map<String, dynamic>.from(jsonDecode(encoded) as Map),
      );
    } on Object {
      // A corrupt local preference never changes the sale or the server profile.
      return const PrinterPrintProfile();
    }
  }

  @override
  Future<void> save(PrinterDetails printer, PrinterPrintProfile profile) {
    profile.validate();
    return storage.write(
      key: _key(printer),
      value: jsonEncode(profile.toJson()),
    );
  }
}
