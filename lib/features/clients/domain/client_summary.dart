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

class ClientDetails {
  const ClientDetails({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.wilaya,
    required this.customerType,
    required this.email,
    required this.taxNumber,
    required this.balance,
    required this.notes,
    this.latitude,
    this.longitude,
    this.locationAccuracy,
    this.formattedAddress,
    this.placeId,
  });
  final int id;
  final String name,
      phone,
      address,
      wilaya,
      customerType,
      email,
      taxNumber,
      balance,
      notes;
  final double? latitude, longitude, locationAccuracy;
  final String? formattedAddress, placeId;

  factory ClientDetails.fromJson(Map<String, dynamic> json) => ClientDetails(
    id: (json['id'] as num).toInt(),
    name: json['name']?.toString() ?? '',
    phone: json['phone']?.toString() ?? '',
    address: json['address']?.toString() ?? '',
    wilaya: json['wilaya']?.toString() ?? '',
    customerType: json['customer_type']?.toString() ?? 'RETAIL',
    email: json['email']?.toString() ?? '',
    taxNumber: json['tax_number']?.toString() ?? '',
    balance: json['balance']?.toString() ?? '0.00',
    notes: json['notes']?.toString() ?? '',
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    locationAccuracy: (json['location_accuracy'] as num?)?.toDouble(),
    formattedAddress: json['formatted_address']?.toString(),
    placeId: json['place_id']?.toString(),
  );
}

class ClientWriteRequest {
  const ClientWriteRequest({
    required this.name,
    required this.phone,
    required this.address,
    required this.wilaya,
    required this.customerType,
    required this.email,
    required this.taxNumber,
    required this.balance,
    required this.notes,
    this.latitude,
    this.longitude,
    this.locationAccuracy,
    this.formattedAddress,
    this.placeId,
  });
  final String name,
      phone,
      address,
      wilaya,
      customerType,
      email,
      taxNumber,
      balance,
      notes;
  final double? latitude, longitude, locationAccuracy;
  final String? formattedAddress, placeId;
  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'address': address,
    'wilaya': wilaya,
    'customer_type': customerType,
    'email': email,
    'tax_number': taxNumber,
    'balance': balance,
    'notes': notes,
    'latitude': latitude,
    'longitude': longitude,
    'location_accuracy': locationAccuracy,
    'formatted_address': formattedAddress,
    'place_id': placeId,
  };
}
