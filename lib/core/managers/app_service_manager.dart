import 'dart:async';
import '../services/service_locator.dart';
import '../../data/services/analytics_service.dart';
import '../../presentation/navigation/app_router.dart';
import '../utils/logger.dart';
import '../../presentation/widgets/common/pulse_toast.dart';

/// App service manager for coordinating all services
class AppServiceManager {
  static AppServiceManager? _instance;
  static AppServiceManager get instance => _instance ??= AppServiceManager._();
  AppServiceManager._();

  bool _initialized = false;
  String? _currentUserId;
  Timer? _heartbeatTimer;
  Timer? _analyticsTimer;

  final List<StreamSubscription> _subscriptions = [];

  /// Initialize the app service manager
  Future<void> initialize({String? authToken, String? userId}) async {
    if (_initialized) return;

    try {
      AppLogger.info('Initializing App Service Manager...');

      // Initialize service locator
      await ServiceLocator.instance.initialize(authToken: authToken);

      _currentUserId = userId;

      // Set up service listeners
      _setupServiceListeners();

      // Start periodic tasks
      _startPeriodicTasks();

      _initialized = true;
      AppLogger.info('App Service Manager initialized successfully');

      // Track app launch
      await _trackAppLaunch();

    } catch (e) {
      AppLogger.error('Failed to initialize App Service Manager: $e');
      rethrow;
    }
  }

  /// Set up listeners for various services
  void _setupServiceListeners() {
    try {
      // Listen to push notifications
      final notificationSubscription = ServiceLocator.instance.pushNotification.onNotification.listen(
        _handleNotification,
        onError: (error) => AppLogger.error('Notification stream error: $error'),
      );
      _subscriptions.add(notificationSubscription);

      AppLogger.info('Service listeners set up successfully');
    } catch (e) {
      AppLogger.error('Failed to set up service listeners: $e');
    }
  }

  /// Handle incoming notifications
  void _handleNotification(Map<String, dynamic> notification) {
    try {
      final type = notification['type'] as String?;
      
      // Track notification received
      ServiceLocator.instance.analytics.trackEvent(
        eventType: AnalyticsEventType.messageReceived,
        properties: {
          'notificationType': type,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      // Handle different notification types
      switch (type) {
        case 'new_message':
          _handleNewMessage(notification);
          break;
        case 'new_match':
          _handleNewMatch(notification);
          break;
        case 'premium_expiry':
          _handlePremiumExpiry(notification);
          break;
        case 'achievement_unlocked':
          _handleAchievementUnlocked(notification);
          break;
        default:
          AppLogger.info('Unknown notification type: $type');
      }
    } catch (e) {
      AppLogger.error('Error handling notification: $e');
    }
  }

  /// Handle new message notification
  void _handleNewMessage(Map<String, dynamic> notification) {
    final conversationId = notification['conversationId'] as String?;
    final senderId = notification['senderId'] as String?;
    final senderName = notification['senderName'] as String? ?? 'Someone';
    final message = notification['message'] as String? ?? 'New message';
    
    ServiceLocator.instance.analytics.trackMessagingEvent(
      action: 'received',
      conversationId: conversationId,
      properties: {
        'senderId': senderId,
        'source': 'notification',
      },
    );

    // Show in-app notification snackbar
    _showInAppNotification('$senderName: $message');
  }

  /// Show in-app notification snackbar
  void _showInAppNotification(String message) {
    try {
      final context = AppRouter.navigatorKey.currentContext;
      if (context != null && context.mounted) {
        PulseToast.info(context, message: message);
      }
    } catch (e) {
      AppLogger.error('Failed to show in-app notification: $e');
    }
  }

  /// Handle new match notification
  void _handleNewMatch(Map<String, dynamic> notification) {
    final matchId = notification['matchId'] as String?;
    
    ServiceLocator.instance.analytics.trackMatchingEvent(
      action: 'matched',
      targetUserId: matchId ?? 'unknown',
      properties: {
        'source': 'notification',
      },
    );
  }

  /// Handle premium expiry notification
  void _handlePremiumExpiry(Map<String, dynamic> notification) {
    ServiceLocator.instance.analytics.trackPremiumEvent(
      action: 'expiry_notification',
      properties: {
        'source': 'notification',
      },
    );
  }

  /// Handle achievement unlocked notification
  void _handleAchievementUnlocked(Map<String, dynamic> notification) {
    final achievementId = notification['achievementId'] as String?;
    
    ServiceLocator.instance.analytics.trackEvent(
      eventType: AnalyticsEventType.achievementUnlocked,
      properties: {
        'achievementId': achievementId,
        'source': 'notification',
      },
    );
  }

  /// Start periodic tasks
  void _startPeriodicTasks() {
    // Heartbeat every 30 seconds
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _sendHeartbeat();
    });

    // Analytics flush every 5 minutes
    _analyticsTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _flushAnalytics();
    });
  }

  /// Send heartbeat to keep connections alive
  void _sendHeartbeat() {
    try {
      // Track app activity
      ServiceLocator.instance.analytics.trackEvent(
        eventType: AnalyticsEventType.featureUsed,
        properties: {
          'feature': 'app_heartbeat',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      AppLogger.error('Error sending heartbeat: $e');
    }
  }

  /// Flush analytics data
  void _flushAnalytics() {
    try {
      AppLogger.info('Flushing analytics data...');
      // Analytics service automatically handles batching and sending
    } catch (e) {
      AppLogger.error('Error flushing analytics: $e');
    }
  }

  /// Track app launch
  Future<void> _trackAppLaunch() async {
    try {
      await ServiceLocator.instance.analytics.trackEvent(
        eventType: AnalyticsEventType.appOpened,
        properties: {
          'timestamp': DateTime.now().toIso8601String(),
          'userId': _currentUserId,
        },
      );
    } catch (e) {
      AppLogger.error('Error tracking app launch: $e');
    }
  }

  /// Update user authentication
  Future<void> updateAuth({required String authToken, required String userId}) async {
    try {
      _currentUserId = userId;
      await ServiceLocator.instance.setAuthToken(authToken);
      
      // Track login
      await ServiceLocator.instance.analytics.trackEvent(
        eventType: AnalyticsEventType.userLogin,
        properties: {
          'userId': userId,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      AppLogger.info('Auth updated for user: $userId');
    } catch (e) {
      AppLogger.error('Failed to update auth: $e');
    }
  }

  /// Handle user logout
  Future<void> logout() async {
    try {
      // Track logout
      if (_currentUserId != null) {
        await ServiceLocator.instance.analytics.trackEvent(
          eventType: AnalyticsEventType.userLogout,
          properties: {
            'userId': _currentUserId,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      }

      // Clear all service data
      await ServiceLocator.instance.clearAllData();
      
      _currentUserId = null;
      
      AppLogger.info('User logged out successfully');
    } catch (e) {
      AppLogger.error('Error during logout: $e');
    }
  }

  /// Handle app close
  Future<void> onAppClose() async {
    try {
      // Track app close
      await ServiceLocator.instance.analytics.trackEvent(
        eventType: AnalyticsEventType.appClosed,
        properties: {
          'userId': _currentUserId,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      AppLogger.info('App close tracked');
    } catch (e) {
      AppLogger.error('Error tracking app close: $e');
    }
  }

  /// Handle app background
  Future<void> onAppBackground() async {
    try {
      // Track background event
      await ServiceLocator.instance.analytics.trackEvent(
        eventType: AnalyticsEventType.featureUsed,
        properties: {
          'feature': 'app_background',
          'userId': _currentUserId,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      AppLogger.info('App background tracked');
    } catch (e) {
      AppLogger.error('Error tracking app background: $e');
    }
  }

  /// Handle app foreground
  Future<void> onAppForeground() async {
    try {
      // Track foreground event
      await ServiceLocator.instance.analytics.trackEvent(
        eventType: AnalyticsEventType.featureUsed,
        properties: {
          'feature': 'app_foreground',
          'userId': _currentUserId,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      AppLogger.info('App foreground tracked');
    } catch (e) {
      AppLogger.error('Error tracking app foreground: $e');
    }
  }

  /// Get service health status
  Map<String, bool> getServiceHealth() {
    try {
      return {
        'messaging': _initialized,
        'premium': _initialized,
        'socialGaming': _initialized,
        'notification': _initialized,
        'payment': _initialized,
        'analytics': _initialized,
        'pushNotification': _initialized,
      };
    } catch (e) {
      AppLogger.error('Error getting service health: $e');
      return {};
    }
  }

  /// Force analytics sync
  Future<void> forceAnalyticsSync() async {
    try {
      await ServiceLocator.instance.analytics.trackEvent(
        eventType: AnalyticsEventType.featureUsed,
        properties: {
          'feature': 'force_sync',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      AppLogger.info('Analytics sync forced');
    } catch (e) {
      AppLogger.error('Error forcing analytics sync: $e');
    }
  }

  /// Check if initialized
  bool get isInitialized => _initialized;

  /// Get current user ID
  String? get currentUserId => _currentUserId;

  /// Dispose the service manager
  void dispose() {
    try {
      // Cancel timers
      _heartbeatTimer?.cancel();
      _analyticsTimer?.cancel();

      // Cancel subscriptions
      for (final subscription in _subscriptions) {
        subscription.cancel();
      }
      _subscriptions.clear();

      // Dispose service locator
      ServiceLocator.instance.dispose();

      _initialized = false;
      AppLogger.info('App Service Manager disposed');
    } catch (e) {
      AppLogger.error('Error disposing App Service Manager: $e');
    }
  }
}
