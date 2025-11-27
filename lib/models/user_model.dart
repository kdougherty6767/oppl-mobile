class AppUser {
  final String id;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String role; // admin | rep | user
  final int? handicap;
  final int? membershipExpiry; // millis since epoch

  AppUser({
    required this.id,
    required this.role,
    this.firstName,
    this.lastName,
    this.email,
    this.handicap,
    this.membershipExpiry,
  });

  factory AppUser.fromMap(String id, Map<String, dynamic> data) {
    return AppUser(
      id: id,
      firstName: data['firstName'] as String?,
      lastName: data['lastName'] as String?,
      email: data['email'] as String?,
      role: (data['role'] as String?) ?? 'user',
      handicap: (data['handicap'] as num?)?.toInt(),
      membershipExpiry: (data['membershipExpiry'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'role': role,
      'handicap': handicap,
      'membershipExpiry': membershipExpiry,
    }..removeWhere((key, value) => value == null);
  }
}
