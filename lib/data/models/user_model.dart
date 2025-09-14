/// Simple user model without complex JSON generation
/// Part of the clean architecture - easy to read and maintain
class UserModel {
  final String id;
  final String email;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? bio;
  final List<String> interests;
  final int? age;
  final String? gender;
  final List<String> photos;
  final String? location;
  final Map<String, dynamic>? coordinates;
  final bool premium;
  final bool verified;
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
    required this.username,
    this.firstName,
    this.lastName,
    this.bio,
    this.interests = const [],
    this.age,
    this.gender,
    this.photos = const [],
    this.location,
    this.coordinates,
    this.premium = false,
    this.verified = false,
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
      username: json['username'] ?? '',
      firstName: json['firstName'],
      lastName: json['lastName'],
      bio: json['bio'],
      interests: json['interests'] != null 
          ? List<String>.from(json['interests'])
          : [],
      age: json['age'],
      gender: json['gender'],
      photos: json['photos'] != null 
          ? List<String>.from(json['photos'])
          : [],
      location: json['location'],
      coordinates: json['coordinates'] != null 
          ? Map<String, dynamic>.from(json['coordinates'])
          : null,
      premium: json['premium'] ?? false,
      verified: json['verified'] ?? false,
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
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'bio': bio,
      'interests': interests,
      'age': age,
      'gender': gender,
      'photos': photos,
      'location': location,
      'coordinates': coordinates,
      'premium': premium,
      'verified': verified,
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
    String? username,
    String? firstName,
    String? lastName,
    String? bio,
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
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      bio: bio ?? this.bio,
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
