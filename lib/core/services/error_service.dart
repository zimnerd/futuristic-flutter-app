import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../presentation/theme/pulse_colors.dart';
import '../../presentation/widgets/common/pulse_toast.dart';

/// Severity level of the error
enum ErrorSeverity {
  info,
  warning,
  error,
  critical,
}

/// Parsed error details from backend
class ErrorDetails {
  final String message;
  final String? errorCode;
  final Map<String, String>? fieldErrors;
  final ErrorSeverity severity;
  final bool requiresAcknowledgment;

  const ErrorDetails({
    required this.message,
    this.errorCode,
    this.fieldErrors,
    this.severity = ErrorSeverity.error,
    this.requiresAcknowledgment = false,
  });

  /// Check if error has field-specific errors
  bool get hasFieldErrors =>
      fieldErrors != null && fieldErrors!.isNotEmpty;

  /// Get error for a specific field
  String? getFieldError(String fieldName) {
    // Try exact match first
    if (fieldErrors?.containsKey(fieldName) == true) {
      return fieldErrors![fieldName];
    }

    // If no exact match, try case-insensitive lookup
    final lowerFieldName = fieldName.toLowerCase();
    for (final entry
        in (fieldErrors?.entries ?? <MapEntry<String, String>>[]).toList()) {
      if (entry.key.toLowerCase() == lowerFieldName) {
        return entry.value;
      }
    }

    return null;
  }
}

/// Centralized error handling service
/// Parses backend errors and displays them consistently
class ErrorService {
  ErrorService._();
  static final ErrorService instance = ErrorService._();

  /// Parse error from any exception
  ErrorDetails parseError(dynamic error) {
    if (error is DioException) {
      return _parseDioError(error);
    }

    return ErrorDetails(
      message: error.toString(),
      severity: ErrorSeverity.error,
    );
  }

  /// Parse DioException from backend API
  ErrorDetails _parseDioError(DioException error) {
    final response = error.response;
    if (response?.data == null) {
      return _handleNetworkError(error);
    }

    final data = response!.data;
    if (data is! Map<String, dynamic>) {
      return ErrorDetails(
        message: 'An unexpected error occurred',
        severity: ErrorSeverity.error,
      );
    }

    // Extract backend error response
    // Format: { success: false, statusCode: 409, message: "...", fieldErrors: {...}, severity: "error" }
    final message = data['message'] as String? ?? 'An error occurred';
    final errorCode = data['error'] as String?;
    final fieldErrors = _extractFieldErrors(data['fieldErrors']);
    final severity = _parseSeverity(data['severity'] as String?);
    final requiresAcknowledgment = severity == ErrorSeverity.critical ||
        (fieldErrors != null && fieldErrors.isNotEmpty);

    return ErrorDetails(
      message: message,
      errorCode: errorCode,
      fieldErrors: fieldErrors,
      severity: severity,
      requiresAcknowledgment: requiresAcknowledgment,
    );
  }

  /// Extract field errors from backend response
  Map<String, String>? _extractFieldErrors(dynamic fieldErrorsData) {
    if (fieldErrorsData is! Map) return null;

    final fieldErrors = <String, String>{};
    fieldErrorsData.forEach((field, errors) {
      if (errors is List && errors.isNotEmpty) {
        fieldErrors[field.toString()] = errors.first.toString();
      } else if (errors is String) {
        fieldErrors[field.toString()] = errors;
      }
    });

    return fieldErrors.isNotEmpty ? fieldErrors : null;
  }

  /// Parse severity from backend
  ErrorSeverity _parseSeverity(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'info':
        return ErrorSeverity.info;
      case 'warning':
        return ErrorSeverity.warning;
      case 'critical':
        return ErrorSeverity.critical;
      default:
        return ErrorSeverity.error;
    }
  }

  /// Handle network errors
  ErrorDetails _handleNetworkError(DioException error) {
    String message;
    ErrorSeverity severity;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'Connection timeout. Please check your internet connection.';
        severity = ErrorSeverity.warning;
        break;
      case DioExceptionType.connectionError:
        message = 'Unable to connect to server. Please check your internet connection.';
        severity = ErrorSeverity.warning;
        break;
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        message = _getStatusCodeMessage(statusCode);
        severity = statusCode == 500 || statusCode == 503
            ? ErrorSeverity.critical
            : ErrorSeverity.error;
        break;
      default:
        message = 'An unexpected error occurred. Please try again.';
        severity = ErrorSeverity.error;
    }

    return ErrorDetails(message: message, severity: severity);
  }

  /// Get user-friendly message for HTTP status codes
  String _getStatusCodeMessage(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Invalid request. Please check your input.';
      case 401:
        return 'Authentication failed. Please log in again.';
      case 403:
        return 'You don\'t have permission to perform this action.';
      case 404:
        return 'The requested resource was not found.';
      case 409:
        return 'This resource already exists.';
      case 422:
        return 'Validation failed. Please check your input.';
      case 429:
        return 'Too many requests. Please try again later.';
      case 500:
        return 'Server error. Please try again later.';
      case 503:
        return 'Service temporarily unavailable. Please try again later.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  /// Show error to user based on severity and context
  void showError(
    BuildContext context,
    dynamic error, {
    VoidCallback? onRetry,
  }) {
    final errorDetails = parseError(error);

    if (errorDetails.requiresAcknowledgment || errorDetails.severity == ErrorSeverity.critical) {
      _showPersistentAlert(context, errorDetails, onRetry: onRetry);
    } else {
      _showToast(context, errorDetails);
    }
  }

  /// Show persistent alert dialog for critical errors
  void _showPersistentAlert(
    BuildContext context,
    ErrorDetails errorDetails, {
    VoidCallback? onRetry,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getSeverityIcon(errorDetails.severity),
              color: _getSeverityColor(errorDetails.severity),
            ),
            const SizedBox(width: 12),
            Text(_getSeverityTitle(errorDetails.severity)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(errorDetails.message),
            if (errorDetails.hasFieldErrors) ...[
              const SizedBox(height: 16),
              Text(
                'Please check the following fields:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: PulseColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              ...errorDetails.fieldErrors!.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• '),
                      Expanded(
                        child: Text(
                          '${_humanizeFieldName(entry.key)}: ${entry.value}',
                          style: TextStyle(color: PulseColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (errorDetails.errorCode != null) ...[
              const SizedBox(height: 12),
              Text(
                'Error Code: ${errorDetails.errorCode}',
                style: TextStyle(
                  fontSize: 12,
                  color: PulseColors.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: Text('Retry'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: PulseColors.primary,
            ),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show toast for non-critical errors
  void _showToast(BuildContext context, ErrorDetails errorDetails) {
    switch (errorDetails.severity) {
      case ErrorSeverity.info:
        PulseToast.info(context, message: errorDetails.message);
        break;
      case ErrorSeverity.warning:
        PulseToast.warning(context, message: errorDetails.message);
        break;
      case ErrorSeverity.error:
      case ErrorSeverity.critical:
        PulseToast.error(context, message: errorDetails.message);
        break;
    }
  }

  /// Get icon for severity level
  IconData _getSeverityIcon(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.info:
        return Icons.info_outline;
      case ErrorSeverity.warning:
        return Icons.warning_amber_outlined;
      case ErrorSeverity.error:
        return Icons.error_outline;
      case ErrorSeverity.critical:
        return Icons.error;
    }
  }

  /// Get color for severity level
  Color _getSeverityColor(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.info:
        return PulseColors.secondary;
      case ErrorSeverity.warning:
        return PulseColors.warning;
      case ErrorSeverity.error:
        return PulseColors.error;
      case ErrorSeverity.critical:
        return PulseColors.errorDark;
    }
  }

  /// Get title for severity level
  String _getSeverityTitle(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.info:
        return 'Information';
      case ErrorSeverity.warning:
        return 'Warning';
      case ErrorSeverity.error:
        return 'Error';
      case ErrorSeverity.critical:
        return 'Critical Error';
    }
  }

  /// Humanize field names for display
  String _humanizeFieldName(String fieldName) {
    // Convert camelCase or snake_case to Title Case
    final words = fieldName
        .replaceAllMapped(
          RegExp(r'([A-Z])'),
          (match) => ' ${match.group(1)}',
        )
        .replaceAll('_', ' ')
        .trim()
        .split(' ');

    return words
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }
}
