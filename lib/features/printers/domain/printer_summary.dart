class PrinterSummary {
  const PrinterSummary({
    required this.id,
    required this.name,
    required this.model,
    required this.connection,
    required this.paperWidth,
    required this.isActive,
    required this.isDefault,
  });
  final int id;
  final String name;
  final String model;
  final String connection;
  final int paperWidth;
  final bool isActive;
  final bool isDefault;
  factory PrinterSummary.fromJson(Map<String, dynamic> json) => PrinterSummary(
    id: (json['id'] as num).toInt(),
    name: json['name']?.toString() ?? '',
    model: json['model_name']?.toString() ?? '',
    connection:
        json['connection_mode_display']?.toString() ??
        json['connection_mode']?.toString() ??
        '',
    paperWidth: (json['paper_width'] as num?)?.toInt() ?? 0,
    isActive: json['is_active'] == true,
    isDefault: json['is_default'] == true,
  );
}

class PrinterDetails {
  const PrinterDetails({
    required this.id,
    required this.name,
    required this.description,
    required this.printerType,
    required this.manufacturer,
    required this.modelName,
    required this.connectionMode,
    required this.localIdentifier,
    required this.bluetoothName,
    required this.bluetoothAddress,
    required this.ipAddress,
    required this.networkPort,
    required this.paperWidth,
    required this.protocol,
    required this.charactersPerLine,
    required this.encoding,
    required this.autoPrint,
    required this.printInvoices,
    required this.printReceipts,
    required this.isDefault,
    required this.isActive,
  });
  final int id, paperWidth, charactersPerLine;
  final int? networkPort;
  final String name,
      description,
      printerType,
      manufacturer,
      modelName,
      connectionMode,
      localIdentifier,
      bluetoothName,
      bluetoothAddress,
      ipAddress,
      protocol,
      encoding;
  final bool autoPrint, printInvoices, printReceipts, isDefault, isActive;
  factory PrinterDetails.fromJson(Map<String, dynamic> j) => PrinterDetails(
    id: (j['id'] as num).toInt(),
    name: j['name']?.toString() ?? '',
    description: j['description']?.toString() ?? '',
    printerType: j['printer_type']?.toString() ?? 'thermal',
    manufacturer: j['manufacturer']?.toString() ?? '',
    modelName: j['model_name']?.toString() ?? '',
    connectionMode: j['connection_mode']?.toString() ?? 'bluetooth',
    localIdentifier: j['local_identifier']?.toString() ?? '',
    bluetoothName: j['bluetooth_name']?.toString() ?? '',
    bluetoothAddress: j['bluetooth_address']?.toString() ?? '',
    ipAddress: j['ip_address']?.toString() ?? '',
    networkPort: (j['network_port'] as num?)?.toInt(),
    paperWidth: (j['paper_width'] as num?)?.toInt() ?? 80,
    protocol: j['protocol']?.toString() ?? 'generic_escpos',
    charactersPerLine: (j['characters_per_line'] as num?)?.toInt() ?? 48,
    encoding: j['encoding']?.toString() ?? 'cp858',
    autoPrint: j['auto_print'] == true,
    printInvoices: j['print_invoices'] == true,
    printReceipts: j['print_receipts'] == true,
    isDefault: j['is_default'] == true,
    isActive: j['is_active'] == true,
  );
}

class PrinterWriteRequest {
  const PrinterWriteRequest(this.data);
  final Map<String, dynamic> data;
  Map<String, dynamic> toJson() => data;
}
