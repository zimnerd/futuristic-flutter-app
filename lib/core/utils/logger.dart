import 'dart:developer' as developer;

/// Application logger utility with different log levels
class AppLogger {
  static const String _tag = 'PulseLink';
  
  /// Log debug message
  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: _tag,
      level: 500, // Debug level
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log info message
  static void info(String message, [dynamic error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: _tag,
      level: 800, // Info level
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log warning message
  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: _tag,
      level: 900, // Warning level
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log error message
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: _tag,
      level: 1000, // Error level
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log severe/fatal message
  static void severe(String message, [dynamic error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: _tag,
      level: 1200, // Severe level
      error: error,
      stackTrace: stackTrace,
    );
  }
}
