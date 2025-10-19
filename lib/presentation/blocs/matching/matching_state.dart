part of 'matching_bloc.dart';

/// Enum for matching status
enum MatchingStatus { initial, loading, loaded, error }

/// State class for matching functionality
class MatchingState extends Equatable {
  const MatchingState({
    this.status = MatchingStatus.initial,
    this.profiles = const [],
    this.swipeHistory = const [],
    this.filters = const MatchingFilters(),
    this.hasReachedMax = false,
    this.lastSwipeWasMatch = false,
    this.matchedProfile,
    this.superLikesRemaining = 5,
    this.undosRemaining = 3,
    this.boostActive = false,
    this.boostExpiresAt,
    this.error,
  });

  final MatchingStatus status;
  final List<UserProfile> profiles;
  final List<MatchingSwipeAction> swipeHistory;
  final MatchingFilters filters;
  final bool hasReachedMax;
  final bool lastSwipeWasMatch;
  final UserProfile? matchedProfile;
  final int superLikesRemaining;
  final int undosRemaining;
  final bool boostActive;
  final DateTime? boostExpiresAt;
  final String? error;

  MatchingState copyWith({
    MatchingStatus? status,
    List<UserProfile>? profiles,
    List<MatchingSwipeAction>? swipeHistory,
    MatchingFilters? filters,
    bool? hasReachedMax,
    bool? lastSwipeWasMatch,
    UserProfile? matchedProfile,
    int? superLikesRemaining,
    int? undosRemaining,
    bool? boostActive,
    DateTime? boostExpiresAt,
    String? error,
  }) {
    return MatchingState(
      status: status ?? this.status,
      profiles: profiles ?? this.profiles,
      swipeHistory: swipeHistory ?? this.swipeHistory,
      filters: filters ?? this.filters,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      lastSwipeWasMatch: lastSwipeWasMatch ?? this.lastSwipeWasMatch,
      matchedProfile: matchedProfile ?? this.matchedProfile,
      superLikesRemaining: superLikesRemaining ?? this.superLikesRemaining,
      undosRemaining: undosRemaining ?? this.undosRemaining,
      boostActive: boostActive ?? this.boostActive,
      boostExpiresAt: boostExpiresAt ?? this.boostExpiresAt,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    status,
    profiles,
    swipeHistory,
    filters,
    hasReachedMax,
    lastSwipeWasMatch,
    matchedProfile,
    superLikesRemaining,
    undosRemaining,
    boostActive,
    boostExpiresAt,
    error,
  ];
}
