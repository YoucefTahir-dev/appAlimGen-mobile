import 'dart:convert';
import 'dart:typed_data';
import 'package:app_alim_gen_mobile/features/printers/domain/printer_print_profile.dart';
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
  PrinterTestService(this.transport, this.driver, {this.pause = _pause});
  final PrinterTransport transport;
  final PrinterDriver driver;
  final Future<void> Function(Duration) pause;
  Future<void> _tail = Future<void>.value();
  static Future<void> _pause(Duration duration) =>
      Future<void>.delayed(duration);
  Future<void> run({
    required PrinterDetails printer,
    Map<String, dynamic>? serverPayload,
    void Function(PrinterTestStage)? onStage,
    PrinterPrintProfile profile = const PrinterPrintProfile(),
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
            profile: profile,
          );
    await send(
      printer: printer,
      bytes: bytes,
      onStage: onStage,
      profile: profile,
    );
  }

  Future<void> send({
    required PrinterDetails printer,
    required Uint8List bytes,
    void Function(PrinterTestStage)? onStage,
    void Function(int sent, int total)? onProgress,
    PrinterPrintProfile profile = const PrinterPrintProfile(),
  }) {
    // Serialize whole jobs (not just individual writes), including connect and
    // cleanup. Snapshot bytes before queueing so callers cannot mutate a job.
    final snapshot = Uint8List.fromList(bytes);
    final task = _tail.then(
      (_) => _send(
        printer: printer,
        bytes: snapshot,
        onStage: onStage,
        onProgress: onProgress,
        profile: profile,
      ),
    );
    _tail = task.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return task;
  }

  Future<void> _send({
    required PrinterDetails printer,
    required Uint8List bytes,
    required PrinterPrintProfile profile,
    void Function(PrinterTestStage)? onStage,
    void Function(int sent, int total)? onProgress,
  }) async {
    profile.validate();
    if (bytes.isEmpty) throw StateError('Le document à transmettre est vide.');
    onStage?.call(PrinterTestStage.permissions);
    await transport.ensurePermissions();
    onStage?.call(PrinterTestStage.bluetooth);
    if (!await transport.isEnabled()) throw StateError('Bluetooth désactivé.');
    onStage?.call(PrinterTestStage.device);
    final devices = await transport.pairedDevices();
    final configured = printer.bluetoothAddress.trim().toUpperCase();
    PrinterDevice? device;
    for (final d in devices) {
      if (configured.isNotEmpty
          ? d.address.toUpperCase() == configured
          : d.name.toLowerCase() ==
                printer.bluetoothName.trim().toLowerCase()) {
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
    var sent = 0;
    try {
      await transport.connect(device.address);
      onStage?.call(PrinterTestStage.connected);
      for (var offset = 0; offset < bytes.length;) {
        final end = (offset + profile.chunkBytes).clamp(0, bytes.length);
        await transport.write(Uint8List.sublistView(bytes, offset, end));
        sent = end;
        onProgress?.call(sent, bytes.length);
        offset = end;
        if (offset < bytes.length && profile.pauseMs > 0) {
          await pause(Duration(milliseconds: profile.pauseMs));
        }
      }
      onStage?.call(PrinterTestStage.sent);
      // Keep SPP open. Android close() aborts pending socket operations; flush
      // does not acknowledge the paper. The native layer reuses this connection.
    } catch (error, stack) {
      try {
        await transport.disconnect();
      } catch (_) {
        // Never replace the original transmission failure with a cleanup error.
      }
      Error.throwWithStackTrace(
        PrinterTransmissionException(sent, bytes.length, error),
        stack,
      );
    }
  }
}

class PrinterTransmissionException implements Exception {
  const PrinterTransmissionException(
    this.sentBytes,
    this.totalBytes,
    this.cause,
  );

  /// Completed writes only; the failing write can itself have been partial.
  final int sentBytes, totalBytes;
  final Object cause;

  @override
  String toString() =>
      'Transmission interrompue ($sentBytes/$totalBytes octets '
      'dans les écritures terminées). Une partie du ticket peut déjà être sortie. '
      'Vérifiez le papier avant de réimprimer. $cause';
}
