import 'package:logger/logger.dart';

import '../../models/notification_model.dart';
import '../../../core/network/api_client.dart';
import '../../exceptions/app_exceptions.dart';

/// Remote data source for notification-related API operations
abstract class NotificationRemoteDataSource {
  Future<List<NotificationModel>> getNotifications({
    int page = 1,
    int limit = 20,
  });
  Future<int> getUnreadCount();
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead();
  Future<void> deleteNotification(String notificationId);
  Future<void> clearAllNotifications();
  Future<Map<String, bool>> getNotificationPreferences();
  Future<void> updateNotificationPreferences(Map<String, bool> preferences);
}

/// Implementation of NotificationRemoteDataSource using API service
class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final ApiClient _apiService;
  final Logger _logger = Logger();

  NotificationRemoteDataSourceImpl(this._apiService);

  @override
  Future<List<NotificationModel>> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      _logger.i('Getting notifications (page: $page, limit: $limit)');

      final response = await _apiService.get(
        '/notifications',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> notificationsData = response.data['notifications'];
        return notificationsData
            .map((json) => NotificationModel.fromJson(json))
            .toList();
      } else {
        throw ApiException(
          'Failed to get notifications: ${response.statusMessage}',
        );
      }
    } catch (e) {
      _logger.e('Get notifications error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to get notifications: ${e.toString()}');
    }
  }

  @override
  Future<int> getUnreadCount() async {
    try {
      _logger.i('Getting unread notification count');

      final response = await _apiService.get('/notifications/unread-count');

      if (response.statusCode == 200) {
        return response.data['count'] as int;
      } else {
        throw ApiException(
          'Failed to get unread count: ${response.statusMessage}',
        );
      }
    } catch (e) {
      _logger.e('Get unread count error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to get unread count: ${e.toString()}');
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      _logger.i('Marking notification as read: $notificationId');

      final response = await _apiService.patch(
        '/notifications/$notificationId/read',
      );

      if (response.statusCode != 200) {
        throw ApiException(
          'Failed to mark notification as read: ${response.statusMessage}',
        );
      }
    } catch (e) {
      _logger.e('Mark notification as read error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to mark notification as read: ${e.toString()}');
    }
  }

  @override
  Future<void> markAllAsRead() async {
    try {
      _logger.i('Marking all notifications as read');

      final response = await _apiService.patch('/notifications/mark-all-read');

      if (response.statusCode != 200) {
        throw ApiException(
          'Failed to mark all notifications as read: ${response.statusMessage}',
        );
      }
    } catch (e) {
      _logger.e('Mark all notifications as read error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to mark all notifications as read: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    try {
      _logger.i('Deleting notification: $notificationId');

      final response = await _apiService.delete('/notifications/$notificationId');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ApiException(
          'Failed to delete notification: ${response.statusMessage}',
        );
      }
    } catch (e) {
      _logger.e('Delete notification error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to delete notification: ${e.toString()}');
    }
  }

  @override
  Future<void> clearAllNotifications() async {
    try {
      _logger.i('Clearing all notifications');

      final response = await _apiService.delete('/notifications');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ApiException(
          'Failed to clear all notifications: ${response.statusMessage}',
        );
      }
    } catch (e) {
      _logger.e('Clear all notifications error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to clear all notifications: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, bool>> getNotificationPreferences() async {
    try {
      _logger.i('Getting notification preferences');

      final response = await _apiService.get('/notifications/preferences');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        return data.map((key, value) => MapEntry(key, value as bool));
      } else {
        throw ApiException(
          'Failed to get notification preferences: ${response.statusMessage}',
        );
      }
    } catch (e) {
      _logger.e('Get notification preferences error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to get notification preferences: ${e.toString()}');
    }
  }

  @override
  Future<void> updateNotificationPreferences(Map<String, bool> preferences) async {
    try {
      _logger.i('Updating notification preferences');

      final response = await _apiService.patch(
        '/notifications/preferences',
        data: preferences,
      );

      if (response.statusCode != 200) {
        throw ApiException(
          'Failed to update notification preferences: ${response.statusMessage}',
        );
      }
    } catch (e) {
      _logger.e('Update notification preferences error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to update notification preferences: ${e.toString()}');
    }
  }
}