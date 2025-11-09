class AppUser {
  final String uid;
  final String email;
  final String name;
  final String? phone;
  final String role;
  final bool premium;
  final String? semester; // current selected semester
  final List<String> semesters; // list of available semesters

  AppUser({
    required this.uid,
    required this.email,
    required this.name,
    this.phone,
    required this.role,
    required this.premium,
    this.semester,
    this.semesters = const [],
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    return AppUser(
      uid: uid,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'],
      role: data['role'] ?? 'user',
      premium: data['premium'] ?? false,
      semester: data['semester'],
      semesters: List<String>.from(data['semesters'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'phone': phone,
      'role': role,
      'premium': premium,
      'semester': semester,
      'semesters': semesters,
    };
  }
}
