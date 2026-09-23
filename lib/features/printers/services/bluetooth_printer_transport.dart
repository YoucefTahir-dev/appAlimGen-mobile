import 'package:app_alim_gen_mobile/features/printers/services/printer_transport.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class PrinterTransportException implements Exception {
  const PrinterTransportException(this.code, this.message);
  final String code, message;
  @override
  String toString() => message;
}

class BluetoothPrinterTransport implements PrinterTransport {
  BluetoothPrinterTransport({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('com.elamine.erp/bluetooth');
  final MethodChannel _channel;
  @override
  Future<void> ensurePermissions() async {
    final result = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();
    if (result.values.any((s) => !s.isGranted)) {
      throw const PrinterTransportException(
        'permission_denied',
        'Permission Bluetooth refusée.',
      );
    }
  }

  @override
  Future<bool> isEnabled() async =>
      await _channel.invokeMethod<bool>('isEnabled') ?? false;
  @override
  Future<List<PrinterDevice>> pairedDevices() async {
    final devices = await _channel.invokeListMethod<dynamic>('pairedDevices');
    return (devices ?? const [])
        .whereType<Map>()
        .map(
          (device) => PrinterDevice(
            name: device['name']?.toString() ?? 'Inconnu',
            address: device['address']?.toString() ?? '',
          ),
        )
        .toList(growable: false);
  }
  @override
  Future<void> connect(String address) async {
    final ok = await _channel
        .invokeMethod<bool>('connect', {'address': address})
        .timeout(const Duration(seconds: 12));
    if (ok != true) {
      throw const PrinterTransportException(
        'connection_failure',
        'Impossible de se connecter à l’imprimante.',
      );
    }
  }

  @override
  Future<void> write(Uint8List bytes) async {
    final ok = await _channel.invokeMethod<bool>('write', {'bytes': bytes});
    if (ok != true) {
      throw const PrinterTransportException(
        'print_failure',
        'Connexion interrompue pendant l’envoi.',
      );
    }
  }

  @override
  Future<void> disconnect() async {
    await _channel.invokeMethod<void>('disconnect');
  }
}
