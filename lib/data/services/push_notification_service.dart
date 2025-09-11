import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../core/utils/logger.dart';

/// Push notification service for handling notifications
class PushNotificationService {
  static PushNotificationService? _instance;
  static PushNotificationService get instance => _instance ??= PushNotificationService._();
  PushNotificationService._();

  String? _authToken;
  String? _deviceToken;
  
  final StreamController<Map<String, dynamic>> _notificationStreamController = 
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onNotification => _notificationStreamController.stream;

  /// Initialize push notifications
  Future<void> initialize({String? authToken}) async {
    _authToken = authToken;
    
    try {
      // Generate a mock device token for now
      _deviceToken = 'device_${DateTime.now().millisecondsSinceEpoch}';
      
      if (_authToken != null) {
        await _registerTokenWithBackend(_deviceToken!);
      }
      
      AppLogger.info('Push notifications initialized successfully');
    } catch (e) {
      AppLogger.error('Failed to initialize push notifications: $e');
    }
  }

  /// Register device token with backend
  Future<void> _registerTokenWithBackend(String token) async {
    if (_authToken == null) return;
    
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.notifications}/register-token'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'deviceToken': token,
          'platform': 'mobile',
        }),
      );

      if (response.statusCode == 200) {
        AppLogger.info('Device token registered successfully');
      } else {
        AppLogger.warning('Failed to register device token: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error registering device token: $e');
    }
  }

  /// Send test notification
  Future<void> sendTestNotification() async {
    if (_authToken == null) return;
    
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.notifications}/test'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        AppLogger.info('Test notification sent successfully');
        // Simulate receiving the notification
        _simulateNotification({
          'type': 'test',
          'title': 'Test Notification',
          'body': 'This is a test notification from PulseLink',
        });
      } else {
        AppLogger.warning('Failed to send test notification: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error sending test notification: $e');
    }
  }

  /// Simulate receiving a notification (for testing)
  void _simulateNotification(Map<String, dynamic> notification) {
    _notificationStreamController.add(notification);
  }

  /// Update notification preferences
  Future<void> updateNotificationPreferences({
    required bool enableMessages,
    required bool enableMatches,
    required bool enablePremium,
    required bool enableSocial,
    bool? quietHours,
    int? quietStartHour,
    int? quietEndHour,
  }) async {
    if (_authToken == null) return;
    
    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.notifications}/preferences'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'enableMessages': enableMessages,
          'enableMatches': enableMatches,
          'enablePremium': enablePremium,
          'enableSocial': enableSocial,
          'quietHours': quietHours,
          'quietStartHour': quietStartHour,
          'quietEndHour': quietEndHour,
        }),
      );

      if (response.statusCode == 200) {
        AppLogger.info('Notification preferences updated successfully');
      } else {
        AppLogger.warning('Failed to update notification preferences: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error updating notification preferences: $e');
    }
  }

  /// Get notification preferences
  Future<Map<String, dynamic>?> getNotificationPreferences() async {
    if (_authToken == null) return null;
    
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
        AppLogger.warning('Failed to get notification preferences: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      AppLogger.error('Error getting notification preferences: $e');
      return null;
    }
  }

  /// Get notification history
  Future<List<Map<String, dynamic>>> getNotificationHistory({
    int page = 1,
    int limit = 20,
  }) async {
    if (_authToken == null) return [];
    
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.notifications}/history?page=$page&limit=$limit'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['notifications'] ?? []);
      } else {
        AppLogger.warning('Failed to get notification history: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      AppLogger.error('Error getting notification history: $e');
      return [];
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    if (_authToken == null) return;
    
    try {
      final response = await http.patch(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.notifications}/$notificationId/read'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        AppLogger.info('Notification marked as read: $notificationId');
      } else {
        AppLogger.warning('Failed to mark notification as read: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error marking notification as read: $e');
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    if (_authToken == null) return;
    
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.notifications}/$notificationId'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        AppLogger.info('Notification deleted: $notificationId');
      } else {
        AppLogger.warning('Failed to delete notification: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error deleting notification: $e');
    }
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    if (_authToken == null) return;
    
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.notifications}/subscribe'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'topic': topic,
        }),
      );

      if (response.statusCode == 200) {
        AppLogger.info('Subscribed to topic: $topic');
      } else {
        AppLogger.warning('Failed to subscribe to topic: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error subscribing to topic $topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    if (_authToken == null) return;
    
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.notifications}/unsubscribe'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'topic': topic,
        }),
      );

      if (response.statusCode == 200) {
        AppLogger.info('Unsubscribed from topic: $topic');
      } else {
        AppLogger.warning('Failed to unsubscribe from topic: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error unsubscribing from topic $topic: $e');
    }
  }

  /// Update auth token
  void updateAuthToken(String authToken) {
    _authToken = authToken;
    
    // Re-register device token with new auth
    if (_deviceToken != null) {
      _registerTokenWithBackend(_deviceToken!);
    }
  }

  /// Clear notifications and token on logout
  Future<void> clearNotifications() async {
    try {
      // Unregister token from backend
      if (_deviceToken != null && _authToken != null) {
        await _unregisterTokenFromBackend(_deviceToken!);
      }
      
      _authToken = null;
      _deviceToken = null;
      
      AppLogger.info('Notifications cleared successfully');
    } catch (e) {
      AppLogger.error('Error clearing notifications: $e');
    }
  }

  /// Unregister device token from backend
  Future<void> _unregisterTokenFromBackend(String token) async {
    if (_authToken == null) return;
    
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.notifications}/unregister-token'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'deviceToken': token,
        }),
      );

      if (response.statusCode == 200) {
        AppLogger.info('Device token unregistered successfully');
      } else {
        AppLogger.warning('Failed to unregister device token: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error unregistering device token: $e');
    }
  }

  /// Dispose service
  void dispose() {
    _notificationStreamController.close();
  }
}
