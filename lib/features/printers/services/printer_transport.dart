import 'dart:typed_data';

class PrinterDevice {
  const PrinterDevice({required this.name, required this.address});
  final String name, address;
}

abstract class PrinterTransport {
  Future<void> ensurePermissions();
  Future<bool> isEnabled();
  Future<List<PrinterDevice>> pairedDevices();
  Future<void> connect(String address);
  Future<void> write(Uint8List bytes);
  Future<void> disconnect();
}

abstract class PrinterDriver {
  Uint8List testTicket({
    required String printerName,
    required int paperWidth,
    required DateTime now,
  });

  Uint8List invoiceTicket({
    required Map<String, dynamic> data,
    required int paperWidth,
  });

  Uint8List rasterTicket({
    required Uint8List rgba,
    required int width,
    required int height,
  });
}
