enum UserRole { delegate, enterprise, admin }

class User {
  final String id;
  final String email;
  final String name;
  final String role;
  final UserRole userRole;
  final String company;
  final String? phone;
  final String? region;
  bool isBlocked;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.userRole,
    required this.company,
    this.phone,
    this.region,
    this.isBlocked = false,
  });
  String get roleName {
    return userRole.name.toUpperCase();
  }
}
