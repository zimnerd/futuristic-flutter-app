import '../models/notification_model.dart';

/// Abstract repository for notification operations
abstract class NotificationRepository {
  /// Get notifications for the current user
  Future<List<NotificationModel>> getNotifications({
    int page = 1,
    int limit = 20,
  });

  /// Get unread notification count
  Future<int> getUnreadCount();

  /// Mark notification as read
  Future<void> markAsRead(String notificationId);

  /// Mark all notifications as read
  Future<void> markAllAsRead();

  /// Delete a notification
  Future<void> deleteNotification(String notificationId);

  /// Clear all notifications
  Future<void> clearAllNotifications();

  /// Get notification preferences
  Future<Map<String, bool>> getNotificationPreferences();

  /// Update notification preferences
  Future<void> updateNotificationPreferences(Map<String, bool> preferences);
}
