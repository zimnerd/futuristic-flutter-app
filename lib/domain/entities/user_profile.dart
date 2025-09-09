import 'package:equatable/equatable.dart';

/// User profile entity for matching and display
class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.bio,
    required this.photos,
    required this.location,
    this.isVerified = false,
    this.interests = const [],
    this.occupation,
    this.education,
    this.height,
    this.zodiacSign,
    this.lifestyle = const {},
    this.preferences = const {},
    this.lastActiveAt,
    this.distanceKm,
  });

  final String id;
  final String name;
  final int age;
  final String bio;
  final List<ProfilePhoto> photos;
  final UserLocation location;
  final bool isVerified;
  final List<String> interests;
  final String? occupation;
  final String? education;
  final int? height; // in cm
  final String? zodiacSign;
  final Map<String, dynamic> lifestyle;
  final Map<String, dynamic> preferences;
  final DateTime? lastActiveAt;
  final double? distanceKm;

  /// Get primary photo URL
  String get primaryPhotoUrl {
    if (photos.isEmpty) return '';
    return photos.first.url;
  }

  /// Get formatted distance string
  String get distanceString {
    if (distanceKm == null) return '';
    if (distanceKm! < 1) {
      return '< 1 km away';
    } else if (distanceKm! < 10) {
      return '${distanceKm!.toStringAsFixed(1)} km away';
    } else {
      return '${distanceKm!.round()} km away';
    }
  }

  /// Get age display string
  String get ageString => '$age';

  /// Get formatted name with age
  String get nameWithAge => '$name, $age';

  /// Check if user is recently active (within 24 hours)
  bool get isRecentlyActive {
    if (lastActiveAt == null) return false;
    final now = DateTime.now();
    final difference = now.difference(lastActiveAt!);
    return difference.inHours < 24;
  }

  /// Get lifestyle value safely
  T? getLifestyleValue<T>(String key) {
    return lifestyle[key] as T?;
  }

  /// Get preference value safely
  T? getPreferenceValue<T>(String key) {
    return preferences[key] as T?;
  }

  UserProfile copyWith({
    String? id,
    String? name,
    int? age,
    String? bio,
    List<ProfilePhoto>? photos,
    UserLocation? location,
    bool? isVerified,
    List<String>? interests,
    String? occupation,
    String? education,
    int? height,
    String? zodiacSign,
    Map<String, dynamic>? lifestyle,
    Map<String, dynamic>? preferences,
    DateTime? lastActiveAt,
    double? distanceKm,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      bio: bio ?? this.bio,
      photos: photos ?? this.photos,
      location: location ?? this.location,
      isVerified: isVerified ?? this.isVerified,
      interests: interests ?? this.interests,
      occupation: occupation ?? this.occupation,
      education: education ?? this.education,
      height: height ?? this.height,
      zodiacSign: zodiacSign ?? this.zodiacSign,
      lifestyle: lifestyle ?? this.lifestyle,
      preferences: preferences ?? this.preferences,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        age,
        bio,
        photos,
        location,
        isVerified,
        interests,
        occupation,
        education,
        height,
        zodiacSign,
        lifestyle,
        preferences,
        lastActiveAt,
        distanceKm,
      ];
}

/// Profile photo entity
class ProfilePhoto extends Equatable {
  const ProfilePhoto({
    required this.id,
    required this.url,
    required this.order,
    this.isVerified = false,
    this.uploadedAt,
  });

  final String id;
  final String url;
  final int order;
  final bool isVerified;
  final DateTime? uploadedAt;

  ProfilePhoto copyWith({
    String? id,
    String? url,
    int? order,
    bool? isVerified,
    DateTime? uploadedAt,
  }) {
    return ProfilePhoto(
      id: id ?? this.id,
      url: url ?? this.url,
      order: order ?? this.order,
      isVerified: isVerified ?? this.isVerified,
      uploadedAt: uploadedAt ?? this.uploadedAt,
    );
  }

  @override
  List<Object?> get props => [id, url, order, isVerified, uploadedAt];
}

/// User location entity
class UserLocation extends Equatable {
  const UserLocation({
    required this.latitude,
    required this.longitude,
    this.city,
    this.country,
    this.address,
  });

  final double latitude;
  final double longitude;
  final String? city;
  final String? country;
  final String? address;

  /// Get display name for location
  String get displayName {
    if (city != null && country != null) {
      return '$city, $country';
    } else if (city != null) {
      return city!;
    } else if (country != null) {
      return country!;
    } else {
      return 'Unknown location';
    }
  }

  UserLocation copyWith({
    double? latitude,
    double? longitude,
    String? city,
    String? country,
    String? address,
  }) {
    return UserLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      city: city ?? this.city,
      country: country ?? this.country,
      address: address ?? this.address,
    );
  }

  @override
  List<Object?> get props => [latitude, longitude, city, country, address];
}
