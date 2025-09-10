import 'package:equatable/equatable.dart';

abstract class SpeedDatingEvent extends Equatable {
  const SpeedDatingEvent();

  @override
  List<Object?> get props => [];
}

class LoadSpeedDatingEvents extends SpeedDatingEvent {}

class LoadUserSpeedDatingSessions extends SpeedDatingEvent {}

class JoinSpeedDatingEvent extends SpeedDatingEvent {
  final String eventId;

  const JoinSpeedDatingEvent(this.eventId);

  @override
  List<Object> get props => [eventId];
}

class LeaveSpeedDatingEvent extends SpeedDatingEvent {
  final String eventId;

  const LeaveSpeedDatingEvent(this.eventId);

  @override
  List<Object> get props => [eventId];
}

class StartSpeedDatingSession extends SpeedDatingEvent {
  final String eventId;

  const StartSpeedDatingSession(this.eventId);

  @override
  List<Object> get props => [eventId];
}

class EndSpeedDatingSession extends SpeedDatingEvent {
  final String sessionId;

  const EndSpeedDatingSession(this.sessionId);

  @override
  List<Object> get props => [sessionId];
}

class SendSpeedDatingMessage extends SpeedDatingEvent {
  final String sessionId;
  final String message;

  const SendSpeedDatingMessage({
    required this.sessionId,
    required this.message,
  });

  @override
  List<Object> get props => [sessionId, message];
}

class RateSpeedDatingMatch extends SpeedDatingEvent {
  final String sessionId;
  final String matchUserId;
  final int rating;
  final String? notes;

  const RateSpeedDatingMatch({
    required this.sessionId,
    required this.matchUserId,
    required this.rating,
    this.notes,
  });

  @override
  List<Object?> get props => [sessionId, matchUserId, rating, notes];
}

class GetSpeedDatingMatches extends SpeedDatingEvent {
  final String eventId;

  const GetSpeedDatingMatches(this.eventId);

  @override
  List<Object> get props => [eventId];
}

class CreateSpeedDatingEvent extends SpeedDatingEvent {
  final String title;
  final String description;
  final DateTime scheduledDate;
  final int maxParticipants;
  final Map<String, dynamic> preferences;

  const CreateSpeedDatingEvent({
    required this.title,
    required this.description,
    required this.scheduledDate,
    required this.maxParticipants,
    this.preferences = const {},
  });

  @override
  List<Object> get props => [title, description, scheduledDate, maxParticipants, preferences];
}

class LoadSpeedDatingHistory extends SpeedDatingEvent {}

class RefreshSpeedDatingData extends SpeedDatingEvent {}
