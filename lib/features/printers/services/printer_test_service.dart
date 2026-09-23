import 'dart:convert';
import 'dart:typed_data';
import 'package:app_alim_gen_mobile/features/printers/domain/printer_summary.dart';
import 'package:app_alim_gen_mobile/features/printers/services/printer_transport.dart';

enum PrinterTestStage {
  permissions,
  bluetooth,
  device,
  connecting,
  connected,
  sent,
}

class PrinterTestService {
  const PrinterTestService(this.transport, this.driver);
  final PrinterTransport transport;
  final PrinterDriver driver;
  Future<void> run({
    required PrinterDetails printer,
    Map<String, dynamic>? serverPayload,
    void Function(PrinterTestStage)? onStage,
  }) async {
    final encoded = serverPayload?['payload'];
    final bytes = encoded is String && encoded.isNotEmpty
        ? Uint8List.fromList(base64Decode(encoded))
        : driver.testTicket(
            printerName: printer.bluetoothName.isEmpty
                ? printer.name
                : printer.bluetoothName,
            paperWidth: printer.paperWidth,
            now: DateTime.now(),
          );
    await send(printer: printer, bytes: bytes, onStage: onStage);
  }

  Future<void> send({
    required PrinterDetails printer,
    required Uint8List bytes,
    void Function(PrinterTestStage)? onStage,
  }) async {
    onStage?.call(PrinterTestStage.permissions);
    await transport.ensurePermissions();
    onStage?.call(PrinterTestStage.bluetooth);
    if (!await transport.isEnabled()) throw StateError('Bluetooth désactivé.');
    onStage?.call(PrinterTestStage.device);
    final devices = await transport.pairedDevices();
    final configured = printer.bluetoothAddress.trim().toUpperCase();
    PrinterDevice? device;
    for (final d in devices) {
      if ((configured.isNotEmpty && d.address.toUpperCase() == configured) ||
          d.name.toLowerCase() == printer.bluetoothName.trim().toLowerCase()) {
        device = d;
        break;
      }
    }
    if (device == null) {
      throw StateError(
        'Imprimante ${printer.bluetoothName} introuvable ou non appairée.',
      );
    }
    onStage?.call(PrinterTestStage.connecting);
    try {
      await transport.connect(device.address);
      onStage?.call(PrinterTestStage.connected);
      await transport.write(bytes);
      onStage?.call(PrinterTestStage.sent);
    } finally {
      await transport.disconnect();
    }
  }
}
