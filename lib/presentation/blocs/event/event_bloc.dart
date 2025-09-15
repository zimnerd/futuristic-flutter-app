import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/logger.dart';
import '../../../data/services/event_service.dart';
import '../../../domain/entities/event.dart';
import 'event_event.dart';
import 'event_state.dart';

class EventBloc extends Bloc<EventEvent, EventState> {
  final EventService _eventService;

  List<Event> _allEvents = [];
  String? _currentCategory;
  String? _searchQuery;

  EventBloc({
    EventService? eventService,
  })  : _eventService = eventService ?? EventService.instance,
        super(const EventInitial()) {
    on<LoadEvents>(_onLoadEvents);
    on<LoadNearbyEvents>(_onLoadNearbyEvents);
    on<LoadEventDetails>(_onLoadEventDetails);
    on<CreateEvent>(_onCreateEvent);
    on<UpdateEvent>(_onUpdateEvent);
    on<DeleteEvent>(_onDeleteEvent);
    on<AttendEvent>(_onAttendEvent);
    on<LeaveEvent>(_onLeaveEvent);
    on<LoadEventAttendees>(_onLoadEventAttendees);
    on<FilterEventsByCategory>(_onFilterEventsByCategory);
    on<SearchEvents>(_onSearchEvents);
    on<RefreshEvents>(_onRefreshEvents);
    on<ClearEventError>(_onClearEventError);
    on<ResetEventState>(_onResetEventState);
  }

  Future<void> _onLoadEvents(LoadEvents event, Emitter<EventState> emit) async {
    try {
      emit(const EventLoading());

      final events = await _eventService.getEvents(
        latitude: event.latitude,
        longitude: event.longitude,
        radiusKm: event.radiusKm,
        category: event.category,
      );

      _allEvents = events;
      _currentCategory = event.category;

      final filteredEvents = _applyFilters(events);

      emit(EventsLoaded(
        events: events,
        filteredEvents: filteredEvents,
        currentCategory: _currentCategory,
        searchQuery: _searchQuery,
      ));
    } catch (e) {
      AppLogger.error('Error loading events: $e');

      String errorMessage;
      if (e is EventServiceException) {
        // Handle specific error cases based on status code
        switch (e.statusCode) {
          case 401:
            errorMessage = 'Your session has expired. Please log in again.';
            break;
          case 403:
            errorMessage = 'You don\'t have permission to view events.';
            break;
          case 404:
            errorMessage = 'No events found in your area.';
            break;
          case 500:
            errorMessage = 'Server error. Please try again later.';
            break;
          case null:
            // Network errors or other exceptions without status code
            if (e.message.contains('Network error')) {
              errorMessage =
                  'Network connection error. Please check your internet connection.';
            } else {
              errorMessage = e.message;
            }
            break;
          default:
            errorMessage = 'Failed to load events. Please try again.';
        }
      } else {
        // Generic error handling for non-EventServiceException errors
        errorMessage = 'An unexpected error occurred. Please try again.';
      }

      emit(EventError(message: errorMessage));
    }
  }

  Future<void> _onLoadNearbyEvents(
      LoadNearbyEvents event, Emitter<EventState> emit) async {
    try {
      emit(const EventLoading());

      final events = await _eventService.getNearbyEvents(
        latitude: event.latitude,
        longitude: event.longitude,
        radiusKm: event.radiusKm,
      );

      _allEvents = events;
      final filteredEvents = _applyFilters(events);

      emit(EventsLoaded(
        events: events,
        filteredEvents: filteredEvents,
        currentCategory: _currentCategory,
        searchQuery: _searchQuery,
      ));
    } catch (e) {
      AppLogger.error('Error loading nearby events: $e');

      String errorMessage;
      if (e is EventServiceException) {
        // Handle specific error cases based on status code
        switch (e.statusCode) {
          case 401:
            errorMessage = 'Your session has expired. Please log in again.';
            break;
          case 403:
            errorMessage = 'You don\'t have permission to view events.';
            break;
          case 404:
            errorMessage = 'No events found in your area.';
            break;
          case 500:
            errorMessage = 'Server error. Please try again later.';
            break;
          case null:
            // Network errors or other exceptions without status code
            if (e.message.contains('Network error')) {
              errorMessage =
                  'Network connection error. Please check your internet connection.';
            } else {
              errorMessage = e.message;
            }
            break;
          default:
            errorMessage = 'Failed to load nearby events. Please try again.';
        }
      } else {
        // Generic error handling for non-EventServiceException errors
        errorMessage = 'An unexpected error occurred. Please try again.';
      }

      emit(EventError(message: errorMessage));
    }
  }

  Future<void> _onLoadEventDetails(
      LoadEventDetails event, Emitter<EventState> emit) async {
    try {
      emit(const EventLoading());

      final eventDetails = await _eventService.getEventById(event.eventId);

      emit(EventDetailsLoaded(
        event: eventDetails,
        attendees: eventDetails.attendees,
      ));
    } catch (e) {
      emit(EventError(message: e.toString()));
    }
  }

  Future<void> _onCreateEvent(
      CreateEvent event, Emitter<EventState> emit) async {
    try {
      emit(const EventActionLoading('Creating event...'));

      final newEvent = await _eventService.createEvent(
        title: event.request.title,
        description: event.request.description,
        location: event.request.location,
        dateTime: event.request.date,
        latitude: event.request.coordinates.lat,
        longitude: event.request.coordinates.lng,
        category: event.request.category,
        image: event.request.image,
      );

      emit(EventCreated(newEvent));

      // Refresh events list
      add(const RefreshEvents());
    } catch (e) {
      emit(EventError(message: e.toString()));
    }
  }

  Future<void> _onUpdateEvent(
      UpdateEvent event, Emitter<EventState> emit) async {
    try {
      emit(const EventActionLoading('Updating event...'));

      final updatedEvent = await _eventService.updateEvent(
        eventId: event.eventId,
        title: event.request.title,
        description: event.request.description,
        location: event.request.location,
        dateTime: event.request.date,
        latitude: event.request.coordinates.lat,
        longitude: event.request.coordinates.lng,
        category: event.request.category,
        image: event.request.image,
      );

      emit(EventUpdated(updatedEvent));

      // Refresh events list
      add(const RefreshEvents());
    } catch (e) {
      emit(EventError(message: e.toString()));
    }
  }

  Future<void> _onDeleteEvent(
      DeleteEvent event, Emitter<EventState> emit) async {
    try {
      emit(const EventActionLoading('Deleting event...'));

      await _eventService.deleteEvent(event.eventId);

      emit(EventDeleted(event.eventId));

      // Refresh events list
      add(const RefreshEvents());
    } catch (e) {
      emit(EventError(message: e.toString()));
    }
  }

  Future<void> _onAttendEvent(
      AttendEvent event, Emitter<EventState> emit) async {
    try {
      emit(const EventActionLoading('Joining event...'));

      await _eventService.joinEvent(event.eventId);

      // Update the event in our local list
      _updateEventAttendance(event.eventId, true);

      final updatedEvent = _allEvents.firstWhere((e) => e.id == event.eventId);

      emit(EventAttendanceUpdated(
        eventId: event.eventId,
        isAttending: true,
        attendeeCount: updatedEvent.attendeeCount,
      ));

      // Refresh events list to get updated data
      add(const RefreshEvents());
    } catch (e) {
      emit(EventError(message: e.toString()));
    }
  }

  Future<void> _onLeaveEvent(LeaveEvent event, Emitter<EventState> emit) async {
    try {
      emit(const EventActionLoading('Leaving event...'));

      await _eventService.leaveEvent(event.eventId);

      // Update the event in our local list
      _updateEventAttendance(event.eventId, false);

      final updatedEvent = _allEvents.firstWhere((e) => e.id == event.eventId);

      emit(EventAttendanceUpdated(
        eventId: event.eventId,
        isAttending: false,
        attendeeCount: updatedEvent.attendeeCount,
      ));

      // Refresh events list to get updated data
      add(const RefreshEvents());
    } catch (e) {
      emit(EventError(message: e.toString()));
    }
  }

  Future<void> _onLoadEventAttendees(
      LoadEventAttendees event, Emitter<EventState> emit) async {
    try {
      final eventDetails = await _eventService.getEventById(event.eventId);

      emit(EventAttendeesLoaded(
        eventId: event.eventId,
        attendees: eventDetails.attendees,
      ));
    } catch (e) {
      emit(EventError(message: e.toString()));
    }
  }

  void _onFilterEventsByCategory(
      FilterEventsByCategory event, Emitter<EventState> emit) {
    _currentCategory = event.category;

    final filteredEvents = _applyFilters(_allEvents);

    if (state is EventsLoaded) {
      final currentState = state as EventsLoaded;
      emit(currentState.copyWith(
        filteredEvents: filteredEvents,
        currentCategory: _currentCategory,
      ));
    }
  }

  void _onSearchEvents(SearchEvents event, Emitter<EventState> emit) {
    _searchQuery = event.query.trim().isEmpty ? null : event.query.trim();

    final filteredEvents = _applyFilters(_allEvents);

    if (state is EventsLoaded) {
      final currentState = state as EventsLoaded;
      emit(currentState.copyWith(
        filteredEvents: filteredEvents,
        searchQuery: _searchQuery,
      ));
    }
  }

  Future<void> _onRefreshEvents(
      RefreshEvents event, Emitter<EventState> emit) async {
    try {
      if (state is EventsLoaded) {
        final currentState = state as EventsLoaded;
        emit(EventRefreshing(currentState.events));
      }

      final events = await _eventService.getEvents(
        category: _currentCategory,
      );

      _allEvents = events;
      final filteredEvents = _applyFilters(events);

      emit(EventsLoaded(
        events: events,
        filteredEvents: filteredEvents,
        currentCategory: _currentCategory,
        searchQuery: _searchQuery,
      ));
    } catch (e) {
      emit(EventError(message: e.toString()));
    }
  }

  void _onClearEventError(ClearEventError event, Emitter<EventState> emit) {
    if (state is EventError) {
      emit(const EventInitial());
    }
  }

  void _onResetEventState(ResetEventState event, Emitter<EventState> emit) {
    _allEvents = [];
    _currentCategory = null;
    _searchQuery = null;
    emit(const EventInitial());
  }

  /// Apply current filters to events list
  List<Event> _applyFilters(List<Event> events) {
    List<Event> filtered = List.from(events);

    // Apply category filter
    if (_currentCategory != null && _currentCategory!.isNotEmpty) {
      filtered = filtered
          .where((event) => event.category == _currentCategory)
          .toList();
    }

    // Apply search filter
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      final query = _searchQuery!.toLowerCase();
      filtered = filtered.where((event) {
        return event.title.toLowerCase().contains(query) ||
            event.description.toLowerCase().contains(query) ||
            event.location.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  /// Update event attendance status in local list
  void _updateEventAttendance(String eventId, bool isAttending) {
    final index = _allEvents.indexWhere((event) => event.id == eventId);
    if (index != -1) {
      final event = _allEvents[index];
      _allEvents[index] = event.copyWith(
        isAttending: isAttending,
        attendeeCount: isAttending
            ? event.attendeeCount + 1
            : event.attendeeCount - 1,
      );
    }
  }
}