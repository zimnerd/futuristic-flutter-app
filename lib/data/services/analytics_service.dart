import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../core/utils/logger.dart';

/// Analytics event types
enum AnalyticsEventType {
  // User actions
  userRegistered,
  userLogin,
  userLogout,
  profileUpdated,

  // Messaging
  messageSent,
  messageReceived,
  conversationStarted,

  // Matching
  profileViewed,
  profileLiked,
  profilePassed,
  matchCreated,

  // Premium
  premiumViewed,
  subscriptionStarted,
  subscriptionCompleted,
  subscriptionCancelled,
  boostPurchased,
  boostUsed,

  // Social
  achievementUnlocked,
  leaderboardViewed,
  challengeCreated,
  challengeCompleted,

  // Engagement
  appOpened,
  appClosed,
  screenViewed,
  featureUsed,
  buttonClicked,

  // Errors
  errorOccurred,
  crashReported,
}

/// Analytics service for tracking user behavior and app performance
class AnalyticsService {
  static AnalyticsService? _instance;
  static AnalyticsService get instance => _instance ??= AnalyticsService._();
  AnalyticsService._();

  String? _authToken;
  String? _userId;
  final List<Map<String, dynamic>> _eventQueue = [];
  bool _isOnline = true;

  /// Set authentication token and user ID
  void setUser({required String authToken, required String userId}) {
    _authToken = authToken;
    _userId = userId;

    // Send any queued events
    _flushEventQueue();
  }

  /// Track an analytics event
  Future<void> trackEvent({
    required AnalyticsEventType eventType,
    Map<String, dynamic>? properties,
    Map<String, dynamic>? userProperties,
  }) async {
    final event = {
      'eventType': eventType.name,
      'properties': properties ?? {},
      'userProperties': userProperties ?? {},
      'timestamp': DateTime.now().toIso8601String(),
      'userId': _userId,
    };

    if (_isOnline && _authToken != null) {
      await _sendEvent(event);
    } else {
      _queueEvent(event);
    }
  }

  /// Track screen view
  Future<void> trackScreenView({
    required String screenName,
    Map<String, dynamic>? properties,
  }) async {
    await trackEvent(
      eventType: AnalyticsEventType.screenViewed,
      properties: {'screenName': screenName, ...?properties},
    );
  }

  /// Track button click
  Future<void> trackButtonClick({
    required String buttonName,
    required String screenName,
    Map<String, dynamic>? properties,
  }) async {
    await trackEvent(
      eventType: AnalyticsEventType.buttonClicked,
      properties: {
        'buttonName': buttonName,
        'screenName': screenName,
        ...?properties,
      },
    );
  }

  /// Track feature usage
  Future<void> trackFeatureUsage({
    required String featureName,
    Map<String, dynamic>? properties,
  }) async {
    await trackEvent(
      eventType: AnalyticsEventType.featureUsed,
      properties: {'featureName': featureName, ...?properties},
    );
  }

  /// Track user engagement session
  Future<void> trackEngagementSession({
    required Duration sessionDuration,
    required int screenViews,
    required int interactions,
  }) async {
    await trackEvent(
      eventType: AnalyticsEventType.appClosed,
      properties: {
        'sessionDuration': sessionDuration.inSeconds,
        'screenViews': screenViews,
        'interactions': interactions,
      },
    );
  }

  /// Track error occurrence
  Future<void> trackError({
    required String errorType,
    required String errorMessage,
    String? stackTrace,
    Map<String, dynamic>? context,
  }) async {
    await trackEvent(
      eventType: AnalyticsEventType.errorOccurred,
      properties: {
        'errorType': errorType,
        'errorMessage': errorMessage,
        'stackTrace': stackTrace,
        'context': context,
      },
    );
  }

  /// Track premium subscription events
  Future<void> trackPremiumEvent({
    required String action, // 'viewed', 'started', 'completed', 'cancelled'
    String? planId,
    double? amount,
    String? currency,
    Map<String, dynamic>? properties,
  }) async {
    AnalyticsEventType eventType;
    switch (action) {
      case 'viewed':
        eventType = AnalyticsEventType.premiumViewed;
        break;
      case 'started':
        eventType = AnalyticsEventType.subscriptionStarted;
        break;
      case 'completed':
        eventType = AnalyticsEventType.subscriptionCompleted;
        break;
      case 'cancelled':
        eventType = AnalyticsEventType.subscriptionCancelled;
        break;
      default:
        eventType = AnalyticsEventType.featureUsed;
    }

    await trackEvent(
      eventType: eventType,
      properties: {
        'action': action,
        'planId': planId,
        'amount': amount,
        'currency': currency,
        ...?properties,
      },
    );
  }

  /// Track matching events
  Future<void> trackMatchingEvent({
    required String action, // 'viewed', 'liked', 'passed', 'matched'
    required String targetUserId,
    Map<String, dynamic>? properties,
  }) async {
    AnalyticsEventType eventType;
    switch (action) {
      case 'viewed':
        eventType = AnalyticsEventType.profileViewed;
        break;
      case 'liked':
        eventType = AnalyticsEventType.profileLiked;
        break;
      case 'passed':
        eventType = AnalyticsEventType.profilePassed;
        break;
      case 'matched':
        eventType = AnalyticsEventType.matchCreated;
        break;
      default:
        eventType = AnalyticsEventType.featureUsed;
    }

    await trackEvent(
      eventType: eventType,
      properties: {
        'action': action,
        'targetUserId': targetUserId,
        ...?properties,
      },
    );
  }

  /// Track messaging events
  Future<void> trackMessagingEvent({
    required String action, // 'sent', 'received', 'conversation_started'
    String? conversationId,
    String? messageType,
    Map<String, dynamic>? properties,
  }) async {
    AnalyticsEventType eventType;
    switch (action) {
      case 'sent':
        eventType = AnalyticsEventType.messageSent;
        break;
      case 'received':
        eventType = AnalyticsEventType.messageReceived;
        break;
      case 'conversation_started':
        eventType = AnalyticsEventType.conversationStarted;
        break;
      default:
        eventType = AnalyticsEventType.featureUsed;
    }

    await trackEvent(
      eventType: eventType,
      properties: {
        'action': action,
        'conversationId': conversationId,
        'messageType': messageType,
        ...?properties,
      },
    );
  }

  /// Set user properties
  Future<void> setUserProperties(Map<String, dynamic> properties) async {
    if (_authToken == null || _userId == null) return;

    try {
      final response = await http.patch(
        Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.analytics}/user-properties',
        ),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({'userId': _userId, 'properties': properties}),
      );

      if (response.statusCode != 200) {
        AppLogger.warning(
          'Failed to set user properties: ${response.statusCode}',
        );
      }
    } catch (e) {
      AppLogger.error('Error setting user properties: $e');
    }
  }

  /// Get analytics insights for user
  Future<Map<String, dynamic>?> getUserInsights() async {
    if (_authToken == null || _userId == null) return null;

    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.analytics}/insights/$_userId',
        ),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['insights'] as Map<String, dynamic>;
      } else {
        AppLogger.warning(
          'Failed to get user insights: ${response.statusCode}',
        );
        return null;
      }
    } catch (e) {
      AppLogger.error('Error getting user insights: $e');
      return null;
    }
  }

  /// Send event to backend
  Future<void> _sendEvent(Map<String, dynamic> event) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.analytics}/events'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(event),
      );

      if (response.statusCode != 201) {
        AppLogger.warning(
          'Failed to send analytics event: ${response.statusCode}',
        );
        // Queue the event for retry
        _queueEvent(event);
      }
    } catch (e) {
      AppLogger.error('Error sending analytics event: $e');
      // Queue the event for retry
      _queueEvent(event);
    }
  }

  /// Queue event for later sending
  void _queueEvent(Map<String, dynamic> event) {
    _eventQueue.add(event);

    // Limit queue size to prevent memory issues
    if (_eventQueue.length > 100) {
      _eventQueue.removeAt(0);
    }
  }

  /// Flush queued events
  Future<void> _flushEventQueue() async {
    if (_eventQueue.isEmpty || _authToken == null) return;

    final eventsToSend = List<Map<String, dynamic>>.from(_eventQueue);
    _eventQueue.clear();

    for (final event in eventsToSend) {
      await _sendEvent(event);
    }
  }

  /// Set online/offline status
  void setOnlineStatus(bool isOnline) {
    _isOnline = isOnline;

    if (isOnline) {
      _flushEventQueue();
    }
  }

  /// Clear user data (on logout)
  void clearUserData() {
    _authToken = null;
    _userId = null;
    _eventQueue.clear();
  }
}
