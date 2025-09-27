import '../../../domain/entities/user_profile.dart';

/// Simple match model without complex JSON generation
/// Part of the clean architecture - easy to read and maintain
class MatchModel {
  final String id;
  final String user1Id;
  final String user2Id;
  final bool isMatched;
  final double compatibilityScore;
  final Map<String, dynamic>? matchReasons;
  final String status; // pending, matched, rejected, expired
  final DateTime? matchedAt;
  final DateTime? rejectedAt;
  final DateTime? expiredAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Added user profile data from API
  final UserProfile? userProfile;
  final String? otherUserId;
  final String? conversationId;

  const MatchModel({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    this.isMatched = false,
    this.compatibilityScore = 0.0,
    this.matchReasons,
    this.status = 'pending',
    this.matchedAt,
    this.rejectedAt,
    this.expiredAt,
    required this.createdAt,
    required this.updatedAt,
    this.userProfile,
    this.otherUserId,
    this.conversationId,
  });

  // Simple JSON methods without code generation
  factory MatchModel.fromJson(Map<String, dynamic> json) {
    print('🔍 Parsing MatchModel from JSON: ${json.keys.toList()}');
    UserProfile? userProfile;

    // Extract user data from API response (the API returns the 'user' object)
    if (json['user'] != null) {
      try {
        print('👤 Parsing user profile from: ${json['user']}');
        userProfile = _parseUserProfile(json['user']);
        print('✅ Successfully parsed userProfile: ${userProfile?.name}');
      } catch (e) {
        // If parsing fails, userProfile will remain null
        print('❌ Failed to parse user profile from match: $e');
      }
    } else {
      print('⚠️ No user data found in match JSON response');
    }
    
    return MatchModel(
      id: json['id'] ?? '',
      user1Id: json['user1Id'] ?? '',
      user2Id: json['user2Id'] ?? '',
      isMatched: json['isMatched'] ?? false,
      compatibilityScore:
          (json['compatibilityScore'] ?? json['compatibility'] ?? 0.0)
              .toDouble(),
      matchReasons: json['matchReasons'] != null
          ? Map<String, dynamic>.from(json['matchReasons'])
          : null,
      status: json['status'] ?? 'pending',
      matchedAt: json['matchedAt'] != null
          ? DateTime.parse(json['matchedAt'])
          : null,
      rejectedAt: json['rejectedAt'] != null
          ? DateTime.parse(json['rejectedAt'])
          : null,
      expiredAt: json['expiredAt'] != null
          ? DateTime.parse(json['expiredAt'])
          : null,
      createdAt: DateTime.parse(json['createdAt'] ?? json['matchedAt']),
      updatedAt: DateTime.parse(json['updatedAt'] ?? json['matchedAt']),
      userProfile: userProfile,
      otherUserId: userProfile?.id,
      conversationId: json['conversationId'],
    );
  }

  /// Helper method to parse user profile from API response
  static UserProfile? _parseUserProfile(Map<String, dynamic> userJson) {
    try {
      return UserProfile(
        id: userJson['id'] ?? '',
        name: '${userJson['firstName'] ?? ''} ${userJson['lastName'] ?? ''}'
            .trim(),
        age: userJson['age'] ?? 0,
        bio: userJson['bio'] ?? '',
        photos:
            (userJson['photos'] as List<dynamic>?)
                ?.asMap()
                .entries
                .map((entry) {
                  final index = entry.key;
                  final photo = entry.value;

                  // Handle both string URLs and photo objects
                  if (photo is String) {
                    return ProfilePhoto(
                      id: 'photo_$index',
                      url: photo,
                      order: index,
                      isVerified: false,
                    );
                  } else if (photo is Map<String, dynamic>) {
                    return ProfilePhoto(
                      id: photo['id'] ?? 'photo_$index',
                      url: photo['url'] ?? '',
                      order: photo['order'] ?? index,
                      isVerified: photo['isVerified'] ?? false,
                    );
                  }
                  return null;
                },
                )
                .where((photo) => photo != null)
                .cast<ProfilePhoto>()
                .toList() ??
            [],
        location: UserLocation(
          latitude: userJson['coordinates']?['latitude']?.toDouble() ?? 0.0,
          longitude: userJson['coordinates']?['longitude']?.toDouble() ?? 0.0,
          city: userJson['location'] is String
              ? userJson['location']
              : userJson['location']?['city'],
          country: userJson['location'] is String
              ? null
              : userJson['location']?['country'],
          address: userJson['location'] is String
              ? userJson['location']
              : userJson['location']?['address'],
        ),
        interests:
            (userJson['interests'] as List<dynamic>?)
                ?.map((interest) {
                  // Handle both string interests and interest objects
                  if (interest is String) {
                    return interest;
                  } else if (interest is Map<String, dynamic>) {
                    return interest['name']?.toString() ?? '';
                  }
                  return interest.toString();
                })
                .where((name) => name.isNotEmpty)
                .toList() ??
            [],
        occupation: userJson['occupation'],
        education: userJson['education'],
        gender: userJson['gender'],
        isVerified: userJson['isVerified'] ?? false,
      );
    } catch (e) {
      print('Error parsing user profile: $e');
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user1Id': user1Id,
      'user2Id': user2Id,
      'isMatched': isMatched,
      'compatibilityScore': compatibilityScore,
      'matchReasons': matchReasons,
      'status': status,
      'matchedAt': matchedAt?.toIso8601String(),
      'rejectedAt': rejectedAt?.toIso8601String(),
      'expiredAt': expiredAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'conversationId': conversationId,
    };
  }

  MatchModel copyWith({
    String? id,
    String? user1Id,
    String? user2Id,
    bool? isMatched,
    double? compatibilityScore,
    Map<String, dynamic>? matchReasons,
    String? status,
    DateTime? matchedAt,
    DateTime? rejectedAt,
    DateTime? expiredAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserProfile? userProfile,
    String? otherUserId,
    String? conversationId,
  }) {
    return MatchModel(
      id: id ?? this.id,
      user1Id: user1Id ?? this.user1Id,
      user2Id: user2Id ?? this.user2Id,
      isMatched: isMatched ?? this.isMatched,
      compatibilityScore: compatibilityScore ?? this.compatibilityScore,
      matchReasons: matchReasons ?? this.matchReasons,
      status: status ?? this.status,
      matchedAt: matchedAt ?? this.matchedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      expiredAt: expiredAt ?? this.expiredAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userProfile: userProfile ?? this.userProfile,
      otherUserId: otherUserId ?? this.otherUserId,
      conversationId: conversationId ?? this.conversationId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MatchModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'MatchModel(id: $id, status: $status, score: $compatibilityScore)';
}
