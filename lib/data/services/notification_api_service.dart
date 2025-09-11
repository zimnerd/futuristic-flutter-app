import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../core/constants/api_constants.dart';
import '../../core/utils/logger.dart';
import '../models/notification.dart';

/// Service for notifications API integration with NestJS backend
class NotificationApiService {
  static NotificationApiService? _instance;
  static NotificationApiService get instance => _instance ??= NotificationApiService._();
  NotificationApiService._();

  io.Socket? _socket;
  String? _authToken;

  /// Set authentication token
  void setAuthToken(String token) {
    _authToken = token;
  }

  /// Initialize WebSocket connection for real-time notifications
  Future<void> initializeSocket(String authToken) async {
    _authToken = authToken;
    
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
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (unreadOnly != null) {
        queryParams['unreadOnly'] = unreadOnly.toString();
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.notifications}')
            .replace(queryParameters: queryParams),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['notifications'] as List)
            .map((json) => NotificationModel.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load notifications: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error fetching notifications: $e');
      rethrow;
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final response = await http.patch(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.notifications}/$notificationId/read'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark notification as read: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error marking notification as read: $e');
      rethrow;
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final response = await http.patch(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.notifications}/read-all'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark all notifications as read: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.notifications}/$notificationId'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete notification: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error deleting notification: $e');
      rethrow;
    }
  }

  /// Get notification preferences
  Future<Map<String, dynamic>> getNotificationPreferences() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.notifications}/preferences'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['preferences'] as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load notification preferences: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error fetching notification preferences: $e');
      rethrow;
    }
  }

  /// Update notification preferences
  Future<void> updateNotificationPreferences(Map<String, dynamic> preferences) async {
    try {
      final response = await http.patch(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.notifications}/preferences'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({'preferences': preferences}),
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update notification preferences');
      }
    } catch (e) {
      AppLogger.error('Error updating notification preferences: $e');
      rethrow;
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.notifications}/unread-count'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['count'] as int;
      } else {
        throw Exception('Failed to load unread count: ${response.statusCode}');
      }
    } catch (e) {
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
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.notifications}/send'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'userId': userId,
          'title': title,
          'body': body,
          'type': type,
          'data': data,
        }),
      );

      if (response.statusCode != 201) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to send notification');
      }
    } catch (e) {
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
  void listenForNotificationUpdates(Function(String notificationId, Map<String, dynamic> updates) onUpdate) {
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
