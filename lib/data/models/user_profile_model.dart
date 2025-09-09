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
      photos: (json['photos'] as List<dynamic>?)
          ?.map((photo) => ProfilePhotoModel.fromJson(photo as Map<String, dynamic>))
          .toList() ?? [],
      location: UserLocationModel.fromJson(json['location'] as Map<String, dynamic>),
      isVerified: json['isVerified'] as bool? ?? false,
      interests: (json['interests'] as List<dynamic>?)
          ?.map((interest) => interest as String)
          .toList() ?? [],
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
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'bio': bio,
      'photos': photos.map((photo) => (photo as ProfilePhotoModel).toJson()).toList(),
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
      photos: entity.photos.map((photo) => 
          photo is ProfilePhotoModel 
              ? photo 
              : ProfilePhotoModel.fromEntity(photo)
      ).toList(),
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
}

/// Data model for ProfilePhoto with JSON serialization
class ProfilePhotoModel extends ProfilePhoto {
  const ProfilePhotoModel({
    required super.id,
    required super.url,
    required super.order,
    super.isVerified = false,
    super.uploadedAt,
  });

  factory ProfilePhotoModel.fromJson(Map<String, dynamic> json) {
    return ProfilePhotoModel(
      id: json['id'] as String,
      url: json['url'] as String,
      order: json['order'] as int,
      isVerified: json['isVerified'] as bool? ?? false,
      uploadedAt: json['uploadedAt'] != null 
          ? DateTime.parse(json['uploadedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'order': order,
      'isVerified': isVerified,
      'uploadedAt': uploadedAt?.toIso8601String(),
    };
  }

  factory ProfilePhotoModel.fromEntity(ProfilePhoto entity) {
    return ProfilePhotoModel(
      id: entity.id,
      url: entity.url,
      order: entity.order,
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
