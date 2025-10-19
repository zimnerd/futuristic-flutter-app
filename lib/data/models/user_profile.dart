import '../models/user.dart';
import 'photo.dart';

/// Extended user profile for AI analysis
class UserProfile {
  final String id;
  final String? displayName;
  final String? bio;
  final int? age;
  final String? gender;
  final String? location;
  final List<String> interests;
  final List<Photo> photos;
  final Map<String, dynamic>? preferences;
  final ProfilePersonality? personality;
  final List<String> lifestyle;
  final List<String> relationshipGoals;

  const UserProfile({
    required this.id,
    this.displayName,
    this.bio,
    this.age,
    this.gender,
    this.location,
    this.interests = const [],
    this.photos = const [],
    this.preferences,
    this.personality,
    this.lifestyle = const [],
    this.relationshipGoals = const [],
  });

  /// Create UserProfile from User model
  factory UserProfile.fromUser(User user) {
    return UserProfile(
      id: user.id,
      displayName:
          user.displayName ??
          '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim(),
      bio: user.bio,
      age: user.age,
      gender: user.gender,
      location: user.location,
      interests: user.interests,
      photos: user.photos, // Already Photo objects
      preferences: user.preferences,
      personality: user.metadata != null
          ? ProfilePersonality.fromJson(user.metadata!)
          : null,
      lifestyle: user.metadata?['lifestyle'] != null
          ? List<String>.from(user.metadata!['lifestyle'])
          : [],
      relationshipGoals: user.metadata?['relationshipGoals'] != null
          ? List<String>.from(user.metadata!['relationshipGoals'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'bio': bio,
      'age': age,
      'gender': gender,
      'location': location,
      'interests': interests,
      'photos': photos.map((photo) => photo.toJson()).toList(),
      'preferences': preferences,
      'personality': personality?.toJson(),
      'lifestyle': lifestyle,
      'relationshipGoals': relationshipGoals,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      displayName: json['displayName'],
      bio: json['bio'],
      age: json['age'],
      gender: json['gender'],
      location: json['location'],
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
              .toList() ??
          [],
      photos:
          (json['photos'] as List?)?.map((photo) {
            // Handle both string URLs (backward compatibility) and Photo objects
            if (photo is String) {
              return Photo.fromUrl(photo);
            }
            if (photo is Map<String, dynamic>) {
              return Photo.fromJson(photo);
            }
            return Photo.fromUrl(photo.toString());
          }).toList() ??
          [],
      preferences: json['preferences'],
      personality: json['personality'] != null
          ? ProfilePersonality.fromJson(json['personality'])
          : null,
      lifestyle: json['lifestyle'] != null
          ? List<String>.from(json['lifestyle'])
          : [],
      relationshipGoals: json['relationshipGoals'] != null
          ? List<String>.from(json['relationshipGoals'])
          : [],
    );
  }
}

/// Personality traits for compatibility analysis
class ProfilePersonality {
  final double openness; // 0.0 to 1.0
  final double conscientiousness;
  final double extraversion;
  final double agreeableness;
  final double neuroticism;
  final List<String> communicationStyle;
  final List<String> loveLanguages;

  const ProfilePersonality({
    required this.openness,
    required this.conscientiousness,
    required this.extraversion,
    required this.agreeableness,
    required this.neuroticism,
    this.communicationStyle = const [],
    this.loveLanguages = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'openness': openness,
      'conscientiousness': conscientiousness,
      'extraversion': extraversion,
      'agreeableness': agreeableness,
      'neuroticism': neuroticism,
      'communicationStyle': communicationStyle,
      'loveLanguages': loveLanguages,
    };
  }

  factory ProfilePersonality.fromJson(Map<String, dynamic> json) {
    return ProfilePersonality(
      openness: json['openness'] ?? 0.5,
      conscientiousness: json['conscientiousness'] ?? 0.5,
      extraversion: json['extraversion'] ?? 0.5,
      agreeableness: json['agreeableness'] ?? 0.5,
      neuroticism: json['neuroticism'] ?? 0.5,
      communicationStyle: json['communicationStyle'] != null
          ? List<String>.from(json['communicationStyle'])
          : [],
      loveLanguages: json['loveLanguages'] != null
          ? List<String>.from(json['loveLanguages'])
          : [],
    );
  }
}
