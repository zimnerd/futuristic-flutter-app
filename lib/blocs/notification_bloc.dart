import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:logger/logger.dart';

import '../data/models/notification_model.dart';
import '../data/repositories/notification_repository.dart';

// Events
abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class LoadNotifications extends NotificationEvent {
  final int page;
  final int limit;

  const LoadNotifications({
    this.page = 1,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [page, limit];
}

class MarkNotificationAsRead extends NotificationEvent {
  final String notificationId;

  const MarkNotificationAsRead({required this.notificationId});

  @override
  List<Object?> get props => [notificationId];
}

class MarkAllNotificationsAsRead extends NotificationEvent {
  const MarkAllNotificationsAsRead();
}

class DeleteNotification extends NotificationEvent {
  final String notificationId;

  const DeleteNotification({required this.notificationId});

  @override
  List<Object?> get props => [notificationId];
}

class ClearAllNotifications extends NotificationEvent {
  const ClearAllNotifications();
}

class RefreshNotifications extends NotificationEvent {
  const RefreshNotifications();
}

// States
abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {
  const NotificationInitial();
}

class NotificationLoading extends NotificationState {
  const NotificationLoading();
}

class NotificationsLoaded extends NotificationState {
  final List<NotificationModel> notifications;
  final bool hasMoreNotifications;
  final int unreadCount;

  const NotificationsLoaded({
    required this.notifications,
    required this.hasMoreNotifications,
    required this.unreadCount,
  });

  @override
  List<Object?> get props => [notifications, hasMoreNotifications, unreadCount];
}

class NotificationActionSuccess extends NotificationState {
  final String message;

  const NotificationActionSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class NotificationError extends NotificationState {
  final String message;

  const NotificationError({required this.message});

  @override
  List<Object?> get props => [message];
}

// BLoC
class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository _notificationRepository;
  final Logger _logger = Logger();

  NotificationBloc({required NotificationRepository notificationRepository})
      : _notificationRepository = notificationRepository,
        super(const NotificationInitial()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<MarkNotificationAsRead>(_onMarkNotificationAsRead);
    on<MarkAllNotificationsAsRead>(_onMarkAllNotificationsAsRead);
    on<DeleteNotification>(_onDeleteNotification);
    on<ClearAllNotifications>(_onClearAllNotifications);
    on<RefreshNotifications>(_onRefreshNotifications);
  }

  Future<void> _onLoadNotifications(
    LoadNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      emit(const NotificationLoading());
      
      final notifications = await _notificationRepository.getNotifications(
        page: event.page,
        limit: event.limit,
      );
      
      final unreadCount = await _notificationRepository.getUnreadCount();
      
      // Check if there are more notifications available
      final hasMoreNotifications = notifications.length == event.limit;
      
      emit(NotificationsLoaded(
        notifications: notifications,
        hasMoreNotifications: hasMoreNotifications,
        unreadCount: unreadCount,
      ));
      
      _logger.d('Loaded ${notifications.length} notifications');
    } catch (e) {
      _logger.e('Error loading notifications: $e');
      emit(NotificationError(message: 'Failed to load notifications: $e'));
    }
  }

  Future<void> _onMarkNotificationAsRead(
    MarkNotificationAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _notificationRepository.markAsRead(event.notificationId);
      
      // Refresh notifications to show updated state
      add(const RefreshNotifications());
      
      _logger.d('Notification marked as read: ${event.notificationId}');
    } catch (e) {
      _logger.e('Error marking notification as read: $e');
      emit(NotificationError(message: 'Failed to mark notification as read: $e'));
    }
  }

  Future<void> _onMarkAllNotificationsAsRead(
    MarkAllNotificationsAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _notificationRepository.markAllAsRead();
      
      // Refresh notifications to show updated state
      add(const RefreshNotifications());
      
      emit(const NotificationActionSuccess(message: 'All notifications marked as read'));
      _logger.d('All notifications marked as read');
    } catch (e) {
      _logger.e('Error marking all notifications as read: $e');
      emit(NotificationError(message: 'Failed to mark all notifications as read: $e'));
    }
  }

  Future<void> _onDeleteNotification(
    DeleteNotification event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _notificationRepository.deleteNotification(event.notificationId);
      
      // Refresh notifications to show updated state
      add(const RefreshNotifications());
      
      _logger.d('Notification deleted: ${event.notificationId}');
    } catch (e) {
      _logger.e('Error deleting notification: $e');
      emit(NotificationError(message: 'Failed to delete notification: $e'));
    }
  }

  Future<void> _onClearAllNotifications(
    ClearAllNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _notificationRepository.clearAllNotifications();
      
      // Refresh notifications to show updated state
      add(const RefreshNotifications());
      
      emit(const NotificationActionSuccess(message: 'All notifications cleared'));
      _logger.d('All notifications cleared');
    } catch (e) {
      _logger.e('Error clearing all notifications: $e');
      emit(NotificationError(message: 'Failed to clear all notifications: $e'));
    }
  }

  Future<void> _onRefreshNotifications(
    RefreshNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    // Reload notifications with default parameters
    add(const LoadNotifications());
  }
}