import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../core/network/api_client.dart';
import '../core/utils/logger.dart';

/// Firebase Cloud Messaging service for real-time push notifications
class FirebaseNotificationService {
  static FirebaseNotificationService? _instance;
  static FirebaseNotificationService get instance => _instance ??= FirebaseNotificationService._();
  FirebaseNotificationService._();

  FirebaseMessaging? _messaging;
  FlutterLocalNotificationsPlugin? _localNotifications;
  final ApiClient _apiClient = ApiClient.instance;
  String? _fcmToken;
  
  final StreamController<Map<String, dynamic>> _notificationStreamController = 
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onNotification => _notificationStreamController.stream;

  final StreamController<Map<String, dynamic>> _messageClickStreamController = 
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onMessageClick => _messageClickStreamController.stream;

  /// Initialize Firebase messaging and local notifications
  Future<void> initialize({String? authToken}) async {
    try {
      AppLogger.info('🔔 Initializing Firebase notifications...');
      
      // Get Firebase messaging instance (Firebase should already be initialized)
      _messaging = FirebaseMessaging.instance;
      
      // Request notification permissions
      await _requestNotificationPermissions();
      
      // Initialize local notifications
      await _initializeLocalNotifications();
      
      // Get FCM token
      _fcmToken = await _messaging?.getToken();
      AppLogger.info(
        '📱 FCM Token obtained: ${_fcmToken != null ? "${_fcmToken!.substring(0, 20)}..." : "null"}',
      );
      
      // Register token with backend if we have it
      if (_fcmToken != null) {
        AppLogger.info('🚀 Registering FCM token with backend...');
        await _registerTokenWithBackend(_fcmToken!);
      } else {
        AppLogger.warning('⚠️ Cannot register FCM token: token not available');
      }
      
      // Set up message handlers
      _setupMessageHandlers();
      
      AppLogger.info('✅ Firebase notifications initialized successfully');
    } catch (e) {
      AppLogger.error('❌ Failed to initialize Firebase notifications: $e');
    }
  }

  /// Request notification permissions
  Future<void> _requestNotificationPermissions() async {
    final settings = await _messaging?.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    AppLogger.info('Notification permission granted: ${settings?.authorizationStatus}');
  }

  /// Initialize local notifications for foreground messages
  Future<void> _initializeLocalNotifications() async {
    _localNotifications = FlutterLocalNotificationsPlugin();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications?.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationClick,
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'pulselink_messages',
        'PulseLink Messages',
        description: 'Chat messages and notifications',
        importance: Importance.high,
      );

      await _localNotifications
          ?.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  /// Set up Firebase message handlers
  void _setupMessageHandlers() {
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      AppLogger.info('Foreground message received: ${message.data}');
      _handleForegroundMessage(message);
    });

    // Handle message opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      AppLogger.info('Message opened from notification: ${message.data}');
      _handleMessageOpened(message);
    });

    // Listen for token refresh - Firebase will automatically retry
    _messaging?.onTokenRefresh.listen((String newToken) {
      AppLogger.info('🔄 FCM token refreshed: ${newToken.substring(0, 20)}...');
      _fcmToken = newToken;
      // Automatically register new token with backend
      _registerTokenWithBackend(newToken);
    });

    // Check for initial message when app is opened from terminated state
    _checkInitialMessage();
  }

  /// Handle foreground messages by showing local notification
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      // Show local notification for foreground messages
      await _showLocalNotification(message);
      
      // Add to stream for app to handle
      _notificationStreamController.add({
        'title': message.notification?.title ?? 'New Message',
        'body': message.notification?.body ?? '',
        'data': message.data,
        'type': message.data['type'] ?? 'message',
      });
    } catch (e) {
      AppLogger.error('Error handling foreground message: $e');
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'pulselink_messages',
        'PulseLink Messages',
        channelDescription: 'Chat messages and notifications',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications?.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        message.notification?.title ?? 'PulseLink',
        message.notification?.body ?? 'You have a new message',
        details,
        payload: json.encode(message.data),
      );
    } catch (e) {
      AppLogger.error('Error showing local notification: $e');
    }
  }

  /// Handle message opened from notification
  void _handleMessageOpened(RemoteMessage message) {
    _messageClickStreamController.add({
      'title': message.notification?.title ?? '',
      'body': message.notification?.body ?? '',
      'data': message.data,
      'type': message.data['type'] ?? 'message',
    });
  }

  /// Handle local notification click
  void _onLocalNotificationClick(NotificationResponse response) {
    try {
      if (response.payload != null) {
        final data = json.decode(response.payload!);
        _messageClickStreamController.add({
          'data': data,
          'type': data['type'] ?? 'message',
        });
      }
    } catch (e) {
      AppLogger.error('Error handling notification click: $e');
    }
  }

  /// Check for initial message when app is opened from terminated state
  Future<void> _checkInitialMessage() async {
    try {
      final initialMessage = await _messaging?.getInitialMessage();
      if (initialMessage != null) {
        AppLogger.info('App opened from terminated state via notification: ${initialMessage.data}');
        _handleMessageOpened(initialMessage);
      }
    } catch (e) {
      AppLogger.error('Error checking initial message: $e');
    }
  }

  /// Register FCM token with backend using ApiClient
  Future<void> _registerTokenWithBackend(String token) async {
    try {
      // Get current user ID
      final userId = await _apiClient.getCurrentUserId();
      
      if (userId == null) {
        AppLogger.error(
          '❌ Cannot register FCM token: user ID is null (user not authenticated)',
        );
        return;
      }

      // Get device ID
      final deviceId = await _getDeviceId();
      final platform = Platform.isIOS ? 'ios' : 'android';

      AppLogger.info(
        '📤 Registering FCM token for user: $userId, device: $deviceId',
      );

      // Use ApiClient which automatically handles /api/v1 prefix and auth token
      final response = await _apiClient.post(
        '/push-notifications/register-token',
        data: {
          'token': token,
          'userId': userId,
          'deviceId': deviceId,
          'platform': platform,
        },
      );

      if (response.data['success'] == true) {
        AppLogger.info('✅ FCM token registered successfully for user: $userId');
      } else {
        AppLogger.warning(
          '❌ Failed to register FCM token: ${response.data['message']}',
        );
      }
    } catch (e) {
      AppLogger.error('❌ Error registering FCM token: $e');
    }
  }

  /// Get device ID for registration
  Future<String> _getDeviceId() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'ios-unknown';
      }
      return 'unknown-device';
    } catch (e) {
      AppLogger.warning('Failed to get device ID: $e');
      return 'device-${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Re-register FCM token (call this on login)
  /// Non-blocking: If token unavailable, onTokenRefresh listener will handle it
  Future<void> reRegisterToken() async {
    try {
      // If we have a cached token, use it immediately
      if (_fcmToken != null) {
        AppLogger.info('🔄 Re-registering cached FCM token...');
        await _registerTokenWithBackend(_fcmToken!);
        return;
      }

      // Try to get token once (non-blocking)
      AppLogger.info('🔄 Attempting to fetch FCM token...');
      try {
        _fcmToken = await _messaging?.getToken().timeout(
          const Duration(seconds: 3),
          onTimeout: () => null,
        );

        if (_fcmToken != null) {
          AppLogger.info(
            '✅ FCM token obtained: ${_fcmToken!.substring(0, 20)}...',
          );
          await _registerTokenWithBackend(_fcmToken!);
        } else {
          AppLogger.info(
            '⏳ FCM token not ready yet - will auto-register via onTokenRefresh listener',
          );
        }
      } catch (e) {
        AppLogger.warning(
          '⚠️ Could not fetch FCM token: $e - will auto-register via onTokenRefresh listener',
        );
      }
    } catch (e) {
      AppLogger.error('❌ Error in reRegisterToken: $e');
    }
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging?.subscribeToTopic(topic);
      AppLogger.info('Subscribed to topic: $topic');
    } catch (e) {
      AppLogger.error('Error subscribing to topic $topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging?.unsubscribeFromTopic(topic);
      AppLogger.info('Unsubscribed from topic: $topic');
    } catch (e) {
      AppLogger.error('Error unsubscribing from topic $topic: $e');
    }
  }

  /// Get current FCM token
  Future<String?> getToken() async {
    try {
      return await _messaging?.getToken();
    } catch (e) {
      AppLogger.error('Error getting FCM token: $e');
      return null;
    }
  }

  /// Send test notification using ApiClient
  Future<void> sendTestNotification() async {
    try {
      final response = await _apiClient.post('/notifications/test');

      if (response.data['success'] == true) {
        AppLogger.info('✅ Test notification sent successfully');
      } else {
        AppLogger.warning(
          '❌ Failed to send test notification: ${response.data['message']}',
        );
      }
    } catch (e) {
      AppLogger.error('❌ Error sending test notification: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _notificationStreamController.close();
    _messageClickStreamController.close();
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialized in main.dart, so we don't need to initialize again
  // Only initialize if running in background isolate and Firebase is not initialized
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
  AppLogger.info('Background message received: ${message.data}');
}