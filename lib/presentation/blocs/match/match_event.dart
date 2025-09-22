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

/// Event to load user's matches with optional filtering
final class LoadMatches extends MatchEvent {
  const LoadMatches({this.status, this.limit = 20, this.offset = 0});

  final String? status;
  final int? limit;
  final int offset;

  @override
  List<Object?> get props => [status, limit, offset];
}

/// Event to load match suggestions
final class LoadMatchSuggestions extends MatchEvent {
  const LoadMatchSuggestions({
    this.limit = 10,
    this.useAI = false,
    this.filters,
  });

  final int limit;
  final bool useAI;
  final Map<String, dynamic>? filters;

  @override
  List<Object?> get props => [limit, useAI, filters];
}

/// Event to create a new match (like someone)
final class CreateMatch extends MatchEvent {
  const CreateMatch({required this.targetUserId, this.isSuper = false});

  final String targetUserId;
  final bool isSuper;

  @override
  List<Object?> get props => [targetUserId, isSuper];
}

/// Event to accept a pending match
final class AcceptMatch extends MatchEvent {
  const AcceptMatch({required this.matchId});

  final String matchId;

  @override
  List<Object?> get props => [matchId];
}

/// Event to reject a pending match
final class RejectMatch extends MatchEvent {
  const RejectMatch({required this.matchId});

  final String matchId;

  @override
  List<Object?> get props => [matchId];
}

/// Event to unmatch a user
final class UnmatchUser extends MatchEvent {
  const UnmatchUser({required this.matchId});

  final String matchId;

  @override
  List<Object?> get props => [matchId];
}

/// Event to load detailed match information
final class LoadMatchDetails extends MatchEvent {
  const LoadMatchDetails({required this.matchId});

  final String matchId;

  @override
  List<Object?> get props => [matchId];
}

/// Event to update match status
final class UpdateMatchStatus extends MatchEvent {
  const UpdateMatchStatus({required this.matchId, required this.status});

  final String matchId;
  final String status;

  @override
  List<Object?> get props => [matchId, status];
}

/// Event to reset match state
final class ResetMatchState extends MatchEvent {
  const ResetMatchState();
}

/// Event to remove a match from the list when conversation is created
final class RemoveMatchFromList extends MatchEvent {
  const RemoveMatchFromList({required this.matchId});

  final String matchId;

  @override
  List<Object?> get props => [matchId];
}
