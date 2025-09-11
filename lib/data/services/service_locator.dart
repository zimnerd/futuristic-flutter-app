import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import 'matching_service.dart';
import 'messaging_service.dart';
import 'profile_service.dart';
import 'file_upload_service.dart';
import 'websocket_service.dart';
import 'preferences_service.dart';
import 'api_service_impl.dart';

/// Simple service locator without external dependencies
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  // Service instances
  late final ApiClient _apiClient;
  late final ApiServiceImpl _apiService;
  late final MatchingService _matchingService;
  late final MessagingService _messagingService;
  late final ProfileService _profileService;
  late final FileUploadService _fileUploadService;
  late final WebSocketService _webSocketService;
  late final PreferencesService _preferencesService;

  bool _isInitialized = false;

  /// Initialize all services
  void initialize() {
    if (_isInitialized) return;

    // Initialize API client and service
    _apiClient = ApiClient(baseUrl: ApiConstants.baseUrl);
    _apiService = ApiServiceImpl(baseUrl: ApiConstants.baseUrl);

    // Initialize services
    _matchingService = MatchingService(apiClient: _apiClient);
    _messagingService = MessagingService(apiClient: _apiClient);
    _profileService = ProfileService(apiService: _apiService);
    _fileUploadService = FileUploadService(apiClient: _apiClient);
    _webSocketService = WebSocketService.instance;
    _preferencesService = PreferencesService(_apiClient);

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
}
