import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/user_profile.dart';
import '../entities/discovery_types.dart' as discovery_types;
import '../../presentation/blocs/matching/matching_bloc.dart';

/// Repository interface for matching functionality
abstract class MatchingRepository {
  /// Get potential matches based on filters
  Future<Either<Failure, List<UserProfile>>> getPotentialMatches({
    MatchingFilters? filters,
    int limit = 10,
    int offset = 0,
  });

  /// Swipe on a profile (like, pass, or super like)
  Future<Either<Failure, discovery_types.SwipeResult>> swipeProfile({
    required String profileId,
    required discovery_types.SwipeAction direction,
  });

  /// Undo the last swipe action
  Future<Either<Failure, bool>> undoSwipe(String profileId);

  /// Report a profile for inappropriate content
  Future<Either<Failure, bool>> reportProfile({
    required String profileId,
    required String reason,
    String? description,
  });

  /// Get swipe history for the user
  Future<Either<Failure, List<discovery_types.SwipeAction>>> getSwipeHistory({
    int limit = 50,
    int offset = 0,
  });

  /// Get current user's match statistics
  Future<Either<Failure, MatchStats>> getMatchStats();

  /// Update user's location for matching
  Future<Either<Failure, bool>> updateLocation({
    required double latitude,
    required double longitude,
  });

  /// Get remaining super likes and undos
  Future<Either<Failure, UserLimits>> getUserLimits();

  /// Purchase additional super likes or undos
  Future<Either<Failure, bool>> purchaseLimits({
    int? superLikes,
    int? undos,
  });
}

/// Match statistics
class MatchStats {
  const MatchStats({
    required this.totalLikes,
    required this.totalPasses,
    required this.totalSuperLikes,
    required this.totalMatches,
    required this.likesReceived,
    required this.matchRate,
  });

  final int totalLikes;
  final int totalPasses;
  final int totalSuperLikes;
  final int totalMatches;
  final int likesReceived;
  final double matchRate; // percentage

  factory MatchStats.fromJson(Map<String, dynamic> json) {
    return MatchStats(
      totalLikes: json['totalLikes'] ?? 0,
      totalPasses: json['totalPasses'] ?? 0,
      totalSuperLikes: json['totalSuperLikes'] ?? 0,
      totalMatches: json['totalMatches'] ?? 0,
      likesReceived: json['likesReceived'] ?? 0,
      matchRate: (json['matchRate'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalLikes': totalLikes,
      'totalPasses': totalPasses,
      'totalSuperLikes': totalSuperLikes,
      'totalMatches': totalMatches,
      'likesReceived': likesReceived,
      'matchRate': matchRate,
    };
  }
}

/// User limits for super likes and undos
class UserLimits {
  const UserLimits({
    required this.superLikesRemaining,
    required this.undosRemaining,
    required this.superLikesResetAt,
    required this.undosResetAt,
  });

  final int superLikesRemaining;
  final int undosRemaining;
  final DateTime superLikesResetAt;
  final DateTime undosResetAt;

  factory UserLimits.fromJson(Map<String, dynamic> json) {
    return UserLimits(
      superLikesRemaining: json['superLikesRemaining'] ?? 0,
      undosRemaining: json['undosRemaining'] ?? 0,
      superLikesResetAt: DateTime.parse(json['superLikesResetAt']),
      undosResetAt: DateTime.parse(json['undosResetAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'superLikesRemaining': superLikesRemaining,
      'undosRemaining': undosRemaining,
      'superLikesResetAt': superLikesResetAt.toIso8601String(),
      'undosResetAt': undosResetAt.toIso8601String(),
    };
  }
}
