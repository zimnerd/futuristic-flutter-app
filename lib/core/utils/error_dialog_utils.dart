import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../presentation/theme/pulse_colors.dart';
import '../../presentation/widgets/common/pulse_toast.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';

/// Utility class for showing error dialogs with detailed error information
class ErrorDialogUtils {
  /// Show a comprehensive error dialog based on the error type
  static Future<void> showErrorDialog(
    BuildContext context,
    dynamic error, {
    String? title,
    String? customMessage,
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
  }) async {
    final errorInfo = _parseError(context, error);

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(errorInfo.icon, color: errorInfo.color, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title ?? errorInfo.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customMessage ?? errorInfo.message,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
                if (errorInfo.details != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: context.outlineColor.withValues(alpha: 0.3)!,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: context.onSurfaceVariantColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Error Details',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: context.onSurfaceVariantColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          errorInfo.details!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[800],
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (errorInfo.statusCode != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: errorInfo.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: errorInfo.color.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          'Status: ${errorInfo.statusCode}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: errorInfo.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            if (onRetry != null)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onRetry();
                },
                child: Text(
                  'Retry',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onDismiss?.call();
              },
              child: Text(
                onRetry != null ? 'Cancel' : 'OK',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: onRetry != null
                      ? context.onSurfaceVariantColor
                      : PulseColors.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Show a simple error snackbar for non-critical errors
  static void showErrorSnackbar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    PulseToast.error(context, message: message);
  }

  /// Parse error and extract relevant information
  static ErrorInfo _parseError(BuildContext context, dynamic error) {
    // Handle DioException (HTTP errors)
    if (error is DioException) {
      return _parseDioException(context, error);
    }

    // Handle custom app exceptions
    if (error is Exception) {
      return ErrorInfo(
        title: 'Error',
        message: error.toString().replaceAll('Exception: ', ''),
        icon: Icons.error_outline,
        color: PulseColors.error,
      );
    }

    // Handle string errors
    if (error is String) {
      return ErrorInfo(
        title: 'Error',
        message: error,
        icon: Icons.error_outline,
        color: PulseColors.error,
      );
    }

    // Unknown error
    return ErrorInfo(
      title: 'Unexpected Error',
      message: 'An unexpected error occurred. Please try again.',
      details: error.toString(),
      icon: Icons.warning_amber_rounded,
      color: Colors.orange,
    );
  }

  /// Parse DioException and extract HTTP error details
  static ErrorInfo _parseDioException(
    BuildContext context,
    DioException error,
  ) {
    final statusCode = error.response?.statusCode;
    String title;
    String message;
    IconData icon;
    Color color;
    String? details;

    switch (statusCode) {
      case 400:
        title = 'Invalid Request';
        message = 'The request contains invalid data. Please check your input.';
        icon = Icons.warning_amber_rounded;
        color = Colors.orange;
        // Extract validation errors if available
        if (error.response?.data != null) {
          final data = error.response!.data;
          if (data is Map && data['message'] != null) {
            if (data['message'] is List) {
              details = (data['message'] as List).join('\n• ');
              details = '• $details';
            } else {
              details = data['message'].toString();
            }
          }
        }
        break;

      case 401:
        title = 'Authentication Required';
        message = 'Your session has expired. Please log in again.';
        icon = Icons.lock_outline;
        color = Colors.red;
        break;

      case 403:
        title = 'Access Denied';
        message = 'You don\'t have permission to perform this action.';
        icon = Icons.block;
        color = Colors.red[700]!;
        break;

      case 404:
        title = 'Not Found';
        message = 'The requested resource could not be found.';
        icon = Icons.search_off;
        color = context.onSurfaceVariantColor!;
        break;

      case 409:
        title = 'Conflict';
        message = 'This action conflicts with existing data.';
        icon = Icons.sync_problem;
        color = Colors.orange[700]!;
        if (error.response?.data != null &&
            error.response!.data['message'] != null) {
          details = error.response!.data['message'].toString();
        }
        break;

      case 422:
        title = 'Validation Error';
        message = 'The provided data failed validation.';
        icon = Icons.error_outline;
        color = Colors.orange;
        if (error.response?.data != null &&
            error.response!.data['message'] != null) {
          if (error.response!.data['message'] is List) {
            details = (error.response!.data['message'] as List).join('\n• ');
            details = '• $details';
          } else {
            details = error.response!.data['message'].toString();
          }
        }
        break;

      case 429:
        title = 'Too Many Requests';
        message =
            'You\'re making too many requests. Please wait a moment and try again.';
        icon = Icons.speed;
        color = Colors.amber[700]!;
        break;

      case 500:
      case 502:
      case 503:
      case 504:
        title = 'Server Error';
        message = 'The server encountered an error. Please try again later.';
        icon = Icons.cloud_off;
        color = Colors.red[800]!;
        details = 'Status code: $statusCode';
        break;

      default:
        // Handle network errors (no response)
        if (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.sendTimeout ||
            error.type == DioExceptionType.receiveTimeout) {
          title = 'Connection Timeout';
          message =
              'The request took too long. Please check your internet connection and try again.';
          icon = Icons.timer_off;
          color = Colors.orange[700]!;
        } else if (error.type == DioExceptionType.connectionError) {
          title = 'Connection Error';
          message =
              'Unable to connect to the server. Please check your internet connection.';
          icon = Icons.wifi_off;
          color = context.onSurfaceVariantColor!;
        } else if (error.type == DioExceptionType.cancel) {
          title = 'Request Cancelled';
          message = 'The request was cancelled.';
          icon = Icons.cancel_outlined;
          color = context.onSurfaceVariantColor!;
        } else {
          title = 'Network Error';
          message = 'A network error occurred. Please try again.';
          icon = Icons.error_outline;
          color = PulseColors.error;
          details = error.message;
        }
    }

    return ErrorInfo(
      title: title,
      message: message,
      details: details,
      icon: icon,
      color: color,
      statusCode: statusCode,
    );
  }
}

/// Model class to hold error information
class ErrorInfo {
  final String title;
  final String message;
  final String? details;
  final IconData icon;
  final Color color;
  final int? statusCode;

  ErrorInfo({
    required this.title,
    required this.message,
    this.details,
    required this.icon,
    required this.color,
    this.statusCode,
  });
}
