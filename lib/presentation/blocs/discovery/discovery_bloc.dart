import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../domain/entities/discovery_types.dart';
import '../../../data/services/discovery_service.dart';
import '../../../data/services/preferences_service.dart';
import '../../../services/media_prefetch_service.dart';
import '../../../core/utils/logger.dart';
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
/// - Media prefetching for smooth scrolling experience
class DiscoveryBloc extends Bloc<DiscoveryEvent, DiscoveryState> {
  DiscoveryBloc({
    required DiscoveryService discoveryService,
    required PreferencesService preferencesService,
    MediaPrefetchService? prefetchService,
  }) : _discoveryService = discoveryService,
       _preferencesService = preferencesService,
       _prefetchService = prefetchService ?? MediaPrefetchService(),
       super(const DiscoveryInitial()) {
    // Register event handlers
    on<LoadDiscoverableUsers>(_onLoadDiscoverableUsers);
    on<LoadDiscoverableUsersWithPreferences>(
      _onLoadDiscoverableUsersWithPreferences,
    );
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
    on<LoadWhoLikedYou>(_onLoadWhoLikedYou);
  }

  final DiscoveryService _discoveryService;
  final PreferencesService _preferencesService;
  final MediaPrefetchService _prefetchService;

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

      emit(
        DiscoveryLoaded(
          userStack: users,
          currentFilters: filters,
          canUndo: false,
          hasMoreUsers:
              users.length >= 10, // Assume more if we got a full batch
        ),
      );

      // 🚀 Trigger prefetch for upcoming profiles
      _prefetchService.prefetchProfiles(
        profiles: users,
        currentIndex: 0, // Start prefetching from the first profile
      );
    } catch (error) {
      AppLogger.error('Error loading discoverable users: $error');
      emit(
        DiscoveryError(message: _extractUserFriendlyErrorMessage(error)),
      );
    }
  }

  /// Load discoverable users with saved filter preferences
  Future<void> _onLoadDiscoverableUsersWithPreferences(
    LoadDiscoverableUsersWithPreferences event,
    Emitter<DiscoveryState> emit,
  ) async {
    try {
      emit(const DiscoveryLoading());

      // Load user's saved filter preferences
      final preferences = await _preferencesService.getFilterPreferences();

      // Convert FilterPreferences to DiscoveryFilters
      final filters = DiscoveryFilters(
        minAge: preferences.minAge,
        maxAge: preferences.maxAge,
        maxDistance: preferences.maxDistance,
        interests: preferences.interests,
        verifiedOnly: preferences.showOnlyVerified,
        premiumOnly: false, // Not in FilterPreferences
        recentlyActive: false, // Not in FilterPreferences
      );

      // Load users with the filters applied
      final users = await _discoveryService.getDiscoverableUsers(
        filters: filters,
      );

      if (users.isEmpty) {
        emit(DiscoveryEmpty(currentFilters: filters, hasUsedAllUsers: true));
        return;
      }

      emit(
        DiscoveryLoaded(
          userStack: users,
          currentFilters: filters,
          canUndo: false,
          hasMoreUsers: users.length >= 10,
        ),
      );

      // 🚀 Trigger prefetch for upcoming profiles
      _prefetchService.prefetchProfiles(profiles: users, currentIndex: 0);
    } catch (error) {
      // Fallback to loading without filters if preferences fail
      AppLogger.debug('Error loading with preferences, falling back: $error');
      AppLogger.error('Full error details: ${error.toString()}');
      add(const LoadDiscoverableUsers());
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

      emit(
        currentState.copyWith(
          userStack: updatedStack,
          lastSwipedUser: event.userProfile,
          lastSwipeAction: SwipeAction.left,
          canUndo: true,
        ),
      );

      // 🚀 Prefetch next profiles after swipe
      if (updatedStack.isNotEmpty) {
        _prefetchService.prefetchProfiles(
          profiles: updatedStack,
          currentIndex: 0, // Always start from current top profile
        );
      }

      // Load more users if stack is getting low
      if (updatedStack.length <= 3) {
        add(const LoadMoreUsers());
      }
    } catch (error) {
      emit(
        DiscoveryError(
          message: _extractUserFriendlyErrorMessage(error),
          previousState: currentState,
        ),
      );
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
        emit(
          DiscoveryMatchFound(
            matchedUser: event.userProfile,
            isNewMatch: true,
            previousState: updatedState,
          ),
        );
      } else {
        emit(updatedState);
      }

      // 🚀 Prefetch next profiles after swipe
      if (updatedStack.isNotEmpty) {
        _prefetchService.prefetchProfiles(
          profiles: updatedStack,
          currentIndex: 0,
        );
      }

      // Load more users if stack is getting low
      if (updatedStack.length <= 3) {
        add(const LoadMoreUsers());
      }
    } catch (error) {
      emit(
        DiscoveryError(
          message: _extractUserFriendlyErrorMessage(error),
          previousState: currentState,
        ),
      );
    }
  }

  /// Handle up swipe (super like)
  Future<void> _onSwipeUp(SwipeUp event, Emitter<DiscoveryState> emit) async {
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
        emit(
          DiscoveryMatchFound(
            matchedUser: event.userProfile,
            isNewMatch: true,
            previousState: updatedState,
          ),
        );
      } else {
        emit(updatedState);
      }

      // 🚀 Prefetch next profiles after super like
      if (updatedStack.isNotEmpty) {
        _prefetchService.prefetchProfiles(
          profiles: updatedStack,
          currentIndex: 0,
        );
      }

      // Load more users if needed
      if (updatedStack.length <= 3) {
        add(const LoadMoreUsers());
      }
    } catch (error) {
      emit(
        DiscoveryError(
          message: _extractUserFriendlyErrorMessage(error),
          previousState: currentState,
        ),
      );
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
      final updatedStack = [
        currentState.lastSwipedUser!,
        ...currentState.userStack,
      ];

      emit(
        currentState.copyWith(
          userStack: updatedStack,
          lastSwipedUser: null,
          lastSwipeAction: null,
          canUndo: false,
          rewindJustCompleted: true,
        ),
      );
    } catch (error) {
      emit(
        DiscoveryError(
          message: _extractUserFriendlyErrorMessage(error),
          previousState: currentState,
        ),
      );
    }
  }

  /// Apply new filters to discovery
  Future<void> _onApplyFilters(
    ApplyFilters event,
    Emitter<DiscoveryState> emit,
  ) async {
    add(LoadDiscoverableUsers(resetStack: true, filters: event.filters));
  }

  /// Activate boost feature
  Future<void> _onUseBoost(UseBoost event, Emitter<DiscoveryState> emit) async {
    if (state is! DiscoveryLoaded) return;

    final currentState = state as DiscoveryLoaded;

    try {
      emit(DiscoveryBoostActivating(previousState: currentState));

      final boostResult = await _discoveryService.activateBoost();

      emit(
        DiscoveryBoostActivated(
          boostDuration: boostResult.duration,
          updatedState: currentState.copyWith(
            isBoostActive: true,
            boostTimeRemaining: boostResult.duration,
          ),
        ),
      );

      // Return to normal state after showing boost confirmation
      await Future.delayed(const Duration(seconds: 2));
      emit(
        currentState.copyWith(
          isBoostActive: true,
          boostTimeRemaining: boostResult.duration,
        ),
      );
    } catch (error) {
      emit(
        DiscoveryError(
          message: _extractUserFriendlyErrorMessage(error),
          previousState: currentState,
        ),
      );
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

      emit(
        currentState.copyWith(
          userStack: updatedStack,
          hasMoreUsers: moreUsers.length >= 10,
        ),
      );
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

    emit(
      DiscoveryMatchFound(
        matchedUser: event.matchedUser,
        isNewMatch: event.isNewMatch,
        previousState: currentState,
      ),
    );
  }

  /// Refresh the entire discovery stack
  Future<void> _onRefreshDiscovery(
    RefreshDiscovery event,
    Emitter<DiscoveryState> emit,
  ) async {
    if (state is DiscoveryLoaded) {
      final currentState = state as DiscoveryLoaded;
      add(
        LoadDiscoverableUsers(
          resetStack: true,
          filters: currentState.currentFilters,
        ),
      );
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

  /// Load users who liked the current user (premium feature)
  Future<void> _onLoadWhoLikedYou(
    LoadWhoLikedYou event,
    Emitter<DiscoveryState> emit,
  ) async {
    try {
      emit(const DiscoveryLoading());
      AppLogger.debug('Loading who liked you...');

      final users = await _discoveryService.getWhoLikedYou(
        filters: event.filters,
        limit: 20,
      );
      
      AppLogger.debug('Got ${users.length} users who liked you');

      if (users.isEmpty) {
        AppLogger.debug('Empty list - emitting DiscoveryEmpty');
        emit(
          DiscoveryEmpty(
            currentFilters: event.filters ?? const DiscoveryFilters(),
          ),
        );
        return;
      }

      AppLogger.debug('Emitting DiscoveryLoaded with ${users.length} users');
      emit(
        DiscoveryLoaded(
          userStack: users,
          currentFilters: event.filters ?? const DiscoveryFilters(),
          canUndo: false,
          hasMoreUsers: users.length >= 20,
        ),
      );

      // Prefetch media for smooth experience
      _prefetchService.prefetchProfiles(profiles: users, currentIndex: 0);
    } catch (error) {
      AppLogger.debug('Failed to load who liked you: $error');
      AppLogger.error('Full error: ${error.toString()}');
      emit(
        DiscoveryError(
          message: _extractUserFriendlyErrorMessage(error),
        ),
      );
    }
  }

  /// Extract user-friendly error message from error object
  /// Prevents technical DioException details from showing to users
  String _extractUserFriendlyErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Log the full error for debugging
    AppLogger.error('Discovery error: $errorString');

    // Check for authentication/session errors
    if (errorString.contains('401') ||
        errorString.contains('session has expired') ||
        errorString.contains('unauthorized')) {
      return 'Your session has expired. Please log in again.';
    }

    // Check for network errors
    if (errorString.contains('sockexception') ||
        errorString.contains('connection refused') ||
        errorString.contains('failed host lookup') ||
        errorString.contains('network is unreachable')) {
      return 'Connection problem. Please check your internet.';
    }

    // Check for timeout errors
    if (errorString.contains('timeout') ||
        errorString.contains('timeoutexception')) {
      return 'Request timed out. Please try again.';
    }

    // Check for server errors
    if (errorString.contains('500') ||
        errorString.contains('502') ||
        errorString.contains('503') ||
        errorString.contains('504')) {
      return 'Server error. Please try again later.';
    }

    // Check for permission errors
    if (errorString.contains('403') || errorString.contains('forbidden')) {
      return 'You don\'t have permission to do that.';
    }

    // Check for not found errors
    if (errorString.contains('404') || errorString.contains('not found')) {
      return 'Content not found. Please try again.';
    }

    // Check for rate limiting
    if (errorString.contains('429') ||
        errorString.contains('too many requests')) {
      return 'You\'re swiping too fast. Take a breather!';
    }

    // Check for bad requests
    if (errorString.contains('400') || errorString.contains('bad request')) {
      return 'Invalid request. Please try again.';
    }

    // Check for API endpoint issues
    if (errorString.contains('failed to fetch') ||
        errorString.contains('endpoint') ||
        errorString.contains('api')) {
      return 'Server connection issue. Please try again.';
    }

    // Generic fallback with helpful suggestion
    return 'Oops! Try refreshing or check your connection.';
  }
}

/// Internal event for dismissing match celebrations
class _DismissMatchEvent extends DiscoveryEvent {
  const _DismissMatchEvent();
}
