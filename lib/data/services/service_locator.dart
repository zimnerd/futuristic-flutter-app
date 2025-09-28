import '../../../core/network/api_client.dart';
import 'package:logger/logger.dart';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'matching_service.dart';
import 'messaging_service.dart';
import 'profile_service.dart';
import 'file_upload_service.dart';
import '../../domain/services/websocket_service.dart';
import 'websocket_service_impl.dart';
import 'ai_companion_websocket_service.dart';
import 'preferences_service.dart';
import 'discovery_service.dart';
import 'virtual_gift_service.dart';
import 'safety_service.dart';
import 'premium_service.dart';
import 'ai_companion_service.dart';
import 'speed_dating_service.dart';
import 'live_streaming_service.dart';
import 'date_planning_service.dart';
import 'voice_message_service.dart';
import 'call_service.dart';
import 'auth_service.dart';
import 'subscription_service.dart';
import 'saved_payment_methods_service.dart';
import 'ai_matching_service.dart';
import 'icebreaker_service.dart';
import 'auto_reply_service.dart';
import 'ai_chat_assistant_service.dart';
import '../../services/media_upload_service.dart';
import '../../services/firebase_notification_service.dart';

/// Simple service locator without external dependencies
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  // Service instances
  late final ApiClient _apiClient;
  late final MatchingService _matchingService;
  late final MessagingService _messagingService;
  late final ProfileService _profileService;
  late final FileUploadService _fileUploadService;
  late final WebSocketService _webSocketService;
  late final AiCompanionWebSocketService _aiCompanionWebSocketService;
  late final PreferencesService _preferencesService;
  late final DiscoveryService _discoveryService;
  late final VirtualGiftService _virtualGiftService;
  late final SafetyService _safetyService;
  late final PremiumService _premiumService;
  late final AiCompanionService _aiCompanionService;
  late final SpeedDatingService _speedDatingService;
  late final LiveStreamingService _liveStreamingService;
  late final DatePlanningService _datePlanningService;
  late final VoiceMessageService _voiceMessageService;
  late final CallService _callService;
  late final AuthService _authService;
  late final SubscriptionService _subscriptionService;
  late final AiMatchingService _aiMatchingService;
  late final IcebreakerService _icebreakerService;
  late final AutoReplyService _autoReplyService;
  late final AiChatAssistantService _aiChatAssistantService;
  late final MediaUploadService _mediaUploadService;
  late final FirebaseNotificationService _firebaseNotificationService;

  bool _isInitialized = false;

  /// Initialize all services
  void initialize([Box<String>? secureStorageBox]) {
    if (_isInitialized) return;

    // Initialize API client
    _apiClient = ApiClient.instance;

    // Initialize AuthService with provided secure storage box or try to get existing one
    final secureStorage =
        secureStorageBox ?? Hive.box<String>('secure_storage');
    _authService = AuthService(
      httpClient: Dio(),
      secureStorage: secureStorage,
    );

    // Initialize core services
    _matchingService = MatchingService(apiClient: _apiClient);
    _messagingService = MessagingService(apiClient: _apiClient);
    _profileService = ProfileService(
      apiClient: _apiClient,
      authService: _authService,
    );
    _fileUploadService = FileUploadService(apiClient: _apiClient);
    _webSocketService = WebSocketServiceImpl.instance;
    _aiCompanionWebSocketService = AiCompanionWebSocketService.instance;
    _preferencesService = PreferencesService(_apiClient);

    // Initialize feature services
    _discoveryService = DiscoveryService(apiClient: _apiClient);
    _virtualGiftService = VirtualGiftService(_apiClient);
    _safetyService = SafetyService(_apiClient);
    _premiumService = PremiumService(_apiClient);
    _aiCompanionService = AiCompanionService();
    _speedDatingService = SpeedDatingService(_apiClient);
    _liveStreamingService = LiveStreamingService(_apiClient);
    _datePlanningService = DatePlanningService(_apiClient);
    _voiceMessageService = VoiceMessageService(_apiClient);
    _callService = CallService.instance;

    // Initialize AI services
    _aiMatchingService = AiMatchingService(_apiClient);
    _icebreakerService = IcebreakerService(_apiClient);
    _autoReplyService = AutoReplyService(_apiClient);
    _aiChatAssistantService = AiChatAssistantService();
    _mediaUploadService = MediaUploadService(
      httpClient: Dio(),
      secureStorage: secureStorage,
    );
    _firebaseNotificationService = FirebaseNotificationService.instance;

    // Initialize SubscriptionService
    _subscriptionService = SubscriptionService(
      savedMethodsService: SavedPaymentMethodsService.instance,
      apiClient: _apiClient,
      authService: _authService,
    );

    _isInitialized = true;
  }

  /// Get MatchingService instance
  MatchingService get matchingService {
    if (!_isInitialized) initialize();
    return _matchingService;
  }

  /// Get MessagingService instance
  MessagingService get messagingService {
    if (!_isInitialized) initialize();
    return _messagingService;
  }

  /// Get ProfileService instance
  ProfileService get profileService {
    if (!_isInitialized) initialize();
    return _profileService;
  }

  /// Get FileUploadService instance
  FileUploadService get fileUploadService {
    if (!_isInitialized) initialize();
    return _fileUploadService;
  }

  /// Get WebSocketService instance
  WebSocketService get webSocketService {
    if (!_isInitialized) initialize();
    return _webSocketService;
  }

  /// Get ApiClient instance
  ApiClient get apiClient {
    if (!_isInitialized) initialize();
    return _apiClient;
  }

  /// Get PreferencesService instance
  PreferencesService get preferencesService {
    if (!_isInitialized) initialize();
    return _preferencesService;
  }

  /// Get DiscoveryService instance
  DiscoveryService get discoveryService {
    if (!_isInitialized) initialize();
    return _discoveryService;
  }

  /// Get VirtualGiftService instance
  VirtualGiftService get virtualGiftService {
    if (!_isInitialized) initialize();
    return _virtualGiftService;
  }

  /// Get SafetyService instance
  SafetyService get safetyService {
    if (!_isInitialized) initialize();
    return _safetyService;
  }

  /// Get PremiumService instance
  PremiumService get premiumService {
    if (!_isInitialized) initialize();
    return _premiumService;
  }

  /// Get AiCompanionService instance
  AiCompanionService get aiCompanionService {
    if (!_isInitialized) initialize();
    return _aiCompanionService;
  }

  /// Get SpeedDatingService instance
  SpeedDatingService get speedDatingService {
    if (!_isInitialized) initialize();
    return _speedDatingService;
  }

  /// Get LiveStreamingService instance
  LiveStreamingService get liveStreamingService {
    if (!_isInitialized) initialize();
    return _liveStreamingService;
  }

  /// Get DatePlanningService instance
  DatePlanningService get datePlanningService {
    if (!_isInitialized) initialize();
    return _datePlanningService;
  }

  /// Get VoiceMessageService instance
  VoiceMessageService get voiceMessageService {
    if (!_isInitialized) initialize();
    return _voiceMessageService;
  }

  /// Get CallService instance
  CallService get callService {
    if (!_isInitialized) initialize();
    return _callService;
  }



  /// Get AuthService instance
  AuthService get authService {
    if (!_isInitialized) initialize();
    return _authService;
  }

  /// Get SubscriptionService instance
  SubscriptionService get subscriptionService {
    if (!_isInitialized) initialize();
    return _subscriptionService;
  }

  /// Get AiMatchingService instance
  AiMatchingService get aiMatchingService {
    if (!_isInitialized) initialize();
    return _aiMatchingService;
  }

  /// Get IcebreakerService instance
  IcebreakerService get icebreakerService {
    if (!_isInitialized) initialize();
    return _icebreakerService;
  }

  /// Get AutoReplyService instance
  AutoReplyService get autoReplyService {
    if (!_isInitialized) initialize();
    return _autoReplyService;
  }

  /// Get AiChatAssistantService instance
  AiChatAssistantService get aiChatAssistantService {
    if (!_isInitialized) initialize();
    return _aiChatAssistantService;
  }

  /// Get MediaUploadService instance
  MediaUploadService get mediaUploadService {
    if (!_isInitialized) initialize();
    return _mediaUploadService;
  }

  /// Get Firebase Notification Service instance
  FirebaseNotificationService get firebaseNotificationService {
    if (!_isInitialized) initialize();
    return _firebaseNotificationService;
  }

  /// Legacy getter for backward compatibility
  FirebaseNotificationService get pushNotification => firebaseNotificationService;

  /// Set auth token for all services that require authentication
  Future<void> setAuthToken(String token) async {
    if (!_isInitialized) initialize();

    Logger().d('🔑 ServiceLocator: Setting auth token for WebSocket services');

    // Set auth token for WebSocket service
    _webSocketService.setAuthToken(token);

    // Connect WebSocket service if not already connected
    Logger().d(
      '🔌 ServiceLocator: Checking WebSocket connection status: ${_webSocketService.isConnected}',
    );
    if (!_webSocketService.isConnected) {
      try {
        Logger().d(
          '🔌 ServiceLocator: Attempting to connect WebSocket service...',
        );
        await _webSocketService.connect();

        // Wait a moment for connection to be established
        int attempts = 0;
        const maxAttempts = 10;
        while (!_webSocketService.isConnected && attempts < maxAttempts) {
          await Future.delayed(const Duration(milliseconds: 100));
          attempts++;
          Logger().d(
            '🔍 ServiceLocator: Waiting for connection... attempt $attempts/$maxAttempts',
          );
        }

        if (_webSocketService.isConnected) {
          Logger().d(
            '✅ ServiceLocator: WebSocket service connected successfully',
          );
        } else {
          Logger().d(
            '⚠️ ServiceLocator: WebSocket connection timed out after ${maxAttempts * 100}ms',
          );
        }
      } catch (e) {
        // Log error but don't fail the entire auth process
        Logger().e('❌ ServiceLocator: Failed to connect WebSocket service: $e');
      }
    } else {
      Logger().d('✅ ServiceLocator: WebSocket service already connected');
    }

    // Set auth token for AI companion WebSocket service and connect
    Logger().d(
      '🤖 ServiceLocator: Checking AI companion WebSocket connection status: ${_aiCompanionWebSocketService.isConnected}',
    );
    if (!_aiCompanionWebSocketService.isConnected) {
      try {
        Logger().d(
          '🤖 ServiceLocator: Attempting to connect AI companion WebSocket service...',
        );
        await _aiCompanionWebSocketService.connect(token);

        // Wait a moment for connection to be established
        int attempts = 0;
        const maxAttempts = 10;
        while (!_aiCompanionWebSocketService.isConnected &&
            attempts < maxAttempts) {
          await Future.delayed(const Duration(milliseconds: 100));
          attempts++;
          Logger().d(
            '🔍 ServiceLocator: Waiting for AI companion connection... attempt $attempts/$maxAttempts',
          );
        }

        if (_aiCompanionWebSocketService.isConnected) {
          Logger().d(
            '✅ ServiceLocator: AI companion WebSocket service connected successfully',
          );
        } else {
          Logger().d(
            '⚠️ ServiceLocator: AI companion WebSocket connection timed out after ${maxAttempts * 100}ms',
          );
        }
      } catch (e) {
        // Log error but don't fail the entire auth process
        Logger().e(
          '❌ ServiceLocator: Failed to connect AI companion WebSocket service: $e',
        );
      }
    } else {
      Logger().d(
        '✅ ServiceLocator: AI companion WebSocket service already connected',
      );
    }

    // Set auth token for API client (which sets it for all HTTP services)
    _apiClient.setAuthToken(token);

    // Initialize Firebase notifications with auth token
    try {
      Logger().d('🔔 ServiceLocator: Initializing Firebase notifications with auth token');
      await _firebaseNotificationService.updateAuthToken(token);
    } catch (e) {
      Logger().e('❌ ServiceLocator: Failed to initialize Firebase notifications: $e');
    }
  }
}
