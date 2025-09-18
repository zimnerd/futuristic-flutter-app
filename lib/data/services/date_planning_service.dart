import 'package:logger/logger.dart';
import '../../core/network/api_client.dart';

/// Service for date planning and suggestions
/// TODO: Backend module needs to be created for date-planning features
/// Currently using placeholder endpoints - requires backend implementation
class DatePlanningService {
  final ApiClient _apiClient;
  final Logger _logger = Logger();

  DatePlanningService(this._apiClient);

  /// Get AI-powered date suggestions
  Future<List<Map<String, dynamic>>> getDateSuggestions({
    required String matchId,
    String? location,
    String? dateType, // 'casual', 'romantic', 'active', 'cultural'
    int? budget, // in cents
    List<String>? interests,
  }) async {
    try {
      final response = await _apiClient.post(
        '/date-planning/suggestions',
        data: {
          'matchId': matchId,
          if (location != null) 'location': location,
          if (dateType != null) 'dateType': dateType,
          if (budget != null) 'budget': budget,
          if (interests != null) 'interests': interests,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['suggestions'] ?? [];
        final suggestions = data.map((suggestion) => Map<String, dynamic>.from(suggestion)).toList();
        
        _logger.d('Retrieved ${suggestions.length} date suggestions');
        return suggestions;
      } else {
        _logger.e('Failed to get date suggestions: ${response.statusMessage}');
        return [];
      }
    } catch (e) {
      _logger.e('Error getting date suggestions: $e');
      return [];
    }
  }

  /// Plan a date with specific details
  Future<Map<String, dynamic>?> planDate({
    required String matchId,
    required String venue,
    required DateTime dateTime,
    String? description,
    Map<String, dynamic>? details,
  }) async {
    try {
      final response = await _apiClient.post(
        '/date-planning/plans',
        data: {
          'matchId': matchId,
          'venue': venue,
          'dateTime': dateTime.toIso8601String(),
          if (description != null) 'description': description,
          if (details != null) 'details': details,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        _logger.d('Successfully planned date: ${response.data['dateId']}');
        return response.data;
      } else {
        _logger.e('Failed to plan date: ${response.statusMessage}');
        return null;
      }
    } catch (e) {
      _logger.e('Error planning date: $e');
      return null;
    }
  }

  /// Accept a date invitation
  Future<bool> acceptDateInvitation(String dateId) async {
    try {
      final response = await _apiClient.put(
        '/date-planning/plans/$dateId/accept',
        data: {
          'dateId': dateId,
        },
      );

      if (response.statusCode == 200) {
        _logger.d('Successfully accepted date invitation: $dateId');
        return true;
      } else {
        _logger.e('Failed to accept date invitation: ${response.statusMessage}');
        return false;
      }
    } catch (e) {
      _logger.e('Error accepting date invitation: $e');
      return false;
    }
  }

  /// Decline a date invitation
  Future<bool> declineDateInvitation(String dateId, {String? reason}) async {
    try {
      final response = await _apiClient.put(
        '/date-planning/plans/$dateId/decline',
        data: {
          'dateId': dateId,
          if (reason != null) 'reason': reason,
        },
      );

      if (response.statusCode == 200) {
        _logger.d('Successfully declined date invitation: $dateId');
        return true;
      } else {
        _logger.e('Failed to decline date invitation: ${response.statusMessage}');
        return false;
      }
    } catch (e) {
      _logger.e('Error declining date invitation: $e');
      return false;
    }
  }

  /// Reschedule a planned date
  Future<bool> rescheduleDate({
    required String dateId,
    required DateTime newDateTime,
    String? reason,
  }) async {
    try {
      final response = await _apiClient.put(
        '/date-planning/plans/$dateId/reschedule',
        data: {
          'dateId': dateId,
          'newDateTime': newDateTime.toIso8601String(),
          if (reason != null) 'reason': reason,
        },
      );

      if (response.statusCode == 200) {
        _logger.d('Successfully rescheduled date: $dateId');
        return true;
      } else {
        _logger.e('Failed to reschedule date: ${response.statusMessage}');
        return false;
      }
    } catch (e) {
      _logger.e('Error rescheduling date: $e');
      return false;
    }
  }

  /// Cancel a planned date
  Future<bool> cancelDate(String dateId, {String? reason}) async {
    try {
      final response = await _apiClient.delete(
        '/date-planning/plans/$dateId',
        data: {
          'dateId': dateId,
          if (reason != null) 'reason': reason,
        },
      );

      if (response.statusCode == 200) {
        _logger.d('Successfully cancelled date: $dateId');
        return true;
      } else {
        _logger.e('Failed to cancel date: ${response.statusMessage}');
        return false;
      }
    } catch (e) {
      _logger.e('Error cancelling date: $e');
      return false;
    }
  }

  /// Get upcoming dates
  Future<List<Map<String, dynamic>>> getUpcomingDates() async {
    try {
      final response = await _apiClient.get('/date-planning/plans');

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['plans'] ?? response.data['dates'] ?? [];
        final dates = data.map((date) => Map<String, dynamic>.from(date)).toList();
        
        _logger.d('Retrieved ${dates.length} upcoming dates');
        return dates;
      } else {
        _logger.e('Failed to get upcoming dates: ${response.statusMessage}');
        return [];
      }
    } catch (e) {
      _logger.e('Error getting upcoming dates: $e');
      return [];
    }
  }

  /// Get date history
  Future<List<Map<String, dynamic>>> getDateHistory({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        '/date-planning/plans/history',
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['dates'] ?? [];
        final dates = data.map((date) => Map<String, dynamic>.from(date)).toList();
        
        _logger.d('Retrieved ${dates.length} date history records');
        return dates;
      } else {
        _logger.e('Failed to get date history: ${response.statusMessage}');
        return [];
      }
    } catch (e) {
      _logger.e('Error getting date history: $e');
      return [];
    }
  }

  /// Rate a completed date
  Future<bool> rateDate({
    required String dateId,
    required int rating, // 1-5 scale
    String? feedback,
    List<String>? tags,
  }) async {
    try {
      final response = await _apiClient.post(
        '/date-planning/plans/$dateId/rate',
        data: {
          'dateId': dateId,
          'rating': rating,
          if (feedback != null) 'feedback': feedback,
          if (tags != null) 'tags': tags,
        },
      );

      if (response.statusCode == 200) {
        _logger.d('Successfully rated date: $dateId');
        return true;
      } else {
        _logger.e('Failed to rate date: ${response.statusMessage}');
        return false;
      }
    } catch (e) {
      _logger.e('Error rating date: $e');
      return false;
    }
  }

  /// Get nearby venues for dates
  Future<List<Map<String, dynamic>>> getNearbyVenues({
    required double latitude,
    required double longitude,
    String? category, // 'restaurant', 'cafe', 'entertainment', 'outdoor'
    int radiusKm = 10,
  }) async {
    try {
      final response = await _apiClient.get(
        '/date-planning/venues',
        queryParameters: {
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
          'radiusKm': radiusKm.toString(),
          if (category != null) 'category': category,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['venues'] ?? [];
        final venues = data.map((venue) => Map<String, dynamic>.from(venue)).toList();
        
        _logger.d('Retrieved ${venues.length} nearby venues');
        return venues;
      } else {
        _logger.e('Failed to get nearby venues: ${response.statusMessage}');
        return [];
      }
    } catch (e) {
      _logger.e('Error getting nearby venues: $e');
      return [];
    }
  }

  /// Get date ideas based on interests
  Future<List<Map<String, dynamic>>> getDateIdeas({
    List<String>? interests,
    String? season,
    String? timeOfDay, // 'morning', 'afternoon', 'evening', 'night'
    bool isFirstDate = false,
  }) async {
    try {
      final response = await _apiClient.get(
        '/date-planning/ideas',
        queryParameters: {
          if (interests != null) 'interests': interests,
          if (season != null) 'season': season,
          if (timeOfDay != null) 'timeOfDay': timeOfDay,
          if (isFirstDate) 'isFirstDate': isFirstDate.toString(),
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['ideas'] ?? [];
        final ideas = data.map((idea) => Map<String, dynamic>.from(idea)).toList();
        
        _logger.d('Retrieved ${ideas.length} date ideas');
        return ideas;
      } else {
        _logger.e('Failed to get date ideas: ${response.statusMessage}');
        return [];
      }
    } catch (e) {
      _logger.e('Error getting date ideas: $e');
      return [];
    }
  }
}
