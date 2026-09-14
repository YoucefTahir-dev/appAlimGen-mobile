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
