import 'package:equatable/equatable.dart';
import '../../../data/repositories/call_history_repository.dart';

/// Base class for all call history events
abstract class CallHistoryEvent extends Equatable {
  const CallHistoryEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load initial call history
class LoadCallHistory extends CallHistoryEvent {
  final CallHistoryFilters? filters;

  const LoadCallHistory({this.filters});

  @override
  List<Object?> get props => [filters];
}

/// Event to refresh call history (pull-to-refresh)
class RefreshCallHistory extends CallHistoryEvent {
  final CallHistoryFilters? filters;

  const RefreshCallHistory({this.filters});

  @override
  List<Object?> get props => [filters];
}

/// Event to load more call history (pagination)
class LoadMoreCallHistory extends CallHistoryEvent {
  const LoadMoreCallHistory();
}

/// Event to delete a call record
class DeleteCallRecord extends CallHistoryEvent {
  final String callId;

  const DeleteCallRecord(this.callId);

  @override
  List<Object> get props => [callId];
}

/// Event to apply filters to call history
class ApplyCallHistoryFilters extends CallHistoryEvent {
  final CallHistoryFilters? filters;

  const ApplyCallHistoryFilters({this.filters});

  @override
  List<Object?> get props => [filters];
}

/// Event to load call statistics
class LoadCallStatistics extends CallHistoryEvent {
  const LoadCallStatistics();
}

/// Event to view call details
class ViewCallDetails extends CallHistoryEvent {
  final String callId;

  const ViewCallDetails(this.callId);

  @override
  List<Object> get props => [callId];
}

/// Event to clear call details
class ClearCallDetails extends CallHistoryEvent {
  const ClearCallDetails();
}
