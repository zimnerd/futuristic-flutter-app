import 'package:equatable/equatable.dart';

import '../../../domain/entities/event.dart';

// Events
abstract class EventEvent extends Equatable {
  const EventEvent();

  @override
  List<Object?> get props => [];
}

class LoadEvents extends EventEvent {
  final double? latitude;
  final double? longitude;
  final double? radiusKm;
  final String? category;

  const LoadEvents({
    this.latitude,
    this.longitude,
    this.radiusKm = 50.0,
    this.category,
  });

  @override
  List<Object?> get props => [latitude, longitude, radiusKm, category];
}

class LoadNearbyEvents extends EventEvent {
  final double latitude;
  final double longitude;
  final double radiusKm;

  const LoadNearbyEvents({
    required this.latitude,
    required this.longitude,
    this.radiusKm = 10.0,
  });

  @override
  List<Object?> get props => [latitude, longitude, radiusKm];
}

class LoadEventDetails extends EventEvent {
  final String eventId;

  const LoadEventDetails(this.eventId);

  @override
  List<Object?> get props => [eventId];
}

class CreateEvent extends EventEvent {
  final CreateEventRequest request;

  const CreateEvent(this.request);

  @override
  List<Object?> get props => [request];
}

class UpdateEvent extends EventEvent {
  final String eventId;
  final CreateEventRequest request;

  const UpdateEvent(this.eventId, this.request);

  @override
  List<Object?> get props => [eventId, request];
}

class DeleteEvent extends EventEvent {
  final String eventId;

  const DeleteEvent(this.eventId);

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

class LoadEventAttendees extends EventEvent {
  final String eventId;

  const LoadEventAttendees(this.eventId);

  @override
  List<Object?> get props => [eventId];
}

class FilterEventsByCategory extends EventEvent {
  final String? category;

  const FilterEventsByCategory(this.category);

  @override
  List<Object?> get props => [category];
}

class SearchEvents extends EventEvent {
  final String query;

  const SearchEvents(this.query);

  @override
  List<Object?> get props => [query];
}

class RefreshEvents extends EventEvent {
  const RefreshEvents();
}

class ClearEventError extends EventEvent {
  const ClearEventError();
}

class LoadEventCategories extends EventEvent {
  final bool forceRefresh;
  
  const LoadEventCategories({this.forceRefresh = false});
}

class RefreshEventCategories extends EventEvent {
  const RefreshEventCategories();
}

class ResetEventState extends EventEvent {
  const ResetEventState();
}

class ToggleJoinedOnlyFilter extends EventEvent {
  final bool showJoinedOnly;

  const ToggleJoinedOnlyFilter(this.showJoinedOnly);

  @override
  List<Object?> get props => [showJoinedOnly];
}

class ApplyAdvancedFilters extends EventEvent {
  final DateTime? startDate;
  final DateTime? endDate;
  final double? maxDistance;
  final bool? hasAvailableSpots;
  final bool? showJoinedOnly;

  const ApplyAdvancedFilters({
    this.startDate,
    this.endDate,
    this.maxDistance,
    this.hasAvailableSpots,
    this.showJoinedOnly,
  });

  @override
  List<Object?> get props => [
    startDate,
    endDate,
    maxDistance,
    hasAvailableSpots,
    showJoinedOnly,
  ];
}

class ClearAdvancedFilters extends EventEvent {
  const ClearAdvancedFilters();
}
