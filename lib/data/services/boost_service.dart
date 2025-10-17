import 'package:logger/logger.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';

/// Service for handling profile boost features
/// 
/// Manages API calls for:
/// - Activating a profile boost
/// - Checking boost status
/// - Managing boost-related operations
class BoostService {
  final ApiClient _apiClient;
  final Logger _logger = Logger();

  BoostService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  /// Activate a profile boost (premium feature)
  /// 
  /// Returns boost details including:
  /// - boostId: Unique identifier for the boost
  /// - startTime: When the boost was activated
  /// - expiresAt: When the boost will expire
  /// - durationMinutes: Total boost duration
  /// 
  /// Throws exception if:
  /// - No active premium subscription
  /// - Already have an active boost
  /// - Network error
  Future<Map<String, dynamic>> activateBoost() async {
    try {
      _logger.d('BoostService: Activating profile boost...');
      
      final response = await _apiClient.post(
        ApiConstants.premiumBoost,
        data: {},
      );

      _logger.d('BoostService: Boost activation response: ${response.data}');

      // Backend returns the boost details directly
      final Map<String, dynamic> result = response.data as Map<String, dynamic>;
      
      return {
        'success': result['success'] ?? true,
        'boostId': result['boostId'] as String,
        'startTime': result['startTime'] as String,
        'expiresAt': result['expiresAt'] as String,
        'durationMinutes': result['durationMinutes'] as int,
      };
    } catch (e) {
      _logger.e('BoostService: Error activating boost: $e');
      rethrow;
    }
  }

  /// Get current boost status
  /// 
  /// Returns null if no active boost, otherwise returns:
  /// - boostId: Unique identifier for the boost
  /// - startTime: When the boost was activated
  /// - expiresAt: When the boost will expire
  /// - durationMinutes: Total boost duration
  /// - remainingMinutes: Minutes remaining
  Future<Map<String, dynamic>?> getBoostStatus() async {
    try {
      _logger.d('BoostService: Checking boost status...');
      
      final response = await _apiClient.get(
        ApiConstants.premiumBoostStatus,
      );

      _logger.d('BoostService: Boost status response: ${response.data}');

      final result = response.data as Map<String, dynamic>?;

      // If no active boost, backend returns null
      if (result == null || result.isEmpty) {
        _logger.d('BoostService: No active boost');
        return null;
      }

      return {
        'boostId': result['boostId'] as String,
        'startTime': result['startTime'] as String,
        'expiresAt': result['expiresAt'] as String,
        'durationMinutes': result['durationMinutes'] as int,
        'remainingMinutes': result['remainingMinutes'] as int,
      };
    } catch (e) {
      _logger.e('BoostService: Error checking boost status: $e');
      // Return null on error (treat as no active boost)
      return null;
    }
  }
}
