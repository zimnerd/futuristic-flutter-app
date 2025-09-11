/// Generic API response wrapper
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final String? errorCode;
  final Map<String, dynamic>? metadata;

  const ApiResponse({
    required this.success,
    this.data,
    this.error,
    this.errorCode,
    this.metadata,
  });

  /// Create successful response
  factory ApiResponse.success(T data, {Map<String, dynamic>? metadata}) {
    return ApiResponse<T>(
      success: true,
      data: data,
      metadata: metadata,
    );
  }

  /// Create error response
  factory ApiResponse.error(String error, {String? errorCode, Map<String, dynamic>? metadata}) {
    return ApiResponse<T>(
      success: false,
      error: error,
      errorCode: errorCode,
      metadata: metadata,
    );
  }

  /// Create from JSON
  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) fromJsonT) {
    return ApiResponse<T>(
      success: json['success'] as bool,
      data: json['data'] != null ? fromJsonT(json['data'] as Map<String, dynamic>) : null,
      error: json['error'] as String?,
      errorCode: json['errorCode'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson(Map<String, dynamic> Function(T)? toJsonT) {
    return {
      'success': success,
      'data': data != null && toJsonT != null ? toJsonT(data as T) : data,
      'error': error,
      'errorCode': errorCode,
      'metadata': metadata,
    };
  }

  /// Check if response has data
  bool get hasData => success && data != null;

  /// Check if response has error
  bool get hasError => !success && error != null;

  @override
  String toString() {
    if (success) {
      return 'ApiResponse.success(data: $data)';
    } else {
      return 'ApiResponse.error(error: $error, code: $errorCode)';
    }
  }
}
