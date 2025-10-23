import 'package:dio/dio.dart';

/// Parses API errors into user-friendly messages
class ErrorParser {
  /// Extract user-friendly error message from DioException
  static String parseError(dynamic error) {
    if (error is DioException) {
      return _parseDioError(error);
    }
    return error.toString();
  }

  /// Parse DioException to extract meaningful error messages
  static String _parseDioError(DioException error) {
    // Try to extract error from response data
    if (error.response?.data != null) {
      final data = error.response!.data;

      // Backend sends errors in this format:
      // { success: false, statusCode: 409, message: "...", error: "...", details: {...} }
      if (data is Map<String, dynamic>) {
        // Check for validation errors first (field-specific)
        if (data['details'] != null && data['details'] is Map) {
          final details = data['details'] as Map<String, dynamic>;
          if (details.isNotEmpty) {
            // Return the first validation error
            final firstError = details.values.first;
            if (firstError is List && firstError.isNotEmpty) {
              return firstError.first.toString();
            }
            return firstError.toString();
          }
        }

        // Return the main error message
        if (data['message'] != null) {
          return _humanizeErrorMessage(data['message'].toString());
        }

        // Fallback to error field
        if (data['error'] != null) {
          return _humanizeErrorMessage(data['error'].toString());
        }
      }

      // If data is a string
      if (data is String && data.isNotEmpty) {
        return _humanizeErrorMessage(data);
      }
    }

    // Handle specific HTTP status codes
    switch (error.response?.statusCode) {
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
    }

    // Handle network errors
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Connection timeout. Please check your internet connection.';
    }

    if (error.type == DioExceptionType.connectionError) {
      return 'Unable to connect to server. Please check your internet connection.';
    }

    // Default message
    return 'An unexpected error occurred. Please try again.';
  }

  /// Humanize error messages (convert technical messages to user-friendly ones)
  static String _humanizeErrorMessage(String message) {
    // Convert common backend error messages to user-friendly format
    final lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('user with this email already exists') ||
        lowerMessage.contains('email already exists') ||
        lowerMessage.contains('email is already registered')) {
      return 'This email is already registered. Please use a different email or sign in.';
    }

    if (lowerMessage.contains('user with this username already exists') ||
        lowerMessage.contains('username already exists') ||
        lowerMessage.contains('username is taken')) {
      return 'This username is already taken. Please choose a different username.';
    }

    if (lowerMessage.contains('user with this phone already exists') ||
        lowerMessage.contains('phone number already exists') ||
        lowerMessage.contains('phone is already registered')) {
      return 'This phone number is already registered. Please use a different number.';
    }

    if (lowerMessage.contains('invalid credentials') ||
        lowerMessage.contains('invalid email or password')) {
      return 'Invalid email or password. Please try again.';
    }

    if (lowerMessage.contains('account is not verified')) {
      return 'Please verify your account before logging in.';
    }

    if (lowerMessage.contains('account is blocked') ||
        lowerMessage.contains('account has been blocked')) {
      return 'Your account has been blocked. Please contact support.';
    }

    if (lowerMessage.contains('password must contain') ||
        lowerMessage.contains('password does not meet')) {
      return 'Password must contain at least 8 characters, including uppercase, lowercase, number, and special character (@\$!%*?&#).';
    }

    // Return original message if no pattern matches
    return message;
  }

  /// Extract field-specific errors for form validation
  static Map<String, String>? extractFieldErrors(dynamic error) {
    if (error is! DioException) return null;

    final data = error.response?.data;
    if (data is! Map<String, dynamic>) return null;

    final details = data['details'];
    if (details is! Map<String, dynamic>) return null;

    final fieldErrors = <String, String>{};
    details.forEach((field, errors) {
      if (errors is List && errors.isNotEmpty) {
        fieldErrors[field] = errors.first.toString();
      } else {
        fieldErrors[field] = errors.toString();
      }
    });

    return fieldErrors.isNotEmpty ? fieldErrors : null;
  }

  /// Determine which field has the error based on the message
  static String? getErrorField(String message) {
    final lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('email')) return 'email';
    if (lowerMessage.contains('username')) return 'username';
    if (lowerMessage.contains('phone')) return 'phone';
    if (lowerMessage.contains('password')) return 'password';
    if (lowerMessage.contains('name')) return 'name';

    return null; // General error, not field-specific
  }
}
