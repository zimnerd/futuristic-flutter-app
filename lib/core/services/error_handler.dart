import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

/// Centralized error handler for all HTTP and network errors
/// Displays user-friendly popup dialogs for all error types
class ErrorHandler {
  static final Logger _logger = Logger();

  /// Main error handling method
  /// Returns user-friendly error message and optionally shows dialog
  static String handleError(
    dynamic error, {
    BuildContext? context,
    bool showDialog = true,
  }) {
    String userMessage = 'An unexpected error occurred';
    String? technicalDetails;
    int? statusCode;

    if (error is DioException) {
      statusCode = error.response?.statusCode;
      technicalDetails = _extractTechnicalDetails(error);

      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          userMessage =
              'Connection timeout. Please check your internet and try again.';
          break;
        case DioExceptionType.badResponse:
          userMessage = _handleHttpError(statusCode, error.response?.data);
          break;
        case DioExceptionType.connectionError:
          userMessage =
              'Unable to connect. Please check your internet connection.';
          break;
        case DioExceptionType.badCertificate:
          userMessage = 'Security certificate error. Please contact support.';
          break;
        case DioExceptionType.cancel:
          userMessage = 'Request was cancelled.';
          break;
        default:
          userMessage = 'Network error occurred. Please try again.';
      }
    } else if (error is Exception) {
      userMessage = error.toString().replaceAll('Exception: ', '');
      technicalDetails = error.toString();
    } else {
      userMessage = error.toString();
      technicalDetails = error.toString();
    }

    _logger.e('Error occurred', error: error);

    if (context != null && showDialog) {
      _showErrorDialog(
        context: context,
        title: _getErrorTitle(statusCode),
        message: userMessage,
        technicalDetails: technicalDetails,
        statusCode: statusCode,
      );
    }

    return userMessage;
  }

  /// Handle HTTP status code errors
  static String _handleHttpError(int? statusCode, dynamic responseData) {
    String message = _extractErrorMessage(responseData);

    switch (statusCode) {
      case 400:
        return message.isNotEmpty
            ? message
            : 'Invalid request. Please check your input.';
      case 401:
        return 'Session expired. Please log in again.';
      case 403:
        return 'You do not have permission to perform this action.';
      case 404:
        return 'The requested resource was not found.';
      case 409:
        return message.isNotEmpty ? message : 'Conflict with existing data.';
      case 422:
        return message.isNotEmpty
            ? message
            : 'Validation failed. Please check your input.';
      case 429:
        return 'Too many requests. Please wait a moment and try again.';
      case 500:
      case 502:
      case 503:
      case 504:
        return 'Server error. Please try again later.';
      default:
        return message.isNotEmpty
            ? message
            : 'An error occurred (Status: $statusCode)';
    }
  }

  /// Extract error message from various API response formats
  static String _extractErrorMessage(dynamic responseData) {
    if (responseData == null) return '';

    try {
      if (responseData is Map<String, dynamic>) {
        // Try common error message fields
        if (responseData['message'] != null) {
          final message = responseData['message'];
          if (message is List) {
            return message.join(', ');
          }
          return message.toString();
        }
        if (responseData['error'] != null) {
          final error = responseData['error'];
          if (error is Map && error['message'] != null) {
            return error['message'].toString();
          }
          return error.toString();
        }
      }
    } catch (e) {
      _logger.w('Failed to extract error message', error: e);
    }

    return '';
  }

  /// Extract technical details for debugging
  static String _extractTechnicalDetails(DioException error) {
    final buffer = StringBuffer();
    buffer.writeln('Error Type: ${error.type}');
    buffer.writeln('Status Code: ${error.response?.statusCode}');
    buffer.writeln('URL: ${error.requestOptions.uri}');
    buffer.writeln('Method: ${error.requestOptions.method}');
    if (error.response?.data != null) {
      buffer.writeln('Response: ${error.response?.data}');
    }
    return buffer.toString();
  }

  /// Get appropriate error title based on status code
  static String _getErrorTitle(int? statusCode) {
    if (statusCode == null) return 'Error';
    if (statusCode >= 400 && statusCode < 500) return 'Request Error';
    if (statusCode >= 500) return 'Server Error';
    return 'Error';
  }

  /// Show error dialog to user
  static void _showErrorDialog({
    required BuildContext context,
    required String title,
    required String message,
    String? technicalDetails,
    int? statusCode,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(color: Colors.black87),
            ),
            if (statusCode != null && statusCode >= 500) ...[
              SizedBox(height: 16),
              Text(
                'You can try again or contact support if the problem persists.',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            ],
          ],
        ),
        actions: [
          if (statusCode == 401)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Navigate to login screen
              },
              child: Text('LOG IN'),
            ),
          if (statusCode != null && statusCode >= 500)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Implement retry logic
              },
              child: Text('RETRY'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Handle validation errors specifically
  static Map<String, String> handleValidationErrors(dynamic error) {
    final errors = <String, String>{};

    if (error is DioException && error.response?.data is Map<String, dynamic>) {
      final data = error.response!.data as Map<String, dynamic>;

      if (data['message'] is List) {
        for (final msg in data['message']) {
          if (msg is String) {
            final parts = msg.split(':');
            if (parts.length == 2) {
              errors[parts[0].trim()] = parts[1].trim();
            } else {
              errors['general'] = msg;
            }
          }
        }
      }
    }

    return errors;
  }
}
