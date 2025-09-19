part of 'matching_bloc.dart';

/// Base class for all matching events
abstract class MatchingEvent extends Equatable {
  const MatchingEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load potential matches
class LoadPotentialMatches extends MatchingEvent {
  const LoadPotentialMatches({this.refresh = false});

  final bool refresh;

  @override
  List<Object?> get props => [refresh];
}

/// Event to swipe on a profile
class SwipeProfile extends MatchingEvent {
  const SwipeProfile({
    required this.profileId,
    required this.direction,
  });

  final String profileId;
  final SwipeAction direction;

  @override
  List<Object?> get props => [profileId, direction];
}

/// Event to undo the last swipe
class UndoLastSwipe extends MatchingEvent {
  const UndoLastSwipe();
}

/// Event to refresh all matches
class RefreshMatches extends MatchingEvent {
  const RefreshMatches();
}

/// Event to super like a profile
class SuperLikeProfile extends MatchingEvent {
  const SuperLikeProfile({required this.profileId});

  final String profileId;

  @override
  List<Object?> get props => [profileId];
}

/// Event to report a profile
class ReportProfile extends MatchingEvent {
  const ReportProfile({
    required this.profileId,
    required this.reason,
    this.description,
  });

  final String profileId;
  final String reason;
  final String? description;

  @override
  List<Object?> get props => [profileId, reason, description];
}

/// Event to update matching filters
class UpdateFilters extends MatchingEvent {
  const UpdateFilters({required this.filters});

  final MatchingFilters filters;

  @override
  List<Object?> get props => [filters];
}

/// Event to boost profile visibility
class BoostProfile extends MatchingEvent {
  const BoostProfile();
}
