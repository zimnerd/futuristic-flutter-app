import '../../data/services/analytics_service.dart';
import '../../data/services/messaging_service.dart';
import '../../data/services/notification_api_service.dart';
import '../../data/services/payment_service.dart';
import '../../data/services/premium_api_service.dart';
import '../../data/services/push_notification_service.dart';
import '../../data/services/social_gaming_api_service.dart';
import '../../data/services/token_service.dart';
import '../../data/services/matching_service.dart';
import '../network/api_client.dart';
import '../network/unified_api_client.dart';
import '../utils/logger.dart';

/// Service locator for managing app services
class ServiceLocator {
  static ServiceLocator? _instance;
  static ServiceLocator get instance => _instance ??= ServiceLocator._();
  ServiceLocator._();

  bool _initialized = false;

  // Services
  UnifiedApiClient? _unifiedApiClient;
  ApiClient? _apiClient;
  MatchingService? _matchingService;
  MessagingService? _messagingService;
  PremiumApiService? _premiumService;
  SocialGamingApiService? _socialGamingService;
  NotificationApiService? _notificationService;
  PaymentService? _paymentService;
  AnalyticsService? _analyticsService;
  PushNotificationService? _pushNotificationService;
  TokenService? _tokenService;

  /// Initialize all services
  Future<void> initialize({String? authToken}) async {
    if (_initialized) return;

    try {
      AppLogger.info('Initializing services...');

      // Initialize unified API client (new primary client)
      _unifiedApiClient = UnifiedApiClient.instance;

      // Initialize legacy API client for backward compatibility
      _apiClient = ApiClient();
      
      // Initialize core services
      _matchingService = MatchingService(apiClient: _apiClient!);
      _messagingService = MessagingService(apiClient: _unifiedApiClient!);
      _premiumService = PremiumApiService.instance;
      _socialGamingService = SocialGamingApiService.instance;
      _notificationService = NotificationApiService.instance;
      _paymentService = PaymentService.instance;
      _analyticsService = AnalyticsService.instance;
      _pushNotificationService = PushNotificationService.instance;
      _tokenService = TokenService();

      // Set auth tokens if provided
      if (authToken != null) {
        await setAuthToken(authToken);
      }

      // Initialize push notifications
      await _pushNotificationService!.initialize(authToken: authToken);

      _initialized = true;
      AppLogger.info('All services initialized successfully');
    } catch (e) {
      AppLogger.error('Failed to initialize services: $e');
      rethrow;
    }
  }

  /// Set auth token for all services
  Future<void> setAuthToken(String authToken) async {
    try {
      _unifiedApiClient?.setAuthToken(authToken);
      _apiClient?.setAuthToken(authToken);
      _premiumService?.setAuthToken(authToken);
      _socialGamingService?.setAuthToken(authToken);
      _notificationService?.setAuthToken(authToken);
      _paymentService?.setAuthToken(authToken);
      _pushNotificationService?.updateAuthToken(authToken);

      // Get user ID from token (you might need to decode the JWT)
      final userId = _extractUserIdFromToken(authToken);
      if (userId != null) {
        _analyticsService?.setUser(authToken: authToken, userId: userId);
      }

      AppLogger.info('Auth token set for all services');
    } catch (e) {
      AppLogger.error('Failed to set auth token: $e');
    }
  }

  /// Extract user ID from JWT token (simplified implementation)
  String? _extractUserIdFromToken(String token) {
    try {
      // Use the token service for proper JWT decoding
      return _tokenService?.extractUserIdFromToken(token);
    } catch (e) {
      AppLogger.error('Failed to extract user ID from token: $e');
      return null;
    }
  }

  /// Clear all service data (on logout)
  Future<void> clearAllData() async {
    try {
      await _pushNotificationService?.clearNotifications();
      _analyticsService?.clearUserData();
      
      AppLogger.info('All service data cleared');
    } catch (e) {
      AppLogger.error('Failed to clear service data: $e');
    }
  }

  /// Get API client
  ApiClient get apiClient {
    _ensureInitialized();
    return _apiClient!;
  }

  /// Get matching service
  MatchingService get matchingService {
    _ensureInitialized();
    return _matchingService!;
  }

  /// Get messaging service
  MessagingService get messaging {
    _ensureInitialized();
    return _messagingService!;
  }

  /// Get premium service
  PremiumApiService get premium {
    _ensureInitialized();
    return _premiumService!;
  }

  /// Get social gaming service
  SocialGamingApiService get socialGaming {
    _ensureInitialized();
    return _socialGamingService!;
  }

  /// Get notification service
  NotificationApiService get notification {
    _ensureInitialized();
    return _notificationService!;
  }

  /// Get payment service
  PaymentService get payment {
    _ensureInitialized();
    return _paymentService!;
  }

  /// Get analytics service
  AnalyticsService get analytics {
    _ensureInitialized();
    return _analyticsService!;
  }

  /// Get push notification service
  PushNotificationService get pushNotification {
    _ensureInitialized();
    return _pushNotificationService!;
  }

  /// Get token service
  TokenService get token {
    _ensureInitialized();
    return _tokenService!;
  }

  /// Ensure services are initialized
  void _ensureInitialized() {
    if (!_initialized) {
      throw Exception('ServiceLocator not initialized. Call initialize() first.');
    }
  }

  /// Dispose all services
  void dispose() {
    _pushNotificationService?.dispose();
    _analyticsService = null;
    _apiClient = null;
    _matchingService = null;
    _messagingService = null;
    _premiumService = null;
    _socialGamingService = null;
    _notificationService = null;
    _paymentService = null;
    _pushNotificationService = null;
    _tokenService = null;
    _initialized = false;
  }
}
