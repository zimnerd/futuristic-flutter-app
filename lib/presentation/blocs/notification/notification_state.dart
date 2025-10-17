part of 'notification_bloc.dart';

/// States for notification settings management
abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

/// Initial state before loading preferences
class NotificationInitial extends NotificationState {
  const NotificationInitial();
}

/// State when notification preferences are being loaded
class NotificationLoading extends NotificationState {
  const NotificationLoading();
}

/// State when notification preferences are successfully loaded
class NotificationPreferencesLoaded extends NotificationState {
  final NotificationPreferences preferences;

  const NotificationPreferencesLoaded(this.preferences);

  @override
  List<Object?> get props => [preferences];
}

/// State when notification preferences are being updated
class NotificationUpdating extends NotificationState {
  final NotificationPreferences currentPreferences;

  const NotificationUpdating(this.currentPreferences);

  @override
  List<Object?> get props => [currentPreferences];
}

/// State when notification preferences are successfully updated
class NotificationPreferencesUpdated extends NotificationState {
  final NotificationPreferences preferences;
  final String message;

  const NotificationPreferencesUpdated({
    required this.preferences,
    required this.message,
  });

  @override
  List<Object?> get props => [preferences, message];
}

/// State when a test notification is being sent
class SendingTestNotification extends NotificationState {
  const SendingTestNotification();
}

/// State when a test notification is successfully sent
class TestNotificationSent extends NotificationState {
  final String message;

  const TestNotificationSent(this.message);

  @override
  List<Object?> get props => [message];
}

/// State when a notification operation fails
class NotificationError extends NotificationState {
  final String message;
  final String? errorCode;

  const NotificationError({
    required this.message,
    this.errorCode,
  });

  @override
  List<Object?> get props => [message, errorCode];
}
