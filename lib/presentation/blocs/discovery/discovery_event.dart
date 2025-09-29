import 'package:equatable/equatable.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../domain/entities/discovery_types.dart';

/// Events for the Discovery system - swipe-based user discovery and matching
/// 
/// Handles all user interactions in the discovery interface including
/// swiping, filtering, and advanced discovery features
abstract class DiscoveryEvent extends Equatable {
  const DiscoveryEvent();

  @override
  List<Object?> get props => [];
}

/// Load initial set of discoverable users
class LoadDiscoverableUsers extends DiscoveryEvent {
  const LoadDiscoverableUsers({
    this.resetStack = false,
    this.filters,
  });

  final bool resetStack;
  final DiscoveryFilters? filters;

  @override
  List<Object?> get props => [resetStack, filters];
}

/// User swiped left (pass/reject)
class SwipeLeft extends DiscoveryEvent {
  const SwipeLeft(this.userProfile);

  final UserProfile userProfile;

  @override
  List<Object> get props => [userProfile];
}

/// User swiped right (like)
class SwipeRight extends DiscoveryEvent {
  const SwipeRight(this.userProfile);

  final UserProfile userProfile;

  @override
  List<Object> get props => [userProfile];
}

/// User swiped up (super like)
class SwipeUp extends DiscoveryEvent {
  const SwipeUp(this.userProfile);

  final UserProfile userProfile;

  @override
  List<Object> get props => [userProfile];
}

/// Undo the last swipe action
class UndoLastSwipe extends DiscoveryEvent {
  const UndoLastSwipe();
}

/// Apply filters to discovery results
class ApplyFilters extends DiscoveryEvent {
  const ApplyFilters(this.filters);

  final DiscoveryFilters filters;

  @override
  List<Object> get props => [filters];
}

/// Use boost feature to increase visibility
class UseBoost extends DiscoveryEvent {
  const UseBoost();
}

/// Load more users when stack is getting low
class LoadMoreUsers extends DiscoveryEvent {
  const LoadMoreUsers();
}

/// Handle when a match is detected
class MatchDetected extends DiscoveryEvent {
  const MatchDetected({
    required this.matchedUser,
    required this.isNewMatch,
  });

  final UserProfile matchedUser;
  final bool isNewMatch;

  @override
  List<Object> get props => [matchedUser, isNewMatch];
}

/// Refresh discovery stack
class RefreshDiscovery extends DiscoveryEvent {
  const RefreshDiscovery();
}

/// Dismiss the match dialog and return to discovery
class DismissMatch extends DiscoveryEvent {
  const DismissMatch();
}

/// Clear the rewind just completed flag to prevent showing the toast again
class ClearRewindFlag extends DiscoveryEvent {
  const ClearRewindFlag();
}

/// Load discoverable users with user's saved filter preferences
class LoadDiscoverableUsersWithPreferences extends DiscoveryEvent {
  const LoadDiscoverableUsersWithPreferences();
}
