import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/interest_category.dart';
import '../models/interest.dart';

class InterestsRepository {
  final String baseUrl;
  final String? accessToken;

  InterestsRepository({
    required this.baseUrl,
    this.accessToken,
  });

  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (accessToken != null) {
      headers['Authorization'] = 'Bearer $accessToken';
    }
    return headers;
  }

  /// Fetch all interest categories with nested interests
  Future<List<InterestCategory>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/interests/categories'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final categories = data['data']['categories'] as List<dynamic>;
          return categories
              .map((json) => InterestCategory.fromJson(json as Map<String, dynamic>))
              .toList();
        }
        throw Exception('Invalid response format');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please log in again');
      } else {
        throw Exception('Failed to fetch interest categories: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching interest categories: $e');
    }
  }

  /// Fetch all interests with category information
  Future<List<Interest>> getAllInterests() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/interests'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final interests = data['data']['interests'] as List<dynamic>;
          return interests
              .map((json) => Interest.fromJson(json as Map<String, dynamic>))
              .toList();
        }
        throw Exception('Invalid response format');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please log in again');
      } else {
        throw Exception('Failed to fetch interests: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching interests: $e');
    }
  }

  /// Fetch just the interest names (backward compatibility)
  Future<List<String>> getInterestNames() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/interests/names'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final names = data['data']['names'] as List<dynamic>;
          return names.map((name) => name as String).toList();
        }
        throw Exception('Invalid response format');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please log in again');
      } else {
        throw Exception('Failed to fetch interest names: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching interest names: $e');
    }
  }
}
