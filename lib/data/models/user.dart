import 'package:equatable/equatable.dart';

/// User model for the application
class User extends Equatable {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? displayName;
  final String? profileImageUrl;
  final String? bio;
  final DateTime? birthDate;
  final String? location;
  final List<String> interests;
  final bool isOnline;
  final DateTime? lastSeen;
  final bool isVerified;
  final bool isPremium;
  final Map<String, dynamic>? preferences;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.displayName,
    this.profileImageUrl,
    this.bio,
    this.birthDate,
    this.location,
    this.interests = const [],
    this.isOnline = false,
    this.lastSeen,
    this.isVerified = false,
    this.isPremium = false,
    this.preferences,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create User from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      displayName: json['displayName'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      bio: json['bio'] as String?,
      birthDate: json['birthDate'] != null
          ? DateTime.parse(json['birthDate'] as String)
          : null,
      location: json['location'] as String?,
      interests: (json['interests'] as List?)?.cast<String>() ?? [],
      isOnline: json['isOnline'] as bool? ?? false,
      lastSeen: json['lastSeen'] != null
          ? DateTime.parse(json['lastSeen'] as String)
          : null,
      isVerified: json['isVerified'] as bool? ?? false,
      isPremium: json['isPremium'] as bool? ?? false,
      preferences: json['preferences'] as Map<String, dynamic>?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Convert User to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'displayName': displayName,
      'profileImageUrl': profileImageUrl,
      'bio': bio,
      'birthDate': birthDate?.toIso8601String(),
      'location': location,
      'interests': interests,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
      'isVerified': isVerified,
      'isPremium': isPremium,
      'preferences': preferences,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Get full name
  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    } else if (firstName != null) {
      return firstName!;
    } else if (lastName != null) {
      return lastName!;
    }
    return displayName ?? email.split('@').first;
  }

  /// Get display name (fallback to full name or email)
  String get name => displayName ?? fullName;

  /// Get age from birth date
  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - birthDate!.year;
    if (now.month < birthDate!.month ||
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      age--;
    }
    return age;
  }

  /// Check if user is currently online
  bool get isCurrentlyOnline => isOnline;

  /// Get status text (Online, Last seen, etc.)
  String get statusText {
    if (isOnline) return 'Online';
    if (lastSeen != null) {
      final now = DateTime.now();
      final difference = now.difference(lastSeen!);
      
      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return 'Last seen ${lastSeen!.day}/${lastSeen!.month}';
      }
    }
    return 'Offline';
  }

  /// Copy with method for immutable updates
  User copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? displayName,
    String? profileImageUrl,
    String? bio,
    DateTime? birthDate,
    String? location,
    List<String>? interests,
    bool? isOnline,
    DateTime? lastSeen,
    bool? isVerified,
    bool? isPremium,
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      displayName: displayName ?? this.displayName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bio: bio ?? this.bio,
      birthDate: birthDate ?? this.birthDate,
      location: location ?? this.location,
      interests: interests ?? this.interests,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      isVerified: isVerified ?? this.isVerified,
      isPremium: isPremium ?? this.isPremium,
      preferences: preferences ?? this.preferences,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        firstName,
        lastName,
        displayName,
        profileImageUrl,
        bio,
        birthDate,
        location,
        interests,
        isOnline,
        lastSeen,
        isVerified,
        isPremium,
        preferences,
        metadata,
        createdAt,
        updatedAt,
      ];
}
