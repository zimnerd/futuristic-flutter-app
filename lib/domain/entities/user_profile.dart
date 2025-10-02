import 'package:equatable/equatable.dart';

/// User profile entity for matching and display
class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    required this.name,
    required this.age,
    this.dateOfBirth,
    this.ageChangeCount = 0,
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
    this.gender,
    this.job,
    this.company,
    this.school,
    this.lookingFor,
    this.isOnline = false,
    this.lastSeen,
    this.verified = false,
  });

  final String id;
  final String name;
  final int age;
  final DateTime? dateOfBirth;
  final int ageChangeCount;
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
  final String? gender;
  final String? job;
  final String? company;
  final String? school;
  final String? lookingFor;
  final bool isOnline;
  final DateTime? lastSeen;
  final bool verified;

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
    DateTime? dateOfBirth,
    int? ageChangeCount,
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
    String? gender,
    String? job,
    String? company,
    String? school,
    String? lookingFor,
    bool? isOnline,
    DateTime? lastSeen,
    bool? verified,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      ageChangeCount: ageChangeCount ?? this.ageChangeCount,
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
      gender: gender ?? this.gender,
      job: job ?? this.job,
      company: company ?? this.company,
      school: school ?? this.school,
      lookingFor: lookingFor ?? this.lookingFor,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      verified: verified ?? this.verified,
    );
  }

  /// Create UserProfile from JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      age: json['age'] as int,
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'] as String)
          : null,
      ageChangeCount: json['ageChangeCount'] as int? ?? 0,
      bio: json['bio'] as String? ?? '',
      photos:
          (json['photos'] as List<dynamic>?)
              ?.map(
                (photo) => ProfilePhoto.fromJson(photo as Map<String, dynamic>),
              )
              .toList() ??
          [],
      location: UserLocation.fromJson(json['location'] as Map<String, dynamic>),
      isVerified: json['isVerified'] as bool? ?? false,
      interests: (json['interests'] as List<dynamic>?)?.cast<String>() ?? [],
      occupation: json['occupation'] as String?,
      education: json['education'] as String?,
      height: json['height'] as int?,
      zodiacSign: json['zodiacSign'] as String?,
      lifestyle: json['lifestyle'] as Map<String, dynamic>? ?? {},
      preferences: json['preferences'] as Map<String, dynamic>? ?? {},
      lastActiveAt: json['lastActiveAt'] != null
          ? DateTime.parse(json['lastActiveAt'] as String)
          : null,
      distanceKm: json['distanceKm'] as double?,
      gender: json['gender'] as String?,
      job: json['job'] as String?,
      company: json['company'] as String?,
      school: json['school'] as String?,
      lookingFor: json['lookingFor'] as String?,
      isOnline: json['isOnline'] as bool? ?? false,
      lastSeen: json['lastSeen'] != null
          ? DateTime.parse(json['lastSeen'] as String)
          : null,
      verified: json['verified'] as bool? ?? false,
    );
  }

  /// Convert UserProfile to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'ageChangeCount': ageChangeCount,
      'bio': bio,
      'photos': photos.map((photo) => photo.toJson()).toList(),
      'location': location.toJson(),
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
      'gender': gender,
      'job': job,
      'company': company,
      'school': school,
      'lookingFor': lookingFor,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
      'verified': verified,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        age,
    dateOfBirth,
    ageChangeCount,
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
    gender,
    job,
    company,
    school,
    lookingFor,
    isOnline,
    lastSeen,
    verified,
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

  /// Create ProfilePhoto from JSON
  factory ProfilePhoto.fromJson(Map<String, dynamic> json) {
    return ProfilePhoto(
      id: json['id'] as String,
      url: json['url'] as String,
      order: json['order'] as int,
      isVerified: json['isVerified'] as bool? ?? false,
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.parse(json['uploadedAt'] as String)
          : null,
    );
  }

  /// Convert ProfilePhoto to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'order': order,
      'isVerified': isVerified,
      'uploadedAt': uploadedAt?.toIso8601String(),
    };
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

  /// Create UserLocation from JSON
  factory UserLocation.fromJson(Map<String, dynamic> json) {
    return UserLocation(
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      city: json['city'] as String?,
      country: json['country'] as String?,
      address: json['address'] as String?,
    );
  }

  /// Convert UserLocation to JSON
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
      'country': country,
      'address': address,
    };
  }

  @override
  List<Object?> get props => [latitude, longitude, city, country, address];
}
