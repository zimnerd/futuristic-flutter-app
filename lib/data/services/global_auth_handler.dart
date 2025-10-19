import 'package:logger/logger.dart';
import '../services/token_service.dart';
import '../../core/network/api_client.dart';

/// Global authentication state manager
///
/// This singleton service handles global authentication events like
/// automatic logout on 401 responses. It provides a way for the API
/// client to trigger logout without having direct access to the BLoC.
class GlobalAuthHandler {
  static GlobalAuthHandler? _instance;
  static GlobalAuthHandler get instance => _instance ??= GlobalAuthHandler._();

  GlobalAuthHandler._();

  final Logger _logger = Logger();
  final TokenService _tokenService = TokenService();

  /// Callback function to trigger logout in the UI layer
  void Function()? _onLogoutRequired;

  /// Flag to prevent multiple simultaneous logout attempts
  bool _isHandlingAuthFailure = false;

  /// Register the logout callback (typically called from the main app widget)
  void registerLogoutCallback(void Function() callback) {
    _onLogoutRequired = callback;
    _logger.i('🔗 Global auth logout callback registered');
  }

  /// Handle authentication failure (401 responses)
  /// This method is called by the API client when authentication fails
  Future<void> handleAuthenticationFailure({
    String? reason,
    bool clearTokens = true,
  }) async {
    // Prevent multiple simultaneous auth failure handling
    if (_isHandlingAuthFailure) {
      _logger.i(
        '🔄 Auth failure already being handled, skipping duplicate call',
      );
      return;
    }

    _isHandlingAuthFailure = true;

    try {
      _logger.w(
        '🚨 Authentication failure detected: ${reason ?? 'Unknown reason'}',
      );

      // Clear stored tokens if requested
      if (clearTokens) {
        await _tokenService.clearTokens();
        _logger.i('🗑️ Cleared stored authentication tokens');
      }

      // Clear API client token
      ApiClient.instance.clearAuthToken();

      // Trigger logout in the UI layer
      if (_onLogoutRequired != null) {
        _onLogoutRequired!();
        _logger.i('🚪 Triggered global logout');
      } else {
        _logger.e('❌ No logout callback registered - cannot navigate to login');
      }
    } catch (e) {
      _logger.e('💥 Error during authentication failure handling: $e');
    } finally {
      // Reset flag after a short delay to allow for completion
      Future.delayed(const Duration(milliseconds: 500), () {
        _isHandlingAuthFailure = false;
      });
    }
  }

  /// Check if logout callback is registered
  bool get isLogoutCallbackRegistered => _onLogoutRequired != null;
}
