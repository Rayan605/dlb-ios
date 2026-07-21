class AppUser {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String gender; // 'M' | 'F' | 'X'
  final String social;
  final bool isAdmin;
  final bool isScanner;

  const AppUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.social,
    required this.isAdmin,
    required this.isScanner,
  });

  String get fullName => '$firstName $lastName'.trim();
  bool get isGirl => gender == 'F';
  bool get canScan => isScanner || isAdmin;

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'] as int,
        email: j['email'] as String? ?? '',
        firstName: j['first_name'] as String? ?? '',
        lastName: j['last_name'] as String? ?? '',
        gender: j['gender'] as String? ?? 'X',
        social: j['social'] as String? ?? '',
        isAdmin: j['is_admin'] == true || j['is_admin'] == 1,
        isScanner: j['is_scanner'] == true || j['is_scanner'] == 1,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'gender': gender,
        'social': social,
        'is_admin': isAdmin,
        'is_scanner': isScanner,
      };
}
