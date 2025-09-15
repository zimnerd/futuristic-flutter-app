import 'package:flutter_bloc/flutter_bloc.dart';

// Temporary placeholder events until the actual BLoC files are integrated
abstract class EventEvent {}

class LoadEvents extends EventEvent {}

class EventState {
  final bool isLoading;
  final List<dynamic> events;
  final String? error;
  final Set<String> attendingEventIds;

  const EventState({
    this.isLoading = false,
    this.events = const [],
    this.error,
    this.attendingEventIds = const {},
  });

  EventState copyWith({
    bool? isLoading,
    List<dynamic>? events,
    String? error,
    Set<String>? attendingEventIds,
  }) {
    return EventState(
      isLoading: isLoading ?? this.isLoading,
      events: events ?? this.events,
      error: error ?? this.error,
      attendingEventIds: attendingEventIds ?? this.attendingEventIds,
    );
  }
}

// Placeholder EventBloc for app_providers.dart
class EventBloc extends Bloc<EventEvent, EventState> {
  EventBloc() : super(const EventState()) {
    on<LoadEvents>((event, emit) {
      // Placeholder implementation
      emit(state.copyWith(isLoading: false, events: []));
    });
  }
}