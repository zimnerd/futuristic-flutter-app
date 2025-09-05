import 'package:dio/dio.dart';

/// API service interface for handling HTTP requests to the backend
abstract class ApiService {
  // Base Configuration
  String get baseUrl;
  Map<String, String> get defaultHeaders;
  Duration get connectTimeout;
  Duration get receiveTimeout;

  // Authentication Headers
  void setAuthToken(String token);
  void clearAuthToken();
  String? getAuthToken();

  // HTTP Methods
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    CancelToken? cancelToken,
  });

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    CancelToken? cancelToken,
  });

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    CancelToken? cancelToken,
  });

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    CancelToken? cancelToken,
  });

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    CancelToken? cancelToken,
  });

  // File Upload
  Future<Response<T>> uploadFile<T>(
    String path,
    String filePath, {
    String fileName = 'file',
    Map<String, dynamic>? data,
    Map<String, String>? headers,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  });

  Future<Response<T>> uploadMultipleFiles<T>(
    String path,
    List<String> filePaths, {
    List<String>? fileNames,
    Map<String, dynamic>? data,
    Map<String, String>? headers,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  });

  // File Download
  Future<Response> downloadFile(
    String urlPath,
    String savePath, {
    ProgressCallback? onReceiveProgress,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    bool deleteOnError = true,
  });

  // Request Interceptors
  void addRequestInterceptor(InterceptorsWrapper interceptor);
  void addResponseInterceptor(InterceptorsWrapper interceptor);
  void clearInterceptors();

  // Error Handling
  Future<T> handleApiCall<T>(Future<Response> Function() apiCall);
  String extractErrorMessage(dynamic error);

  // Connection Status
  Future<bool> checkConnectivity();
  Future<bool> pingServer();

  // Cache Management
  void enableCaching({Duration? maxAge});
  void disableCaching();
  void clearCache();

  // Request Cancellation
  CancelToken createCancelToken();
  void cancelAllRequests();

  // Retry Logic
  Future<Response<T>> retryRequest<T>(
    Future<Response<T>> Function() request, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
  });

  // Multipart Data
  FormData createFormData(Map<String, dynamic> data);

  // Request/Response Logging
  void enableLogging({bool logHeaders = true, bool logBody = true});
  void disableLogging();

  // URL Building
  String buildUrl(String path, {Map<String, dynamic>? queryParameters});
}
