import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import '../../../domain/entities/notification_preferences.dart';
import '../../../domain/repositories/user_repository.dart';
import '../auth/auth_bloc.dart';
import '../auth/auth_state.dart';

part 'notification_event.dart';
part 'notification_state.dart';

/// BLoC for managing notification settings
class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final UserRepository _userRepository;
  final AuthBloc _authBloc;

  NotificationBloc({
    required UserRepository userRepository,
    required AuthBloc authBloc,
  })  : _userRepository = userRepository,
       _authBloc = authBloc,
        super(const NotificationInitial()) {
    on<LoadNotificationPreferences>(_onLoadNotificationPreferences);
    on<UpdateNotificationPreferences>(_onUpdateNotificationPreferences);
    on<UpdateSinglePreference>(_onUpdateSinglePreference);
    on<SendTestNotification>(_onSendTestNotification);
    on<ResetNotificationPreferences>(_onResetNotificationPreferences);
  }

  /// Get current user ID from auth context
  String _getCurrentUserId() {
    final authState = _authBloc.state;
    if (authState is AuthAuthenticated) {
      return authState.user.id;
    }
    throw Exception(
      'User not authenticated. Please log in to access notifications.',
    );
  }

  /// Load notification preferences from repository
  Future<void> _onLoadNotificationPreferences(
    LoadNotificationPreferences event,
    Emitter<NotificationState> emit,
  ) async {
    emit(const NotificationLoading());

    try {
      // Get userId from auth context
      final userId = _getCurrentUserId();
      
      final preferencesJson = await _userRepository.getNotificationPreferences(userId);
      final preferences = NotificationPreferences.fromJson(preferencesJson);
      emit(NotificationPreferencesLoaded(preferences));
    } catch (e) {
      emit(NotificationError(
        message: 'Failed to load notification preferences: ${e.toString()}',
      ));
    }
  }

  /// Update all notification preferences
  Future<void> _onUpdateNotificationPreferences(
    UpdateNotificationPreferences event,
    Emitter<NotificationState> emit,
  ) async {
    // Keep current preferences visible while updating
    emit(NotificationUpdating(event.preferences));

    try {
      // Get userId from auth context
      final userId = _getCurrentUserId();
      
      await _userRepository.updateNotificationPreferences(
        userId,
        event.preferences.toJson(),
      );
      emit(NotificationPreferencesUpdated(
        preferences: event.preferences,
        message: 'Notification preferences updated successfully',
      ));
    } catch (e) {
      emit(NotificationError(
        message: 'Failed to update notification preferences: ${e.toString()}',
      ));
    }
  }

  /// Update a single notification preference
  Future<void> _onUpdateSinglePreference(
    UpdateSinglePreference event,
    Emitter<NotificationState> emit,
  ) async {
    final currentState = state;
    
    // Only proceed if we have loaded preferences
    if (currentState is! NotificationPreferencesLoaded &&
        currentState is! NotificationPreferencesUpdated) {
      return;
    }

    // Get current preferences
    final currentPreferences = currentState is NotificationPreferencesLoaded
        ? currentState.preferences
        : (currentState as NotificationPreferencesUpdated).preferences;

    // Create updated preferences with the single change
    final updatedPreferences = currentPreferences.copyWith({
      event.preferenceKey: event.value,
    });

    // Update via the full update event
    add(UpdateNotificationPreferences(updatedPreferences));
  }

  /// Send a test notification
  Future<void> _onSendTestNotification(
    SendTestNotification event,
    Emitter<NotificationState> emit,
  ) async {
    emit(const SendingTestNotification());

    try {
      // Send test notification via API
      final apiClient = ApiClient.instance;
      final response = await apiClient.post('/notifications/test');

      if (response.statusCode == 200 || response.statusCode == 201) {
        emit(
          const TestNotificationSent(
            'Test notification sent successfully! Check your notification tray.',
          ),
        );
      } else {
        throw Exception('Failed to send test notification');
      }

      // Return to loaded state after brief delay
      await Future.delayed(const Duration(seconds: 2));
      if (state is TestNotificationSent) {
        add(const LoadNotificationPreferences());
      }
    } catch (e) {
      emit(NotificationError(
        message: 'Failed to send test notification: ${e.toString()}',
      ));
    }
  }

  /// Reset notification preferences to defaults
  Future<void> _onResetNotificationPreferences(
    ResetNotificationPreferences event,
    Emitter<NotificationState> emit,
  ) async {
    emit(const NotificationLoading());

    try {
      // Create default preferences (all enabled)
      final defaultPreferences = NotificationPreferences(
        matchNotifications: true,
        messageNotifications: true,
        likeNotifications: true,
        superLikeNotifications: true,
        eventNotifications: true,
        eventReminders: true,
        speedDatingNotifications: true,
        premiumNotifications: true,
        promotionalNotifications: false, // Opt-in for promotional
        securityAlerts: true,
        accountActivity: true,
        newFeatures: true,
        tipsTricks: true,
      );

      // Get userId from auth context
      final userId = _getCurrentUserId();
      
      await _userRepository.updateNotificationPreferences(
        userId,
        defaultPreferences.toJson(),
      );
      
      emit(NotificationPreferencesUpdated(
        preferences: defaultPreferences,
        message: 'Notification preferences reset to defaults',
      ));
    } catch (e) {
      emit(NotificationError(
        message: 'Failed to reset notification preferences: ${e.toString()}',
      ));
    }
  }
}
