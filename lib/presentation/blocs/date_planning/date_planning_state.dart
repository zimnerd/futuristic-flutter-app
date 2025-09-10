import 'package:equatable/equatable.dart';

/// Base state for date planning feature
abstract class DatePlanningState extends Equatable {
  const DatePlanningState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class DatePlanningInitial extends DatePlanningState {
  const DatePlanningInitial();
}

/// Loading state
class DatePlanningLoading extends DatePlanningState {
  const DatePlanningLoading();
}

/// Date suggestions loaded successfully
class DateSuggestionsLoaded extends DatePlanningState {
  final List<Map<String, dynamic>> suggestions;

  const DateSuggestionsLoaded(this.suggestions);

  @override
  List<Object> get props => [suggestions];
}

/// Date plan created successfully
class DatePlanCreated extends DatePlanningState {
  final Map<String, dynamic> datePlan;

  const DatePlanCreated(this.datePlan);

  @override
  List<Object> get props => [datePlan];
}

/// Date invitation sent successfully
class DateInvitationSent extends DatePlanningState {
  final String planId;
  final String inviteeId;

  const DateInvitationSent({
    required this.planId,
    required this.inviteeId,
  });

  @override
  List<Object> get props => [planId, inviteeId];
}

/// Responded to invitation successfully
class InvitationResponseSent extends DatePlanningState {
  final String invitationId;
  final String response;

  const InvitationResponseSent({
    required this.invitationId,
    required this.response,
  });

  @override
  List<Object> get props => [invitationId, response];
}

/// Date plan updated successfully
class DatePlanUpdated extends DatePlanningState {
  final String planId;
  final Map<String, dynamic> updatedPlan;

  const DatePlanUpdated({
    required this.planId,
    required this.updatedPlan,
  });

  @override
  List<Object> get props => [planId, updatedPlan];
}

/// Date plan cancelled successfully
class DatePlanCancelled extends DatePlanningState {
  final String planId;

  const DatePlanCancelled(this.planId);

  @override
  List<Object> get props => [planId];
}

/// User's date plans loaded successfully
class UserDatePlansLoaded extends DatePlanningState {
  final List<Map<String, dynamic>> datePlans;
  final bool hasMorePlans;
  final int currentPage;

  const UserDatePlansLoaded({
    required this.datePlans,
    this.hasMorePlans = false,
    this.currentPage = 1,
  });

  UserDatePlansLoaded copyWith({
    List<Map<String, dynamic>>? datePlans,
    bool? hasMorePlans,
    int? currentPage,
  }) {
    return UserDatePlansLoaded(
      datePlans: datePlans ?? this.datePlans,
      hasMorePlans: hasMorePlans ?? this.hasMorePlans,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  @override
  List<Object?> get props => [datePlans, hasMorePlans, currentPage];
}

/// Date invitations loaded successfully
class DateInvitationsLoaded extends DatePlanningState {
  final List<Map<String, dynamic>> invitations;
  final bool hasMoreInvitations;
  final int currentPage;

  const DateInvitationsLoaded({
    required this.invitations,
    this.hasMoreInvitations = false,
    this.currentPage = 1,
  });

  DateInvitationsLoaded copyWith({
    List<Map<String, dynamic>>? invitations,
    bool? hasMoreInvitations,
    int? currentPage,
  }) {
    return DateInvitationsLoaded(
      invitations: invitations ?? this.invitations,
      hasMoreInvitations: hasMoreInvitations ?? this.hasMoreInvitations,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  @override
  List<Object?> get props => [invitations, hasMoreInvitations, currentPage];
}

/// AI date suggestions loaded successfully
class AIDateSuggestionsLoaded extends DatePlanningState {
  final List<Map<String, dynamic>> aiSuggestions;

  const AIDateSuggestionsLoaded(this.aiSuggestions);

  @override
  List<Object> get props => [aiSuggestions];
}

/// Date rated successfully
class DateRated extends DatePlanningState {
  final String planId;
  final int rating;

  const DateRated({
    required this.planId,
    required this.rating,
  });

  @override
  List<Object> get props => [planId, rating];
}

/// Date activity added successfully
class DateActivityAdded extends DatePlanningState {
  final String planId;
  final Map<String, dynamic> activity;

  const DateActivityAdded({
    required this.planId,
    required this.activity,
  });

  @override
  List<Object> get props => [planId, activity];
}

/// Date activity removed successfully
class DateActivityRemoved extends DatePlanningState {
  final String planId;
  final String activityId;

  const DateActivityRemoved({
    required this.planId,
    required this.activityId,
  });

  @override
  List<Object> get props => [planId, activityId];
}

/// Error state
class DatePlanningError extends DatePlanningState {
  final String message;

  const DatePlanningError(this.message);

  @override
  List<Object> get props => [message];
}
