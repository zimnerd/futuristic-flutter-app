import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import '../../../data/services/speed_dating_service.dart';
import '../auth/auth_bloc.dart';
import '../auth/auth_state.dart';
import 'speed_dating_event.dart';
import 'speed_dating_state.dart';

class SpeedDatingBloc extends Bloc<SpeedDatingEvent, SpeedDatingState> {
  final SpeedDatingService _speedDatingService;
  final AuthBloc _authBloc;
  final Logger _logger = Logger();
  static const String _tag = 'SpeedDatingBloc';

  SpeedDatingBloc({
    required SpeedDatingService speedDatingService,
    required AuthBloc authBloc,
  }) : _speedDatingService = speedDatingService,
       _authBloc = authBloc,
       super(SpeedDatingInitial()) {
    on<LoadSpeedDatingEvents>(_onLoadSpeedDatingEvents);
    on<LoadUserSpeedDatingSessions>(_onLoadUserSpeedDatingSessions);
    on<JoinSpeedDatingEvent>(_onJoinSpeedDatingEvent);
    on<LeaveSpeedDatingEvent>(_onLeaveSpeedDatingEvent);
    on<StartSpeedDatingSession>(_onStartSpeedDatingSession);
    on<EndSpeedDatingSession>(_onEndSpeedDatingSession);
    on<SendSpeedDatingMessage>(_onSendSpeedDatingMessage);
    on<RateSpeedDatingMatch>(_onRateSpeedDatingMatch);
    on<GetSpeedDatingMatches>(_onGetSpeedDatingMatches);
    on<CreateSpeedDatingEvent>(_onCreateSpeedDatingEvent);
    on<LoadSpeedDatingHistory>(_onLoadSpeedDatingHistory);
    on<RefreshSpeedDatingData>(_onRefreshSpeedDatingData);
  }

  /// Get current user ID from auth context
  String _getCurrentUserId() {
    final authState = _authBloc.state;
    if (authState is AuthAuthenticated) {
      return authState.user.id;
    }
    throw Exception(
      'User not authenticated. Please log in to access Speed Dating.',
    );
  }

  Future<void> _onLoadSpeedDatingEvents(
    LoadSpeedDatingEvents event,
    Emitter<SpeedDatingState> emit,
  ) async {
    try {
      // Only show loading if we don't already have loaded data
      if (state is! SpeedDatingLoaded) {
        emit(SpeedDatingLoading());
      } else {
        // Show refreshing indicator if data already loaded
        final currentState = state as SpeedDatingLoaded;
        emit(currentState.copyWith(isRefreshing: true));
      }
      _logger.d('$_tag: Loading speed dating events');

      final events = await _speedDatingService.getUpcomingEvents();

      if (state is SpeedDatingLoaded) {
        final currentState = state as SpeedDatingLoaded;
        emit(currentState.copyWith(events: events, isRefreshing: false));
      } else {
        emit(SpeedDatingLoaded(events: events));
      }

      _logger.d('$_tag: Loaded ${events.length} speed dating events');
    } catch (e, stackTrace) {
      _logger.e(
        '$_tag: Failed to load events',
        error: e,
        stackTrace: stackTrace,
      );
      emit(SpeedDatingError('Failed to load events: ${e.toString()}'));
    }
  }

  Future<void> _onLoadUserSpeedDatingSessions(
    LoadUserSpeedDatingSessions event,
    Emitter<SpeedDatingState> emit,
  ) async {
    try {
      // Show refreshing indicator if data already loaded
      if (state is SpeedDatingLoaded) {
        final currentState = state as SpeedDatingLoaded;
        emit(currentState.copyWith(isRefreshing: true));
      }
      _logger.d('$_tag: Loading user speed dating sessions');

      final sessions = await _speedDatingService.getUserEvents();

      if (state is SpeedDatingLoaded) {
        final currentState = state as SpeedDatingLoaded;
        emit(
          currentState.copyWith(userSessions: sessions, isRefreshing: false),
        );
      } else {
        emit(SpeedDatingLoaded(userSessions: sessions));
      }

      _logger.d('$_tag: Loaded ${sessions.length} user sessions');
    } catch (e, stackTrace) {
      _logger.e(
        '$_tag: Failed to load sessions',
        error: e,
        stackTrace: stackTrace,
      );
      emit(SpeedDatingError('Failed to load sessions: ${e.toString()}'));
    }
  }

  Future<void> _onJoinSpeedDatingEvent(
    JoinSpeedDatingEvent event,
    Emitter<SpeedDatingState> emit,
  ) async {
    try {
      // Show joining state instead of error
      emit(SpeedDatingJoining(event.eventId));
      _logger.d('$_tag: Joining speed dating event: ${event.eventId}');

      final userId = _getCurrentUserId();
      final result = await _speedDatingService.joinEvent(event.eventId, userId);

      if (result != null) {
        // Emit joined state - this will trigger the success toast
        emit(SpeedDatingJoined(event.eventId));
        _logger.d('$_tag: Successfully joined event');

        // Refresh user sessions AND events
        add(LoadUserSpeedDatingSessions());
        add(LoadSpeedDatingEvents());
      } else {
        emit(SpeedDatingError('Failed to join event'));
      }
    } catch (e, stackTrace) {
      _logger.e(
        '$_tag: Failed to join event',
        error: e,
        stackTrace: stackTrace,
      );
      
      // Extract user-friendly error message
      String errorMessage = 'Failed to join event';
      if (e.toString().contains('already registered')) {
        errorMessage = 'You are already registered for this event';
      } else if (e.toString().contains('Event is full')) {
        errorMessage = 'This event is full';
      } else if (e.toString().contains('not found')) {
        errorMessage = 'Event not found';
      }

      emit(SpeedDatingError(errorMessage));
    }
  }

  Future<void> _onLeaveSpeedDatingEvent(
    LeaveSpeedDatingEvent event,
    Emitter<SpeedDatingState> emit,
  ) async {
    try {
      emit(SpeedDatingLeaving(event.eventId));
      _logger.d('$_tag: Leaving speed dating event: ${event.eventId}');

      final userId = _getCurrentUserId();
      final success = await _speedDatingService.leaveEvent(
        event.eventId,
        userId,
      );

      if (success) {
        emit(SpeedDatingLeft(event.eventId));
        _logger.d('$_tag: Successfully left event');

        // Refresh both user sessions AND events list to update registration status
        add(LoadUserSpeedDatingSessions());
        add(LoadSpeedDatingEvents());
      } else {
        emit(SpeedDatingError('Failed to leave event'));
      }
    } catch (e, stackTrace) {
      _logger.e(
        '$_tag: Failed to leave event',
        error: e,
        stackTrace: stackTrace,
      );
      emit(SpeedDatingError('Failed to leave event: ${e.toString()}'));
    }
  }

  Future<void> _onStartSpeedDatingSession(
    StartSpeedDatingSession event,
    Emitter<SpeedDatingState> emit,
  ) async {
    try {
      emit(SpeedDatingSessionStarting(event.eventId));
      _logger.d(
        '$_tag: Starting speed dating session for event: ${event.eventId}',
      );

      // Note: Service doesn't have startSession method - using join instead
      final userId = _getCurrentUserId();
      final session = await _speedDatingService.joinEvent(
        event.eventId,
        userId,
      );

      if (session != null) {
        emit(SpeedDatingSessionStarted(session));

        // Update the current session in loaded state
        if (state is SpeedDatingLoaded) {
          final currentState = state as SpeedDatingLoaded;
          emit(currentState.copyWith(currentSession: session));
        }

        _logger.d('$_tag: Session started successfully');
      } else {
        emit(SpeedDatingError('Failed to start session'));
      }
    } catch (e, stackTrace) {
      _logger.e(
        '$_tag: Failed to start session',
        error: e,
        stackTrace: stackTrace,
      );
      emit(SpeedDatingError('Failed to start session: ${e.toString()}'));
    }
  }

  Future<void> _onEndSpeedDatingSession(
    EndSpeedDatingSession event,
    Emitter<SpeedDatingState> emit,
  ) async {
    try {
      emit(SpeedDatingSessionEnding(event.sessionId));
      _logger.d('$_tag: Ending speed dating session: ${event.sessionId}');

      // Note: Service doesn't have endSession method - using leave instead
      final userId = _getCurrentUserId();
      final success = await _speedDatingService.leaveEvent(
        event.sessionId,
        userId,
      );

      if (success) {
        emit(SpeedDatingSessionEnded(event.sessionId));

        // Clear current session
        if (state is SpeedDatingLoaded) {
          final currentState = state as SpeedDatingLoaded;
          emit(currentState.copyWith(currentSession: null));
        }

        _logger.d('$_tag: Session ended successfully');
      } else {
        emit(SpeedDatingError('Failed to end session'));
      }
    } catch (e, stackTrace) {
      _logger.e(
        '$_tag: Failed to end session',
        error: e,
        stackTrace: stackTrace,
      );
      emit(SpeedDatingError('Failed to end session: ${e.toString()}'));
    }
  }

  Future<void> _onSendSpeedDatingMessage(
    SendSpeedDatingMessage event,
    Emitter<SpeedDatingState> emit,
  ) async {
    try {
      emit(SpeedDatingMessageSending(event.sessionId, event.message));
      _logger.d('$_tag: Sending message in session: ${event.sessionId}');

      // Note: Service doesn't have sendMessage method
      // This would typically be handled by a separate chat service
      emit(
        SpeedDatingError('Messaging not implemented in speed dating service'),
      );
      return;
    } catch (e, stackTrace) {
      _logger.e(
        '$_tag: Failed to send message',
        error: e,
        stackTrace: stackTrace,
      );
      emit(SpeedDatingError('Failed to send message: ${e.toString()}'));
    }
  }

  Future<void> _onRateSpeedDatingMatch(
    RateSpeedDatingMatch event,
    Emitter<SpeedDatingState> emit,
  ) async {
    try {
      emit(SpeedDatingRatingSubmitting(event.sessionId, event.matchUserId));
      _logger.d(
        '$_tag: Rating match: ${event.matchUserId} with ${event.rating}',
      );

      final result = await _speedDatingService.rateSession(
        event.sessionId,
        event.matchUserId,
        event.rating,
        notes: event.notes,
      );

      if (result != null) {
        emit(
          SpeedDatingRatingSubmitted(
            event.sessionId,
            event.matchUserId,
            event.rating,
          ),
        );
        _logger.d('$_tag: Rating submitted successfully');
      } else {
        emit(SpeedDatingError('Failed to submit rating'));
      }
    } catch (e, stackTrace) {
      _logger.e(
        '$_tag: Failed to submit rating',
        error: e,
        stackTrace: stackTrace,
      );
      emit(SpeedDatingError('Failed to submit rating: ${e.toString()}'));
    }
  }

  Future<void> _onGetSpeedDatingMatches(
    GetSpeedDatingMatches event,
    Emitter<SpeedDatingState> emit,
  ) async {
    try {
      emit(SpeedDatingMatchesLoading(event.eventId));
      _logger.d('$_tag: Loading matches for event: ${event.eventId}');

      final userId = _getCurrentUserId();
      final matches = await _speedDatingService.getEventMatches(
        event.eventId,
        userId,
      );

      emit(SpeedDatingMatchesLoaded(matches));

      // Update matches in loaded state
      if (state is SpeedDatingLoaded) {
        final currentState = state as SpeedDatingLoaded;
        emit(currentState.copyWith(matches: matches));
      }

      _logger.d('$_tag: Loaded ${matches.length} matches');
    } catch (e, stackTrace) {
      _logger.e(
        '$_tag: Failed to load matches',
        error: e,
        stackTrace: stackTrace,
      );
      emit(SpeedDatingError('Failed to load matches: ${e.toString()}'));
    }
  }

  Future<void> _onCreateSpeedDatingEvent(
    CreateSpeedDatingEvent event,
    Emitter<SpeedDatingState> emit,
  ) async {
    try {
      emit(SpeedDatingEventCreating());
      _logger.d('$_tag: Creating speed dating event: ${event.title}');

      // Note: Service doesn't have createEvent method
      // This would need to be implemented in the backend first
      emit(
        SpeedDatingError(
          'Event creation not implemented in speed dating service',
        ),
      );
      return;
    } catch (e, stackTrace) {
      _logger.e(
        '$_tag: Failed to create event',
        error: e,
        stackTrace: stackTrace,
      );
      emit(SpeedDatingError('Failed to create event: ${e.toString()}'));
    }
  }

  Future<void> _onLoadSpeedDatingHistory(
    LoadSpeedDatingHistory event,
    Emitter<SpeedDatingState> emit,
  ) async {
    try {
      _logger.d('$_tag: Loading speed dating history');

      // Note: Service doesn't have getSessionHistory method
      // Using empty list as placeholder
      final history = <Map<String, dynamic>>[];

      if (state is SpeedDatingLoaded) {
        final currentState = state as SpeedDatingLoaded;
        emit(currentState.copyWith(userSessions: history));
      } else {
        emit(SpeedDatingLoaded(userSessions: history));
      }

      _logger.d('$_tag: Loaded ${history.length} historical sessions');
    } catch (e, stackTrace) {
      _logger.e(
        '$_tag: Failed to load history',
        error: e,
        stackTrace: stackTrace,
      );
      emit(SpeedDatingError('Failed to load history: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshSpeedDatingData(
    RefreshSpeedDatingData event,
    Emitter<SpeedDatingState> emit,
  ) async {
    // Only refresh if we're currently in a loaded state
    if (state is SpeedDatingLoaded) {
      add(LoadSpeedDatingEvents());
      add(LoadUserSpeedDatingSessions());
    }
  }
}
