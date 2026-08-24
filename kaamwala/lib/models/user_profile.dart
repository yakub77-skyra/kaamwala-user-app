/// users table model - Phase 3 section 7.1.
library;

enum UserRole { client, worker }

class UserProfile {
  const UserProfile({
    required this.id,
    required this.phone,
    this.name = '',
    this.role = UserRole.client,
    this.city = '',
    this.photoUrl,
  });

  final String id;
  final String phone;
  final String name;
  final UserRole role;
  final String city;
  final String? photoUrl;

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
    id: map['id'] as String,
    phone: (map['phone'] ?? '') as String,
    name: (map['name'] ?? '') as String,
    role: map['role'] == 'worker' ? UserRole.worker : UserRole.client,
    city: (map['city'] ?? '') as String,
    photoUrl: map['photo_url'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'phone': phone,
    'name': name,
    'role': role == UserRole.worker ? 'worker' : 'client',
    'city': city,
    'photo_url': photoUrl,
  };
}
