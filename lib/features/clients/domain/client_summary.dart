class ClientSummary {
  const ClientSummary({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.customerType,
  });
  final int id;
  final String name;
  final String phone;
  final String address;
  final String customerType;
  factory ClientSummary.fromJson(Map<String, dynamic> json) => ClientSummary(
    id: (json['id'] as num).toInt(),
    name: json['name']?.toString() ?? '',
    phone: json['phone']?.toString() ?? '',
    address: json['address']?.toString() ?? '',
    customerType: json['customer_type']?.toString() ?? '',
  );
}
