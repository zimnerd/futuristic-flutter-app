import 'package:dio/dio.dart';

/// Centralized response parser for consistent API response handling
/// 
/// All backend responses follow the format:
/// ```json
/// {
///   "success": true,
///   "statusCode": 200,
///   "message": "Success",
///   "data": [actual_data]
/// }
/// ```
class ResponseParser {
  /// Extract data from standardized API response wrapper
  /// This handles the backend's consistent { data: ... } structure
  static dynamic extractData(Response response) {
    if (response.data == null) {
      throw Exception('Response data is null');
    }

    final responseData = response.data;
    
    // If response is wrapped in standard format, extract data field
    if (responseData is Map<String, dynamic>) {
      return responseData['data'] ?? responseData;
    }

    throw Exception('Response data is not a valid Map');
  }

  /// Extract a specific field from the extracted data
  static T? extractField<T>(Response response, String fieldName) {
    try {
      final data = extractData(response);
      if (data is Map<String, dynamic>) {
        return data[fieldName] as T?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Helper for common list extraction pattern
  static List<dynamic> extractList(Response response, String fieldName) {
    return extractField<List<dynamic>>(response, fieldName) ?? [];
  }

  /// Extract list directly from data field (when data itself is a list)
  static List<dynamic> extractListDirect(Response response) {
    final data = extractData(response);
    if (data is List) {
      return data;
    }
    return [];
  }
}