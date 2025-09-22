import 'package:dio/dio.dart';

/// Centralized response parser for consistent API response handling
/// 
/// All backend responses follow the format:
/// {
///   "success": true,
///   "statusCode": 200,
///   "message": "Success",
///   "data": <actual_data>
/// }
class ResponseParser {
  /// Extract data from standardized API response wrapper
  static T extractData<T>(Response response) {
    if (response.data == null) {
      throw Exception('Response data is null');
    }

    final responseData = response.data;
    
    // If response is already unwrapped (has the actual data), return it
    if (responseData is T) {
      return responseData;
    }

    // If response is wrapped in standard format, extract data field
    if (responseData is Map<String, dynamic>) {
      final data = responseData['data'];
      if (data is T) {
        return data;
      }
      // If data is null but T is nullable, allow it
      if (data == null) {
        return data as T;
      }
    }

    throw Exception('Unable to extract data of type $T from response');
  }

  /// Extract list data from response
  static List<dynamic> extractListData(Response response) {
    final data = extractData<dynamic>(response);
    
    if (data is List) {
      return data;
    }
    
    if (data is Map<String, dynamic>) {
      // Handle cases where list is nested in a field
      for (final value in data.values) {
        if (value is List) {
          return value;
        }
      }
    }
    
    return [];
  }

  /// Extract specific field from nested response data
  static T? extractField<T>(Response response, String fieldName) {
    try {
      final data = extractData<Map<String, dynamic>>(response);
      return data[fieldName] as T?;
    } catch (e) {
      return null;
    }
  }
}