import 'dart:typed_data';
import 'package:app_alim_gen_mobile/features/printers/domain/printer_print_profile.dart';

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

  test('connects and sends without closing pending printer output', () async {
    final transport = _FakeTransport();
    final stages = <PrinterTestStage>[];
    await PrinterTestService(
      transport,
      _FakeDriver(),
    ).run(printer: printer, onStage: stages.add);

    expect(transport.connectedAddress, printer.bluetoothAddress);
    expect(transport.written, Uint8List.fromList([1, 2, 3]));
    expect(transport.disconnected, isFalse);
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
      throwsA(isA<PrinterTransmissionException>()),
    );
    expect(transport.disconnected, isTrue);
  });

  test('reports a connection failure and still disconnects', () async {
    final transport = _FakeTransport(
      connectError: StateError('connection failed'),
    );
    await expectLater(
      PrinterTestService(transport, _FakeDriver()).run(printer: printer),
      throwsA(isA<PrinterTransmissionException>()),
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
        'company': {
          'name_fr': 'EL AMINE',
          'tax_number': 'NIF-E',
          'nis': 'NIS-E',
          'rc_number': 'RC-E',
          'article_number': 'AI-E',
        },
        'customer': {'name': 'Client', 'tax_number': 'NIF-C'},
        'items': [
          {
            'name': 'Produit',
            'quantity': 1,
            'packaging': 'Carton de 24',
            'unit_price': '100',
            'total': '100',
          },
        ],
        'totals': {
          'total_ht': '100.00',
          'discount': '0.00',
          'tax_amount': '0.00',
          'tax_rate': '19.00',
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
    expect(text, contains('NIF-E'));
    expect(text, contains('NIF-C'));
    expect(text, contains('TVA (19.00%)'));
    expect(text, contains('Carton de 24'));
  });

  test('minimal 58 and 80 mm tickets reject unsafe native text rendering', () {
    const data = {
      'invoice_number': 'FAC-SECRET',
      'ticket_number': 'TCK-SECRET',
      'issued_at': '2026-10-17T10:00:00Z',
      'cashier': 'CAISSIER-SECRET',
      'show_ticket_information': false,
      'show_legal_information': false,
      'company': {
        'name_fr': 'ENTREPRISE-SECRET',
        'address': 'ADRESSE-SOCIETE-SECRET',
        'phone': 'TELEPHONE-SOCIETE-SECRET',
        'tax_number': 'NIF-SECRET',
        'nis': 'NIS-SECRET',
        'rc_number': 'RC-SECRET',
        'article_number': 'AI-SECRET',
      },
      'customer': {
        'name': 'CLIENT-SECRET',
        'phone': 'TELEPHONE-CLIENT-SECRET',
        'address': 'ADRESSE-CLIENT-SECRET',
        'tax_number': 'NIF-CLIENT-SECRET',
      },
      'items': [
        {
          'name': 'PRODUIT-AUTORISE',
          'quantity': 2,
          'packaging': 'CARTON-24',
          'unit_price': '100.00',
          'total': '200.00',
        },
      ],
      'totals': {
        'total_ht': '180.00',
        'discount': '5.00',
        'tax_amount': '25.00',
        'tax_rate': '19.00',
        'total_ttc': '200.00',
        'amount_paid': '200.00',
        'balance_due': '0.00',
        'payment_method': 'ESPECES-SECRET',
      },
      'qr_code': 'QR-SECRET',
      'messages': {'thank_you_fr': 'MERCI-SECRET'},
    };

    for (final width in [58, 80]) {
      expect(
        () =>
            EscPosPrinterDriver().invoiceTicket(data: data, paperWidth: width),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'reason',
            contains('raster'),
          ),
        ),
      );
    }
  });

  test('raster ticket converts RGBA pixels to ESC/POS image bytes', () {
    final bytes = EscPosPrinterDriver().rasterTicket(
      rgba: Uint8List.fromList([
        0,
        0,
        0,
        255,
        255,
        255,
        255,
        255,
        0,
        0,
        0,
        255,
        255,
        255,
        255,
        255,
        0,
        0,
        0,
        255,
        255,
        255,
        255,
        255,
        0,
        0,
        0,
        255,
        255,
        255,
        255,
        255,
      ]),
      width: 8,
      height: 1,
    );
    expect(bytes.sublist(0, 8), [
      0x1b,
      0x40,
      0x1b,
      0x7b,
      0x00,
      0x1d,
      0x42,
      0x00,
    ]);
    expect(bytes.sublist(8, 16), [0x1d, 0x76, 0x30, 0, 1, 0, 1, 0]);
    expect(bytes[16], 0xaa);
    expect(bytes.sublist(bytes.length - 3), [0x1d, 0x56, 0]);
  });

  test('long raster tickets are split into ordered printer bands', () {
    const width = 8;
    const height = 129;
    final rgba = Uint8List(width * height * 4);
    for (var y = 0; y < height; y++) {
      final offset = y * width * 4;
      rgba[offset] = y == 0 ? 0 : 255;
      rgba[offset + 3] = 255;
    }

    final bytes = EscPosPrinterDriver().rasterTicket(
      rgba: rgba,
      width: width,
      height: height,
    );
    final firstBand = [0x1d, 0x76, 0x30, 0, 1, 0, 128, 0];
    final secondBand = [0x1d, 0x76, 0x30, 0, 1, 0, 1, 0];
    expect(bytes, containsSequence(firstBand));
    expect(bytes, containsSequence(secondBand));
    expect(bytes.last, 0x00);
    expect(bytes.sublist(bytes.length - 3), [0x1d, 0x56, 0]);
  });
}

Matcher containsSequence(List<int> expected) => predicate<Uint8List>((actual) {
  for (var start = 0; start <= actual.length - expected.length; start++) {
    var matches = true;
    for (var index = 0; index < expected.length; index++) {
      if (actual[start + index] != expected[index]) {
        matches = false;
        break;
      }
    }
    if (matches) return true;
  }
  return false;
}, 'contains byte sequence $expected');

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
    PrinterPrintProfile profile = const PrinterPrintProfile(),
  }) => Uint8List.fromList([1, 2, 3]);

  @override
  Uint8List invoiceTicket({
    required Map<String, dynamic> data,
    required int paperWidth,
    PrinterPrintProfile profile = const PrinterPrintProfile(),
  }) => Uint8List.fromList([4, 5, 6]);

  @override
  Uint8List rasterTicket({
    required Uint8List rgba,
    required int width,
    required int height,
    PrinterPrintProfile profile = const PrinterPrintProfile(),
  }) => Uint8List.fromList([7, 8, 9]);
}
