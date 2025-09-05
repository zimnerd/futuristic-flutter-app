import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../../core/config/app_config.dart';
import '../../domain/services/api_service.dart';
import '../exceptions/app_exceptions.dart';

/// Concrete implementation of ApiService using Dio HTTP client
class ApiServiceImpl implements ApiService {
  late final Dio _dio;
  final Logger _logger = Logger();
  String? _authToken;

  ApiServiceImpl({
    String? baseUrl,
    Duration? connectTimeout,
    Duration? receiveTimeout,
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? AppConfig.apiBaseUrl,
        connectTimeout: connectTimeout ?? AppConfig.apiTimeout,
        receiveTimeout: receiveTimeout ?? AppConfig.apiTimeout,
        headers: defaultHeaders,
      ),
    );

    _setupInterceptors();
  }

  @override
  String get baseUrl => _dio.options.baseUrl;

  @override
  Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': AppConfig.userAgent,
    'X-Platform': 'mobile-flutter', // Identify as mobile Flutter app
    'X-App-Version': AppConfig.appVersion, // App version for backend tracking
    'Access-Control-Allow-Origin': '*', // For CORS preflight
    'Access-Control-Allow-Methods': 'GET,PUT,POST,DELETE,PATCH,OPTIONS',
    'Access-Control-Allow-Headers':
        'Content-Type,Authorization,X-Requested-With,Accept,Origin,User-Agent',
  };

  @override
  Duration get connectTimeout =>
      _dio.options.connectTimeout ?? AppConfig.apiTimeout;

  @override
  Duration get receiveTimeout =>
      _dio.options.receiveTimeout ?? AppConfig.apiTimeout;

  void _setupInterceptors() {
    // Request interceptor for authentication
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_authToken != null) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }
          _logger.d('🚀 REQUEST: ${options.method} ${options.path}');
          _logger.d('📤 Headers: ${options.headers}');
          if (options.data != null) {
            _logger.d('📤 Body: ${options.data}');
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.d(
            '✅ RESPONSE: ${response.statusCode} ${response.requestOptions.path}',
          );
          _logger.d('📥 Data: ${response.data}');
          handler.next(response);
        },
        onError: (error, handler) {
          _logger.e('❌ ERROR: ${error.requestOptions.path}');
          _logger.e('📥 Error: ${error.message}');
          _logger.e('📥 Response: ${error.response?.data}');
          handler.next(error);
        },
      ),
    );

    // Retry interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          if (error.response?.statusCode == 401 && _authToken != null) {
            // Token expired, try to refresh
            try {
              await _refreshToken();
              // Retry the original request
              final clonedRequest = await _dio.request(
                error.requestOptions.path,
                options: Options(
                  method: error.requestOptions.method,
                  headers: error.requestOptions.headers,
                ),
                data: error.requestOptions.data,
                queryParameters: error.requestOptions.queryParameters,
              );
              return handler.resolve(clonedRequest);
            } catch (refreshError) {
              // Refresh failed, clear token and pass error
              _authToken = null;
              handler.next(error);
            }
          } else {
            handler.next(error);
          }
        },
      ),
    );
  }

  @override
  void setAuthToken(String token) {
    _authToken = token;
    _logger.i('🔑 Auth token set');
  }

  @override
  void clearAuthToken() {
    _authToken = null;
    _logger.i('🔑 Auth token cleared');
  }

  @override
  String? getAuthToken() => _authToken;

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: Options(headers: headers),
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: headers),
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: headers),
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: headers),
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: headers),
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<Response<T>> uploadFile<T>(
    String path,
    String filePath, {
    String fileName = 'file',
    Map<String, dynamic>? data,
    Map<String, String>? headers,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final formData = FormData.fromMap({
        fileName: await MultipartFile.fromFile(filePath),
        if (data != null) ...data,
      });

      return await _dio.post<T>(
        path,
        data: formData,
        options: Options(headers: headers),
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<Response<T>> uploadMultipleFiles<T>(
    String path,
    List<String> filePaths, {
    List<String>? fileNames,
    Map<String, dynamic>? data,
    Map<String, String>? headers,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final Map<String, dynamic> formDataMap = {};

      for (int i = 0; i < filePaths.length; i++) {
        final fileName = fileNames != null && fileNames.length > i
            ? fileNames[i]
            : 'file_$i';
        formDataMap[fileName] = await MultipartFile.fromFile(filePaths[i]);
      }

      if (data != null) {
        formDataMap.addAll(data);
      }

      final formData = FormData.fromMap(formDataMap);

      return await _dio.post<T>(
        path,
        data: formData,
        options: Options(headers: headers),
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<Response> downloadFile(
    String urlPath,
    String savePath, {
    ProgressCallback? onReceiveProgress,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    bool deleteOnError = true,
  }) async {
    try {
      return await _dio.download(
        urlPath,
        savePath,
        queryParameters: queryParameters,
        onReceiveProgress: onReceiveProgress,
        cancelToken: cancelToken,
        deleteOnError: deleteOnError,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  void addRequestInterceptor(InterceptorsWrapper interceptor) {
    _dio.interceptors.add(interceptor);
  }

  @override
  void addResponseInterceptor(InterceptorsWrapper interceptor) {
    _dio.interceptors.add(interceptor);
  }

  @override
  void clearInterceptors() {
    _dio.interceptors.clear();
    _setupInterceptors(); // Re-add default interceptors
  }

  @override
  Future<T> handleApiCall<T>(Future<Response> Function() apiCall) async {
    try {
      final response = await apiCall();
      return response.data as T;
    } on DioException catch (e) {
      throw _mapDioException(e);
    } catch (e) {
      throw GenericException('Unexpected error: ${e.toString()}');
    }
  }

  @override
  String extractErrorMessage(dynamic error) {
    if (error is DioException) {
      if (error.response?.data is Map) {
        final data = error.response!.data as Map;
        return data['message'] ?? data['error'] ?? 'Unknown error occurred';
      }
      return error.message ?? 'Network error occurred';
    }
    if (error is AppException) {
      return error.message;
    }
    return error.toString();
  }

  @override
  Future<bool> checkConnectivity() async {
    try {
      final response = await _dio.get('/health');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> pingServer() async {
    try {
      final response = await _dio.get('/ping');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  void enableCaching({Duration? maxAge}) {
    // Implementation depends on caching strategy
    // Could use dio_cache_interceptor package
  }

  @override
  void disableCaching() {
    // Remove caching interceptor
  }

  @override
  void clearCache() {
    // Clear cached responses
  }

  @override
  CancelToken createCancelToken() => CancelToken();

  @override
  void cancelAllRequests() {
    // Cancel all ongoing requests
  }

  @override
  Future<Response<T>> retryRequest<T>(
    Future<Response<T>> Function() request, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
  }) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        return await request();
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) rethrow;
        await Future.delayed(delay * attempts);
      }
    }
    throw GenericException('Max retries exceeded');
  }

  @override
  FormData createFormData(Map<String, dynamic> data) {
    return FormData.fromMap(data);
  }

  @override
  void enableLogging({bool logHeaders = true, bool logBody = true}) {
    // Logging is already enabled via interceptors
    _logger.i('📝 API logging enabled');
  }

  @override
  void disableLogging() {
    _logger.i('📝 API logging disabled');
  }

  @override
  String buildUrl(String path, {Map<String, dynamic>? queryParameters}) {
    final uri = Uri.parse('$baseUrl$path');
    if (queryParameters != null) {
      return uri.replace(queryParameters: queryParameters).toString();
    }
    return uri.toString();
  }

  AppException _mapDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutException();
      case DioExceptionType.connectionError:
        return const NoInternetException();
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = extractErrorMessage(error);

        switch (statusCode) {
          case 401:
            return const UnauthorizedException();
          case 404:
            return UserNotFoundException();
          case 422:
            return ValidationException(message);
          case 500:
            return ServerException('Server error', statusCode: statusCode);
          default:
            return ServerException(message, statusCode: statusCode);
        }
      case DioExceptionType.cancel:
        return const GenericException('Request was cancelled');
      case DioExceptionType.unknown:
        return NetworkException(error.message ?? 'Unknown network error');
      default:
        return GenericException('Unexpected error: ${error.message}');
    }
  }

  Future<void> _refreshToken() async {
    // Implementation for token refresh
    // This would typically call a refresh endpoint
    throw const TokenExpiredException();
  }
}
