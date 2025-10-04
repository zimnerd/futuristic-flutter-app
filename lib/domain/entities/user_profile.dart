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
    this.showMe,
    this.job,
    this.company,
    this.school,
    this.lookingFor,
    this.isOnline = false,
    this.lastSeen,
    this.verified = false,
    // New profile fields from Prisma schema
    this.lifestyleChoice,
    this.relationshipGoals = const [],
    this.religion,
    this.politics,
    this.drinking,
    this.smoking,
    this.exercise,
    this.drugs,
    this.children,
    this.languages = const [],
    this.personalityTraits = const [],
    this.promptQuestions = const [],
    this.promptAnswers = const [],
    // Privacy settings from backend User model (all 8 fields)
    this.showAge,
    this.showDistance,
    this.showLastActive,
    this.showOnlineStatus,
    this.incognitoMode,
    this.readReceipts,
    this.whoCanMessageMe,
    this.whoCanSeeMyProfile,
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
  final List<String>?
  showMe; // Gender preferences for matching: ['MEN', 'WOMEN'], ['MEN'], or ['WOMEN']
  final String? job;
  final String? company;
  final String? school;
  @Deprecated(
    'Use relationshipGoals instead. lookingFor is no longer sent to backend.',
  )
  final String? lookingFor; // DEPRECATED - kept for backward compatibility only
  final bool isOnline;
  final DateTime? lastSeen;
  final bool verified;

  // New profile fields from Prisma schema
  final String?
  lifestyleChoice; // Single choice: active, relaxed, adventurous, etc.
  final List<String>
  relationshipGoals; // Replaces lookingFor - dating, fun, companionship, etc.
  final String? religion;
  final String? politics;
  final String? drinking; // never, occasionally, regularly, prefer-not-to-say
  final String? smoking;
  final String? exercise; // never, rarely, sometimes, regularly, daily
  final String? drugs;
  final String? children; // don't have/want, have/want more, etc.
  final List<String> languages;
  final List<String> personalityTraits;
  final List<String> promptQuestions;
  final List<String> promptAnswers;

  // Privacy settings from backend User model (all 8 fields)
  final bool? showAge;
  final bool? showDistance;
  final bool? showLastActive;
  final bool? showOnlineStatus;
  final bool? incognitoMode;
  final bool? readReceipts;
  final String? whoCanMessageMe;
  final String? whoCanSeeMyProfile;

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
    List<String>? showMe,
    String? job,
    String? company,
    String? school,
    String? lookingFor,
    bool? isOnline,
    DateTime? lastSeen,
    bool? verified,
    // New profile fields
    String? lifestyleChoice,
    List<String>? relationshipGoals,
    String? religion,
    String? politics,
    String? drinking,
    String? smoking,
    String? exercise,
    String? drugs,
    String? children,
    List<String>? languages,
    List<String>? personalityTraits,
    List<String>? promptQuestions,
    List<String>? promptAnswers,
    // Privacy settings (all 8 fields)
    bool? showAge,
    bool? showDistance,
    bool? showLastActive,
    bool? showOnlineStatus,
    bool? incognitoMode,
    bool? readReceipts,
    String? whoCanMessageMe,
    String? whoCanSeeMyProfile,
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
      showMe: showMe ?? this.showMe,
      job: job ?? this.job,
      company: company ?? this.company,
      school: school ?? this.school,
      lookingFor: lookingFor ?? this.lookingFor,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      verified: verified ?? this.verified,
      // New profile fields
      lifestyleChoice: lifestyleChoice ?? this.lifestyleChoice,
      relationshipGoals: relationshipGoals ?? this.relationshipGoals,
      religion: religion ?? this.religion,
      politics: politics ?? this.politics,
      drinking: drinking ?? this.drinking,
      smoking: smoking ?? this.smoking,
      exercise: exercise ?? this.exercise,
      drugs: drugs ?? this.drugs,
      children: children ?? this.children,
      languages: languages ?? this.languages,
      personalityTraits: personalityTraits ?? this.personalityTraits,
      promptQuestions: promptQuestions ?? this.promptQuestions,
      promptAnswers: promptAnswers ?? this.promptAnswers,
      // Privacy settings (all 8 fields)
      showAge: showAge ?? this.showAge,
      showDistance: showDistance ?? this.showDistance,
      showLastActive: showLastActive ?? this.showLastActive,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      incognitoMode: incognitoMode ?? this.incognitoMode,
      readReceipts: readReceipts ?? this.readReceipts,
      whoCanMessageMe: whoCanMessageMe ?? this.whoCanMessageMe,
      whoCanSeeMyProfile: whoCanSeeMyProfile ?? this.whoCanSeeMyProfile,
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
      showMe: (json['showMe'] as List<dynamic>?)?.cast<String>(),
      job: json['job'] as String?,
      company: json['company'] as String?,
      school: json['school'] as String?,
      lookingFor: json['lookingFor'] as String?,
      isOnline: json['isOnline'] as bool? ?? false,
      lastSeen: json['lastSeen'] != null
          ? DateTime.parse(json['lastSeen'] as String)
          : null,
      verified: json['verified'] as bool? ?? false,
      // New profile fields
      lifestyleChoice: json['lifestyleChoice'] as String?,
      relationshipGoals:
          (json['relationshipGoals'] as List<dynamic>?)?.cast<String>() ?? [],
      religion: json['religion'] as String?,
      politics: json['politics'] as String?,
      drinking: json['drinking'] as String?,
      smoking: json['smoking'] as String?,
      exercise: json['exercise'] as String?,
      drugs: json['drugs'] as String?,
      children: json['children'] as String?,
      languages: (json['languages'] as List<dynamic>?)?.cast<String>() ?? [],
      personalityTraits:
          (json['personalityTraits'] as List<dynamic>?)?.cast<String>() ?? [],
      promptQuestions:
          (json['promptQuestions'] as List<dynamic>?)?.cast<String>() ?? [],
      promptAnswers:
          (json['promptAnswers'] as List<dynamic>?)?.cast<String>() ?? [],
      // Privacy settings (all 8 fields from backend)
      showAge: json['showAge'] as bool?,
      showDistance: json['showDistance'] as bool?,
      showLastActive: json['showLastActive'] as bool?,
      showOnlineStatus: json['showOnlineStatus'] as bool?,
      incognitoMode: json['incognitoMode'] as bool?,
      readReceipts: json['readReceipts'] as bool?,
      whoCanMessageMe: json['whoCanMessageMe'] as String?,
      whoCanSeeMyProfile: json['whoCanSeeMyProfile'] as String?,
    ).._logReadReceipts('fromJson');
  }

  /// Log readReceipts value for debugging
  void _logReadReceipts(String source) {
    print('🔍 [UserProfile.$source] readReceipts = $readReceipts');
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
      'showMe': showMe,
      'job': job,
      'company': company,
      'school': school,
      'lookingFor': lookingFor,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
      'verified': verified,
      // New profile fields
      'lifestyleChoice': lifestyleChoice,
      'relationshipGoals': relationshipGoals,
      'religion': religion,
      'politics': politics,
      'drinking': drinking,
      'smoking': smoking,
      'exercise': exercise,
      'drugs': drugs,
      'children': children,
      'languages': languages,
      'personalityTraits': personalityTraits,
      'promptQuestions': promptQuestions,
      'promptAnswers': promptAnswers,
      // Privacy settings (all 8 fields)
      'showAge': showAge,
      'showDistance': showDistance,
      'showLastActive': showLastActive,
      'showOnlineStatus': showOnlineStatus,
      'incognitoMode': incognitoMode,
      'readReceipts': readReceipts,
      'whoCanMessageMe': whoCanMessageMe,
      'whoCanSeeMyProfile': whoCanSeeMyProfile,
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
    showMe,
    job,
    company,
    school,
    lookingFor,
    isOnline,
    lastSeen,
    verified,
    // New profile fields
    lifestyleChoice,
    relationshipGoals,
    religion,
    politics,
    drinking,
    smoking,
    exercise,
    drugs,
    children,
    languages,
    personalityTraits,
    promptQuestions,
    promptAnswers,
    // Privacy settings (all 8 fields)
    showAge,
    showDistance,
    showLastActive,
    showOnlineStatus,
    incognitoMode,
    readReceipts,
    whoCanMessageMe,
    whoCanSeeMyProfile,
      ];
}

/// Profile photo entity
class ProfilePhoto extends Equatable {
  const ProfilePhoto({  
    required this.id,
    required this.url,
    required this.order,
    this.description,
    this.isMain = false,
    this.isVerified = false,
    this.uploadedAt,
  });

  final String id;
  final String url;
  final int order;
  final String? description;
  final bool isMain;
  final bool isVerified;
  final DateTime? uploadedAt;

  ProfilePhoto copyWith({
    String? id,
    String? url,
    int? order,
    String? description,
    bool? isMain,
    bool? isVerified,
    DateTime? uploadedAt,
  }) {
    return ProfilePhoto(
      id: id ?? this.id,
      url: url ?? this.url,
      order: order ?? this.order,
      description: description ?? this.description,
      isMain: isMain ?? this.isMain,
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

  /// Convert ProfilePhoto to JSON
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

  @override
  List<Object?> get props => [
    id,
    url,
    order,
    description,
    isMain,
    isVerified,
    uploadedAt,
  ];
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
