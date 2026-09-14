import 'package:app_alim_gen_mobile/core/storage/token_storage.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.role,
    required this.permissions,
  });

  final int id;
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String role;
  final Set<String> permissions;

  String get displayName {
    final fullName = '$firstName $lastName'.trim();
    return fullName.isEmpty ? username : fullName;
  }

  bool can(String permission) => permissions.contains(permission);

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: (json['id'] as num).toInt(),
    username: json['username']?.toString() ?? '',
    firstName: json['first_name']?.toString() ?? '',
    lastName: json['last_name']?.toString() ?? '',
    email: json['email']?.toString() ?? '',
    phone: json['phone']?.toString() ?? '',
    role: json['role']?.toString() ?? '',
    permissions: ((json['permissions'] as List?) ?? const [])
        .map((item) => item.toString())
        .toSet(),
  );
}

class LoginResult {
  const LoginResult({required this.tokens, required this.user});
  final StoredTokens tokens;
  final UserProfile user;
}
