import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../exceptions/app_exceptions.dart';

/// Service for reporting functionality that centralizes all report operations
class ReportsService {
  final ApiClient _apiClient;

  ReportsService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Report a user profile
  Future<void> reportProfile({
    required String userId,
    required String reason,
    String? details,
  }) async {
    try {
      await _apiClient.reportProfile(
        userId: userId,
        reason: reason,
        details: details,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Report a conversation
  Future<void> reportConversation({
    required String conversationId,
    required String reason,
    String? description,
  }) async {
    try {
      await _apiClient.reportConversation(
        conversationId: conversationId,
        reason: reason,
        description: description,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Report a message
  Future<void> reportMessage({
    required String messageId,
    required String reason,
    String? description,
  }) async {
    try {
      final response = await _apiClient.post(
        '/reports',
        data: {
          'messageId': messageId,
          'type': 'message',
          'reason': reason,
          if (description != null) 'description': description,
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw NetworkException('Failed to report message');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Report inappropriate content
  Future<void> reportContent({
    required String contentId,
    required String contentType, // 'photo', 'video', 'audio', etc.
    required String reason,
    String? description,
  }) async {
    try {
      final response = await _apiClient.post(
        '/reports',
        data: {
          'contentId': contentId,
          'type': contentType,
          'reason': reason,
          if (description != null) 'description': description,
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw NetworkException('Failed to report content');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
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
