import 'package:dio/dio.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/logger.dart';
import '../models/notification.dart';

/// Service for notifications API integration with NestJS backend
class NotificationApiService {
  static NotificationApiService? _instance;
  static NotificationApiService get instance =>
      _instance ??= NotificationApiService._();
  NotificationApiService._();

  final ApiClient _apiClient = ApiClient.instance;
  io.Socket? _socket;

  /// Set authentication token
  void setAuthToken(String token) {
    // ApiClient handles authentication internally
  }

  /// Initialize WebSocket connection for real-time notifications
  Future<void> initializeSocket(String authToken) async {

    try {
      _socket = io.io(
        ApiConstants.websocketUrl,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .setAuth({'token': authToken})
            .enableAutoConnect()
            .build(),
      );

      _socket!.connect();

      _socket!.onConnect((_) {
        AppLogger.info('Notifications WebSocket connected');
      });

      _socket!.onConnectError((error) {
        AppLogger.error('Notifications WebSocket connection error: $error');
      });

      _socket!.onDisconnect((_) {
        AppLogger.info('Notifications WebSocket disconnected');
      });
    } catch (e) {
      AppLogger.error('Failed to initialize notifications socket: $e');
      rethrow;
    }
  }

  /// Get user notifications
  Future<List<NotificationModel>> getNotifications({
    int page = 1,
    int limit = 20,
    bool? unreadOnly,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'limit': limit,
      };

      if (unreadOnly != null) {
        queryParams['unreadOnly'] = unreadOnly;
      }

      final response = await _apiClient.get(
        ApiConstants.notifications,
        queryParameters: queryParams,
      );

      final data = response.data as Map<String, dynamic>;
      return (data['notifications'] as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();
    } on DioException catch (e) {
      AppLogger.error('Error fetching notifications: $e');
      rethrow;
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _apiClient.patch(
        '${ApiConstants.notifications}/$notificationId/read',
      );
    } on DioException catch (e) {
      AppLogger.error('Error marking notification as read: $e');
      rethrow;
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      await _apiClient.patch('${ApiConstants.notifications}/read-all',
      );
    } on DioException catch (e) {
      AppLogger.error('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _apiClient.delete('${ApiConstants.notifications}/$notificationId',
      );
    } on DioException catch (e) {
      AppLogger.error('Error deleting notification: $e');
      rethrow;
    }
  }

  /// Get notification preferences
  Future<Map<String, dynamic>> getNotificationPreferences() async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.notifications}/preferences',
      );

      final data = response.data as Map<String, dynamic>;
      return data['preferences'] as Map<String, dynamic>;
    } on DioException catch (e) {
      AppLogger.error('Error fetching notification preferences: $e');
      rethrow;
    }
  }

  /// Update notification preferences
  Future<void> updateNotificationPreferences(
    Map<String, dynamic> preferences,
  ) async {
    try {
      await _apiClient.patch(
        '${ApiConstants.notifications}/preferences',
        data: {'preferences': preferences},
      );
    } on DioException catch (e) {
      AppLogger.error('Error updating notification preferences: $e');
      rethrow;
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount() async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.notifications}/unread-count',
      );

      final data = response.data as Map<String, dynamic>;
      return data['count'] as int;
    } on DioException catch (e) {
      AppLogger.error('Error fetching unread count: $e');
      rethrow;
    }
  }

  /// Send notification (for admin/system use)
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    String? type,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _apiClient.post(
        '${ApiConstants.notifications}/send',
        data: {
          'userId': userId,
          'title': title,
          'body': body,
          'type': type,
          'data': data,
        },
      );
    } on DioException catch (e) {
      AppLogger.error('Error sending notification: $e');
      rethrow;
    }
  }

  /// Listen for real-time notifications
  void listenForNotifications(Function(NotificationModel) onNotification) {
    _socket?.on('new_notification', (data) {
      try {
        final notification = NotificationModel.fromJson(data);
        onNotification(notification);
      } catch (e) {
        AppLogger.error('Error parsing incoming notification: $e');
      }
    });
  }

  /// Listen for notification updates (read status, etc.)
  void listenForNotificationUpdates(
    Function(String notificationId, Map<String, dynamic> updates) onUpdate,
  ) {
    _socket?.on('notification_updated', (data) {
      try {
        onUpdate(
          data['notificationId'] as String,
          data['updates'] as Map<String, dynamic>,
        );
      } catch (e) {
        AppLogger.error('Error parsing notification update: $e');
      }
    });
  }

  /// Listen for unread count updates
  void listenForUnreadCountUpdates(Function(int count) onCountUpdate) {
    _socket?.on('unread_count_updated', (data) {
      try {
        onCountUpdate(data['count'] as int);
      } catch (e) {
        AppLogger.error('Error parsing unread count update: $e');
      }
    });
  }

  /// Disconnect WebSocket
  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }

  /// Check if WebSocket is connected
  bool get isConnected => _socket?.connected == true;
}
