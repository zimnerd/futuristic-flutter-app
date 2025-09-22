import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/services/matching_service.dart';
import 'match_event.dart';
import 'match_state.dart';

/// Business logic for managing matches and match-related operations
/// Handles matching, unmatching, match history, and match suggestions
class MatchBloc extends Bloc<MatchEvent, MatchState> {
  final MatchingService _matchingService;

  MatchBloc({
    required MatchingService matchingService,
  })  : _matchingService = matchingService,
        super(const MatchInitial()) {
    on<LoadMatches>(_onLoadMatches);
    on<LoadMatchSuggestions>(_onLoadMatchSuggestions);
    on<CreateMatch>(_onCreateMatch);
    on<AcceptMatch>(_onAcceptMatch);
    on<RejectMatch>(_onRejectMatch);
    on<UnmatchUser>(_onUnmatchUser);
    on<LoadMatchDetails>(_onLoadMatchDetails);
    on<UpdateMatchStatus>(_onUpdateMatchStatus);
    on<ResetMatchState>(_onResetMatchState);
    on<RemoveMatchFromList>(_onRemoveMatchFromList);
  }

  /// Load user's matches (active, pending, etc.)
  Future<void> _onLoadMatches(
    LoadMatches event,
    Emitter<MatchState> emit,
  ) async {
    emit(MatchLoading());
    
    try {
      final matches = await _matchingService.getMatches(
        status: event.status,
        limit: event.limit,
        offset: event.offset,
        excludeWithConversations:
            true, // Exclude matches that already have conversations
      );
      
      emit(MatchesLoaded(
        matches: matches,
        hasMore: matches.length >= (event.limit ?? 20),
      ));
    } catch (error) {
      emit(MatchError(
        message: 'Failed to load matches: ${error.toString()}',
      ));
    }
  }

  /// Load match suggestions based on user preferences and algorithm
  Future<void> _onLoadMatchSuggestions(
    LoadMatchSuggestions event,
    Emitter<MatchState> emit,
  ) async {
    emit(MatchLoading());
    
    try {
      final suggestions = await _matchingService.getMatchSuggestions(
        limit: event.limit,
        useAI: event.useAI,
        filters: event.filters,
      );
      
      emit(MatchSuggestionsLoaded(
        suggestions: suggestions,
        hasMore: suggestions.length >= event.limit,
      ));
    } catch (error) {
      emit(MatchError(
        message: 'Failed to load match suggestions: ${error.toString()}',
      ));
    }
  }

  /// Create a new match (when user likes someone)
  Future<void> _onCreateMatch(
    CreateMatch event,
    Emitter<MatchState> emit,
  ) async {
    final currentState = state;
    emit(MatchActionInProgress());
    
    try {
      final match = await _matchingService.createMatch(
        targetUserId: event.targetUserId,
        isSuper: event.isSuper,
      );
      
      // If it's a mutual match, show match success
      if (match.isMatched) {
        emit(MatchCreated(
          match: match,
          isNewMatch: true,
          message: 'Congratulations! You have a new match!',
        ));
      } else {
        // Just a like, restore previous state
        if (currentState is MatchSuggestionsLoaded) {
          // Remove the liked user from suggestions
          final updatedSuggestions = currentState.suggestions
              .where((user) => user.id != event.targetUserId)
              .toList();
          
          emit(MatchSuggestionsLoaded(
            suggestions: updatedSuggestions,
            hasMore: currentState.hasMore,
          ));
        } else {
          emit(MatchActionSuccess(message: 'Like sent successfully'));
        }
      }
    } catch (error) {
      emit(MatchError(
        message: 'Failed to create match: ${error.toString()}',
      ));
    }
  }

  /// Accept a pending match
  Future<void> _onAcceptMatch(
    AcceptMatch event,
    Emitter<MatchState> emit,
  ) async {
    emit(MatchActionInProgress());
    
    try {
      final updatedMatch = await _matchingService.acceptMatch(event.matchId);
      
      emit(MatchAccepted(
        match: updatedMatch,
        message: 'Match accepted! You can now start chatting.',
      ));
    } catch (error) {
      emit(MatchError(
        message: 'Failed to accept match: ${error.toString()}',
      ));
    }
  }

  /// Reject a pending match
  Future<void> _onRejectMatch(
    RejectMatch event,
    Emitter<MatchState> emit,
  ) async {
    emit(MatchActionInProgress());
    
    try {
      await _matchingService.rejectMatch(event.matchId);
      
      emit(MatchRejected(
        matchId: event.matchId,
        message: 'Match rejected',
      ));
    } catch (error) {
      emit(MatchError(
        message: 'Failed to reject match: ${error.toString()}',
      ));
    }
  }

  /// Unmatch with a user (remove existing match)
  Future<void> _onUnmatchUser(
    UnmatchUser event,
    Emitter<MatchState> emit,
  ) async {
    emit(MatchActionInProgress());
    
    try {
      await _matchingService.unmatchUser(event.matchId);
      
      emit(MatchUnmatched(
        matchId: event.matchId,
        message: 'User unmatched successfully',
      ));
    } catch (error) {
      emit(MatchError(
        message: 'Failed to unmatch user: ${error.toString()}',
      ));
    }
  }

  /// Load detailed information about a specific match
  Future<void> _onLoadMatchDetails(
    LoadMatchDetails event,
    Emitter<MatchState> emit,
  ) async {
    emit(MatchLoading());
    
    try {
      final matchDetails = await _matchingService.getMatchDetails(event.matchId);
      
      emit(MatchDetailsLoaded(
        match: matchDetails,
      ));
    } catch (error) {
      emit(MatchError(
        message: 'Failed to load match details: ${error.toString()}',
      ));
    }
  }

  /// Update match status (admin/system use)
  Future<void> _onUpdateMatchStatus(
    UpdateMatchStatus event,
    Emitter<MatchState> emit,
  ) async {
    emit(MatchActionInProgress());
    
    try {
      final updatedMatch = await _matchingService.updateMatchStatus(
        matchId: event.matchId,
        status: event.status,
      );
      
      emit(MatchStatusUpdated(
        match: updatedMatch,
        message: 'Match status updated to ${event.status}',
      ));
    } catch (error) {
      emit(MatchError(
        message: 'Failed to update match status: ${error.toString()}',
      ));
    }
  }

  /// Reset match state to initial
  void _onResetMatchState(
    ResetMatchState event,
    Emitter<MatchState> emit,
  ) {
    emit(const MatchInitial());
  }

  /// Remove a match from the current list when conversation is created
  void _onRemoveMatchFromList(
    RemoveMatchFromList event,
    Emitter<MatchState> emit,
  ) {
    final currentState = state;
    if (currentState is MatchesLoaded) {
      // Remove the match with the given ID from the current matches list
      final updatedMatches = currentState.matches
          .where((match) => match.id != event.matchId)
          .toList();

      emit(
        MatchesLoaded(matches: updatedMatches, hasMore: currentState.hasMore),
      );
    }
  }
}
