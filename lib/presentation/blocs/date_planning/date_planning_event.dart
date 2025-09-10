import 'package:equatable/equatable.dart';

/// Base event for date planning feature
abstract class DatePlanningEvent extends Equatable {
  const DatePlanningEvent();

  @override
  List<Object?> get props => [];
}

/// Load date suggestions
class LoadDateSuggestions extends DatePlanningEvent {
  final String? location;
  final String? budget;
  final List<String>? preferences;
  final DateTime? preferredDate;

  const LoadDateSuggestions({
    this.location,
    this.budget,
    this.preferences,
    this.preferredDate,
  });

  @override
  List<Object?> get props => [location, budget, preferences, preferredDate];
}

/// Create a date plan
class CreateDatePlan extends DatePlanningEvent {
  final String title;
  final String description;
  final DateTime scheduledDate;
  final String location;
  final String? budget;
  final List<String> activities;
  final String? inviteeId;

  const CreateDatePlan({
    required this.title,
    required this.description,
    required this.scheduledDate,
    required this.location,
    this.budget,
    this.activities = const [],
    this.inviteeId,
  });

  @override
  List<Object?> get props => [title, description, scheduledDate, location, budget, activities, inviteeId];
}

/// Send date invitation
class SendDateInvitation extends DatePlanningEvent {
  final String planId;
  final String inviteeId;
  final String? personalMessage;

  const SendDateInvitation({
    required this.planId,
    required this.inviteeId,
    this.personalMessage,
  });

  @override
  List<Object?> get props => [planId, inviteeId, personalMessage];
}

/// Respond to date invitation
class RespondToInvitation extends DatePlanningEvent {
  final String invitationId;
  final String response; // 'accepted', 'declined', 'tentative'
  final String? message;

  const RespondToInvitation({
    required this.invitationId,
    required this.response,
    this.message,
  });

  @override
  List<Object?> get props => [invitationId, response, message];
}

/// Update date plan
class UpdateDatePlan extends DatePlanningEvent {
  final String planId;
  final Map<String, dynamic> updates;

  const UpdateDatePlan({
    required this.planId,
    required this.updates,
  });

  @override
  List<Object> get props => [planId, updates];
}

/// Cancel date plan
class CancelDatePlan extends DatePlanningEvent {
  final String planId;
  final String? reason;

  const CancelDatePlan({
    required this.planId,
    this.reason,
  });

  @override
  List<Object?> get props => [planId, reason];
}

/// Load user's date plans
class LoadUserDatePlans extends DatePlanningEvent {
  final String? status; // 'upcoming', 'past', 'cancelled'
  final int page;
  final int limit;

  const LoadUserDatePlans({
    this.status,
    this.page = 1,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [status, page, limit];
}

/// Load date invitations
class LoadDateInvitations extends DatePlanningEvent {
  final String? status; // 'pending', 'accepted', 'declined'
  final int page;
  final int limit;

  const LoadDateInvitations({
    this.status,
    this.page = 1,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [status, page, limit];
}

/// Get AI date suggestions
class GetAIDateSuggestions extends DatePlanningEvent {
  final String partnerPreferences;
  final String location;
  final String budget;
  final DateTime dateTime;

  const GetAIDateSuggestions({
    required this.partnerPreferences,
    required this.location,
    required this.budget,
    required this.dateTime,
  });

  @override
  List<Object> get props => [partnerPreferences, location, budget, dateTime];
}

/// Rate completed date
class RateDate extends DatePlanningEvent {
  final String planId;
  final int rating; // 1-5 scale
  final String? feedback;
  final List<String>? tags;

  const RateDate({
    required this.planId,
    required this.rating,
    this.feedback,
    this.tags,
  });

  @override
  List<Object?> get props => [planId, rating, feedback, tags];
}

/// Add date activity
class AddDateActivity extends DatePlanningEvent {
  final String planId;
  final Map<String, dynamic> activity;

  const AddDateActivity({
    required this.planId,
    required this.activity,
  });

  @override
  List<Object> get props => [planId, activity];
}

/// Remove date activity
class RemoveDateActivity extends DatePlanningEvent {
  final String planId;
  final String activityId;

  const RemoveDateActivity({
    required this.planId,
    required this.activityId,
  });

  @override
  List<Object> get props => [planId, activityId];
}
