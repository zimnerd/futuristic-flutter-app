import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../exceptions/app_exceptions.dart';

/// Service for user blocking/unblocking functionality
class BlockService {
  final ApiClient _apiClient;

  BlockService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Block a user
  Future<void> blockUser(String userId) async {
    try {
      await _apiClient.blockUser(userId);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Unblock a user
  Future<void> unblockUser(String userId) async {
    try {
      await _apiClient.unblockUser(userId);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get list of blocked users
  Future<List<String>> getBlockedUsers() async {
    try {
      final response = await _apiClient.get('/users/blocked');

      final data = response.data as Map<String, dynamic>;
      final blockedUsers = data['blockedUsers'] as List<dynamic>;

      return blockedUsers.cast<String>();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Check if a user is blocked
  Future<bool> isUserBlocked(String userId) async {
    try {
      final blockedUsers = await getBlockedUsers();
      return blockedUsers.contains(userId);
    } catch (e) {
      // If we can't get blocked users list, assume not blocked
      return false;
    }
  }

  /// Handle Dio errors and convert to appropriate exceptions
  Exception _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException(
          'Connection timeout. Please check your internet connection.',
        );
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message =
            e.response?.data?['message'] ?? 'Unknown error occurred';
        return NetworkException('Server error ($statusCode): $message');
      case DioExceptionType.cancel:
        return NetworkException('Request was cancelled');
      case DioExceptionType.unknown:
      default:
        return NetworkException('Network error: ${e.message}');
    }
  }
}
