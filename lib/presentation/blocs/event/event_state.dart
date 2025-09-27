import 'package:equatable/equatable.dart';

import '../../../domain/entities/event.dart';

abstract class EventState extends Equatable {
  const EventState();

  @override
  List<Object?> get props => [];
}

class EventInitial extends EventState {
  const EventInitial();
}

class EventLoading extends EventState {
  const EventLoading();
}

class EventsLoaded extends EventState {
  final List<Event> events;
  final List<Event> filteredEvents;
  final String? currentCategory;
  final String? searchQuery;
  final bool hasReachedMax;

  const EventsLoaded({
    required this.events,
    required this.filteredEvents,
    this.currentCategory,
    this.searchQuery,
    this.hasReachedMax = false,
  });

  @override
  List<Object?> get props => [
        events,
        filteredEvents,
        currentCategory,
        searchQuery,
        hasReachedMax,
      ];

  EventsLoaded copyWith({
    List<Event>? events,
    List<Event>? filteredEvents,
    String? currentCategory,
    String? searchQuery,
    bool? hasReachedMax,
  }) {
    return EventsLoaded(
      events: events ?? this.events,
      filteredEvents: filteredEvents ?? this.filteredEvents,
      currentCategory: currentCategory ?? this.currentCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }
}

class EventDetailsLoaded extends EventState {
  final Event event;
  final List<EventAttendance> attendees;

  const EventDetailsLoaded({
    required this.event,
    required this.attendees,
  });

  @override
  List<Object?> get props => [event, attendees];

  EventDetailsLoaded copyWith({
    Event? event,
    List<EventAttendance>? attendees,
  }) {
    return EventDetailsLoaded(
      event: event ?? this.event,
      attendees: attendees ?? this.attendees,
    );
  }
}

class EventCreated extends EventState {
  final Event event;

  const EventCreated(this.event);

  @override
  List<Object?> get props => [event];
}

class EventUpdated extends EventState {
  final Event event;

  const EventUpdated(this.event);

  @override
  List<Object?> get props => [event];
}

class EventDeleted extends EventState {
  final String eventId;

  const EventDeleted(this.eventId);

  @override
  List<Object?> get props => [eventId];
}

class EventAttendanceUpdated extends EventState {
  final String eventId;
  final bool isAttending;
  final int attendeeCount;

  const EventAttendanceUpdated({
    required this.eventId,
    required this.isAttending,
    required this.attendeeCount,
  });

  @override
  List<Object?> get props => [eventId, isAttending, attendeeCount];
}

class EventAttendeesLoaded extends EventState {
  final String eventId;
  final List<EventAttendance> attendees;

  const EventAttendeesLoaded({
    required this.eventId,
    required this.attendees,
  });

  @override
  List<Object?> get props => [eventId, attendees];
}

class EventError extends EventState {
  final String message;
  final String? errorCode;

  const EventError({
    required this.message,
    this.errorCode,
  });

  @override
  List<Object?> get props => [message, errorCode];
}

class EventActionLoading extends EventState {
  final String action;

  const EventActionLoading(this.action);

  @override
  List<Object?> get props => [action];
}

class EventRefreshing extends EventState {
  final List<Event> currentEvents;

  const EventRefreshing(this.currentEvents);

  @override
  List<Object?> get props => [currentEvents];
}

class EventCategoriesLoaded extends EventState {
  final List<EventCategory> categories;

  const EventCategoriesLoaded(this.categories);

  @override
  List<Object?> get props => [categories];
}
