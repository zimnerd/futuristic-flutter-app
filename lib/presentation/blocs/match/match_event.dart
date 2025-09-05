import 'package:equatable/equatable.dart';

/// Base class for all matching system events
sealed class MatchEvent extends Equatable {
  const MatchEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load user recommendations for discovery
final class MatchRecommendationsLoadRequested extends MatchEvent {
  const MatchRecommendationsLoadRequested({
    required this.userId,
    this.limit = 10,
  });

  final String userId;
  final int limit;

  @override
  List<Object?> get props => [userId, limit];
}

/// Event to load nearby users
final class MatchNearbyUsersLoadRequested extends MatchEvent {
  const MatchNearbyUsersLoadRequested({
    required this.latitude,
    required this.longitude,
    this.radiusKm = 50.0,
    this.limit = 20,
  });

  final double latitude;
  final double longitude;
  final double radiusKm;
  final int limit;

  @override
  List<Object?> get props => [latitude, longitude, radiusKm, limit];
}

/// Event when user likes another user
final class MatchUserLiked extends MatchEvent {
  const MatchUserLiked({required this.likerId, required this.likedUserId});

  final String likerId;
  final String likedUserId;

  @override
  List<Object?> get props => [likerId, likedUserId];
}

/// Event when user passes on another user
final class MatchUserPassed extends MatchEvent {
  const MatchUserPassed({required this.passerId, required this.passedUserId});

  final String passerId;
  final String passedUserId;

  @override
  List<Object?> get props => [passerId, passedUserId];
}

/// Event when user super likes another user
final class MatchUserSuperLiked extends MatchEvent {
  const MatchUserSuperLiked({
    required this.superLikerId,
    required this.superLikedUserId,
  });

  final String superLikerId;
  final String superLikedUserId;

  @override
  List<Object?> get props => [superLikerId, superLikedUserId];
}

/// Event to load user's matches
final class MatchUserMatchesLoadRequested extends MatchEvent {
  const MatchUserMatchesLoadRequested({required this.userId, this.limit = 50});

  final String userId;
  final int limit;

  @override
  List<Object?> get props => [userId, limit];
}

/// Event to unmatch with a user
final class MatchUserUnmatched extends MatchEvent {
  const MatchUserUnmatched({
    required this.unmatcherId,
    required this.unmatchedUserId,
  });

  final String unmatcherId;
  final String unmatchedUserId;

  @override
  List<Object?> get props => [unmatcherId, unmatchedUserId];
}

/// Event to clear match-related errors
final class MatchErrorCleared extends MatchEvent {
  const MatchErrorCleared();
}
