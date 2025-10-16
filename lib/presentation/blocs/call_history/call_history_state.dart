import 'package:equatable/equatable.dart';
import '../../../data/repositories/call_history_repository.dart';

/// Base class for all call history states
abstract class CallHistoryState extends Equatable {
  const CallHistoryState();

  @override
  List<Object?> get props => [];
}

/// Initial state when bloc is first created
class CallHistoryInitial extends CallHistoryState {
  const CallHistoryInitial();
}

/// State when loading initial call history
class CallHistoryLoading extends CallHistoryState {
  const CallHistoryLoading();
}

/// State when call history is loaded successfully
class CallHistoryLoaded extends CallHistoryState {
  final List<CallHistoryItem> calls;
  final PaginationMetadata pagination;
  final CallHistoryFilters? appliedFilters;
  final bool isLoadingMore;
  final CallStatistics? statistics;

  const CallHistoryLoaded({
    required this.calls,
    required this.pagination,
    this.appliedFilters,
    this.isLoadingMore = false,
    this.statistics,
  });

  /// Create a copy with updated fields
  CallHistoryLoaded copyWith({
    List<CallHistoryItem>? calls,
    PaginationMetadata? pagination,
    CallHistoryFilters? appliedFilters,
    bool? isLoadingMore,
    CallStatistics? statistics,
    bool clearFilters = false,
    bool clearStatistics = false,
  }) {
    return CallHistoryLoaded(
      calls: calls ?? this.calls,
      pagination: pagination ?? this.pagination,
      appliedFilters:
          clearFilters ? null : (appliedFilters ?? this.appliedFilters),
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      statistics:
          clearStatistics ? null : (statistics ?? this.statistics),
    );
  }

  @override
  List<Object?> get props =>
      [calls, pagination, appliedFilters, isLoadingMore, statistics];
}

/// State when call history loading fails
class CallHistoryError extends CallHistoryState {
  final String message;

  const CallHistoryError(this.message);

  @override
  List<Object> get props => [message];
}

/// State when refreshing call history
class CallHistoryRefreshing extends CallHistoryState {
  final List<CallHistoryItem> existingCalls;
  final CallHistoryFilters? appliedFilters;

  const CallHistoryRefreshing({
    required this.existingCalls,
    this.appliedFilters,
  });

  @override
  List<Object?> get props => [existingCalls, appliedFilters];
}

/// State when deleting a call record
class CallHistoryDeleting extends CallHistoryState {
  final String callId;
  final List<CallHistoryItem> calls;
  final PaginationMetadata pagination;

  const CallHistoryDeleting({
    required this.callId,
    required this.calls,
    required this.pagination,
  });

  @override
  List<Object> get props => [callId, calls, pagination];
}

/// State when a call record is deleted successfully
class CallHistoryDeleted extends CallHistoryState {
  final String callId;
  final List<CallHistoryItem> updatedCalls;
  final PaginationMetadata updatedPagination;

  const CallHistoryDeleted({
    required this.callId,
    required this.updatedCalls,
    required this.updatedPagination,
  });

  @override
  List<Object> get props => [callId, updatedCalls, updatedPagination];
}

/// State when viewing call details
class CallDetailsLoading extends CallHistoryState {
  final String callId;

  const CallDetailsLoading(this.callId);

  @override
  List<Object> get props => [callId];
}

/// State when call details are loaded
class CallDetailsLoaded extends CallHistoryState {
  final CallDetails details;

  const CallDetailsLoaded(this.details);

  @override
  List<Object> get props => [details];
}

/// State when call details loading fails
class CallDetailsError extends CallHistoryState {
  final String message;
  final String callId;

  const CallDetailsError({
    required this.message,
    required this.callId,
  });

  @override
  List<Object> get props => [message, callId];
}

/// State when loading call statistics
class CallStatisticsLoading extends CallHistoryState {
  const CallStatisticsLoading();
}

/// State when call statistics are loaded
class CallStatisticsLoaded extends CallHistoryState {
  final CallStatistics statistics;

  const CallStatisticsLoaded(this.statistics);

  @override
  List<Object> get props => [statistics];
}

/// State when call statistics loading fails
class CallStatisticsError extends CallHistoryState {
  final String message;

  const CallStatisticsError(this.message);

  @override
  List<Object> get props => [message];
}
