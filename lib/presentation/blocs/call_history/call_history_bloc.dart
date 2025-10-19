import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/call_history_repository.dart';
import 'call_history_event.dart';
import 'call_history_state.dart';

/// BLoC for managing call history state and business logic
class CallHistoryBloc extends Bloc<CallHistoryEvent, CallHistoryState> {
  final CallHistoryRepository _repository;

  // Current page and filters for pagination
  int _currentPage = 1;
  CallHistoryFilters? _currentFilters;

  CallHistoryBloc({CallHistoryRepository? repository})
    : _repository = repository ?? CallHistoryRepository(),
      super(const CallHistoryInitial()) {
    // Register event handlers
    on<LoadCallHistory>(_onLoadCallHistory);
    on<RefreshCallHistory>(_onRefreshCallHistory);
    on<LoadMoreCallHistory>(_onLoadMoreCallHistory);
    on<DeleteCallRecord>(_onDeleteCallRecord);
    on<ApplyCallHistoryFilters>(_onApplyFilters);
    on<LoadCallStatistics>(_onLoadCallStatistics);
    on<ViewCallDetails>(_onViewCallDetails);
    on<ClearCallDetails>(_onClearCallDetails);
  }

  /// Handle loading initial call history
  Future<void> _onLoadCallHistory(
    LoadCallHistory event,
    Emitter<CallHistoryState> emit,
  ) async {
    try {
      emit(const CallHistoryLoading());

      _currentPage = 1;
      _currentFilters = event.filters;

      final response = await _repository.getCallHistory(
        page: _currentPage,
        filters: _currentFilters,
      );

      emit(
        CallHistoryLoaded(
          calls: response.calls,
          pagination: response.pagination,
          appliedFilters: _currentFilters,
        ),
      );
    } catch (e) {
      emit(CallHistoryError('Failed to load call history: ${e.toString()}'));
    }
  }

  /// Handle refreshing call history (pull-to-refresh)
  Future<void> _onRefreshCallHistory(
    RefreshCallHistory event,
    Emitter<CallHistoryState> emit,
  ) async {
    try {
      // Keep existing calls visible during refresh
      final currentState = state;
      final existingCalls = currentState is CallHistoryLoaded
          ? currentState.calls
          : <CallHistoryItem>[];

      emit(
        CallHistoryRefreshing(
          existingCalls: existingCalls,
          appliedFilters: event.filters ?? _currentFilters,
        ),
      );

      _currentPage = 1;
      _currentFilters = event.filters ?? _currentFilters;

      final response = await _repository.getCallHistory(
        page: _currentPage,
        filters: _currentFilters,
      );

      emit(
        CallHistoryLoaded(
          calls: response.calls,
          pagination: response.pagination,
          appliedFilters: _currentFilters,
        ),
      );
    } catch (e) {
      // Revert to previous state on error
      final currentState = state;
      if (currentState is CallHistoryRefreshing) {
        emit(
          CallHistoryLoaded(
            calls: currentState.existingCalls,
            pagination: PaginationMetadata(
              page: _currentPage,
              limit: 20,
              total: currentState.existingCalls.length,
              totalPages: 1,
              hasNext: false,
              hasPrev: false,
            ),
            appliedFilters: currentState.appliedFilters,
          ),
        );
      }
      emit(CallHistoryError('Failed to refresh call history: ${e.toString()}'));
    }
  }

  /// Handle loading more call history (infinite scroll pagination)
  Future<void> _onLoadMoreCallHistory(
    LoadMoreCallHistory event,
    Emitter<CallHistoryState> emit,
  ) async {
    final currentState = state;
    if (currentState is! CallHistoryLoaded) return;

    // Don't load if already loading or no more pages
    if (currentState.isLoadingMore || !currentState.pagination.hasNext) {
      return;
    }

    try {
      // Show loading indicator at bottom
      emit(currentState.copyWith(isLoadingMore: true));

      _currentPage++;

      final response = await _repository.getCallHistory(
        page: _currentPage,
        filters: _currentFilters,
      );

      // Append new calls to existing list
      final updatedCalls = [...currentState.calls, ...response.calls];

      emit(
        CallHistoryLoaded(
          calls: updatedCalls,
          pagination: response.pagination,
          appliedFilters: _currentFilters,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      // Revert page number and hide loading indicator
      _currentPage--;
      emit(currentState.copyWith(isLoadingMore: false));
      emit(
        CallHistoryError('Failed to load more call history: ${e.toString()}'),
      );
    }
  }

  /// Handle deleting a call record
  Future<void> _onDeleteCallRecord(
    DeleteCallRecord event,
    Emitter<CallHistoryState> emit,
  ) async {
    final currentState = state;
    if (currentState is! CallHistoryLoaded) return;

    try {
      emit(
        CallHistoryDeleting(
          callId: event.callId,
          calls: currentState.calls,
          pagination: currentState.pagination,
        ),
      );

      await _repository.deleteCallRecord(event.callId);

      // Remove deleted call from list
      final updatedCalls = currentState.calls
          .where((call) => call.id != event.callId)
          .toList();

      // Update pagination metadata
      final updatedPagination = PaginationMetadata(
        page: currentState.pagination.page,
        limit: currentState.pagination.limit,
        total: currentState.pagination.total - 1,
        totalPages:
            ((currentState.pagination.total - 1) /
                    currentState.pagination.limit)
                .ceil(),
        hasNext: currentState.pagination.hasNext,
        hasPrev: currentState.pagination.hasPrev,
      );

      emit(
        CallHistoryDeleted(
          callId: event.callId,
          updatedCalls: updatedCalls,
          updatedPagination: updatedPagination,
        ),
      );

      // Return to loaded state with updated data
      emit(
        CallHistoryLoaded(
          calls: updatedCalls,
          pagination: updatedPagination,
          appliedFilters: currentState.appliedFilters,
          statistics: currentState.statistics,
        ),
      );
    } catch (e) {
      // Revert to previous state
      emit(
        CallHistoryLoaded(
          calls: currentState.calls,
          pagination: currentState.pagination,
          appliedFilters: currentState.appliedFilters,
          statistics: currentState.statistics,
        ),
      );
      emit(CallHistoryError('Failed to delete call record: ${e.toString()}'));
    }
  }

  /// Handle applying filters
  Future<void> _onApplyFilters(
    ApplyCallHistoryFilters event,
    Emitter<CallHistoryState> emit,
  ) async {
    try {
      emit(const CallHistoryLoading());

      _currentPage = 1;
      _currentFilters = event.filters;

      final response = await _repository.getCallHistory(
        page: _currentPage,
        filters: _currentFilters,
      );

      emit(
        CallHistoryLoaded(
          calls: response.calls,
          pagination: response.pagination,
          appliedFilters: _currentFilters,
        ),
      );
    } catch (e) {
      emit(CallHistoryError('Failed to apply filters: ${e.toString()}'));
    }
  }

  /// Handle loading call statistics
  Future<void> _onLoadCallStatistics(
    LoadCallStatistics event,
    Emitter<CallHistoryState> emit,
  ) async {
    final currentState = state;

    try {
      if (currentState is! CallHistoryLoaded) {
        emit(const CallStatisticsLoading());
      }

      final statistics = await _repository.getCallStats();

      if (currentState is CallHistoryLoaded) {
        // Update existing loaded state with statistics
        emit(currentState.copyWith(statistics: statistics));
      } else {
        emit(CallStatisticsLoaded(statistics));
      }
    } catch (e) {
      emit(
        CallStatisticsError('Failed to load call statistics: ${e.toString()}'),
      );
    }
  }

  /// Handle viewing call details
  Future<void> _onViewCallDetails(
    ViewCallDetails event,
    Emitter<CallHistoryState> emit,
  ) async {
    try {
      emit(CallDetailsLoading(event.callId));

      final details = await _repository.getCallDetails(event.callId);

      emit(CallDetailsLoaded(details));
    } catch (e) {
      emit(
        CallDetailsError(
          message: 'Failed to load call details: ${e.toString()}',
          callId: event.callId,
        ),
      );
    }
  }

  /// Handle clearing call details (returning to list view)
  Future<void> _onClearCallDetails(
    ClearCallDetails event,
    Emitter<CallHistoryState> emit,
  ) async {
    // Reload the call history list
    add(LoadCallHistory(filters: _currentFilters));
  }

  /// Get current filters
  CallHistoryFilters? get currentFilters => _currentFilters;

  /// Get current page
  int get currentPage => _currentPage;
}
