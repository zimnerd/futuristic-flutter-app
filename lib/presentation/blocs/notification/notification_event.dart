part of 'notification_bloc.dart';

/// Events for notification settings management
abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load notification preferences from the server
class LoadNotificationPreferences extends NotificationEvent {
  const LoadNotificationPreferences();
}

/// Event to update notification preferences
class UpdateNotificationPreferences extends NotificationEvent {
  final NotificationPreferences preferences;

  const UpdateNotificationPreferences(this.preferences);

  @override
  List<Object?> get props => [preferences];
}

/// Event to update a single notification preference
class UpdateSinglePreference extends NotificationEvent {
  final String preferenceKey;
  final bool value;

  const UpdateSinglePreference({
    required this.preferenceKey,
    required this.value,
  });

  @override
  List<Object?> get props => [preferenceKey, value];
}

/// Event to send a test notification
class SendTestNotification extends NotificationEvent {
  const SendTestNotification();
}

/// Event to reset notification preferences to defaults
class ResetNotificationPreferences extends NotificationEvent {
  const ResetNotificationPreferences();
}
