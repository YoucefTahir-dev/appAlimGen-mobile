class CompanySettings {
  const CompanySettings({
    required this.companyName,
    required this.address,
    required this.phone,
    required this.email,
    required this.rcNumber,
    required this.taxNumber,
    required this.nis,
    required this.articleNumber,
    required this.taxRate,
    this.logoUrl,
  });

  final String companyName;
  final String address;
  final String phone;
  final String email;
  final String rcNumber;
  final String taxNumber;
  final String nis;
  final String articleNumber;
  final String taxRate;
  final String? logoUrl;

  factory CompanySettings.fromJson(Map<String, dynamic> json) =>
      CompanySettings(
        companyName: json['company_name']?.toString() ?? '',
        address: json['address']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        rcNumber: json['rc_number']?.toString() ?? '',
        taxNumber: json['tax_number']?.toString() ?? '',
        nis: json['nis']?.toString() ?? '',
        articleNumber: json['article_number']?.toString() ?? '',
        taxRate: json['tax_rate']?.toString() ?? '19.00',
        logoUrl: json['logo_url']?.toString(),
      );

  Map<String, dynamic> toJson() => {
    'company_name': companyName,
    'address': address,
    'phone': phone,
    'email': email,
    'rc_number': rcNumber,
    'tax_number': taxNumber,
    'nis': nis,
    'article_number': articleNumber,
    'tax_rate': taxRate,
  };
}
