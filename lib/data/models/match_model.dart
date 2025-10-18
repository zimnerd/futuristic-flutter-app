import 'package:flutter/foundation.dart';
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

  // Analytics fields - Track interaction quality and engagement
  final DateTime? firstMessageSentAt;
  final DateTime? lastInteractionAt;
  final int messageCount;
  final int callCount;
  final int totalCallDuration;
  final bool meetupScheduled;
  final DateTime? meetupDate;
  final int responseTimeAvg;
  final int mutualInterestsCount;

  // Metadata fields - Track match source, quality, and user preferences
  final String?
  matchSource; // SWIPE, SUPER_LIKE, AI_SUGGESTED, EVENT_BASED, AR_PROXIMITY
  final String? matchType; // MUTUAL_LIKE, SUPER_LIKE, BOOST
  final double qualityScore;
  final DateTime? unmatchedAt;
  final String? unmatchReason;
  final bool isFavorite;
  final bool isPremiumMatch;

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
    // Analytics fields
    this.firstMessageSentAt,
    this.lastInteractionAt,
    this.messageCount = 0,
    this.callCount = 0,
    this.totalCallDuration = 0,
    this.meetupScheduled = false,
    this.meetupDate,
    this.responseTimeAvg = 0,
    this.mutualInterestsCount = 0,
    // Metadata fields
    this.matchSource,
    this.matchType,
    this.qualityScore = 0.0,
    this.unmatchedAt,
    this.unmatchReason,
    this.isFavorite = false,
    this.isPremiumMatch = false,
  });

  // ==================== COMPUTED PROPERTIES ====================

  /// Conversation health classification based on message activity and response times
  /// Returns: "excellent", "good", "moderate", "poor", or "inactive"
  String get conversationHealth {
    // Check if match is inactive (no messages or no interaction in 7+ days)
    if (messageCount == 0 ||
        (lastInteractionAt != null &&
            DateTime.now().difference(lastInteractionAt!).inDays > 7)) {
      return 'inactive';
    }

    // Classify based on message count and response time
    if (messageCount >= 20 && responseTimeAvg < 3600) {
      return 'excellent'; // 20+ messages, response < 1 hour
    }
    if (messageCount >= 10 && responseTimeAvg < 14400) {
      return 'good'; // 10+ messages, response < 4 hours
    }
    if (messageCount >= 5 && responseTimeAvg < 86400) {
      return 'moderate'; // 5+ messages, response < 24 hours
    }
    return 'poor'; // Less than 5 messages or slow response
  }

  /// Engagement score on 0-100 scale based on multiple interaction factors
  /// Components: Message frequency (40%), Response speed (30%), Multi-channel (20%), Recency (10%)
  double get engagementScore {
    double score = 0;

    // 1. Message frequency (40 points max)
    // Scale: 0-100 messages = 0-40 points
    score += (messageCount.clamp(0, 100) * 0.4);

    // 2. Response speed (30 points max)
    // Faster response = higher score, max 24 hours considered
    if (responseTimeAvg > 0) {
      final responseScore = 30 * (1 - (responseTimeAvg / 86400).clamp(0, 1));
      score += responseScore;
    }

    // 3. Multi-channel engagement (20 points max)
    // 10 points for having calls, bonus 10 if both messages and calls
    if (callCount > 0) {
      score += 10;
      if (messageCount > 0) {
        score += 10; // Bonus for multi-channel engagement
      }
    }

    // 4. Recency bonus (10 points max)
    // Recent activity indicates active engagement
    if (lastInteractionAt != null) {
      final daysSinceInteraction = DateTime.now()
          .difference(lastInteractionAt!)
          .inDays;
      if (daysSinceInteraction <= 1) {
        score += 10; // Very recent
      } else if (daysSinceInteraction <= 3) {
        score += 7; // Recent
      } else if (daysSinceInteraction <= 7) {
        score += 4; // Somewhat recent
      }
      // No points for older activity
    }

    return score.clamp(0, 100);
  }

  /// Number of days since the match was created
  int get daysActive {
    return DateTime.now().difference(createdAt).inDays;
  }

  /// Whether this match is considered stale (no interaction for 14+ days)
  bool get isStaleMatch {
    // If never interacted and match is old
    if (lastInteractionAt == null && daysActive > 14) {
      return true;
    }
    // If last interaction was more than 14 days ago
    if (lastInteractionAt != null &&
        DateTime.now().difference(lastInteractionAt!).inDays > 14) {
      return true;
    }
    return false;
  }

  /// Whether this match shows high potential for success
  /// Based on high engagement, scheduled meetup, or sustained conversation
  bool get isPotentialSuccess {
    // High engagement score indicates success potential
    if (engagementScore > 70) return true;

    // Scheduled meetup is strong success indicator
    if (meetupScheduled) return true;

    // Sustained high-quality conversation
    if (messageCount > 50 && responseTimeAvg < 3600) {
      return true; // 50+ messages with fast response
    }

    return false;
  }

  /// Display-friendly match quality tier
  /// Returns: "premium", "great", "good", or "standard"
  String get matchQualityDisplay {
    if (qualityScore >= 80) return 'premium';
    if (qualityScore >= 60) return 'great';
    if (qualityScore >= 40) return 'good';
    return 'standard';
  }

  // ==================== JSON METHODS ====================

  // Simple JSON methods without code generation
  factory MatchModel.fromJson(Map<String, dynamic> json) {
    debugPrint('🔍 Parsing MatchModel from JSON: ${json.keys.toList()}');
    UserProfile? userProfile;

    // Extract user data from API response (the API returns the 'user' object)
    if (json['user'] != null) {
      try {
        debugPrint('👤 Parsing user profile from: ${json['user']}');
        userProfile = MatchModel.parseUserProfile(json['user']);
        debugPrint('✅ Successfully parsed userProfile: ${userProfile?.name}');
      } catch (e) {
        // If parsing fails, userProfile will remain null
        debugPrint('❌ Failed to parse user profile from match: $e');
      }
    } else {
      debugPrint('⚠️ No user data found in match JSON response');
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
      matchedAt: () {
        // Debug: Print all available date fields
        debugPrint(
          '🔍 Available date fields in match JSON: ${json.keys.where((key) => key.toString().toLowerCase().contains('at') || key.toString().toLowerCase().contains('date')).toList()}',
        );

        // Try different possible date fields for match time
        final possibleDateFields = ['matchedAt', 'createdAt', 'updatedAt'];
        DateTime? matchTime;

        for (final field in possibleDateFields) {
          if (json[field] != null) {
            try {
              matchTime = DateTime.parse(json[field].toString());
              debugPrint('🕐 Using $field as match time: $matchTime');
              break;
            } catch (e) {
              debugPrint('❌ Failed to parse $field: ${json[field]}');
            }
          }
        }

        return matchTime;
      }(),
      rejectedAt: json['rejectedAt'] != null
          ? DateTime.parse(json['rejectedAt'])
          : null,
      expiredAt: json['expiredAt'] != null
          ? DateTime.parse(json['expiredAt'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : (json['matchedAt'] != null
                ? DateTime.parse(json['matchedAt'])
                : DateTime.now()),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : (json['matchedAt'] != null
                ? DateTime.parse(json['matchedAt'])
                : DateTime.now()),
      userProfile: userProfile,
      otherUserId: userProfile?.id,
      conversationId: json['conversationId'],
      // Analytics fields
      firstMessageSentAt: json['firstMessageSentAt'] != null
          ? DateTime.tryParse(json['firstMessageSentAt'].toString())
          : null,
      lastInteractionAt: json['lastInteractionAt'] != null
          ? DateTime.tryParse(json['lastInteractionAt'].toString())
          : null,
      messageCount: json['messageCount'] as int? ?? 0,
      callCount: json['callCount'] as int? ?? 0,
      totalCallDuration: json['totalCallDuration'] as int? ?? 0,
      meetupScheduled: json['meetupScheduled'] as bool? ?? false,
      meetupDate: json['meetupDate'] != null
          ? DateTime.tryParse(json['meetupDate'].toString())
          : null,
      responseTimeAvg: json['responseTimeAvg'] as int? ?? 0,
      mutualInterestsCount: json['mutualInterestsCount'] as int? ?? 0,
      // Metadata fields
      matchSource: json['matchSource'] as String?,
      matchType: json['matchType'] as String?,
      qualityScore: (json['qualityScore'] as num?)?.toDouble() ?? 0.0,
      unmatchedAt: json['unmatchedAt'] != null
          ? DateTime.tryParse(json['unmatchedAt'].toString())
          : null,
      unmatchReason: json['unmatchReason'] as String?,
      isFavorite: json['isFavorite'] as bool? ?? false,
      isPremiumMatch: json['isPremiumMatch'] as bool? ?? false,
    );
  }

  /// Helper method to parse user profile from API response
  static UserProfile? parseUserProfile(Map<String, dynamic> userJson) {
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
        // Parse lastActive from backend (returned as 'lastActive', not 'lastActiveAt')
        lastActiveAt: userJson['lastActive'] != null
            ? DateTime.tryParse(userJson['lastActive'].toString())
            : null,
      );
    } catch (e) {
      debugPrint('Error parsing user profile: $e');
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
      // Analytics fields
      'firstMessageSentAt': firstMessageSentAt?.toIso8601String(),
      'lastInteractionAt': lastInteractionAt?.toIso8601String(),
      'messageCount': messageCount,
      'callCount': callCount,
      'totalCallDuration': totalCallDuration,
      'meetupScheduled': meetupScheduled,
      'meetupDate': meetupDate?.toIso8601String(),
      'responseTimeAvg': responseTimeAvg,
      'mutualInterestsCount': mutualInterestsCount,
      // Metadata fields
      'matchSource': matchSource,
      'matchType': matchType,
      'qualityScore': qualityScore,
      'unmatchedAt': unmatchedAt?.toIso8601String(),
      'unmatchReason': unmatchReason,
      'isFavorite': isFavorite,
      'isPremiumMatch': isPremiumMatch,
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
    // Analytics fields
    DateTime? firstMessageSentAt,
    DateTime? lastInteractionAt,
    int? messageCount,
    int? callCount,
    int? totalCallDuration,
    bool? meetupScheduled,
    DateTime? meetupDate,
    int? responseTimeAvg,
    int? mutualInterestsCount,
    // Metadata fields
    String? matchSource,
    String? matchType,
    double? qualityScore,
    DateTime? unmatchedAt,
    String? unmatchReason,
    bool? isFavorite,
    bool? isPremiumMatch,
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
      // Analytics fields
      firstMessageSentAt: firstMessageSentAt ?? this.firstMessageSentAt,
      lastInteractionAt: lastInteractionAt ?? this.lastInteractionAt,
      messageCount: messageCount ?? this.messageCount,
      callCount: callCount ?? this.callCount,
      totalCallDuration: totalCallDuration ?? this.totalCallDuration,
      meetupScheduled: meetupScheduled ?? this.meetupScheduled,
      meetupDate: meetupDate ?? this.meetupDate,
      responseTimeAvg: responseTimeAvg ?? this.responseTimeAvg,
      mutualInterestsCount: mutualInterestsCount ?? this.mutualInterestsCount,
      // Metadata fields
      matchSource: matchSource ?? this.matchSource,
      matchType: matchType ?? this.matchType,
      qualityScore: qualityScore ?? this.qualityScore,
      unmatchedAt: unmatchedAt ?? this.unmatchedAt,
      unmatchReason: unmatchReason ?? this.unmatchReason,
      isFavorite: isFavorite ?? this.isFavorite,
      isPremiumMatch: isPremiumMatch ?? this.isPremiumMatch,
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
