/// Simple user model without complex JSON generation
/// Part of the clean architecture - easy to read and maintain
class UserModel {
  final String id;
  final String email;
  final String? phoneNumber;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? bio;
  final String? job;
  final String? company;
  final String? occupation;
  final String? education;
  final List<String> interests;
  final int? age;
  final String? gender;
  final List<dynamic>
  photos; // Changed to dynamic to handle both string URLs and Photo objects
  final String? location;
  final Map<String, dynamic>? coordinates;
  final bool premium;
  final bool verified;
  final bool emailVerified;
  final bool phoneVerified;
  final String role;
  final List<String> permissions;
  final bool isActive;
  final int? profileCompletionPercentage;
  final DateTime? lastSeen;
  final String? fcmToken;
  final Map<String, dynamic>? preferences;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.id,
    required this.email,
    this.phoneNumber,
    required this.username,
    this.firstName,
    this.lastName,
    this.bio,
    this.job,
    this.company,
    this.occupation,
    this.education,
    this.interests = const [],
    this.age,
    this.gender,
    this.photos = const [],
    this.location,
    this.coordinates,
    this.premium = false,
    this.verified = false,
    this.emailVerified = false,
    this.phoneVerified = false,
    this.role = 'USER',
    this.permissions = const [],
    this.isActive = true,
    this.profileCompletionPercentage = 0,
    this.lastSeen,
    this.fcmToken,
    this.preferences,
    required this.createdAt,
    this.updatedAt,
  });

  // Simple JSON methods without code generation
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'],
      username: json['username'] ?? '',
      firstName: json['firstName'],
      lastName: json['lastName'],
      bio: json['bio'],
      job: json['job'],
      company: json['company'],
      occupation: json['occupation'],
      education: json['education'],
      interests:
          (json['interests'] as List?)
              ?.map((item) {
                // Handle new nested structure: {id, interest: {id, name}}
                if (item is String) return item; // Backward compatibility
                if (item is Map<String, dynamic>) {
                  // Extract interest.name from nested structure
                  return item['interest']?['name'] as String? ?? '';
                }
                return item.toString();
              })
              .where((name) => name.isNotEmpty)
              .toList()
              .cast<String>() ??
          [],
      age: json['age'],
      gender: json['gender'],
      // Backend returns media array with profile photos (category: 'profile_photo')
      // Fall back to 'photos' for backward compatibility with old API responses
      photos: (json['media'] as List?)
              ?.cast<dynamic>()
              .toList() ??
          (json['photos'] != null
              ? (json['photos'] is List ? List<dynamic>.from(json['photos']) : [])
              : []),
      location: json['location'],
      coordinates: json['coordinates'] != null
          ? Map<String, dynamic>.from(json['coordinates'])
          : null,
      premium: json['premium'] ?? false,
      verified: json['verified'] ?? false,
      emailVerified: json['emailVerified'] ?? false,
      phoneVerified: json['phoneVerified'] ?? false,
      role: json['role'] ?? 'USER',
      permissions: json['permissions'] != null
          ? List<String>.from(json['permissions'])
          : [],
      isActive: json['isActive'] ?? true,
      profileCompletionPercentage: json['profileCompletionPercentage'],
      lastSeen: json['lastSeen'] != null
          ? DateTime.parse(json['lastSeen'])
          : null,
      fcmToken: json['fcmToken'],
      preferences: json['preferences'] != null
          ? Map<String, dynamic>.from(json['preferences'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(), // Default to now if not provided
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phoneNumber': phoneNumber,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'bio': bio,
      'job': job,
      'company': company,
      'occupation': occupation,
      'education': education,
      'interests': interests,
      'age': age,
      'gender': gender,
      'photos': photos,
      'location': location,
      'coordinates': coordinates,
      'premium': premium,
      'verified': verified,
      'emailVerified': emailVerified,
      'phoneVerified': phoneVerified,
      'role': role,
      'permissions': permissions,
      'isActive': isActive,
      'profileCompletionPercentage': profileCompletionPercentage,
      'lastSeen': lastSeen?.toIso8601String(),
      'fcmToken': fcmToken,
      'preferences': preferences,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? phoneNumber,
    String? username,
    String? firstName,
    String? lastName,
    String? bio,
    String? job,
    String? company,
    String? occupation,
    String? education,
    List<String>? interests,
    int? age,
    String? gender,
    List<String>? photos,
    String? location,
    Map<String, dynamic>? coordinates,
    bool? premium,
    bool? verified,
    String? role,
    List<String>? permissions,
    bool? isActive,
    int? profileCompletionPercentage,
    DateTime? lastSeen,
    String? fcmToken,
    Map<String, dynamic>? preferences,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      bio: bio ?? this.bio,
      job: job ?? this.job,
      company: company ?? this.company,
      occupation: occupation ?? this.occupation,
      education: education ?? this.education,
      interests: interests ?? this.interests,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      photos: photos ?? this.photos,
      location: location ?? this.location,
      coordinates: coordinates ?? this.coordinates,
      premium: premium ?? this.premium,
      verified: verified ?? this.verified,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      isActive: isActive ?? this.isActive,
      profileCompletionPercentage:
          profileCompletionPercentage ?? this.profileCompletionPercentage,
      lastSeen: lastSeen ?? this.lastSeen,
      fcmToken: fcmToken ?? this.fcmToken,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'UserModel(id: $id, username: $username, email: $email)';
}
