import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../domain/entities/discovery_types.dart';
import '../../../data/services/discovery_service.dart';
import 'discovery_event.dart';
import 'discovery_state.dart';

/// BLoC for managing user discovery and swiping functionality
/// 
/// Handles the core dating app experience including:
/// - Loading discoverable users
/// - Processing swipe actions (like, pass, super like)
/// - Managing filters and preferences
/// - Handling matches and boost features
/// - Undo functionality for premium users
class DiscoveryBloc extends Bloc<DiscoveryEvent, DiscoveryState> {
  DiscoveryBloc({
    required DiscoveryService discoveryService,
  })  : _discoveryService = discoveryService,
        super(const DiscoveryInitial()) {
    // Register event handlers
    on<LoadDiscoverableUsers>(_onLoadDiscoverableUsers);
    on<SwipeLeft>(_onSwipeLeft);
    on<SwipeRight>(_onSwipeRight);
    on<SwipeUp>(_onSwipeUp);
    on<UndoLastSwipe>(_onUndoLastSwipe);
    on<ApplyFilters>(_onApplyFilters);
    on<UseBoost>(_onUseBoost);
    on<LoadMoreUsers>(_onLoadMoreUsers);
    on<MatchDetected>(_onMatchDetected);
    on<RefreshDiscovery>(_onRefreshDiscovery);
    on<DismissMatch>(_onDismissMatch);
    on<ClearRewindFlag>(_onClearRewindFlag);
  }

  final DiscoveryService _discoveryService;

  /// Load initial discoverable users with optional filters
  Future<void> _onLoadDiscoverableUsers(
    LoadDiscoverableUsers event,
    Emitter<DiscoveryState> emit,
  ) async {
    try {
      emit(const DiscoveryLoading());

      final filters = event.filters ?? const DiscoveryFilters();
      final users = await _discoveryService.getDiscoverableUsers(
        filters: filters,
        // reset: event.resetStack, // Removed - backend doesn't support this parameter
      );

      if (users.isEmpty) {
        emit(DiscoveryEmpty(currentFilters: filters));
        return;
      }

      emit(DiscoveryLoaded(
        userStack: users,
        currentFilters: filters,
        canUndo: false,
        hasMoreUsers: users.length >= 10, // Assume more if we got a full batch
      ));
    } catch (error) {
      emit(DiscoveryError(
        message: 'Failed to load users: ${error.toString()}',
      ));
    }
  }

  /// Handle left swipe (pass/reject)
  Future<void> _onSwipeLeft(
    SwipeLeft event,
    Emitter<DiscoveryState> emit,
  ) async {
    if (state is! DiscoveryLoaded) return;

    final currentState = state as DiscoveryLoaded;
    
    try {
      // Send pass action to backend
      await _discoveryService.recordSwipeAction(
        targetUserId: event.userProfile.id,
        action: SwipeAction.left,
      );

      // Remove user from stack and update state
      final updatedStack = List<UserProfile>.from(currentState.userStack)
        ..removeWhere((user) => user.id == event.userProfile.id);

      emit(currentState.copyWith(
        userStack: updatedStack,
        lastSwipedUser: event.userProfile,
        lastSwipeAction: SwipeAction.left,
        canUndo: true,
      ));

      // Load more users if stack is getting low
      if (updatedStack.length <= 3) {
        add(const LoadMoreUsers());
      }
    } catch (error) {
      emit(DiscoveryError(
        message: 'Failed to record swipe: ${error.toString()}',
        previousState: currentState,
      ));
    }
  }

  /// Handle right swipe (like)
  Future<void> _onSwipeRight(
    SwipeRight event,
    Emitter<DiscoveryState> emit,
  ) async {
    if (state is! DiscoveryLoaded) return;

    final currentState = state as DiscoveryLoaded;
    
    try {
      // Send like action to backend
      final result = await _discoveryService.recordSwipeAction(
        targetUserId: event.userProfile.id,
        action: SwipeAction.right,
      );

      // Remove user from stack
      final updatedStack = List<UserProfile>.from(currentState.userStack)
        ..removeWhere((user) => user.id == event.userProfile.id);

      final updatedState = currentState.copyWith(
        userStack: updatedStack,
        lastSwipedUser: event.userProfile,
        lastSwipeAction: SwipeAction.right,
        canUndo: true,
      );

      // Check if it's a match
      if (result.isMatch) {
        emit(DiscoveryMatchFound(
          matchedUser: event.userProfile,
          isNewMatch: true,
          previousState: updatedState,
        ));
      } else {
        emit(updatedState);
      }

      // Load more users if needed
      if (updatedStack.length <= 3) {
        add(const LoadMoreUsers());
      }
    } catch (error) {
      emit(DiscoveryError(
        message: 'Failed to record like: ${error.toString()}',
        previousState: currentState,
      ));
    }
  }

  /// Handle up swipe (super like)
  Future<void> _onSwipeUp(
    SwipeUp event,
    Emitter<DiscoveryState> emit,
  ) async {
    if (state is! DiscoveryLoaded) return;

    final currentState = state as DiscoveryLoaded;
    
    try {
      // Send super like action to backend
      final result = await _discoveryService.recordSwipeAction(
        targetUserId: event.userProfile.id,
        action: SwipeAction.up,
      );

      // Remove user from stack
      final updatedStack = List<UserProfile>.from(currentState.userStack)
        ..removeWhere((user) => user.id == event.userProfile.id);

      final updatedState = currentState.copyWith(
        userStack: updatedStack,
        lastSwipedUser: event.userProfile,
        lastSwipeAction: SwipeAction.up,
        canUndo: true,
      );

      // Super likes have higher match probability
      if (result.isMatch) {
        emit(DiscoveryMatchFound(
          matchedUser: event.userProfile,
          isNewMatch: true,
          previousState: updatedState,
        ));
      } else {
        emit(updatedState);
      }

      // Load more users if needed
      if (updatedStack.length <= 3) {
        add(const LoadMoreUsers());
      }
    } catch (error) {
      emit(DiscoveryError(
        message: 'Failed to record super like: ${error.toString()}',
        previousState: currentState,
      ));
    }
  }

  /// Undo the last swipe action (premium feature)
  Future<void> _onUndoLastSwipe(
    UndoLastSwipe event,
    Emitter<DiscoveryState> emit,
  ) async {
    if (state is! DiscoveryLoaded) return;

    final currentState = state as DiscoveryLoaded;
    
    if (!currentState.canUndo || currentState.lastSwipedUser == null) {
      return;
    }

    try {
      // Undo the swipe action on backend
      await _discoveryService.undoLastSwipe();

      // Add the user back to the front of the stack
      final updatedStack = [currentState.lastSwipedUser!, ...currentState.userStack];

      emit(currentState.copyWith(
        userStack: updatedStack,
        lastSwipedUser: null,
        lastSwipeAction: null,
        canUndo: false,
        rewindJustCompleted: true,
      ));
    } catch (error) {
      emit(DiscoveryError(
        message: 'Failed to undo swipe: ${error.toString()}',
        previousState: currentState,
      ));
    }
  }

  /// Apply new filters to discovery
  Future<void> _onApplyFilters(
    ApplyFilters event,
    Emitter<DiscoveryState> emit,
  ) async {
    add(LoadDiscoverableUsers(
      resetStack: true,
      filters: event.filters,
    ));
  }

  /// Activate boost feature
  Future<void> _onUseBoost(
    UseBoost event,
    Emitter<DiscoveryState> emit,
  ) async {
    if (state is! DiscoveryLoaded) return;

    final currentState = state as DiscoveryLoaded;
    
    try {
      emit(DiscoveryBoostActivating(previousState: currentState));

      final boostResult = await _discoveryService.activateBoost();

      emit(DiscoveryBoostActivated(
        boostDuration: boostResult.duration,
        updatedState: currentState.copyWith(
          isBoostActive: true,
          boostTimeRemaining: boostResult.duration,
        ),
      ));

      // Return to normal state after showing boost confirmation
      await Future.delayed(const Duration(seconds: 2));
      emit(currentState.copyWith(
        isBoostActive: true,
        boostTimeRemaining: boostResult.duration,
      ));
    } catch (error) {
      emit(DiscoveryError(
        message: 'Failed to activate boost: ${error.toString()}',
        previousState: currentState,
      ));
    }
  }

  /// Load more users when stack is getting low
  Future<void> _onLoadMoreUsers(
    LoadMoreUsers event,
    Emitter<DiscoveryState> emit,
  ) async {
    if (state is! DiscoveryLoaded) return;

    final currentState = state as DiscoveryLoaded;
    
    try {
      emit(currentState.copyWith()); // Trigger loading indicator

      final moreUsers = await _discoveryService.getDiscoverableUsers(
        filters: currentState.currentFilters,
        offset: currentState.userStack.length,
      );

      if (moreUsers.isEmpty) {
        emit(currentState.copyWith(hasMoreUsers: false));
        return;
      }

      final updatedStack = [...currentState.userStack, ...moreUsers];
      
      emit(currentState.copyWith(
        userStack: updatedStack,
        hasMoreUsers: moreUsers.length >= 10,
      ));
    } catch (error) {
      // Silently fail for background loading
      emit(currentState.copyWith(hasMoreUsers: false));
    }
  }

  /// Handle match detection
  Future<void> _onMatchDetected(
    MatchDetected event,
    Emitter<DiscoveryState> emit,
  ) async {
    if (state is! DiscoveryLoaded) return;

    final currentState = state as DiscoveryLoaded;
    
    emit(DiscoveryMatchFound(
      matchedUser: event.matchedUser,
      isNewMatch: event.isNewMatch,
      previousState: currentState,
    ));
  }

  /// Refresh the entire discovery stack
  Future<void> _onRefreshDiscovery(
    RefreshDiscovery event,
    Emitter<DiscoveryState> emit,
  ) async {
    if (state is DiscoveryLoaded) {
      final currentState = state as DiscoveryLoaded;
      add(LoadDiscoverableUsers(
        resetStack: true,
        filters: currentState.currentFilters,
      ));
    } else {
      add(const LoadDiscoverableUsers(resetStack: true));
    }
  }

  /// Handle dismissing match celebration
  Future<void> _onDismissMatch(
    DismissMatch event,
    Emitter<DiscoveryState> emit,
  ) async {
    if (state is DiscoveryMatchFound) {
      final matchState = state as DiscoveryMatchFound;
      emit(matchState.previousState);
    }
  }

  /// Return to loaded state from match celebration
  void dismissMatch() {
    if (state is DiscoveryMatchFound) {
      add(const _DismissMatchEvent());
    }
  }

  /// Clear the rewind just completed flag
  Future<void> _onClearRewindFlag(
    ClearRewindFlag event,
    Emitter<DiscoveryState> emit,
  ) async {
    if (state is DiscoveryLoaded) {
      final currentState = state as DiscoveryLoaded;
      emit(currentState.copyWith(rewindJustCompleted: false));
    }
  }
}

/// Internal event for dismissing match celebrations
class _DismissMatchEvent extends DiscoveryEvent {
  const _DismissMatchEvent();
}
