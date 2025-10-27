import 'package:equatable/equatable.dart';

/// Enum for tracking swipe actions
enum SwipeAction {
  left, // Pass/Reject
  right, // Like
  up, // Super Like
}

extension SwipeActionExtension on SwipeAction {
  String get displayName {
    switch (this) {
      case SwipeAction.left:
        return 'Passed';
      case SwipeAction.right:
        return 'Liked';
      case SwipeAction.up:
        return 'Super Liked';
    }
  }

  String get emoji {
    switch (this) {
      case SwipeAction.left:
        return '👎';
      case SwipeAction.right:
        return '❤️';
      case SwipeAction.up:
        return '⭐';
    }
  }
}

/// Discovery filters data class
class DiscoveryFilters extends Equatable {
  const DiscoveryFilters({
    this.minAge,
    this.maxAge,
    this.maxDistance,
    this.interests = const [],
    this.verifiedOnly = false,
    this.hasPhotos = false,
    this.premiumOnly = false,
    this.recentlyActive = false,
  });

  final int? minAge;
  final int? maxAge;
  final double? maxDistance;
  final List<String> interests;
  final bool verifiedOnly;
  final bool hasPhotos;
  final bool premiumOnly;
  final bool recentlyActive;

  DiscoveryFilters copyWith({
    int? minAge,
    int? maxAge,
    double? maxDistance,
    List<String>? interests,
    bool? verifiedOnly,
    bool? hasPhotos,
    bool? premiumOnly,
    bool? recentlyActive,
  }) {
    return DiscoveryFilters(
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      maxDistance: maxDistance ?? this.maxDistance,
      interests: interests ?? this.interests,
      verifiedOnly: verifiedOnly ?? this.verifiedOnly,
      hasPhotos: hasPhotos ?? this.hasPhotos,
      premiumOnly: premiumOnly ?? this.premiumOnly,
      recentlyActive: recentlyActive ?? this.recentlyActive,
    );
  }

  @override
  List<Object?> get props => [
    minAge,
    maxAge,
    maxDistance,
    interests,
    verifiedOnly,
    hasPhotos,
    premiumOnly,
    recentlyActive,
  ];
}

/// Result of a swipe action
class SwipeResult {
  const SwipeResult({
    required this.isMatch,
    required this.targetUserId,
    required this.action,
    this.conversationId,
  });

  final bool isMatch;
  final String targetUserId;
  final SwipeAction action;
  final String? conversationId;
}

/// Result of boost activation
class BoostResult {
  const BoostResult({
    required this.success,
    required this.duration,
    required this.startTime,
  });

  final bool success;
  final Duration duration;
  final DateTime startTime;
}
