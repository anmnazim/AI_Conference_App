/// User profile stored in Firestore `users` collection.
class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String role; // 'student' | 'scholar'
  final String? institution;

  UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.institution,
  });

  factory UserProfile.fromMap(String uid, Map<String, dynamic> map) {
    return UserProfile(
      uid: uid,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      role: map['role'] as String? ?? 'student',
      institution: map['institution'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'institution': institution,
      };
}
