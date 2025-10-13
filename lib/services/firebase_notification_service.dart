import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../core/utils/logger.dart';
import '../data/services/token_service.dart';

/// Firebase Cloud Messaging service for real-time push notifications
class FirebaseNotificationService {
  static FirebaseNotificationService? _instance;
  static FirebaseNotificationService get instance => _instance ??= FirebaseNotificationService._();
  FirebaseNotificationService._();

  FirebaseMessaging? _messaging;
  FlutterLocalNotificationsPlugin? _localNotifications;
  String? _authToken;
  String? _fcmToken;
  
  final StreamController<Map<String, dynamic>> _notificationStreamController = 
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onNotification => _notificationStreamController.stream;

  final StreamController<Map<String, dynamic>> _messageClickStreamController = 
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onMessageClick => _messageClickStreamController.stream;

  /// Initialize Firebase messaging and local notifications
  Future<void> initialize({String? authToken}) async {
    _authToken = authToken;
    
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
      
      // Register token with backend
      if (_fcmToken != null && _authToken != null) {
        AppLogger.info('🚀 Registering FCM token with backend...');
        await _registerTokenWithBackend(_fcmToken!);
      } else {
        AppLogger.warning(
          '⚠️ Cannot register FCM token: token=${_fcmToken != null}, authToken=${_authToken != null}',
        );
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

  /// Register FCM token with backend
  Future<void> _registerTokenWithBackend(String token) async {
    if (_authToken == null) return;
    
    try {
      // Get actual user ID from token or stored user data
      String? userId;
      try {
        final tokenService = TokenService();
        final userData = await tokenService.getUserData();
        if (userData != null && userData.containsKey('id')) {
          userId = userData['id']?.toString();
        }

        // Fallback to extracting from access token
        if (userId == null) {
          final accessToken = await tokenService.getAccessToken();
          if (accessToken != null) {
            userId = tokenService.extractUserIdFromToken(accessToken);
          }
        }
      } catch (e) {
        AppLogger.error('Failed to get user ID: $e');
      }

      if (userId == null) {
        AppLogger.error('Cannot register FCM token: user ID is null');
        return;
      }

      AppLogger.info('Registering FCM token for user: $userId');
      
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/push-notifications/register-token'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'token': token,
          'userId': userId,
          'platform': Platform.isIOS ? 'ios' : 'android',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        AppLogger.info(
          '✅ FCM token registered successfully with backend for user: $userId',
        );
      } else {
        AppLogger.warning(
          '❌ Failed to register FCM token: ${response.statusCode}, Body: ${response.body}',
        );
      }
    } catch (e) {
      AppLogger.error('❌ Error registering FCM token: $e');
    }
  }

  /// Update auth token and re-register
  Future<void> updateAuthToken(String? token) async {
    _authToken = token;
    if (token != null && _fcmToken != null) {
      await _registerTokenWithBackend(_fcmToken!);
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

  /// Send test notification
  Future<void> sendTestNotification() async {
    if (_authToken == null) return;
    
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/notifications/test'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        AppLogger.info('Test notification sent successfully');
      } else {
        AppLogger.warning('Failed to send test notification: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error sending test notification: $e');
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
  await Firebase.initializeApp();
  AppLogger.info('Background message received: ${message.data}');
}