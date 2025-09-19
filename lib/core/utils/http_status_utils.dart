/// HTTP status code utilities for API responses
class HttpStatusUtils {
  /// Check if status code indicates success for GET requests
  static bool isGetSuccess(int? statusCode) {
    return statusCode == 200;
  }
  
  /// Check if status code indicates success for POST requests
  static bool isPostSuccess(int? statusCode) {
    return statusCode == 200 || statusCode == 201;
  }
  
  /// Check if status code indicates success for PUT requests
  static bool isPutSuccess(int? statusCode) {
    return statusCode == 200 || statusCode == 201;
  }
  
  /// Check if status code indicates success for PATCH requests
  static bool isPatchSuccess(int? statusCode) {
    return statusCode == 200 || statusCode == 204;
  }
  
  /// Check if status code indicates success for DELETE requests
  static bool isDeleteSuccess(int? statusCode) {
    return statusCode == 200 || statusCode == 204;
  }
  
  /// Check if status code indicates success for any request
  static bool isSuccess(int? statusCode) {
    return statusCode != null && statusCode >= 200 && statusCode < 300;
  }
  
  /// Check if response has successful status code and data
  static bool hasSuccessfulData(dynamic response, {bool requireData = true}) {
    if (response?.statusCode == null) return false;
    
    final isSuccessCode = isSuccess(response.statusCode);
    if (!requireData) return isSuccessCode;
    
    return isSuccessCode && response.data != null;
  }
}