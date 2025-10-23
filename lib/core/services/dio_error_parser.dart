import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

/// Utility class for extracting error messages from DioException responses
/// Provides consistent error message extraction across all API data sources
class DioErrorParser {
  static final Logger _logger = Logger();

  /// Extract a readable error message from a DioException response
  /// Returns a user-friendly error message or a fallback message if parsing fails
  static String extractErrorMessage(
    DioException exception, {
    String fallbackMessage = 'An error occurred',
  }) {
    try {
      if (exception.response?.data is Map<String, dynamic>) {
        final responseData = exception.response!.data as Map<String, dynamic>;
        return _extractFromMap(responseData);
      }
    } catch (e) {
      _logger.w('Failed to extract error message from response', error: e);
    }

    return fallbackMessage;
  }

  /// Extract error message from a Map response (handles multiple formats)
  static String _extractFromMap(Map<String, dynamic> data) {
    // Try 'message' field first (most common)
    if (data['message'] != null) {
      final message = data['message'];
      if (message is List) {
        // Handle array of messages
        return message.join(', ');
      }
      return message.toString();
    }

    // Try 'error' field
    if (data['error'] != null) {
      final error = data['error'];
      if (error is Map && error['message'] != null) {
        return error['message'].toString();
      }
      return error.toString();
    }

    // Try 'errors' field (validation errors)
    if (data['errors'] != null) {
      final errors = data['errors'];
      if (errors is List && errors.isNotEmpty) {
        // Extract first error or message property
        final firstError = errors.first;
        if (firstError is Map && firstError['message'] != null) {
          return firstError['message'].toString();
        }
        return firstError.toString();
      }
    }

    // Try 'details' field
    if (data['details'] != null) {
      return data['details'].toString();
    }

    return '';
  }

  /// Extract error code from a DioException response
  static String? extractErrorCode(DioException exception) {
    try {
      if (exception.response?.data is Map<String, dynamic>) {
        final responseData = exception.response!.data as Map<String, dynamic>;

        if (responseData['code'] != null) {
          return responseData['code'].toString();
        }

        if (responseData['error'] is Map &&
            responseData['error']['code'] != null) {
          return responseData['error']['code'].toString();
        }
      }
    } catch (e) {
      _logger.w('Failed to extract error code from response', error: e);
    }

    return null;
  }
}
