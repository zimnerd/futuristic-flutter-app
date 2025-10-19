import 'package:equatable/equatable.dart';

abstract class SpeedDatingState extends Equatable {
  const SpeedDatingState();

  @override
  List<Object?> get props => [];
}

class SpeedDatingInitial extends SpeedDatingState {}

class SpeedDatingLoading extends SpeedDatingState {}

class SpeedDatingLoaded extends SpeedDatingState {
  final List<Map<String, dynamic>> events;
  final List<Map<String, dynamic>> userSessions;
  final Map<String, dynamic>? currentSession;
  final List<Map<String, dynamic>> matches;
  final Map<String, dynamic>? currentEvent;

  const SpeedDatingLoaded({
    this.events = const [],
    this.userSessions = const [],
    this.currentSession,
    this.matches = const [],
    this.currentEvent,
  });

  @override
  List<Object?> get props => [
    events,
    userSessions,
    currentSession,
    matches,
    currentEvent,
  ];

  SpeedDatingLoaded copyWith({
    List<Map<String, dynamic>>? events,
    List<Map<String, dynamic>>? userSessions,
    Map<String, dynamic>? currentSession,
    List<Map<String, dynamic>>? matches,
    Map<String, dynamic>? currentEvent,
  }) {
    return SpeedDatingLoaded(
      events: events ?? this.events,
      userSessions: userSessions ?? this.userSessions,
      currentSession: currentSession ?? this.currentSession,
      matches: matches ?? this.matches,
      currentEvent: currentEvent ?? this.currentEvent,
    );
  }
}

class SpeedDatingError extends SpeedDatingState {
  final String message;

  const SpeedDatingError(this.message);

  @override
  List<Object> get props => [message];
}

// Event management states
class SpeedDatingJoining extends SpeedDatingState {
  final String eventId;

  const SpeedDatingJoining(this.eventId);

  @override
  List<Object> get props => [eventId];
}

class SpeedDatingJoined extends SpeedDatingState {
  final String eventId;

  const SpeedDatingJoined(this.eventId);

  @override
  List<Object> get props => [eventId];
}

class SpeedDatingLeaving extends SpeedDatingState {
  final String eventId;

  const SpeedDatingLeaving(this.eventId);

  @override
  List<Object> get props => [eventId];
}

class SpeedDatingLeft extends SpeedDatingState {
  final String eventId;

  const SpeedDatingLeft(this.eventId);

  @override
  List<Object> get props => [eventId];
}

// Session states
class SpeedDatingSessionStarting extends SpeedDatingState {
  final String eventId;

  const SpeedDatingSessionStarting(this.eventId);

  @override
  List<Object> get props => [eventId];
}

class SpeedDatingSessionStarted extends SpeedDatingState {
  final Map<String, dynamic> session;

  const SpeedDatingSessionStarted(this.session);

  @override
  List<Object> get props => [session];
}

class SpeedDatingSessionEnding extends SpeedDatingState {
  final String sessionId;

  const SpeedDatingSessionEnding(this.sessionId);

  @override
  List<Object> get props => [sessionId];
}

class SpeedDatingSessionEnded extends SpeedDatingState {
  final String sessionId;

  const SpeedDatingSessionEnded(this.sessionId);

  @override
  List<Object> get props => [sessionId];
}

// Communication states
class SpeedDatingMessageSending extends SpeedDatingState {
  final String sessionId;
  final String message;

  const SpeedDatingMessageSending(this.sessionId, this.message);

  @override
  List<Object> get props => [sessionId, message];
}

class SpeedDatingMessageSent extends SpeedDatingState {
  final String sessionId;
  final String message;

  const SpeedDatingMessageSent(this.sessionId, this.message);

  @override
  List<Object> get props => [sessionId, message];
}

// Rating states
class SpeedDatingRatingSubmitting extends SpeedDatingState {
  final String sessionId;
  final String matchUserId;

  const SpeedDatingRatingSubmitting(this.sessionId, this.matchUserId);

  @override
  List<Object> get props => [sessionId, matchUserId];
}

class SpeedDatingRatingSubmitted extends SpeedDatingState {
  final String sessionId;
  final String matchUserId;
  final int rating;

  const SpeedDatingRatingSubmitted(
    this.sessionId,
    this.matchUserId,
    this.rating,
  );

  @override
  List<Object> get props => [sessionId, matchUserId, rating];
}

// Event creation states
class SpeedDatingEventCreating extends SpeedDatingState {}

class SpeedDatingEventCreated extends SpeedDatingState {
  final Map<String, dynamic> event;

  const SpeedDatingEventCreated(this.event);

  @override
  List<Object> get props => [event];
}

// Matches loading states
class SpeedDatingMatchesLoading extends SpeedDatingState {
  final String eventId;

  const SpeedDatingMatchesLoading(this.eventId);

  @override
  List<Object> get props => [eventId];
}

class SpeedDatingMatchesLoaded extends SpeedDatingState {
  final List<Map<String, dynamic>> matches;

  const SpeedDatingMatchesLoaded(this.matches);

  @override
  List<Object> get props => [matches];
}
