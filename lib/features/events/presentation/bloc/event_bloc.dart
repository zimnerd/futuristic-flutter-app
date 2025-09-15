import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../domain/entities/event.dart';
import '../../../../data/services/event_service.dart';

// Events
abstract class EventEvent extends Equatable {
  const EventEvent();

  @override
  List<Object?> get props => [];
}

class LoadEvents extends EventEvent {
  final double? latitude;
  final double? longitude;
  final String? category;

  const LoadEvents({
    this.latitude,
    this.longitude,
    this.category,
  });

  @override
  List<Object?> get props => [latitude, longitude, category];
}

class CreateEvent extends EventEvent {
  final CreateEventRequest request;

  const CreateEvent(this.request);

  @override
  List<Object?> get props => [request];
}

class LoadEventDetails extends EventEvent {
  final String eventId;

  const LoadEventDetails(this.eventId);

  @override
  List<Object?> get props => [eventId];
}

class AttendEvent extends EventEvent {
  final String eventId;

  const AttendEvent(this.eventId);

  @override
  List<Object?> get props => [eventId];
}

class LeaveEvent extends EventEvent {
  final String eventId;

  const LeaveEvent(this.eventId);

  @override
  List<Object?> get props => [eventId];
}

class LoadUserEvents extends EventEvent {}

class LoadUserAttendingEvents extends EventEvent {}

// States
abstract class EventState extends Equatable {
  const EventState();

  @override
  List<Object?> get props => [];
}

class EventInitial extends EventState {}

class EventLoading extends EventState {}

class EventLoaded extends EventState {
  final List<Event> events;

  const EventLoaded(this.events);

  @override
  List<Object?> get props => [events];
}

class EventDetailsLoaded extends EventState {
  final Event event;

  const EventDetailsLoaded(this.event);

  @override
  List<Object?> get props => [event];
}

class EventCreated extends EventState {
  final Event event;

  const EventCreated(this.event);

  @override
  List<Object?> get props => [event];
}

class EventCreating extends EventState {}

class EventAttended extends EventState {
  final String eventId;

  const EventAttended(this.eventId);

  @override
  List<Object?> get props => [eventId];
}

class EventLeft extends EventState {
  final String eventId;

  const EventLeft(this.eventId);

  @override
  List<Object?> get props => [eventId];
}

class EventError extends EventState {
  final String message;

  const EventError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class EventBloc extends Bloc<EventEvent, EventState> {
  final EventService _eventService;

  EventBloc({
    EventService? eventService,
  })  : _eventService = eventService ?? EventService.instance,
        super(EventInitial()) {
    on<LoadEvents>(_onLoadEvents);
    on<CreateEvent>(_onCreateEvent);
    on<LoadEventDetails>(_onLoadEventDetails);
    on<AttendEvent>(_onAttendEvent);
    on<LeaveEvent>(_onLeaveEvent);
    on<LoadUserEvents>(_onLoadUserEvents);
    on<LoadUserAttendingEvents>(_onLoadUserAttendingEvents);
  }

  Future<void> _onLoadEvents(
    LoadEvents event,
    Emitter<EventState> emit,
  ) async {
    emit(EventLoading());
    try {
      final events = await _eventService.getEvents(
        latitude: event.latitude,
        longitude: event.longitude,
        category: event.category,
      );
      emit(EventLoaded(events));
    } catch (e) {
      emit(EventError('Failed to load events: ${e.toString()}'));
    }
  }

  Future<void> _onCreateEvent(
    CreateEvent event,
    Emitter<EventState> emit,
  ) async {
    emit(EventCreating());
    try {
      final createdEvent = await _eventService.createEvent(
        title: event.request.title,
        description: event.request.description,
        location: event.request.location,
        dateTime: event.request.date,
        latitude: event.request.coordinates.lat,
        longitude: event.request.coordinates.lng,
        category: event.request.category,
        image: event.request.image,
      );
      emit(EventCreated(createdEvent));
    } catch (e) {
      emit(EventError('Failed to create event: ${e.toString()}'));
    }
  }

  Future<void> _onLoadEventDetails(
    LoadEventDetails event,
    Emitter<EventState> emit,
  ) async {
    emit(EventLoading());
    try {
      final eventDetails = await _eventService.getEventById(event.eventId);
      emit(EventDetailsLoaded(eventDetails));
    } catch (e) {
      emit(EventError('Failed to load event details: ${e.toString()}'));
    }
  }

  Future<void> _onAttendEvent(
    AttendEvent event,
    Emitter<EventState> emit,
  ) async {
    try {
      await _eventService.joinEvent(event.eventId);
      emit(EventAttended(event.eventId));
    } catch (e) {
      emit(EventError('Failed to attend event: ${e.toString()}'));
    }
  }

  Future<void> _onLeaveEvent(
    LeaveEvent event,
    Emitter<EventState> emit,
  ) async {
    try {
      await _eventService.leaveEvent(event.eventId);
      emit(EventLeft(event.eventId));
    } catch (e) {
      emit(EventError('Failed to leave event: ${e.toString()}'));
    }
  }

  Future<void> _onLoadUserEvents(
    LoadUserEvents event,
    Emitter<EventState> emit,
  ) async {
    emit(EventLoading());
    try {
      // Note: This would need a user ID - for now using a placeholder
      // In a real app, you'd get the user ID from authentication state
      final events = await _eventService.getEvents();
      emit(EventLoaded(events));
    } catch (e) {
      emit(EventError('Failed to load user events: ${e.toString()}'));
    }
  }

  Future<void> _onLoadUserAttendingEvents(
    LoadUserAttendingEvents event,
    Emitter<EventState> emit,
  ) async {
    emit(EventLoading());
    try {
      // Note: This would need implementation in the service
      // For now, returning empty list
      emit(const EventLoaded([]));
    } catch (e) {
      emit(EventError('Failed to load attending events: ${e.toString()}'));
    }
  }
}