import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../domain/entities/discovery_types.dart';
import '../../../data/services/matching_service.dart';

part 'matching_event.dart';
part 'matching_state.dart';

/// BLoC for handling swipe matching logic and user interactions
class MatchingBloc extends Bloc<MatchingEvent, MatchingState> {
  final MatchingService _matchingService;

  MatchingBloc({
    required MatchingService matchingService,
  })  : _matchingService = matchingService,
        super(const MatchingState()) {
    on<LoadPotentialMatches>(_onLoadPotentialMatches);
    on<SwipeProfile>(_onSwipeProfile);
    on<UndoLastSwipe>(_onUndoLastSwipe);
    on<RefreshMatches>(_onRefreshMatches);
    on<SuperLikeProfile>(_onSuperLikeProfile);
    on<ReportProfile>(_onReportProfile);
    on<UpdateFilters>(_onUpdateFilters);
    on<BoostProfile>(_onBoostProfile);
  }

  Future<void> _onLoadPotentialMatches(
    LoadPotentialMatches event,
    Emitter<MatchingState> emit,
  ) async {
    try {
      emit(state.copyWith(status: MatchingStatus.loading));

      final profiles = await _matchingService.getPotentialMatches(
        limit: 10,
        offset: state.profiles.length,
        filters: {
          'minAge': state.filters.minAge,
          'maxAge': state.filters.maxAge,
          'maxDistance': state.filters.maxDistance,
          if (state.filters.showMeGender != null) 'showMeGender': state.filters.showMeGender,
          'verifiedOnly': state.filters.verifiedOnly,
          'hasPhotos': state.filters.hasPhotos,
        },
      );

      if (profiles.isEmpty && state.profiles.isEmpty) {
        emit(state.copyWith(
          status: MatchingStatus.loaded,
          hasReachedMax: true,
          error: 'No more profiles to show',
        ));
      } else {
        final allProfiles = event.refresh 
            ? profiles 
            : [...state.profiles, ...profiles];
        
        emit(state.copyWith(
          status: MatchingStatus.loaded,
          profiles: allProfiles,
          hasReachedMax: profiles.isEmpty,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: MatchingStatus.error,
        error: 'Failed to load profiles: ${e.toString()}',
      ));
    }
  }

  Future<void> _onSwipeProfile(
    SwipeProfile event,
    Emitter<MatchingState> emit,
  ) async {
    if (state.profiles.isEmpty) return;

    final currentProfile = state.profiles.first;
    final updatedProfiles = List<UserProfile>.from(state.profiles)..removeAt(0);
    
    // Add to swipe history for undo functionality
    final swipeHistory = List<MatchingSwipeAction>.from(state.swipeHistory)
      ..add(MatchingSwipeAction(
        profile: currentProfile,
        direction: event.direction,
        timestamp: DateTime.now(),
      ));

    emit(state.copyWith(
      profiles: updatedProfiles,
      swipeHistory: swipeHistory,
      lastSwipeWasMatch: false,
    ));

    // Send swipe action to backend
    try {
      final result = await _matchingService.swipeProfile(
        profileId: currentProfile.id,
        isLike: event.direction == SwipeAction.right,
      );

      emit(state.copyWith(
        lastSwipeWasMatch: result['isMatch'] ?? false,
        matchedProfile: (result['isMatch'] ?? false) ? currentProfile : null,
          superLikesRemaining: event.direction == SwipeAction.up
            ? (state.superLikesRemaining - 1).clamp(0, double.infinity).toInt()
            : state.superLikesRemaining,
      ));

      // Load more profiles if running low
      if (updatedProfiles.length <= 3) {
        add(const LoadPotentialMatches());
      }
    } catch (e) {
      // Revert the swipe on error
      final revertedProfiles = [currentProfile, ...updatedProfiles];
      final revertedHistory = List<MatchingSwipeAction>.from(swipeHistory)..removeLast();
      
      emit(state.copyWith(
        profiles: revertedProfiles,
        swipeHistory: revertedHistory,
        error: 'Failed to process swipe: ${e.toString()}',
      ));
    }
  }

  Future<void> _onUndoLastSwipe(
    UndoLastSwipe event,
    Emitter<MatchingState> emit,
  ) async {
    if (state.swipeHistory.isEmpty || state.undosRemaining <= 0) return;

    final lastSwipe = state.swipeHistory.last;
    final updatedHistory = List<MatchingSwipeAction>.from(state.swipeHistory)..removeLast();
    final updatedProfiles = [lastSwipe.profile, ...state.profiles];

    emit(state.copyWith(
      profiles: updatedProfiles,
      swipeHistory: updatedHistory,
      undosRemaining: state.undosRemaining - 1,
      lastSwipeWasMatch: false,
      matchedProfile: null,
    ));

    // Call backend to undo the swipe
    try {
      await _matchingService.undoLastSwipe();
    } catch (e) {
      // Revert the undo on error
      final revertedProfiles = List<UserProfile>.from(updatedProfiles)..removeAt(0);
      final revertedHistory = [...updatedHistory, lastSwipe];
      
      emit(state.copyWith(
        profiles: revertedProfiles,
        swipeHistory: revertedHistory,
        undosRemaining: state.undosRemaining + 1,
        error: 'Failed to undo swipe: ${e.toString()}',
      ));
    }
  }

  Future<void> _onBoostProfile(
    BoostProfile event,
    Emitter<MatchingState> emit,
  ) async {
    try {
      emit(state.copyWith(status: MatchingStatus.loading));

      await _matchingService.boostProfile();

      emit(
        state.copyWith(
          status: MatchingStatus.loaded,
          boostActive: true,
          boostExpiresAt: DateTime.now().add(
            const Duration(hours: 1),
          ), // Typical boost duration
          error: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: MatchingStatus.error,
          error: 'Failed to activate boost: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onRefreshMatches(
    RefreshMatches event,
    Emitter<MatchingState> emit,
  ) async {
    emit(state.copyWith(
      profiles: [],
      swipeHistory: [],
      hasReachedMax: false,
      lastSwipeWasMatch: false,
      matchedProfile: null,
    ));

    add(const LoadPotentialMatches(refresh: true));
  }

  Future<void> _onSuperLikeProfile(
    SuperLikeProfile event,
    Emitter<MatchingState> emit,
  ) async {
    if (state.superLikesRemaining <= 0) {
      emit(state.copyWith(error: 'No super likes remaining'));
      return;
    }

    add(SwipeProfile(
      profileId: event.profileId,
      direction: SwipeAction.up,
    ));
  }

  Future<void> _onReportProfile(
    ReportProfile event,
    Emitter<MatchingState> emit,
  ) async {
    try {
      await _matchingService.reportProfile(
        profileId: event.profileId,
        reason: event.reason,
        description: event.description,
      );

      // Remove reported profile from stack
      final updatedProfiles = state.profiles
          .where((profile) => profile.id != event.profileId)
          .toList();
      
      emit(state.copyWith(
        profiles: updatedProfiles,
        error: null,
      ));

      // Load more profiles if needed
      if (updatedProfiles.length <= 3) {
        add(const LoadPotentialMatches());
      }
    } catch (e) {
      emit(state.copyWith(
        error: 'Failed to report profile: ${e.toString()}',
      ));
    }
  }

  Future<void> _onUpdateFilters(
    UpdateFilters event,
    Emitter<MatchingState> emit,
  ) async {
    emit(state.copyWith(
      filters: event.filters,
      profiles: [],
      hasReachedMax: false,
    ));

    add(const LoadPotentialMatches(refresh: true));
  }
}

/// Swipe action for history tracking
class MatchingSwipeAction {
  const MatchingSwipeAction({
    required this.profile,
    required this.direction,
    required this.timestamp,
  });

  final UserProfile profile;
  final SwipeAction direction;
  final DateTime timestamp;
}

/// Matching filters
class MatchingFilters {
  const MatchingFilters({
    this.minAge = 18,
    this.maxAge = 100,
    this.maxDistance = 50,
    this.showMeGender,
    this.verifiedOnly = false,
    this.hasPhotos = true,
  });

  final int minAge;
  final int maxAge;
  final int maxDistance;
  final String? showMeGender;
  final bool verifiedOnly;
  final bool hasPhotos;

  MatchingFilters copyWith({
    int? minAge,
    int? maxAge,
    int? maxDistance,
    String? showMeGender,
    bool? verifiedOnly,
    bool? hasPhotos,
  }) {
    return MatchingFilters(
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      maxDistance: maxDistance ?? this.maxDistance,
      showMeGender: showMeGender ?? this.showMeGender,
      verifiedOnly: verifiedOnly ?? this.verifiedOnly,
      hasPhotos: hasPhotos ?? this.hasPhotos,
    );
  }
}
