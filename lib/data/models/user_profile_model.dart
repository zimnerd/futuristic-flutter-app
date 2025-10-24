import 'package:flutter/foundation.dart';

import '../../domain/entities/user_profile.dart';

/// Data model for UserProfile with JSON serialization
class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.id,
    required super.name,
    required super.age,
    required super.bio,
    required super.photos,
    required super.location,
    super.isVerified = false,
    super.interests = const [],
    super.occupation,
    super.education,
    super.height,
    super.zodiacSign,
    super.lifestyle = const {},
    super.preferences = const {},
    super.lastActiveAt,
    super.distanceKm,
  });

  /// Convert from JSON
  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String,
      name: json['name'] as String,
      age: json['age'] as int,
      bio: json['bio'] as String? ?? '',
      photos:
          (json['photos'] as List<dynamic>?)?.map((photo) {
            // Handle both string URLs (old format) and photo objects (new format)
            if (photo is String) {
              // Backend returning simple URL string - create photo object
              return ProfilePhotoModel(
                id: photo.hashCode.toString(), // Generate temp ID from URL hash
                url: photo,
                order: 0,
                isVerified: false,
              );
            } else if (photo is Map<String, dynamic>) {
              // Backend returning proper photo object with description
              return ProfilePhotoModel.fromJson(photo);
            }
            throw Exception('Invalid photo format: $photo');
          }).toList() ??
          [],
      location: UserLocationModel.fromJson(
        json['location'] as Map<String, dynamic>,
      ),
      isVerified: json['isVerified'] as bool? ?? false,
      interests: _parseInterests(json['interests']),
      occupation: json['occupation'] as String?,
      education: json['education'] as String?,
      height: json['height'] as int?,
      zodiacSign: json['zodiacSign'] as String?,
      lifestyle: json['lifestyle'] as Map<String, dynamic>? ?? {},
      preferences: json['preferences'] as Map<String, dynamic>? ?? {},
      lastActiveAt: json['lastActiveAt'] != null
          ? DateTime.parse(json['lastActiveAt'] as String)
          : null,
      distanceKm: json['distanceKm']?.toDouble(),
    );
  }

  /// Convert to JSON
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'bio': bio,
      'photos': photos
          .map((photo) => (photo as ProfilePhotoModel).toJson())
          .toList(),
      'location': (location as UserLocationModel).toJson(),
      'isVerified': isVerified,
      'interests': interests,
      'occupation': occupation,
      'education': education,
      'height': height,
      'zodiacSign': zodiacSign,
      'lifestyle': lifestyle,
      'preferences': preferences,
      'lastActiveAt': lastActiveAt?.toIso8601String(),
      'distanceKm': distanceKm,
    };
  }

  /// Convert to domain entity
  UserProfile toEntity() {
    return UserProfile(
      id: id,
      name: name,
      age: age,
      bio: bio,
      photos: photos,
      location: location,
      isVerified: isVerified,
      interests: interests,
      occupation: occupation,
      education: education,
      height: height,
      zodiacSign: zodiacSign,
      lifestyle: lifestyle,
      preferences: preferences,
      lastActiveAt: lastActiveAt,
      distanceKm: distanceKm,
    );
  }

  /// Create from domain entity
  factory UserProfileModel.fromEntity(UserProfile entity) {
    return UserProfileModel(
      id: entity.id,
      name: entity.name,
      age: entity.age,
      bio: entity.bio,
      photos: entity.photos
          .map(
            (photo) => photo is ProfilePhotoModel
                ? photo
                : ProfilePhotoModel.fromEntity(photo),
          )
          .toList(),
      location: entity.location is UserLocationModel
          ? entity.location as UserLocationModel
          : UserLocationModel.fromEntity(entity.location),
      isVerified: entity.isVerified,
      interests: entity.interests,
      occupation: entity.occupation,
      education: entity.education,
      height: entity.height,
      zodiacSign: entity.zodiacSign,
      lifestyle: entity.lifestyle,
      preferences: entity.preferences,
      lastActiveAt: entity.lastActiveAt,
      distanceKm: entity.distanceKm,
    );
  }

  /// Parse interests from backend response
  /// Backend returns: [{id: UUID, interest: {id: UUID, name: "Soccer"}}, ...]
  /// We extract the interest names for display
  static List<String> _parseInterests(dynamic interestsData) {
    if (interestsData == null) {
      debugPrint('❌ _parseInterests: interestsData is null');
      return [];
    }
    if (interestsData is! List) {
      debugPrint(
        '❌ _parseInterests: interestsData is not a list, type: ${interestsData.runtimeType}',
      );
      return [];
    }

    debugPrint('🔍 _parseInterests: Processing ${interestsData.length} items');
    final interests = <String>[];

    for (final item in interestsData) {
      debugPrint('   📦 Processing item: ${item.runtimeType} = $item');

      if (item is String) {
        // Plain string format
        debugPrint('   ✅ Added string interest: $item');
        interests.add(item);
      } else if (item is Map<String, dynamic>) {
        // Check if it's the nested format: {id: ..., interest: {id: ..., name: ...}}
        if (item.containsKey('interest')) {
          final interest = item['interest'] as Map<String, dynamic>?;
          debugPrint('   🔗 Found nested interest object: $interest');

          if (interest != null && interest.containsKey('name')) {
            final name = interest['name'] as String?;
            if (name != null && name.isNotEmpty) {
              debugPrint('   ✅ Extracted nested interest name: $name');
              interests.add(name);
            } else {
              debugPrint('   ❌ Interest name is null or empty');
            }
          } else {
            debugPrint('   ❌ Interest object null or no name key');
          }
        } else if (item.containsKey('name')) {
          // Direct format: {id: UUID, name: "Soccer"}
          final name = item['name'] as String?;
          if (name != null && name.isNotEmpty) {
            debugPrint('   ✅ Extracted direct interest name: $name');
            interests.add(name);
          }
        } else {
          debugPrint(
            '   ❌ Item is Map but has no interest or name key. Keys: ${item.keys.toList()}',
          );
        }
      } else {
        debugPrint('   ❌ Item is neither String nor Map: ${item.runtimeType}');
      }
    }

    debugPrint(
      '✨ _parseInterests completed: ${interests.length} interests parsed = $interests',
    );
    return interests;
  }
}

/// Data model for ProfilePhoto with JSON serialization
class ProfilePhotoModel extends ProfilePhoto {
  const ProfilePhotoModel({
    required super.id,
    required super.url,
    required super.order,
    super.description,
    super.isMain = false,
    super.isVerified = false,
    super.uploadedAt,
  });

  factory ProfilePhotoModel.fromJson(Map<String, dynamic> json) {
    return ProfilePhotoModel(
      id: json['id'] as String,
      url: json['url'] as String,
      order: json['order'] as int,
      description: json['description'] as String?,
      isMain: json['isMain'] as bool? ?? false,
      isVerified: json['isVerified'] as bool? ?? false,
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.parse(json['uploadedAt'] as String)
          : json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'order': order,
      'description': description,
      'isMain': isMain,
      'isVerified': isVerified,
      'uploadedAt': uploadedAt?.toIso8601String(),
    };
  }

  factory ProfilePhotoModel.fromEntity(ProfilePhoto entity) {
    return ProfilePhotoModel(
      id: entity.id,
      url: entity.url,
      order: entity.order,
      description: entity.description,
      isMain: entity.isMain,
      isVerified: entity.isVerified,
      uploadedAt: entity.uploadedAt,
    );
  }
}

/// Data model for UserLocation with JSON serialization
class UserLocationModel extends UserLocation {
  const UserLocationModel({
    required super.latitude,
    required super.longitude,
    super.city,
    super.country,
    super.address,
  });

  factory UserLocationModel.fromJson(Map<String, dynamic> json) {
    return UserLocationModel(
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      city: json['city'] as String?,
      country: json['country'] as String?,
      address: json['address'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
      'country': country,
      'address': address,
    };
  }

  factory UserLocationModel.fromEntity(UserLocation entity) {
    return UserLocationModel(
      latitude: entity.latitude,
      longitude: entity.longitude,
      city: entity.city,
      country: entity.country,
      address: entity.address,
    );
  }
}
