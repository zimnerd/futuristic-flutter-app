import 'package:equatable/equatable.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../domain/entities/discovery_types.dart';

/// States for the Discovery system - represents all possible states of the discovery interface
/// 
/// Manages the card stack, loading states, matches, and error handling
/// for the core swiping experience
abstract class DiscoveryState extends Equatable {
  const DiscoveryState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any discovery data is loaded
class DiscoveryInitial extends DiscoveryState {
  const DiscoveryInitial();
}

/// Loading discoverable users
class DiscoveryLoading extends DiscoveryState {
  const DiscoveryLoading({this.isLoadingMore = false});

  final bool isLoadingMore;

  @override
  List<Object> get props => [isLoadingMore];
}

/// Successfully loaded users for discovery
class DiscoveryLoaded extends DiscoveryState {
  const DiscoveryLoaded({
    required this.userStack,
    required this.currentFilters,
    this.lastSwipedUser,
    this.lastSwipeAction,
    this.canUndo = false,
    this.hasMoreUsers = true,
    this.isBoostActive = false,
    this.boostTimeRemaining,
    this.rewindJustCompleted = false,
  });

  final List<UserProfile> userStack;
  final DiscoveryFilters currentFilters;
  final UserProfile? lastSwipedUser;
  final SwipeAction? lastSwipeAction;
  final bool canUndo;
  final bool hasMoreUsers;
  final bool isBoostActive;
  final Duration? boostTimeRemaining;
  final bool rewindJustCompleted;

  /// Get the current top card (user to be swiped)
  UserProfile? get currentUser => userStack.isNotEmpty ? userStack.first : null;

  /// Check if there are users available to swipe
  bool get hasUsers => userStack.isNotEmpty;

  /// Check if we need to load more users (when stack is getting low)
  bool get needsMoreUsers => userStack.length <= 3 && hasMoreUsers;

  DiscoveryLoaded copyWith({
    List<UserProfile>? userStack,
    DiscoveryFilters? currentFilters,
    UserProfile? lastSwipedUser,
    SwipeAction? lastSwipeAction,
    bool? canUndo,
    bool? hasMoreUsers,
    bool? isBoostActive,
    Duration? boostTimeRemaining,
    bool? rewindJustCompleted,
  }) {
    return DiscoveryLoaded(
      userStack: userStack ?? this.userStack,
      currentFilters: currentFilters ?? this.currentFilters,
      lastSwipedUser: lastSwipedUser ?? this.lastSwipedUser,
      lastSwipeAction: lastSwipeAction ?? this.lastSwipeAction,
      canUndo: canUndo ?? this.canUndo,
      hasMoreUsers: hasMoreUsers ?? this.hasMoreUsers,
      isBoostActive: isBoostActive ?? this.isBoostActive,
      boostTimeRemaining: boostTimeRemaining ?? this.boostTimeRemaining,
      rewindJustCompleted: rewindJustCompleted ?? this.rewindJustCompleted,
    );
  }

  @override
  List<Object?> get props => [
        userStack,
        currentFilters,
        lastSwipedUser,
        lastSwipeAction,
        canUndo,
        hasMoreUsers,
        isBoostActive,
        boostTimeRemaining,
        rewindJustCompleted,
      ];
}

/// A match has been detected - show celebration UI
class DiscoveryMatchFound extends DiscoveryState {
  const DiscoveryMatchFound({
    required this.matchedUser,
    required this.isNewMatch,
    required this.previousState,
  });

  final UserProfile matchedUser;
  final bool isNewMatch;
  final DiscoveryLoaded previousState;

  @override
  List<Object> get props => [matchedUser, isNewMatch, previousState];
}

/// No more users available for discovery
class DiscoveryEmpty extends DiscoveryState {
  const DiscoveryEmpty({
    required this.currentFilters,
    this.hasUsedAllUsers = false,
  });

  final DiscoveryFilters currentFilters;
  final bool hasUsedAllUsers;

  @override
  List<Object> get props => [currentFilters, hasUsedAllUsers];
}

/// Error occurred during discovery operations
class DiscoveryError extends DiscoveryState {
  const DiscoveryError({
    required this.message,
    this.previousState,
  });

  final String message;
  final DiscoveryState? previousState;

  @override
  List<Object?> get props => [message, previousState];
}

/// Boost is being activated
class DiscoveryBoostActivating extends DiscoveryState {
  const DiscoveryBoostActivating({required this.previousState});

  final DiscoveryLoaded previousState;

  @override
  List<Object> get props => [previousState];
}

/// Boost has been successfully activated
class DiscoveryBoostActivated extends DiscoveryState {
  const DiscoveryBoostActivated({
    required this.boostDuration,
    required this.updatedState,
  });

  final Duration boostDuration;
  final DiscoveryLoaded updatedState;

  @override
  List<Object> get props => [boostDuration, updatedState];
}
