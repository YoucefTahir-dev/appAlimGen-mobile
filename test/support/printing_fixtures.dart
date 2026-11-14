import 'dart:typed_data';

import 'package:app_alim_gen_mobile/features/business_lists/domain/business_entities.dart';
import 'package:app_alim_gen_mobile/features/printers/domain/printer_summary.dart';
import 'package:app_alim_gen_mobile/features/printers/services/printer_transport.dart';

const exampleProductNames = [
  'FLORIDA STICK 20°7',
  'FLORIDA DRAGEES',
  'SWEET MIN',
  'SORTI SACHET DRAGEE 24PCS',
  'CHW SORTI 9pcs',
  'LIVINDA 900G MELANGE',
  'KOJ TWAM 100pcs',
];

SaleDetails printingSale({
  int count = 7,
  bool information = false,
  SaleCompanyDetails company = const SaleCompanyDetails(
    name: 'COMPANY-PRIVATE',
    taxNumber: 'NIF-PRIVATE',
  ),
}) {
  final quantities = [1, 2, 3, 4, 5, 6, 8];
  final prices = [10000, 10000, 10000, 10000, 1000, 2500, 2620];
  final lines = List.generate(count, (index) {
    final quantity = index < 7 ? quantities[index] : index + 1;
    final price = index < 7 ? prices[index] : 100 + index;
    return SaleLineDetails(
      id: 1000 - index,
      productId: index + 1,
      productName: index < 7
          ? exampleProductNames[index]
          : 'ARTICLE-${index.toString().padLeft(3, '0')}',
      packagingId: index.isEven ? 1 : null,
      packagingName: index.isEven ? 'Carton 24' : 'Piece',
      quantity: quantity,
      stockQuantity: quantity * (index.isEven ? 24 : 1),
      unitPrice: price.toStringAsFixed(2),
      total: (quantity * price).toStringAsFixed(2),
    );
  });
  final total = lines
      .fold<int>(0, (sum, line) => sum + double.parse(line.total).toInt())
      .toStringAsFixed(2);
  return SaleDetails(
    id: 37,
    number: 'INVOICE-PRIVATE',
    ticketNumber: 'TICKET-PRIVATE',
    date: '2026-11-01T12:00:00Z',
    client: const SaleClientDetails(
      id: 1,
      name: 'CLIENT-PRIVATE',
      phone: 'PHONE-PRIVATE',
      address: 'ADDRESS-PRIVATE',
      customerType: 'Retail',
    ),
    company: company,
    lines: lines,
    subtotal: total,
    discount: '0.00',
    taxRate: '0.00',
    taxAmount: '0.00',
    total: total,
    amountPaid: '0.00',
    balanceDue: total,
    paymentType: 'PAYMENT-PRIVATE',
    paymentTypeCode: 'cash',
    paymentStatus: 'unpaid',
    payments: const [],
    showLegalInformation: information,
    capabilities: const SaleCapabilities(
      canUpdate: false,
      canDelete: false,
      canViewInvoice: true,
      canViewPdf: true,
      canPrint: true,
      canAddPayment: false,
      canCancel: false,
    ),
  );
}

PrinterDetails printingPrinter([int width = 80]) => PrinterDetails(
  id: 1,
  name: 'Test printer',
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
  paperWidth: width,
  protocol: 'generic_escpos',
  charactersPerLine: width == 58 ? 32 : 48,
  encoding: 'cp858',
  autoPrint: false,
  printInvoices: true,
  printReceipts: true,
  isDefault: true,
  isActive: true,
);

class RecordingPrinterTransport implements PrinterTransport {
  RecordingPrinterTransport({this.writeLatency = Duration.zero});
  final Duration writeLatency;
  final chunks = <Uint8List>[];
  final events = <String>[];
  int activeWrites = 0, maxConcurrentWrites = 0, attempts = 0;
  int? failAt;
  bool cleanupFails = false;

  Uint8List get stream =>
      Uint8List.fromList(chunks.expand((chunk) => chunk).toList());
  @override
  Future<void> ensurePermissions() async {}
  @override
  Future<bool> isEnabled() async => true;
  @override
  Future<List<PrinterDevice>> pairedDevices() async => const [
    PrinterDevice(name: 'RPP02N', address: 'AA:BB:CC:DD:EE:FF'),
  ];
  @override
  Future<void> connect(String address) async => events.add('connect');
  @override
  Future<void> write(Uint8List bytes) async {
    attempts++;
    activeWrites++;
    if (activeWrites > maxConcurrentWrites) maxConcurrentWrites = activeWrites;
    try {
      // Yield as an actual asynchronous/slow transport would. Missing awaits
      // or parallel chunks make maxConcurrentWrites exceed one.
      await Future<void>.delayed(writeLatency);
      if (attempts == failAt) throw StateError('simulated link loss');
      chunks.add(Uint8List.fromList(bytes));
      events.add('write');
    } finally {
      activeWrites--;
    }
  }

  @override
  Future<void> disconnect() async {
    events.add('disconnect');
    if (cleanupFails) throw StateError('cleanup failure');
  }
}
