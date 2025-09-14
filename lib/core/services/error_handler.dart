import 'package:logger/logger.dart';

/// Global error handler for the application
class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  final Logger _logger = Logger();

  /// Handle API errors
  String handleApiError(dynamic error) {
    _logger.e('API Error: $error');
    
    if (error.toString().contains('401')) {
      return 'Authentication required. Please log in again.';
    } else if (error.toString().contains('403')) {
      return 'Access denied. You don\'t have permission for this action.';
    } else if (error.toString().contains('404')) {
      return 'Resource not found.';
    } else if (error.toString().contains('500')) {
      return 'Server error. Please try again later.';
    } else if (error.toString().contains('Network')) {
      return 'Network error. Please check your connection.';
    } else if (error.toString().contains('timeout')) {
      return 'Request timeout. Please try again.';
    }
    
    return 'An unexpected error occurred. Please try again.';
  }

  /// Handle WebSocket errors
  String handleWebSocketError(dynamic error) {
    _logger.e('WebSocket Error: $error');
    
    if (error.toString().contains('Connection')) {
      return 'Connection lost. Reconnecting...';
    } else if (error.toString().contains('Authentication')) {
      return 'Authentication failed. Please log in again.';
    }
    
    return 'Real-time connection error. Retrying...';
  }

  /// Handle WebRTC errors
  String handleWebRTCError(dynamic error) {
    _logger.e('WebRTC Error: $error');
    
    if (error.toString().contains('Permission')) {
      return 'Camera/microphone permission required.';
    } else if (error.toString().contains('Network')) {
      return 'Network connection issues during call.';
    } else if (error.toString().contains('Device')) {
      return 'Device not supported for video calls.';
    }
    
    return 'Call error. Please try again.';
  }

  /// Handle general errors
  String handleGeneralError(dynamic error) {
    _logger.e('General Error: $error');
    return 'An error occurred. Please try again.';
  }

  /// Log error for debugging
  void logError(String context, dynamic error, [StackTrace? stackTrace]) {
    _logger.e('[$context] Error: $error', error: error, stackTrace: stackTrace);
  }

  /// Log warning
  void logWarning(String context, String message) {
    _logger.w('[$context] Warning: $message');
  }

  /// Log info
  void logInfo(String context, String message) {
    _logger.i('[$context] Info: $message');
  }
}