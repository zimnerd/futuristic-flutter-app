# PulseLink Mobile Integration Guide

## Quick Start

### 1. Initialize Services in Your App

Add to your `main.dart`:

```dart
import 'package:pulselink/core/managers/app_service_manager.dart';
import 'package:pulselink/core/utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize app services
    await AppServiceManager.instance.initialize();
    AppLogger.info('App services initialized successfully');
  } catch (e) {
    AppLogger.error('Failed to initialize app services: $e');
  }
  
  runApp(MyApp());
}
```

### 2. Handle User Authentication

```dart
// On user login
await AppServiceManager.instance.updateAuth(
  authToken: loginResponse.token,
  userId: loginResponse.userId,
);

// On user logout
await AppServiceManager.instance.logout();
```

### 3. Send Messages

```dart
import 'package:pulselink/core/services/service_locator.dart';

// Send a text message
await ServiceLocator.instance.messaging.sendMessage(
  conversationId: conversationId,
  content: messageText,
  type: MessageType.text,
);

// Send an image
await ServiceLocator.instance.messaging.sendMessage(
  conversationId: conversationId,
  content: '',
  type: MessageType.image,
  mediaPath: imagePath,
);
```

### 4. Track Analytics Events

```dart
// Track screen view
await ServiceLocator.instance.analytics.trackScreenView(
  screenName: 'ProfileScreen',
  properties: {'userId': currentUserId},
);

// Track button click
await ServiceLocator.instance.analytics.trackButtonClick(
  buttonName: 'like_button',
  screenName: 'SwipeScreen',
);

// Track custom events
await ServiceLocator.instance.analytics.trackEvent(
  eventType: AnalyticsEventType.profileLiked,
  properties: {
    'targetUserId': targetUserId,
    'source': 'swipe_screen',
  },
);
```

### 5. Handle Premium Features

```dart
// Get available plans
final plans = await ServiceLocator.instance.premium.getAvailablePlans();

// Create subscription
final subscription = await ServiceLocator.instance.premium.createSubscription(
  planId: selectedPlan.id,
  paymentMethodId: paymentMethodId,
);

// Purchase boost
await ServiceLocator.instance.premium.purchaseBoost(
  type: BoostType.profileBoost,
  duration: const Duration(hours: 24),
);
```

### 6. Manage Notifications

```dart
// Update notification preferences
await ServiceLocator.instance.pushNotification.updateNotificationPreferences(
  enableMessages: true,
  enableMatches: true,
  enablePremium: false,
  enableSocial: true,
);

// Listen to notifications
ServiceLocator.instance.pushNotification.onNotification.listen(
  (notification) {
    // Handle notification
    _handleNotification(notification);
  },
);
```

### 7. Social Gaming Features

```dart
// Get user achievements
final achievements = await ServiceLocator.instance.socialGaming.getUserAchievements(userId);

// Get leaderboard
final leaderboard = await ServiceLocator.instance.socialGaming.getLeaderboard(
  type: LeaderboardType.matches,
  timeframe: TimeFrame.weekly,
);

// Create challenge
await ServiceLocator.instance.socialGaming.createChallenge(
  type: ChallengeType.messageCount,
  targetValue: 10,
  duration: const Duration(days: 7),
);
```

## BLoC Integration

### Create Event Classes

```dart
// analytics_events.dart
abstract class AnalyticsEvent {}

class TrackScreenViewEvent extends AnalyticsEvent {
  final String screenName;
  final Map<String, dynamic>? properties;
  
  TrackScreenViewEvent(this.screenName, {this.properties});
}

class TrackButtonClickEvent extends AnalyticsEvent {
  final String buttonName;
  final String screenName;
  final Map<String, dynamic>? properties;
  
  TrackButtonClickEvent(this.buttonName, this.screenName, {this.properties});
}
```

### Create BLoC

```dart
// analytics_bloc.dart
class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  AnalyticsBloc() : super(AnalyticsInitial()) {
    on<TrackScreenViewEvent>(_onTrackScreenView);
    on<TrackButtonClickEvent>(_onTrackButtonClick);
  }

  Future<void> _onTrackScreenView(
    TrackScreenViewEvent event,
    Emitter<AnalyticsState> emit,
  ) async {
    try {
      await ServiceLocator.instance.analytics.trackScreenView(
        screenName: event.screenName,
        properties: event.properties,
      );
    } catch (e) {
      AppLogger.error('Failed to track screen view: $e');
    }
  }

  Future<void> _onTrackButtonClick(
    TrackButtonClickEvent event,
    Emitter<AnalyticsState> emit,
  ) async {
    try {
      await ServiceLocator.instance.analytics.trackButtonClick(
        buttonName: event.buttonName,
        screenName: event.screenName,
        properties: event.properties,
      );
    } catch (e) {
      AppLogger.error('Failed to track button click: $e');
    }
  }
}
```

### Use in Widgets

```dart
class SwipeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Track screen view
    context.read<AnalyticsBloc>().add(
      TrackScreenViewEvent('SwipeScreen'),
    );

    return Scaffold(
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              // Track button click
              context.read<AnalyticsBloc>().add(
                TrackButtonClickEvent('like_button', 'SwipeScreen'),
              );
              
              // Handle like action
              _handleLike();
            },
            child: Text('Like'),
          ),
        ],
      ),
    );
  }
}
```

## Error Handling Best Practices

### Service-Level Error Handling

```dart
try {
  final result = await ServiceLocator.instance.messaging.sendMessage(
    conversationId: conversationId,
    content: content,
    type: MessageType.text,
  );
  
  // Handle success
  _handleMessageSent(result);
  
} catch (e) {
  // Log error
  AppLogger.error('Failed to send message: $e');
  
  // Show user-friendly error
  _showErrorSnackBar('Failed to send message. Please try again.');
  
  // Track error for analytics
  ServiceLocator.instance.analytics.trackError(
    errorType: 'message_send_error',
    errorMessage: e.toString(),
    context: {
      'conversationId': conversationId,
      'messageType': MessageType.text.name,
    },
  );
}
```

### Global Error Handler

```dart
// error_handler.dart
class GlobalErrorHandler {
  static void handleError(dynamic error, StackTrace? stackTrace) {
    // Log error
    AppLogger.error('Global error: $error', stackTrace);
    
    // Track error in analytics
    ServiceLocator.instance.analytics.trackError(
      errorType: 'global_error',
      errorMessage: error.toString(),
      stackTrace: stackTrace?.toString(),
    );
    
    // Show user notification if needed
    if (error is NetworkException) {
      _showNetworkError();
    } else if (error is AuthenticationException) {
      _handleAuthError();
    }
  }
}
```

## Real-time Updates

### WebSocket Event Handling

```dart
// Initialize WebSocket connections
await ServiceLocator.instance.messaging.initializeSocket(authToken);
await ServiceLocator.instance.notification.initializeSocket(authToken);

// Listen to real-time events
ServiceLocator.instance.messaging.onNewMessage.listen((message) {
  // Update UI with new message
  _updateConversation(message);
});

ServiceLocator.instance.messaging.onUserOnline.listen((userId) {
  // Update user status
  _updateUserStatus(userId, true);
});
```

## App Lifecycle Integration

```dart
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppServiceManager.instance.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        AppServiceManager.instance.onAppForeground();
        break;
      case AppLifecycleState.paused:
        AppServiceManager.instance.onAppBackground();
        break;
      case AppLifecycleState.detached:
        AppServiceManager.instance.onAppClose();
        break;
      default:
        break;
    }
  }
}
```

## Testing

### Mock Services for Testing

```dart
// test/mocks/mock_services.dart
class MockMessagingService extends Mock implements MessagingApiService {}
class MockAnalyticsService extends Mock implements AnalyticsService {}
class MockPremiumService extends Mock implements PremiumApiService {}

// In your tests
void main() {
  group('MessageBloc Tests', () {
    late MockMessagingService mockMessagingService;
    late MessageBloc messageBloc;

    setUp(() {
      mockMessagingService = MockMessagingService();
      messageBloc = MessageBloc(messagingService: mockMessagingService);
    });

    test('should send message successfully', () async {
      // Arrange
      when(mockMessagingService.sendMessage(any, any, any))
          .thenAnswer((_) async => mockMessage);

      // Act
      messageBloc.add(SendMessageEvent(content: 'Hello'));

      // Assert
      await expectLater(
        messageBloc.stream,
        emitsInOrder([
          MessageSending(),
          MessageSent(mockMessage),
        ]),
      );
    });
  });
}
```

## Production Deployment

### Environment Configuration

```dart
// config/environment.dart
class Environment {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.pulselink.com',
  );
  
  static const String websocketUrl = String.fromEnvironment(
    'WEBSOCKET_URL',
    defaultValue: 'wss://ws.pulselink.com',
  );
  
  static const bool enableAnalytics = bool.fromEnvironment(
    'ENABLE_ANALYTICS',
    defaultValue: true,
  );
}
```

### Performance Monitoring

```dart
// Monitor service health
final serviceHealth = AppServiceManager.instance.getServiceHealth();
if (!serviceHealth.values.every((isHealthy) => isHealthy)) {
  // Log service issues
  AppLogger.warning('Some services are unhealthy: $serviceHealth');
  
  // Track in analytics
  ServiceLocator.instance.analytics.trackError(
    errorType: 'service_health_issue',
    errorMessage: 'Services unhealthy',
    context: serviceHealth,
  );
}
```

This integration guide provides everything needed to implement the backend services in your PulseLink mobile app. All services are production-ready with comprehensive error handling, analytics tracking, and real-time capabilities.
