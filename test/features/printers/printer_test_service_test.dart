import 'dart:typed_data';

import 'package:app_alim_gen_mobile/features/printers/domain/printer_summary.dart';
import 'package:app_alim_gen_mobile/features/printers/services/printer_test_service.dart';
import 'package:app_alim_gen_mobile/features/printers/services/printer_transport.dart';
import 'package:app_alim_gen_mobile/features/printers/services/esc_pos_printer_driver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const printer = PrinterDetails(
    id: 1,
    name: 'Caisse',
    description: '',
    printerType: 'thermal',
    manufacturer: '',
    modelName: 'RPP02N',
    connectionMode: 'bluetooth',
    localIdentifier: '',
    bluetoothName: 'RPP02N',
    bluetoothAddress: 'AA:BB:CC:DD:EE:FF',
    ipAddress: '',
    networkPort: null,
    paperWidth: 80,
    protocol: 'generic_escpos',
    charactersPerLine: 48,
    encoding: 'cp858',
    autoPrint: false,
    printInvoices: true,
    printReceipts: true,
    isDefault: true,
    isActive: true,
  );

  test('connects to the paired address, writes, then disconnects', () async {
    final transport = _FakeTransport();
    final stages = <PrinterTestStage>[];
    await PrinterTestService(
      transport,
      _FakeDriver(),
    ).run(printer: printer, onStage: stages.add);

    expect(transport.connectedAddress, printer.bluetoothAddress);
    expect(transport.written, Uint8List.fromList([1, 2, 3]));
    expect(transport.disconnected, isTrue);
    expect(stages.last, PrinterTestStage.sent);
  });

  test('stops with a clear error when Bluetooth is disabled', () async {
    final transport = _FakeTransport(enabled: false);
    await expectLater(
      PrinterTestService(transport, _FakeDriver()).run(printer: printer),
      throwsA(isA<StateError>()),
    );
    expect(transport.connectedAddress, isNull);
  });

  test('does not connect when configured printer is not paired', () async {
    final transport = _FakeTransport(
      devices: const [PrinterDevice(name: 'Other', address: '00:00')],
    );
    await expectLater(
      PrinterTestService(transport, _FakeDriver()).run(printer: printer),
      throwsA(isA<StateError>()),
    );
    expect(transport.connectedAddress, isNull);
  });

  test('matches a paired printer by configured name', () async {
    final transport = _FakeTransport(
      devices: const [PrinterDevice(name: 'rpp02n', address: '11:22')],
    );
    const byName = PrinterDetails(
      id: 1,
      name: 'Caisse',
      description: '',
      printerType: 'thermal',
      manufacturer: '',
      modelName: 'RPP02N',
      connectionMode: 'bluetooth',
      localIdentifier: '',
      bluetoothName: 'RPP02N',
      bluetoothAddress: '',
      ipAddress: '',
      networkPort: null,
      paperWidth: 80,
      protocol: 'generic_escpos',
      charactersPerLine: 48,
      encoding: 'cp858',
      autoPrint: false,
      printInvoices: true,
      printReceipts: true,
      isDefault: true,
      isActive: true,
    );
    await PrinterTestService(transport, _FakeDriver()).run(printer: byName);
    expect(transport.connectedAddress, '11:22');
  });

  test('always disconnects when sending data fails', () async {
    final transport = _FakeTransport(writeError: StateError('link lost'));
    await expectLater(
      PrinterTestService(transport, _FakeDriver()).run(printer: printer),
      throwsA(isA<StateError>()),
    );
    expect(transport.disconnected, isTrue);
  });

  test('reports a connection failure and still disconnects', () async {
    final transport = _FakeTransport(
      connectError: StateError('connection failed'),
    );
    await expectLater(
      PrinterTestService(transport, _FakeDriver()).run(printer: printer),
      throwsA(isA<StateError>()),
    );
    expect(transport.written, isNull);
    expect(transport.disconnected, isTrue);
  });

  test('forwards permission errors without attempting connection', () async {
    final transport = _FakeTransport(
      permissionError: StateError('permission refused'),
    );
    await expectLater(
      PrinterTestService(transport, _FakeDriver()).run(printer: printer),
      throwsA(isA<StateError>()),
    );
    expect(transport.connectedAddress, isNull);
  });

  test('invoice ticket uses backend paid and balance values', () {
    final bytes = EscPosPrinterDriver().invoiceTicket(
      data: const {
        'invoice_number': 'FAC-1',
        'issued_at': '2026-09-24T09:00:00Z',
        'company': {'name_fr': 'EL AMINE'},
        'customer': {'name': 'Client'},
        'items': [
          {
            'name': 'Produit',
            'quantity': 1,
            'unit_price': '100',
            'total': '100',
          },
        ],
        'totals': {
          'total_ht': '100.00',
          'discount': '0.00',
          'tax_amount': '0.00',
          'total_ttc': '100.00',
          'amount_paid': '40.00',
          'balance_due': '60.00',
          'payment_method': 'Especes',
        },
      },
      paperWidth: 80,
    );
    final text = String.fromCharCodes(bytes);
    expect(text, contains('Paye'));
    expect(text, contains('40.00'));
    expect(text, contains('Reste'));
    expect(text, contains('60.00'));
  });
}

class _FakeTransport implements PrinterTransport {
  _FakeTransport({
    this.enabled = true,
    this.devices = const [
      PrinterDevice(name: 'RPP02N', address: 'AA:BB:CC:DD:EE:FF'),
    ],
    this.permissionError,
    this.connectError,
    this.writeError,
  });

  final bool enabled;
  final List<PrinterDevice> devices;
  final Object? permissionError, connectError, writeError;
  String? connectedAddress;
  Uint8List? written;
  bool disconnected = false;

  @override
  Future<void> ensurePermissions() async {
    if (permissionError != null) throw permissionError!;
  }

  @override
  Future<bool> isEnabled() async => enabled;

  @override
  Future<List<PrinterDevice>> pairedDevices() async => devices;

  @override
  Future<void> connect(String address) async {
    if (connectError != null) throw connectError!;
    connectedAddress = address;
  }

  @override
  Future<void> write(Uint8List bytes) async {
    if (writeError != null) throw writeError!;
    written = bytes;
  }

  @override
  Future<void> disconnect() async => disconnected = true;
}

class _FakeDriver implements PrinterDriver {
  @override
  Uint8List testTicket({
    required String printerName,
    required int paperWidth,
    required DateTime now,
  }) => Uint8List.fromList([1, 2, 3]);

  @override
  Uint8List invoiceTicket({
    required Map<String, dynamic> data,
    required int paperWidth,
  }) => Uint8List.fromList([4, 5, 6]);
}
