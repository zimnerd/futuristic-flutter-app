import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import 'matching_service.dart';
import 'messaging_service.dart';

/// Simple service locator without external dependencies
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  // Service instances
  late final ApiClient _apiClient;
  late final MatchingService _matchingService;
  late final MessagingService _messagingService;

  bool _isInitialized = false;

  /// Initialize all services
  void initialize() {
    if (_isInitialized) return;

    // Initialize API client
    _apiClient = ApiClient(baseUrl: ApiConstants.baseUrl);

    // Initialize services
    _matchingService = MatchingService(apiClient: _apiClient);
    _messagingService = MessagingService(apiClient: _apiClient);

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

  /// Get ApiClient instance
  ApiClient get apiClient {
    if (!_isInitialized) initialize();
    return _apiClient;
  }
}
