import 'package:logger/logger.dart';

import '../models/notification_model.dart';
import '../datasources/remote/notification_remote_data_source.dart';
import 'notification_repository.dart';

/// Implementation of NotificationRepository
class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource _remoteDataSource;
  final Logger _logger = Logger();

  NotificationRepositoryImpl({
    required NotificationRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  Future<List<NotificationModel>> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      _logger.d('Fetching notifications (page: $page, limit: $limit)');
      final notifications = await _remoteDataSource.getNotifications(
        page: page,
        limit: limit,
      );
      _logger.d('Successfully fetched ${notifications.length} notifications');
      return notifications;
    } catch (e) {
      _logger.e('Error fetching notifications: $e');
      rethrow;
    }
  }

  @override
  Future<int> getUnreadCount() async {
    try {
      _logger.d('Fetching unread notification count');
      final count = await _remoteDataSource.getUnreadCount();
      _logger.d('Unread notification count: $count');
      return count;
    } catch (e) {
      _logger.e('Error fetching unread count: $e');
      rethrow;
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      _logger.d('Marking notification as read: $notificationId');
      await _remoteDataSource.markAsRead(notificationId);
      _logger.d('Successfully marked notification as read');
    } catch (e) {
      _logger.e('Error marking notification as read: $e');
      rethrow;
    }
  }

  @override
  Future<void> markAllAsRead() async {
    try {
      _logger.d('Marking all notifications as read');
      await _remoteDataSource.markAllAsRead();
      _logger.d('Successfully marked all notifications as read');
    } catch (e) {
      _logger.e('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    try {
      _logger.d('Deleting notification: $notificationId');
      await _remoteDataSource.deleteNotification(notificationId);
      _logger.d('Successfully deleted notification');
    } catch (e) {
      _logger.e('Error deleting notification: $e');
      rethrow;
    }
  }

  @override
  Future<void> clearAllNotifications() async {
    try {
      _logger.d('Clearing all notifications');
      await _remoteDataSource.clearAllNotifications();
      _logger.d('Successfully cleared all notifications');
    } catch (e) {
      _logger.e('Error clearing all notifications: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, bool>> getNotificationPreferences() async {
    try {
      _logger.d('Fetching notification preferences');
      final preferences = await _remoteDataSource.getNotificationPreferences();
      _logger.d('Successfully fetched notification preferences');
      return preferences;
    } catch (e) {
      _logger.e('Error fetching notification preferences: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateNotificationPreferences(
    Map<String, bool> preferences,
  ) async {
    try {
      _logger.d('Updating notification preferences');
      await _remoteDataSource.updateNotificationPreferences(preferences);
      _logger.d('Successfully updated notification preferences');
    } catch (e) {
      _logger.e('Error updating notification preferences: $e');
      rethrow;
    }
  }
}
