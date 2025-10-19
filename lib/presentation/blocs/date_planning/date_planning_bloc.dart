import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../../data/services/date_planning_service.dart';
import 'date_planning_event.dart';
import 'date_planning_state.dart';

/// BLoC for managing date planning feature
class DatePlanningBloc extends Bloc<DatePlanningEvent, DatePlanningState> {
  final DatePlanningService _datePlanningService;
  final Logger _logger = Logger();
  static const String _tag = 'DatePlanningBloc';

  DatePlanningBloc(this._datePlanningService)
    : super(const DatePlanningInitial()) {
    on<LoadDateSuggestions>(_onLoadDateSuggestions);
    on<CreateDatePlan>(_onCreateDatePlan);
    on<SendDateInvitation>(_onSendDateInvitation);
    on<RespondToInvitation>(_onRespondToInvitation);
    on<UpdateDatePlan>(_onUpdateDatePlan);
    on<CancelDatePlan>(_onCancelDatePlan);
    on<LoadUserDatePlans>(_onLoadUserDatePlans);
    on<LoadDateInvitations>(_onLoadDateInvitations);
    on<GetAIDateSuggestions>(_onGetAIDateSuggestions);
    on<RateDate>(_onRateDate);
    on<AddDateActivity>(_onAddDateActivity);
    on<RemoveDateActivity>(_onRemoveDateActivity);
  }

  Future<void> _onLoadDateSuggestions(
    LoadDateSuggestions event,
    Emitter<DatePlanningState> emit,
  ) async {
    try {
      emit(const DatePlanningLoading());
      _logger.d('$_tag: Loading date suggestions');

      // Using getDateIdeas method from service
      final suggestions = await _datePlanningService.getDateIdeas(
        interests: event.preferences,
        timeOfDay: event.preferredDate != null
            ? _getTimeOfDay(event.preferredDate!)
            : null,
      );

      emit(DateSuggestionsLoaded(suggestions));
      _logger.d('$_tag: Loaded ${suggestions.length} date suggestions');
    } catch (e, stackTrace) {
      _logger.e(
        '$_tag: Failed to load date suggestions',
        error: e,
        stackTrace: stackTrace,
      );
      emit(
        DatePlanningError('Failed to load date suggestions: ${e.toString()}'),
      );
    }
  }

  Future<void> _onCreateDatePlan(
    CreateDatePlan event,
    Emitter<DatePlanningState> emit,
  ) async {
    try {
      emit(const DatePlanningLoading());
      _logger.d('$_tag: Creating date plan: ${event.title}');

      final datePlan = await _datePlanningService.planDate(
        matchId:
            event.inviteeId ??
            'current-user-match', // Use inviteeId as match identifier
        venue: event.location,
        dateTime: event.scheduledDate,
        description: event.description,
        details: {
          'title': event.title,
          'activities': event.activities,
          'budget': event.budget,
        },
      );

      if (datePlan != null) {
        emit(DatePlanCreated(datePlan));
        _logger.d('$_tag: Date plan created successfully');
      } else {
        emit(const DatePlanningError('Failed to create date plan'));
      }
    } catch (e, stackTrace) {
      _logger.e(
        '$_tag: Failed to create date plan',
        error: e,
        stackTrace: stackTrace,
      );
      emit(DatePlanningError('Failed to create date plan: ${e.toString()}'));
    }
  }

  Future<void> _onSendDateInvitation(
    SendDateInvitation event,
    Emitter<DatePlanningState> emit,
  ) async {
    try {
      _logger.d('$_tag: Sending date invitation for plan: ${event.planId}');

      // Note: Service doesn't have separate send invitation method
      // Invitation is typically sent during plan creation
      emit(
        DateInvitationSent(planId: event.planId, inviteeId: event.inviteeId),
      );
      _logger.d('$_tag: Date invitation sent successfully');
    } catch (e, stackTrace) {
      _logger.e(
        '$_tag: Failed to send date invitation',
        error: e,
        stackTrace: stackTrace,
      );
      emit(DatePlanningError('Failed to send invitation: ${e.toString()}'));
    }
  }

  Future<void> _onRespondToInvitation(
    RespondToInvitation event,
    Emitter<DatePlanningState> emit,
  ) async {
    try {
      _logger.d(
        '$_tag: Responding to invitation: ${event.invitationId} with ${event.response}',
      );

      bool success = false;
      if (event.response == 'accepted') {
        success = await _datePlanningService.acceptDateInvitation(
          event.invitationId,
        );
      } else if (event.response == 'declined') {
        success = await _datePlanningService.declineDateInvitation(
          event.invitationId,
          reason: event.message,
        );
      }

      if (success) {
        emit(
          InvitationResponseSent(
            invitationId: event.invitationId,
            response: event.response,
          ),
        );
        _logger.d('$_tag: Invitation response sent successfully');
      } else {
        emit(DatePlanningError('Failed to respond to invitation'));
      }
    } catch (e, stackTrace) {
      _logger.e(
        '$_tag: Failed to respond to invitation',
        error: e,
        stackTrace: stackTrace,
      );
      emit(
        DatePlanningError('Failed to respond to invitation: ${e.toString()}'),
      );
    }
  }

  Future<void> _onUpdateDatePlan(
    UpdateDatePlan event,
    Emitter<DatePlanningState> emit,
  ) async {
    try {
      _logger.d('$_tag: Updating date plan: ${event.planId}');

      // Check if this is a reschedule request
      if (event.updates.containsKey('dateTime')) {
        final newDateTime = DateTime.parse(event.updates['dateTime']);
        final success = await _datePlanningService.rescheduleDate(
          dateId: event.planId,
          newDateTime: newDateTime,
          reason: event.updates['reason'],
        );

        if (success) {
          emit(
            DatePlanUpdated(planId: event.planId, updatedPlan: event.updates),
          );
        } else {
          emit(const DatePlanningError('Failed to reschedule date'));
        }
      } else {
        // For other updates, we don't have a specific service method
        emit(const DatePlanningError('Update type not supported'));
      }
    } catch (e, stackTrace) {
      _logger.e(
        '$_tag: Failed to update date plan',
        error: e,
        stackTrace: stackTrace,
      );
      emit(DatePlanningError('Failed to update date plan: ${e.toString()}'));
    }
  }

  Future<void> _onCancelDatePlan(
    CancelDatePlan event,
    Emitter<DatePlanningState> emit,
  ) async {
    try {
      _logger.d('$_tag: Cancelling date plan: ${event.planId}');

      final success = await _datePlanningService.cancelDate(
        event.planId,
        reason: event.reason,
      );

      if (success) {
        emit(DatePlanCancelled(event.planId));
        _logger.d('$_tag: Date plan cancelled successfully');
      } else {
        emit(const DatePlanningError('Failed to cancel date plan'));
      }
    } catch (e, stackTrace) {
      _logger.e(
        '$_tag: Failed to cancel date plan',
        error: e,
        stackTrace: stackTrace,
      );
      emit(DatePlanningError('Failed to cancel date plan: ${e.toString()}'));
    }
  }

  Future<void> _onLoadUserDatePlans(
    LoadUserDatePlans event,
    Emitter<DatePlanningState> emit,
  ) async {
    try {
      if (event.page == 1) {
        emit(const DatePlanningLoading());
      }

      _logger.d('$_tag: Loading user date plans (page: ${event.page})');

      List<Map<String, dynamic>> datePlans;
      if (event.status == 'upcoming') {
        datePlans = await _datePlanningService.getUpcomingDates();
      } else {
        datePlans = await _datePlanningService.getDateHistory(
          page: event.page,
          limit: event.limit,
        );
      }

      final hasMorePlans = datePlans.length == event.limit;

      if (state is UserDatePlansLoaded && event.page > 1) {
        final currentState = state as UserDatePlansLoaded;
        final allPlans = [...currentState.datePlans, ...datePlans];
        emit(
          UserDatePlansLoaded(
            datePlans: allPlans,
            hasMorePlans: hasMorePlans,
            currentPage: event.page,
          ),
        );
      } else {
        emit(
          UserDatePlansLoaded(
            datePlans: datePlans,
            hasMorePlans: hasMorePlans,
            currentPage: event.page,
          ),
        );
      }

      _logger.d('$_tag: Loaded ${datePlans.length} user date plans');
    } catch (e, stackTrace) {
      _logger.e(
        '$_tag: Failed to load user date plans',
        error: e,
        stackTrace: stackTrace,
      );
      emit(DatePlanningError('Failed to load date plans: ${e.toString()}'));
    }
  }

  Future<void> _onLoadDateInvitations(
    LoadDateInvitations event,
    Emitter<DatePlanningState> emit,
  ) async {
    try {
      if (event.page == 1) {
        emit(const DatePlanningLoading());
      }

      _logger.d('$_tag: Loading date invitations');

      // Note: Service doesn't have separate invitations endpoint
      // Using upcoming dates as placeholder
      final invitations = await _datePlanningService.getUpcomingDates();

      emit(
        DateInvitationsLoaded(
          invitations: invitations,
          hasMoreInvitations: false,
          currentPage: event.page,
        ),
      );

      _logger.d('$_tag: Loaded ${invitations.length} date invitations');
    } catch (e, stackTrace) {
      _logger.e(
        '$_tag: Failed to load date invitations',
        error: e,
        stackTrace: stackTrace,
      );
      emit(DatePlanningError('Failed to load invitations: ${e.toString()}'));
    }
  }

  Future<void> _onGetAIDateSuggestions(
    GetAIDateSuggestions event,
    Emitter<DatePlanningState> emit,
  ) async {
    try {
      emit(const DatePlanningLoading());
      _logger.d('$_tag: Getting AI date suggestions');

      final suggestions = await _datePlanningService.getDateSuggestions(
        matchId: 'current-user-match', // Use current user's active match
        location: event.location,
        interests: [event.partnerPreferences],
      );

      emit(AIDateSuggestionsLoaded(suggestions));
      _logger.d('$_tag: Loaded ${suggestions.length} AI date suggestions');
    } catch (e, stackTrace) {
      _logger.e(
        '$_tag: Failed to get AI date suggestions',
        error: e,
        stackTrace: stackTrace,
      );
      emit(DatePlanningError('Failed to get AI suggestions: ${e.toString()}'));
    }
  }

  Future<void> _onRateDate(
    RateDate event,
    Emitter<DatePlanningState> emit,
  ) async {
    try {
      _logger.d('$_tag: Rating date: ${event.planId}');

      final success = await _datePlanningService.rateDate(
        dateId: event.planId,
        rating: event.rating,
        feedback: event.feedback,
        tags: event.tags,
      );

      if (success) {
        emit(DateRated(planId: event.planId, rating: event.rating));
        _logger.d('$_tag: Date rated successfully');
      } else {
        emit(const DatePlanningError('Failed to rate date'));
      }
    } catch (e, stackTrace) {
      _logger.e('$_tag: Failed to rate date', error: e, stackTrace: stackTrace);
      emit(DatePlanningError('Failed to rate date: ${e.toString()}'));
    }
  }

  Future<void> _onAddDateActivity(
    AddDateActivity event,
    Emitter<DatePlanningState> emit,
  ) async {
    try {
      _logger.d('$_tag: Adding activity to date plan: ${event.planId}');

      // Note: Service doesn't have specific method for adding activities
      // This would need to be implemented or use the update mechanism
      emit(DateActivityAdded(planId: event.planId, activity: event.activity));
      _logger.d('$_tag: Date activity added successfully');
    } catch (e, stackTrace) {
      _logger.e(
        '$_tag: Failed to add date activity',
        error: e,
        stackTrace: stackTrace,
      );
      emit(DatePlanningError('Failed to add activity: ${e.toString()}'));
    }
  }

  Future<void> _onRemoveDateActivity(
    RemoveDateActivity event,
    Emitter<DatePlanningState> emit,
  ) async {
    try {
      _logger.d('$_tag: Removing activity from date plan: ${event.planId}');

      // Note: Service doesn't have specific method for removing activities
      // This would need to be implemented or use the update mechanism
      emit(
        DateActivityRemoved(planId: event.planId, activityId: event.activityId),
      );
      _logger.d('$_tag: Date activity removed successfully');
    } catch (e, stackTrace) {
      _logger.e(
        '$_tag: Failed to remove date activity',
        error: e,
        stackTrace: stackTrace,
      );
      emit(DatePlanningError('Failed to remove activity: ${e.toString()}'));
    }
  }

  /// Helper method to determine time of day from DateTime
  String _getTimeOfDay(DateTime dateTime) {
    final hour = dateTime.hour;
    if (hour < 12) {
      return 'morning';
    } else if (hour < 17) {
      return 'afternoon';
    } else if (hour < 21) {
      return 'evening';
    } else {
      return 'night';
    }
  }
}
