import 'package:equatable/equatable.dart';
import 'user.dart';

/// Leaderboard entry model
class LeaderboardEntry extends Equatable {
  final String id;
  final String userId;
  final User? user;
  final String category;
  final int score;
  final int position;
  final int? previousPosition;
  final Map<String, dynamic>? additionalData;
  final DateTime lastUpdated;
  final DateTime createdAt;

  const LeaderboardEntry({
    required this.id,
    required this.userId,
    this.user,
    required this.category,
    required this.score,
    required this.position,
    this.previousPosition,
    this.additionalData,
    required this.lastUpdated,
    required this.createdAt,
  });

  /// Create LeaderboardEntry from JSON
  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      id: json['id'] as String,
      userId: json['userId'] as String,
      user: json['user'] != null
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      category: json['category'] as String,
      score: json['score'] as int,
      position: json['position'] as int,
      previousPosition: json['previousPosition'] as int?,
      additionalData: json['additionalData'] as Map<String, dynamic>?,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Convert LeaderboardEntry to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'user': user?.toJson(),
      'category': category,
      'score': score,
      'position': position,
      'previousPosition': previousPosition,
      'additionalData': additionalData,
      'lastUpdated': lastUpdated.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Get position change from previous position
  int? get positionChange {
    if (previousPosition == null) return null;
    return previousPosition! - position; // Positive = moved up, negative = moved down
  }

  /// Get position change text
  String? get positionChangeText {
    final change = positionChange;
    if (change == null || change == 0) return null;
    
    if (change > 0) {
      return '+$change';
    } else {
      return change.toString();
    }
  }

  /// Get position change indicator
  PositionChangeIndicator? get positionChangeIndicator {
    final change = positionChange;
    if (change == null || change == 0) return null;
    
    if (change > 0) {
      return PositionChangeIndicator.up;
    } else {
      return PositionChangeIndicator.down;
    }
  }

  /// Format score for display
  String get formattedScore {
    if (score >= 1000000) {
      return '${(score / 1000000).toStringAsFixed(1)}M';
    } else if (score >= 1000) {
      return '${(score / 1000).toStringAsFixed(1)}K';
    }
    return score.toString();
  }

  /// Get position suffix (1st, 2nd, 3rd, etc.)
  String get positionWithSuffix {
    if (position >= 11 && position <= 13) {
      return '${position}th';
    }
    
    switch (position % 10) {
      case 1:
        return '${position}st';
      case 2:
        return '${position}nd';
      case 3:
        return '${position}rd';
      default:
        return '${position}th';
    }
  }

  /// Check if this is a top position (top 3)
  bool get isTopPosition => position <= 3;

  /// Get rank tier based on position
  RankTier get rankTier {
    if (position == 1) return RankTier.first;
    if (position <= 3) return RankTier.podium;
    if (position <= 10) return RankTier.top10;
    if (position <= 50) return RankTier.top50;
    if (position <= 100) return RankTier.top100;
    return RankTier.other;
  }

  /// Get time since last update
  String get timeSinceUpdate {
    final now = DateTime.now();
    final difference = now.difference(lastUpdated);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  /// Copy with method for immutable updates
  LeaderboardEntry copyWith({
    String? id,
    String? userId,
    User? user,
    String? category,
    int? score,
    int? position,
    int? previousPosition,
    Map<String, dynamic>? additionalData,
    DateTime? lastUpdated,
    DateTime? createdAt,
  }) {
    return LeaderboardEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      user: user ?? this.user,
      category: category ?? this.category,
      score: score ?? this.score,
      position: position ?? this.position,
      previousPosition: previousPosition ?? this.previousPosition,
      additionalData: additionalData ?? this.additionalData,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        user,
        category,
        score,
        position,
        previousPosition,
        additionalData,
        lastUpdated,
        createdAt,
      ];
}

/// Position change indicator enum
enum PositionChangeIndicator {
  up,
  down,
}

/// Rank tier enum
enum RankTier {
  first,
  podium,
  top10,
  top50,
  top100,
  other,
}
