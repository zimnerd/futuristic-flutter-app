import '../../core/network/api_client.dart';
import '../models/interest_category.dart';
import '../models/interest.dart';

class InterestsRepository {
  final ApiClient _apiClient;

  InterestsRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  /// Fetch all interest categories with nested interests
  Future<List<InterestCategory>> getCategories() async {
    try {
      final response = await _apiClient.getInterestCategories();

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true && data['data'] != null) {
          final categories = data['data']['categories'] as List<dynamic>;
          return categories
              .map(
                (json) =>
                    InterestCategory.fromJson(json as Map<String, dynamic>),
              )
              .toList();
        }
        throw Exception('Invalid response format');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please log in again');
      } else {
        throw Exception(
          'Failed to fetch interest categories: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching interest categories: $e');
    }
  }

  /// Fetch all interests with category information
  Future<List<Interest>> getAllInterests() async {
    try {
      final response = await _apiClient.getAllInterests();

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
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
      final response = await _apiClient.getInterestNames();

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true && data['data'] != null) {
          final names = data['data']['names'] as List<dynamic>;
          return names.map((name) => name as String).toList();
        }
        throw Exception('Invalid response format');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please log in again');
      } else {
        throw Exception(
          'Failed to fetch interest names: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching interest names: $e');
    }
  }
}
