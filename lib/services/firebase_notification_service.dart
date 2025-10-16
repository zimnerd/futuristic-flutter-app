import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../core/network/api_client.dart';
import '../core/utils/logger.dart';
import '../core/services/call_notification_service.dart';
import '../presentation/navigation/app_router.dart';

/// Firebase Cloud Messaging service for real-time push notifications
class FirebaseNotificationService {
  static FirebaseNotificationService? _instance;
  static FirebaseNotificationService get instance => _instance ??= FirebaseNotificationService._();
  FirebaseNotificationService._();

  FirebaseMessaging? _messaging;
  FlutterLocalNotificationsPlugin? _localNotifications;
  final ApiClient _apiClient = ApiClient.instance;
  String? _fcmToken;
  
  // Track active call notifications for missed call handling
  final Map<int, Timer> _activeCallTimers = {};
  
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

    // Create notification channels for Android
    if (Platform.isAndroid) {
      final androidPlugin = _localNotifications
          ?.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidPlugin != null) {
        // Regular messages channel
        const messagesChannel = AndroidNotificationChannel(
          'pulselink_messages',
          'PulseLink Messages',
          description: 'Chat messages and notifications',
          importance: Importance.high,
        );

        // High-priority channel for incoming calls with ringtone
        const callsChannel = AndroidNotificationChannel(
          'incoming_calls',
          'Incoming Calls',
          description: 'Notifications for incoming audio and video calls',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          showBadge: true,
        );

        await androidPlugin.createNotificationChannel(messagesChannel);
        await androidPlugin.createNotificationChannel(callsChannel);

        AppLogger.info('✅ Notification channels created');
      }
    }
  }

  /// Set up Firebase message handlers
  void _setupMessageHandlers() {
    // NOTE: Background message handler is registered in main.dart
    
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
      final data = message.data;

      // Check if this is an incoming call notification
      if (data['type'] == 'incoming_call') {
        AppLogger.info('📞 Incoming call notification received');
        
        // Use CallNotificationService for native call UI (CallKit/full-screen intent)
        await CallNotificationService.instance.handleIncomingCallPush(data);

        // Also show fallback notification for older Android versions
        await _showIncomingCallNotification(message);
      } else {
        // Show regular local notification for foreground messages
        await _showLocalNotification(message);
      }
      
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

  /// Show high-priority incoming call notification with ringtone
  Future<void> _showIncomingCallNotification(RemoteMessage message) async {
    try {
      final data = message.data;
      final callType = data['callType'] ?? 'AUDIO';
      final callerName = data['callerName'] ?? 'Unknown';
      final callId = data['callId'] ?? '';

      // Android notification with full-screen intent and action buttons
      // WhatsApp-style persistent notification with looping ringtone
      final androidDetails = AndroidNotificationDetails(
        'incoming_calls',
        'Incoming Calls',
        channelDescription: 'Incoming audio and video calls',
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.call,
        fullScreenIntent: true, // Show full screen even when locked
        playSound: true,
        sound: const RawResourceAndroidNotificationSound(
          'ringtone',
        ), // Custom ringtone (loops automatically)
        enableVibration: true,
        vibrationPattern: Int64List.fromList([
          0,
          1000,
          500,
          1000,
        ]), // Custom vibration pattern that loops
        ongoing: true, // Cannot be dismissed by swiping (WhatsApp-style)
        autoCancel: false, // Don't auto-dismiss until answered/declined
        timeoutAfter: 60000, // 60 seconds timeout (like WhatsApp)
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            'accept_call',
            'Accept',
            showsUserInterface: true,
            cancelNotification: false,
          ),
          AndroidNotificationAction(
            'decline_call',
            'Decline',
            cancelNotification: true,
          ),
        ],
      );

      // iOS notification with critical alert level
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.critical,
        categoryIdentifier: 'INCOMING_CALL',
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Use call ID as notification ID for uniqueness
      final notificationId = callId.hashCode.abs();

      await _localNotifications?.show(
        notificationId,
        '$callType Call',
        '$callerName is calling...',
        details,
        payload: json.encode(data),
      );

      AppLogger.info(
        '✅ Incoming call notification displayed: $callType from $callerName',
      );

      // Schedule missed call notification after 60 seconds if not answered
      _scheduleMissedCallNotification(data, notificationId);
    } catch (e) {
      AppLogger.error('❌ Error showing incoming call notification: $e');
    }
  }

  /// Schedule a missed call notification if the call is not answered within timeout
  /// (WhatsApp-style missed call notification)
  void _scheduleMissedCallNotification(
    Map<String, dynamic> callData,
    int activeNotificationId,
  ) {
    // Cancel any existing timer for this notification ID
    _activeCallTimers[activeNotificationId]?.cancel();

    // Create new timer for 60 seconds (like WhatsApp)
    _activeCallTimers[activeNotificationId] = Timer(
      const Duration(seconds: 60),
      () async {
        try {
          // Check if the original notification is still active
          // If it is, the call was not answered - show missed call notification
          final activeNotifications = await _localNotifications
              ?.getActiveNotifications();

          final isStillActive =
              activeNotifications?.any(
                (notification) => notification.id == activeNotificationId,
              ) ??
              false;

          if (isStillActive) {
            // Call was not answered - cancel ongoing notification and show missed call
            await _localNotifications?.cancel(activeNotificationId);
            await _showMissedCallNotification(callData);

            AppLogger.info(
              '📵 Call not answered - showing missed call notification',
            );
          }

          // Clean up timer
          _activeCallTimers.remove(activeNotificationId);
        } catch (e) {
          AppLogger.error('❌ Error handling missed call notification: $e');
        }
      },
    );
  }

  /// Cancel the missed call timer when user answers or declines
  void _cancelMissedCallTimer(int notificationId) {
    _activeCallTimers[notificationId]?.cancel();
    _activeCallTimers.remove(notificationId);
    AppLogger.info(
      '⏹️ Cancelled missed call timer for notification $notificationId',
    );
  }

  /// Show persistent missed call notification (like WhatsApp)
  Future<void> _showMissedCallNotification(
    Map<String, dynamic> callData,
  ) async {
    try {
      final callerName = callData['callerName'] ?? 'Unknown';
      final callType = callData['callType'] ?? 'AUDIO';
      final callId = callData['callId'] ?? '';

      // Regular notification (not full-screen) for missed calls
      const androidDetails = AndroidNotificationDetails(
        'pulselink_messages',
        'PulseLink Messages',
        channelDescription: 'Missed calls and messages',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        styleInformation: BigTextStyleInformation(
          'Tap to call back',
          htmlFormatBigText: false,
        ),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: false, // No sound for missed calls
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Use different notification ID for missed call
      final missedCallId = '${callId}_missed'.hashCode.abs();

      await _localNotifications?.show(
        missedCallId,
        'Missed $callType Call',
        '$callerName tried to call you',
        details,
        payload: json.encode({
          ...callData,
          'type': 'missed_call',
          'isMissed': true,
        }),
      );

      AppLogger.info('✅ Missed call notification displayed: $callerName');
    } catch (e) {
      AppLogger.error('❌ Error showing missed call notification: $e');
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
      final actionId = response.actionId;
      
      if (response.payload != null) {
        final data = json.decode(response.payload!);
        final type = data['type'] ?? 'message';

        // Handle incoming call actions
        if (type == 'incoming_call') {
          final callId = data['callId'] ?? '';
          final notificationId = callId.hashCode.abs();

          // Cancel missed call timer since user interacted with notification
          _cancelMissedCallTimer(notificationId);

          if (actionId == 'accept_call') {
            AppLogger.info('✅ User accepted call');
            _navigateToCallScreen(data, isAccepted: true);
          } else if (actionId == 'decline_call') {
            AppLogger.info('❌ User declined call');
            _declineCall(data['callId']);
          } else if (actionId == null) {
            // User tapped notification body (not action button)
            AppLogger.info('📱 User tapped call notification');
            _navigateToCallScreen(data, isAccepted: false);
          }
        } else {
          // Handle regular notification clicks
          _messageClickStreamController.add({'data': data, 'type': type});
        }
      }
    } catch (e) {
      AppLogger.error('Error handling notification click: $e');
    }
  }

  /// Navigate to appropriate call screen based on call type
  void _navigateToCallScreen(
    Map<String, dynamic> data, {
    required bool isAccepted,
  }) {
    try {
      final callType = data['callType'] ?? 'AUDIO';
      final callId = data['callId'] ?? '';
      final callerId = data['callerId'] ?? '';
      final callerName = data['callerName'] ?? 'Unknown';
      final callerPhoto = data['callerPhoto'] ?? '';

      // Get navigator from AppRouter
      final navigator = AppRouter.navigatorKey.currentState;
      if (navigator == null) {
        AppLogger.error('❌ Navigator not available');
        return;
      }

      if (callType == 'VIDEO') {
        navigator.pushNamed(
          '/video-call',
          arguments: {
            'callId': callId,
            'remoteUserId': callerId,
            'remoteUserName': callerName,
            'remoteUserPhoto': callerPhoto,
            'isIncoming': true,
            'isAccepted': isAccepted,
          },
        );
      } else {
        navigator.pushNamed(
          '/audio-call',
          arguments: {
            'callId': callId,
            'remoteUserId': callerId,
            'remoteUserName': callerName,
            'remoteUserPhoto': callerPhoto,
            'isIncoming': true,
            'isAccepted': isAccepted,
          },
        );
      }

      AppLogger.info('✅ Navigated to $callType call screen');
    } catch (e) {
      AppLogger.error('❌ Error navigating to call screen: $e');
    }
  }

  /// Decline incoming call
  Future<void> _declineCall(String callId) async {
    try {
      // Call backend API to decline the call
      await _apiClient.post('/calls/$callId/decline');
      AppLogger.info('✅ Call declined: $callId');
    } catch (e) {
      AppLogger.error('❌ Error declining call: $e');
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
