import 'package:equatable/equatable.dart';

import '../../../data/models/match_model.dart';
import '../../../data/models/user_model.dart';

/// Base class for all matching system states
sealed class MatchState extends Equatable {
  const MatchState();

  @override
  List<Object?> get props => [];
}

/// Initial state when MatchBloc is created
final class MatchInitial extends MatchState {
  const MatchInitial();
}

/// State when match operation is in progress
final class MatchLoading extends MatchState {
  const MatchLoading();
}

/// State when user recommendations are loaded
final class MatchRecommendationsLoaded extends MatchState {
  const MatchRecommendationsLoaded({
    required this.users,
    required this.hasMore,
  });

  final List<UserModel> users;
  final bool hasMore;

  @override
  List<Object?> get props => [users, hasMore];
}

/// State when nearby users are loaded
final class MatchNearbyUsersLoaded extends MatchState {
  const MatchNearbyUsersLoaded({required this.users, required this.hasMore});

  final List<UserModel> users;
  final bool hasMore;

  @override
  List<Object?> get props => [users, hasMore];
}

/// State when user has been liked (no match yet)
final class MatchUserLikeRecorded extends MatchState {
  const MatchUserLikeRecorded({
    required this.likedUserId,
    required this.message,
  });

  final String likedUserId;
  final String message;

  @override
  List<Object?> get props => [likedUserId, message];
}

/// State when user has been passed
final class MatchUserPassRecorded extends MatchState {
  const MatchUserPassRecorded({
    required this.passedUserId,
    required this.message,
  });

  final String passedUserId;
  final String message;

  @override
  List<Object?> get props => [passedUserId, message];
}

/// State when user has been super liked
final class MatchUserSuperLikeRecorded extends MatchState {
  const MatchUserSuperLikeRecorded({
    required this.superLikedUserId,
    required this.message,
  });

  final String superLikedUserId;
  final String message;

  @override
  List<Object?> get props => [superLikedUserId, message];
}

/// State when a mutual match occurs (both users liked each other)
final class MatchCreated extends MatchState {
  const MatchCreated({
    required this.match,
    required this.message,
    this.isNewMatch = false,
  });

  final MatchModel match;
  final String message;
  final bool isNewMatch;

  @override
  List<Object?> get props => [match, message, isNewMatch];
}

/// State when user's matches are loaded
final class MatchUserMatchesLoaded extends MatchState {
  const MatchUserMatchesLoaded({required this.matches, required this.hasMore});

  final List<MatchModel> matches;
  final bool hasMore;

  @override
  List<Object?> get props => [matches, hasMore];
}

/// State when user has been unmatched
final class MatchUserUnmatchRecorded extends MatchState {
  const MatchUserUnmatchRecorded({
    required this.unmatchedUserId,
    required this.message,
  });

  final String unmatchedUserId;
  final String message;

  @override
  List<Object?> get props => [unmatchedUserId, message];
}

/// State when match operation fails
final class MatchError extends MatchState {
  const MatchError({required this.message, this.errorCode});

  final String message;
  final String? errorCode;

  @override
  List<Object?> get props => [message, errorCode];
}

/// State when matches are loaded (general)
final class MatchesLoaded extends MatchState {
  const MatchesLoaded({required this.matches, required this.hasMore});

  final List<MatchModel> matches;
  final bool hasMore;

  @override
  List<Object?> get props => [matches, hasMore];
}

/// State when match suggestions are loaded
final class MatchSuggestionsLoaded extends MatchState {
  const MatchSuggestionsLoaded({
    required this.suggestions,
    required this.hasMore,
  });

  final List<UserModel> suggestions;
  final bool hasMore;

  @override
  List<Object?> get props => [suggestions, hasMore];
}

/// State when match action is in progress
final class MatchActionInProgress extends MatchState {
  const MatchActionInProgress();
}

/// State when match action succeeds
final class MatchActionSuccess extends MatchState {
  const MatchActionSuccess({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

/// State when a match is accepted
final class MatchAccepted extends MatchState {
  const MatchAccepted({required this.match, required this.message});

  final MatchModel match;
  final String message;

  @override
  List<Object?> get props => [match, message];
}

/// State when a match is rejected
final class MatchRejected extends MatchState {
  const MatchRejected({required this.matchId, required this.message});

  final String matchId;
  final String message;

  @override
  List<Object?> get props => [matchId, message];
}

/// State when a user is unmatched
final class MatchUnmatched extends MatchState {
  const MatchUnmatched({required this.matchId, required this.message});

  final String matchId;
  final String message;

  @override
  List<Object?> get props => [matchId, message];
}

/// State when match details are loaded
final class MatchDetailsLoaded extends MatchState {
  const MatchDetailsLoaded({required this.match});

  final MatchModel match;

  @override
  List<Object?> get props => [match];
}

/// State when match status is updated
final class MatchStatusUpdated extends MatchState {
  const MatchStatusUpdated({required this.match, required this.message});

  final MatchModel match;
  final String message;

  @override
  List<Object?> get props => [match, message];
}
