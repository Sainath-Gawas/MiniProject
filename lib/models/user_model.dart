class AppUser {
  final String uid;
  final String email;
  final String name;
  final String? phone;
  final String role;
  final bool premium;
  final bool isPremium; // New field for premium status
  final String uiMode; // UI mode: "light", "dark", "focus", "amoled"
  final String? semester; // current selected semester
  final List<String> semesters; // list of available semesters
  final bool attendanceNotificationsEnabled;

  AppUser({
    required this.uid,
    required this.email,
    required this.name,
    this.phone,
    required this.role,
    required this.premium,
    bool? isPremium,
    String? uiMode,
    this.semester,
    this.semesters = const [],
    this.attendanceNotificationsEnabled = true,
  })  : isPremium = isPremium ?? premium,
        uiMode = uiMode ?? 'light';

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    return AppUser(
      uid: uid,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'],
      role: data['role'] ?? 'user',
      premium: data['premium'] ?? false,
      isPremium: data['isPremium'] ?? data['premium'] ?? false,
      uiMode: data['uiMode'] ?? 'light',
      semester: data['semester'],
      semesters: List<String>.from(data['semesters'] ?? []),
      attendanceNotificationsEnabled:
          data['attendanceNotificationsEnabled'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'phone': phone,
      'role': role,
      'premium': premium,
      'isPremium': isPremium,
      'uiMode': uiMode,
      'semester': semester,
      'semesters': semesters,
      'attendanceNotificationsEnabled': attendanceNotificationsEnabled,
    };
  }
}
