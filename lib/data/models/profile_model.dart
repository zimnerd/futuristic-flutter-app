import 'package:equatable/equatable.dart';

/// Comprehensive user profile model for dating app functionality
class UserProfile extends Equatable {
  final String id;
  final String userId;
  final String? bio;
  final List<String> interests;
  final List<String> dealBreakers;
  final List<ProfilePhoto> photos;
  final UserPreferences preferences;
  final ProfileVerification verification;
  final UserLocation? location;
  final int completionPercentage;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Analytics fields - profile engagement metrics
  final int profileViews;
  final int likesReceived;
  final int likesSent;
  final int matchesCount;
  final int messagesCount;
  final int sessionCount;
  final int totalLoginTime; // in minutes
  final DateTime? lastSeenAt;

  // Metadata fields - moderation and verification
  final String? moderationStatus; // APPROVED, PENDING, FLAGGED, SUSPENDED
  final DateTime? moderatedAt;
  final String? verificationMethod; // PHOTO, PHONE, EMAIL, IDENTITY
  final String? verificationStatus; // VERIFIED, PENDING, REJECTED
  final DateTime? verifiedAt;

  const UserProfile({
    required this.id,
    required this.userId,
    this.bio,
    this.interests = const [],
    this.dealBreakers = const [],
    this.photos = const [],
    required this.preferences,
    required this.verification,
    this.location,
    this.completionPercentage = 0,
    required this.createdAt,
    required this.updatedAt,
    // Analytics fields with safe defaults
    this.profileViews = 0,
    this.likesReceived = 0,
    this.likesSent = 0,
    this.matchesCount = 0,
    this.messagesCount = 0,
    this.sessionCount = 0,
    this.totalLoginTime = 0,
    this.lastSeenAt,
    // Metadata fields
    this.moderationStatus,
    this.moderatedAt,
    this.verificationMethod,
    this.verificationStatus,
    this.verifiedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      bio: json['bio'],
      interests: json['interests'] != null
          ? List<String>.from(json['interests'])
          : [],
      dealBreakers: json['dealBreakers'] != null
          ? List<String>.from(json['dealBreakers'])
          : [],
      photos: json['photos'] != null
          ? (json['photos'] as List)
              .map((photo) => ProfilePhoto.fromJson(photo))
              .toList()
          : [],
      preferences: UserPreferences.fromJson(json['preferences'] ?? {}),
      verification: ProfileVerification.fromJson(json['verification'] ?? {}),
      location: json['location'] != null
          ? UserLocation.fromJson(json['location'])
          : null,
      completionPercentage: json['completionPercentage'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      // Analytics fields
      profileViews: json['profileViews'] ?? 0,
      likesReceived: json['likesReceived'] ?? 0,
      likesSent: json['likesSent'] ?? 0,
      matchesCount: json['matchesCount'] ?? 0,
      messagesCount: json['messagesCount'] ?? 0,
      sessionCount: json['sessionCount'] ?? 0,
      totalLoginTime: json['totalLoginTime'] ?? 0,
      lastSeenAt: json['lastSeenAt'] != null
          ? DateTime.parse(json['lastSeenAt'])
          : null,
      // Metadata fields
      moderationStatus: json['moderationStatus'],
      moderatedAt: json['moderatedAt'] != null
          ? DateTime.parse(json['moderatedAt'])
          : null,
      verificationMethod: json['verificationMethod'],
      verificationStatus: json['verificationStatus'],
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.parse(json['verifiedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'bio': bio,
      'interests': interests,
      'dealBreakers': dealBreakers,
      'photos': photos.map((photo) => photo.toJson()).toList(),
      'preferences': preferences.toJson(),
      'verification': verification.toJson(),
      'location': location?.toJson(),
      'completionPercentage': completionPercentage,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      // Analytics fields
      'profileViews': profileViews,
      'likesReceived': likesReceived,
      'likesSent': likesSent,
      'matchesCount': matchesCount,
      'messagesCount': messagesCount,
      'sessionCount': sessionCount,
      'totalLoginTime': totalLoginTime,
      'lastSeenAt': lastSeenAt?.toIso8601String(),
      // Metadata fields
      'moderationStatus': moderationStatus,
      'moderatedAt': moderatedAt?.toIso8601String(),
      'verificationMethod': verificationMethod,
      'verificationStatus': verificationStatus,
      'verifiedAt': verifiedAt?.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? userId,
    String? bio,
    List<String>? interests,
    List<String>? dealBreakers,
    List<ProfilePhoto>? photos,
    UserPreferences? preferences,
    ProfileVerification? verification,
    UserLocation? location,
    int? completionPercentage,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? profileViews,
    int? likesReceived,
    int? likesSent,
    int? matchesCount,
    int? messagesCount,
    int? sessionCount,
    int? totalLoginTime,
    DateTime? lastSeenAt,
    String? moderationStatus,
    DateTime? moderatedAt,
    String? verificationMethod,
    String? verificationStatus,
    DateTime? verifiedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bio: bio ?? this.bio,
      interests: interests ?? this.interests,
      dealBreakers: dealBreakers ?? this.dealBreakers,
      photos: photos ?? this.photos,
      preferences: preferences ?? this.preferences,
      verification: verification ?? this.verification,
      location: location ?? this.location,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      profileViews: profileViews ?? this.profileViews,
      likesReceived: likesReceived ?? this.likesReceived,
      likesSent: likesSent ?? this.likesSent,
      matchesCount: matchesCount ?? this.matchesCount,
      messagesCount: messagesCount ?? this.messagesCount,
      sessionCount: sessionCount ?? this.sessionCount,
      totalLoginTime: totalLoginTime ?? this.totalLoginTime,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      moderationStatus: moderationStatus ?? this.moderationStatus,
      moderatedAt: moderatedAt ?? this.moderatedAt,
      verificationMethod: verificationMethod ?? this.verificationMethod,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      verifiedAt: verifiedAt ?? this.verifiedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        bio,
        interests,
        dealBreakers,
        photos,
        preferences,
        verification,
        location,
        completionPercentage,
        createdAt,
        updatedAt,
    profileViews,
    likesReceived,
    likesSent,
    matchesCount,
    messagesCount,
    sessionCount,
    totalLoginTime,
    lastSeenAt,
    moderationStatus,
    moderatedAt,
    verificationMethod,
    verificationStatus,
    verifiedAt,
      ];
}

/// Profile photo model with metadata
class ProfilePhoto extends Equatable {
  final String id;
  final String url;
  final bool isPrimary;
  final bool isVerified;
  final int order;
  final String? blurhash; // 🎯 Add blurhash field for progressive loading
  final DateTime createdAt;

  const ProfilePhoto({
    required this.id,
    required this.url,
    this.isPrimary = false,
    this.isVerified = false,
    required this.order,
    this.blurhash,
    required this.createdAt,
  });

  factory ProfilePhoto.fromJson(Map<String, dynamic> json) {
    return ProfilePhoto(
      id: json['id'] ?? '',
      url: json['url'] ?? '',
      isPrimary: json['isPrimary'] ?? false,
      isVerified: json['isVerified'] ?? false,
      order: json['order'] ?? 0,
      blurhash: json['blurhash'] as String?,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'isPrimary': isPrimary,
      'isVerified': isVerified,
      'order': order,
      'blurhash': blurhash,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  ProfilePhoto copyWith({
    String? id,
    String? url,
    bool? isPrimary,
    bool? isVerified,
    int? order,
    String? blurhash,
    DateTime? createdAt,
  }) {
    return ProfilePhoto(
      id: id ?? this.id,
      url: url ?? this.url,
      isPrimary: isPrimary ?? this.isPrimary,
      isVerified: isVerified ?? this.isVerified,
      order: order ?? this.order,
      blurhash: blurhash ?? this.blurhash,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    url,
    isPrimary,
    isVerified,
    order,
    blurhash,
    createdAt,
  ];
}

/// User preferences for matching and discovery
class UserPreferences extends Equatable {
  final String id;
  final String userId;
  final AgeRange ageRange;
  final double maxDistance;
  final List<String> genderPreference;
  final List<String> lookingFor;
  final List<String> dealBreakers;
  final List<String> interests;
  final LifestylePreferences lifestyle;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserPreferences({
    required this.id,
    required this.userId,
    required this.ageRange,
    this.maxDistance = 50.0,
    this.genderPreference = const [],
    this.lookingFor = const [],
    this.dealBreakers = const [],
    this.interests = const [],
    required this.lifestyle,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      ageRange: AgeRange.fromJson(json['ageRange'] ?? {}),
      maxDistance: (json['maxDistance'] ?? 50.0).toDouble(),
      genderPreference: json['genderPreference'] != null
          ? List<String>.from(json['genderPreference'])
          : [],
      lookingFor: json['lookingFor'] != null
          ? List<String>.from(json['lookingFor'])
          : [],
      dealBreakers: json['dealBreakers'] != null
          ? List<String>.from(json['dealBreakers'])
          : [],
      interests: json['interests'] != null
          ? List<String>.from(json['interests'])
          : [],
      lifestyle: LifestylePreferences.fromJson(json['lifestyle'] ?? {}),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'ageRange': ageRange.toJson(),
      'maxDistance': maxDistance,
      'genderPreference': genderPreference,
      'lookingFor': lookingFor,
      'dealBreakers': dealBreakers,
      'interests': interests,
      'lifestyle': lifestyle.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  UserPreferences copyWith({
    String? id,
    String? userId,
    AgeRange? ageRange,
    double? maxDistance,
    List<String>? genderPreference,
    List<String>? lookingFor,
    List<String>? dealBreakers,
    List<String>? interests,
    LifestylePreferences? lifestyle,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserPreferences(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      ageRange: ageRange ?? this.ageRange,
      maxDistance: maxDistance ?? this.maxDistance,
      genderPreference: genderPreference ?? this.genderPreference,
      lookingFor: lookingFor ?? this.lookingFor,
      dealBreakers: dealBreakers ?? this.dealBreakers,
      interests: interests ?? this.interests,
      lifestyle: lifestyle ?? this.lifestyle,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        ageRange,
        maxDistance,
        genderPreference,
        lookingFor,
        dealBreakers,
        interests,
        lifestyle,
        createdAt,
        updatedAt,
      ];
}

/// Age range preference
class AgeRange extends Equatable {
  final int min;
  final int max;

  const AgeRange({
    required this.min,
    required this.max,
  });

  factory AgeRange.fromJson(Map<String, dynamic> json) {
    return AgeRange(
      min: json['min'] ?? 18,
      max: json['max'] ?? 50,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'min': min,
      'max': max,
    };
  }

  AgeRange copyWith({
    int? min,
    int? max,
  }) {
    return AgeRange(
      min: min ?? this.min,
      max: max ?? this.max,
    );
  }

  @override
  List<Object?> get props => [min, max];
}

/// Lifestyle preferences for matching
class LifestylePreferences extends Equatable {
  final String? drinkingHabits;
  final String? smokingHabits;
  final String? exerciseFrequency;
  final String? dietType;
  final String? religiosity;
  final String? politicalViews;
  final List<String> hobbies;
  final List<String> musicGenres;
  final List<String> travelPreferences;

  const LifestylePreferences({
    this.drinkingHabits,
    this.smokingHabits,
    this.exerciseFrequency,
    this.dietType,
    this.religiosity,
    this.politicalViews,
    this.hobbies = const [],
    this.musicGenres = const [],
    this.travelPreferences = const [],
  });

  factory LifestylePreferences.fromJson(Map<String, dynamic> json) {
    return LifestylePreferences(
      drinkingHabits: json['drinkingHabits'],
      smokingHabits: json['smokingHabits'],
      exerciseFrequency: json['exerciseFrequency'],
      dietType: json['dietType'],
      religiosity: json['religiosity'],
      politicalViews: json['politicalViews'],
      hobbies: json['hobbies'] != null
          ? List<String>.from(json['hobbies'])
          : [],
      musicGenres: json['musicGenres'] != null
          ? List<String>.from(json['musicGenres'])
          : [],
      travelPreferences: json['travelPreferences'] != null
          ? List<String>.from(json['travelPreferences'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'drinkingHabits': drinkingHabits,
      'smokingHabits': smokingHabits,
      'exerciseFrequency': exerciseFrequency,
      'dietType': dietType,
      'religiosity': religiosity,
      'politicalViews': politicalViews,
      'hobbies': hobbies,
      'musicGenres': musicGenres,
      'travelPreferences': travelPreferences,
    };
  }

  LifestylePreferences copyWith({
    String? drinkingHabits,
    String? smokingHabits,
    String? exerciseFrequency,
    String? dietType,
    String? religiosity,
    String? politicalViews,
    List<String>? hobbies,
    List<String>? musicGenres,
    List<String>? travelPreferences,
  }) {
    return LifestylePreferences(
      drinkingHabits: drinkingHabits ?? this.drinkingHabits,
      smokingHabits: smokingHabits ?? this.smokingHabits,
      exerciseFrequency: exerciseFrequency ?? this.exerciseFrequency,
      dietType: dietType ?? this.dietType,
      religiosity: religiosity ?? this.religiosity,
      politicalViews: politicalViews ?? this.politicalViews,
      hobbies: hobbies ?? this.hobbies,
      musicGenres: musicGenres ?? this.musicGenres,
      travelPreferences: travelPreferences ?? this.travelPreferences,
    );
  }

  @override
  List<Object?> get props => [
        drinkingHabits,
        smokingHabits,
        exerciseFrequency,
        dietType,
        religiosity,
        politicalViews,
        hobbies,
        musicGenres,
        travelPreferences,
      ];
}

/// Profile verification status
class ProfileVerification extends Equatable {
  final bool isPhotoVerified;
  final bool isIdentityVerified;
  final bool isPhoneVerified;
  final bool isEmailVerified;
  final DateTime? photoVerifiedAt;
  final DateTime? identityVerifiedAt;
  final DateTime? phoneVerifiedAt;
  final DateTime? emailVerifiedAt;

  const ProfileVerification({
    this.isPhotoVerified = false,
    this.isIdentityVerified = false,
    this.isPhoneVerified = false,
    this.isEmailVerified = false,
    this.photoVerifiedAt,
    this.identityVerifiedAt,
    this.phoneVerifiedAt,
    this.emailVerifiedAt,
  });

  factory ProfileVerification.fromJson(Map<String, dynamic> json) {
    return ProfileVerification(
      isPhotoVerified: json['isPhotoVerified'] ?? false,
      isIdentityVerified: json['isIdentityVerified'] ?? false,
      isPhoneVerified: json['isPhoneVerified'] ?? false,
      isEmailVerified: json['isEmailVerified'] ?? false,
      photoVerifiedAt: json['photoVerifiedAt'] != null
          ? DateTime.parse(json['photoVerifiedAt'])
          : null,
      identityVerifiedAt: json['identityVerifiedAt'] != null
          ? DateTime.parse(json['identityVerifiedAt'])
          : null,
      phoneVerifiedAt: json['phoneVerifiedAt'] != null
          ? DateTime.parse(json['phoneVerifiedAt'])
          : null,
      emailVerifiedAt: json['emailVerifiedAt'] != null
          ? DateTime.parse(json['emailVerifiedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isPhotoVerified': isPhotoVerified,
      'isIdentityVerified': isIdentityVerified,
      'isPhoneVerified': isPhoneVerified,
      'isEmailVerified': isEmailVerified,
      'photoVerifiedAt': photoVerifiedAt?.toIso8601String(),
      'identityVerifiedAt': identityVerifiedAt?.toIso8601String(),
      'phoneVerifiedAt': phoneVerifiedAt?.toIso8601String(),
      'emailVerifiedAt': emailVerifiedAt?.toIso8601String(),
    };
  }

  ProfileVerification copyWith({
    bool? isPhotoVerified,
    bool? isIdentityVerified,
    bool? isPhoneVerified,
    bool? isEmailVerified,
    DateTime? photoVerifiedAt,
    DateTime? identityVerifiedAt,
    DateTime? phoneVerifiedAt,
    DateTime? emailVerifiedAt,
  }) {
    return ProfileVerification(
      isPhotoVerified: isPhotoVerified ?? this.isPhotoVerified,
      isIdentityVerified: isIdentityVerified ?? this.isIdentityVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      photoVerifiedAt: photoVerifiedAt ?? this.photoVerifiedAt,
      identityVerifiedAt: identityVerifiedAt ?? this.identityVerifiedAt,
      phoneVerifiedAt: phoneVerifiedAt ?? this.phoneVerifiedAt,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
    );
  }

  @override
  List<Object?> get props => [
        isPhotoVerified,
        isIdentityVerified,
        isPhoneVerified,
        isEmailVerified,
        photoVerifiedAt,
        identityVerifiedAt,
        phoneVerifiedAt,
        emailVerifiedAt,
      ];
}

/// User location model with privacy controls
class UserLocation extends Equatable {
  final double latitude;
  final double longitude;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;
  final bool hideExactLocation;
  final bool showCityOnly;
  final DateTime updatedAt;

  const UserLocation({
    required this.latitude,
    required this.longitude,
    this.city,
    this.state,
    this.country,
    this.postalCode,
    this.hideExactLocation = true,
    this.showCityOnly = false,
    required this.updatedAt,
  });

  factory UserLocation.fromJson(Map<String, dynamic> json) {
    return UserLocation(
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      city: json['city'],
      state: json['state'],
      country: json['country'],
      postalCode: json['postalCode'],
      hideExactLocation: json['hideExactLocation'] ?? true,
      showCityOnly: json['showCityOnly'] ?? false,
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
      'state': state,
      'country': country,
      'postalCode': postalCode,
      'hideExactLocation': hideExactLocation,
      'showCityOnly': showCityOnly,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  UserLocation copyWith({
    double? latitude,
    double? longitude,
    String? city,
    String? state,
    String? country,
    String? postalCode,
    bool? hideExactLocation,
    bool? showCityOnly,
    DateTime? updatedAt,
  }) {
    return UserLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      postalCode: postalCode ?? this.postalCode,
      hideExactLocation: hideExactLocation ?? this.hideExactLocation,
      showCityOnly: showCityOnly ?? this.showCityOnly,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        latitude,
        longitude,
        city,
        state,
        country,
        postalCode,
        hideExactLocation,
        showCityOnly,
        updatedAt,
      ];
}
