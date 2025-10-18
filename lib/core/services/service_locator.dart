import 'package:dio/dio.dart';
import '../../data/services/analytics_service.dart';
import '../../data/services/messaging_service.dart';
import '../../data/services/payment_service.dart';
import '../../data/services/push_notification_service.dart';
import '../../services/firebase_notification_service.dart';
import '../../data/services/token_service.dart';
import '../../data/services/matching_service.dart';
import '../../data/services/ai_preferences_service.dart';
import '../network/api_client.dart';
import 'package:logger/logger.dart';
import '../utils/logger.dart';
import 'location_service.dart';

/// Service locator for managing app services
/// 
/// This has been simplified to use the new consolidated ApiClient for all API operations,
/// removing the need for scattered API services.
class ServiceLocator {
  static ServiceLocator? _instance;
  static ServiceLocator get instance => _instance ??= ServiceLocator._();
  ServiceLocator._();

  bool _initialized = false;

  // Core API client (replaces all scattered API services)
  ApiClient? _apiClient;
  
  // Feature-specific services (using the unified API client)
  MatchingService? _matchingService;
  MessagingService? _messagingService;
  PaymentService? _paymentService;
  AnalyticsService? _analyticsService;
  PushNotificationService? _pushNotificationService;
  FirebaseNotificationService? _firebaseNotificationService;
  TokenService? _tokenService;
  AiPreferencesService? _aiPreferencesService;
  LocationService? _locationService;

  /// Initialize all services
  Future<void> initialize({String? authToken}) async {
    if (_initialized) return;

    try {
      AppLogger.info('Initializing services...');

      // Initialize the main API client (replaces all scattered API services)
      _apiClient = ApiClient.instance;

      // Initialize auth token from storage or use provided token
      if (authToken != null) {
        await setAuthToken(authToken);
      } else {
        // Try to load auth token from storage
        await _apiClient!.initializeAuthToken();
      }

      // Initialize feature-specific services that use the unified API client
      _matchingService = MatchingService(apiClient: _apiClient!);
      _messagingService = MessagingService(apiClient: _apiClient!);
      _paymentService = PaymentService.instance;
      _analyticsService = AnalyticsService.instance;
      _pushNotificationService = PushNotificationService.instance;
      _firebaseNotificationService = FirebaseNotificationService.instance;
      _tokenService = TokenService();
      _aiPreferencesService = AiPreferencesService();
      _locationService = LocationService();

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
      Logger().d(
        '🔑 CoreServiceLocator: setAuthToken called with token: ${authToken.substring(0, 20)}...',
      );
      
      _apiClient?.setAuthToken(authToken);
      _paymentService?.setAuthToken(authToken);
      _pushNotificationService?.updateAuthToken(authToken);
      
      // Initialize Firebase notifications with auth token
      if (_firebaseNotificationService != null) {
        await _firebaseNotificationService!.initialize(authToken: authToken);
      }

      // Get user ID from token (you might need to decode the JWT)
      final userId = _extractUserIdFromToken(authToken);
      if (userId != null) {
        _analyticsService?.setUser(authToken: authToken, userId: userId);
      }

      Logger().d('✅ CoreServiceLocator: Auth token set for all services');
      AppLogger.info('Auth token set for all services');
    } catch (e) {
      Logger().d('❌ CoreServiceLocator: Failed to set auth token: $e');
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
      _apiClient?.clearAuthToken();
      await _pushNotificationService?.clearNotifications();
      _analyticsService?.clearUserData();
      
      AppLogger.info('All service data cleared');
    } catch (e) {
      AppLogger.error('Failed to clear service data: $e');
    }
  }

  // ===========================================
  // SERVICE GETTERS (Simplified API)
  // ===========================================

  /// Get the main API client (replaces all old scattered API services)
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

  /// Get AI preferences service
  AiPreferencesService get aiPreferences {
    _ensureInitialized();
    return _aiPreferencesService!;
  }

  /// Get location service
  LocationService get location {
    _ensureInitialized();
    return _locationService!;
  }

  /// Get Firebase notification service
  FirebaseNotificationService get firebaseNotificationService {
    _ensureInitialized();
    return _firebaseNotificationService!;
  }

  // ===========================================
  // DIRECT API ACCESS (for convenience)
  // ===========================================

  /// Direct access to premium features (via API client)
  Future<Response> getPremiumStatus() async {
    _ensureInitialized();
    return await _apiClient!.getPremiumStatus();
  }

  /// Direct access to notifications (via API client)
  Future<Response> getNotifications({int limit = 50, int offset = 0}) async {
    _ensureInitialized();
    return await _apiClient!.getNotifications(limit: limit, offset: offset);
  }

  /// Direct access to social gaming (via API client)
  Future<Response> getAvailableGames() async {
    _ensureInitialized();
    return await _apiClient!.getAvailableGames();
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
    _firebaseNotificationService?.dispose();
    _analyticsService = null;
    _apiClient = null;
    _matchingService = null;
    _messagingService = null;
    _paymentService = null;
    _pushNotificationService = null;
    _firebaseNotificationService = null;
    _tokenService = null;
    _aiPreferencesService = null;
    _locationService = null;
    _initialized = false;
  }
}
