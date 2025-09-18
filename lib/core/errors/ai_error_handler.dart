import 'dart:io';
import 'package:dio/dio.dart';

/// Enhanced error handling for AI service calls
/// Provides structured error responses and appropriate fallback strategies
class AiErrorHandler {
  /// Handle API errors and provide structured error information
  static AiErrorResult handleError(dynamic error, String operationType) {
    if (error is DioException) {
      return _handleDioError(error, operationType);
    } else if (error is SocketException) {
      return AiErrorResult(
        type: AiErrorType.network,
        message: 'Network connection failed',
        shouldFallbackToMock: true,
        canRetry: true,
        operationType: operationType,
      );
    } else if (error is FormatException) {
      return AiErrorResult(
        type: AiErrorType.parsing,
        message: 'Failed to parse API response',
        shouldFallbackToMock: true,
        canRetry: false,
        operationType: operationType,
      );
    } else {
      return AiErrorResult(
        type: AiErrorType.unknown,
        message: 'Unexpected error occurred: ${error.toString()}',
        shouldFallbackToMock: true,
        canRetry: false,
        operationType: operationType,
      );
    }
  }

  static AiErrorResult _handleDioError(DioException error, String operationType) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AiErrorResult(
          type: AiErrorType.timeout,
          message: 'Request timed out',
          shouldFallbackToMock: true,
          canRetry: true,
          operationType: operationType,
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 0;
        return _handleHttpError(statusCode, error.response?.data, operationType);

      case DioExceptionType.cancel:
        return AiErrorResult(
          type: AiErrorType.cancelled,
          message: 'Request was cancelled',
          shouldFallbackToMock: false,
          canRetry: true,
          operationType: operationType,
        );

      case DioExceptionType.connectionError:
        return AiErrorResult(
          type: AiErrorType.network,
          message: 'Failed to connect to server',
          shouldFallbackToMock: true,
          canRetry: true,
          operationType: operationType,
        );

      default:
        return AiErrorResult(
          type: AiErrorType.unknown,
          message: error.message ?? 'Unknown API error',
          shouldFallbackToMock: true,
          canRetry: false,
          operationType: operationType,
        );
    }
  }

  static AiErrorResult _handleHttpError(
    int statusCode,
    dynamic responseData,
    String operationType,
  ) {
    String message = 'API error occurred';
    AiErrorType type = AiErrorType.api;
    bool canRetry = false;

    // Try to extract error message from response
    if (responseData is Map<String, dynamic>) {
      message = responseData['message'] ?? responseData['error'] ?? message;
    }

    switch (statusCode) {
      case 400:
        type = AiErrorType.validation;
        message = 'Invalid request: $message';
        break;
      case 401:
        type = AiErrorType.authentication;
        message = 'Authentication failed';
        break;
      case 403:
        type = AiErrorType.authorization;
        message = 'Access denied';
        break;
      case 404:
        type = AiErrorType.notFound;
        message = 'Resource not found';
        break;
      case 429:
        type = AiErrorType.rateLimited;
        message = 'Too many requests, please try again later';
        canRetry = true;
        break;
      case 500:
      case 502:
      case 503:
      case 504:
        type = AiErrorType.server;
        message = 'Server error, please try again';
        canRetry = true;
        break;
    }

    return AiErrorResult(
      type: type,
      message: message,
      shouldFallbackToMock: statusCode >= 500,
      canRetry: canRetry,
      operationType: operationType,
      statusCode: statusCode,
    );
  }

  /// Log error with appropriate level based on error type
  static void logError(AiErrorResult error) {
    final logLevel = _getLogLevel(error.type);
    final message = '[AI Error] ${error.operationType}: ${error.message}';
    
    switch (logLevel) {
      case 'DEBUG':
        print('🐛 $message');
        break;
      case 'INFO':
        print('ℹ️ $message');
        break;
      case 'WARNING':
        print('⚠️ $message');
        break;
      case 'ERROR':
        print('❌ $message');
        break;
    }
  }

  static String _getLogLevel(AiErrorType type) {
    switch (type) {
      case AiErrorType.network:
      case AiErrorType.timeout:
        return 'WARNING';
      case AiErrorType.authentication:
      case AiErrorType.authorization:
      case AiErrorType.server:
        return 'ERROR';
      case AiErrorType.validation:
      case AiErrorType.parsing:
        return 'WARNING';
      case AiErrorType.cancelled:
        return 'INFO';
      default:
        return 'ERROR';
    }
  }
}

/// Structured error result for AI operations
class AiErrorResult {
  final AiErrorType type;
  final String message;
  final bool shouldFallbackToMock;
  final bool canRetry;
  final String operationType;
  final int? statusCode;

  const AiErrorResult({
    required this.type,
    required this.message,
    required this.shouldFallbackToMock,
    required this.canRetry,
    required this.operationType,
    this.statusCode,
  });

  @override
  String toString() {
    return 'AiErrorResult(type: $type, message: $message, canRetry: $canRetry)';
  }
}

/// Types of AI operation errors
enum AiErrorType {
  network,
  timeout,
  authentication,
  authorization,
  validation,
  notFound,
  rateLimited,
  server,
  api,
  parsing,
  cancelled,
  unknown,
}