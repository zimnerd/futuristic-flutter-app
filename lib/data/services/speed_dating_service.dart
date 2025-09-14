import 'package:logger/logger.dart';
import '../../core/network/api_client.dart';

/// Service for speed dating feature
class SpeedDatingService {
  final ApiClient _apiClient;
  final Logger _logger = Logger();

  SpeedDatingService(this._apiClient);

  /// Join speed dating session
  Future<Map<String, dynamic>?> joinSpeedDatingSession({
    required String sessionId,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/speed-dating/join',
        data: {
          'sessionId': sessionId,
          'preferences': preferences ?? {},
          'joinedAt': DateTime.now().toIso8601String(),
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        _logger.d('Successfully joined speed dating session: $sessionId');
        return response.data;
      } else {
        _logger.e('Failed to join speed dating session: ${response.statusMessage}');
        return null;
      }
    } catch (e) {
      _logger.e('Error joining speed dating session: $e');
      return null;
    }
  }

  /// Get available speed dating sessions
  Future<List<Map<String, dynamic>>> getAvailableSessions() async {
    try {
      final response = await _apiClient.get('/api/speed-dating/sessions');

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['sessions'] ?? [];
        final sessions = data.map((session) => Map<String, dynamic>.from(session)).toList();
        
        _logger.d('Retrieved ${sessions.length} speed dating sessions');
        return sessions;
      } else {
        _logger.e('Failed to get speed dating sessions: ${response.statusMessage}');
        return [];
      }
    } catch (e) {
      _logger.e('Error getting speed dating sessions: $e');
      return [];
    }
  }

  /// Leave speed dating session
  Future<bool> leaveSession(String sessionId) async {
    try {
      final response = await _apiClient.post(
        '/api/speed-dating/leave',
        data: {
          'sessionId': sessionId,
          'leftAt': DateTime.now().toIso8601String(),
        },
      );

      if (response.statusCode == 200) {
        _logger.d('Successfully left speed dating session: $sessionId');
        return true;
      } else {
        _logger.e('Failed to leave speed dating session: ${response.statusMessage}');
        return false;
      }
    } catch (e) {
      _logger.e('Error leaving speed dating session: $e');
      return false;
    }
  }

  /// Submit compatibility rating for a match
  Future<bool> submitRating({
    required String sessionId,
    required String matchUserId,
    required int rating, // 1-5 scale
    String? feedback,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/speed-dating/rate',
        data: {
          'sessionId': sessionId,
          'matchUserId': matchUserId,
          'rating': rating,
          'feedback': feedback,
          'ratedAt': DateTime.now().toIso8601String(),
        },
      );

      if (response.statusCode == 200) {
        _logger.d('Successfully submitted rating for user: $matchUserId');
        return true;
      } else {
        _logger.e('Failed to submit rating: ${response.statusMessage}');
        return false;
      }
    } catch (e) {
      _logger.e('Error submitting rating: $e');
      return false;
    }
  }

  /// Get speed dating results/matches
  Future<List<Map<String, dynamic>>> getSpeedDatingResults(String sessionId) async {
    try {
      final response = await _apiClient.get('/api/speed-dating/results/$sessionId');

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['matches'] ?? [];
        final matches = data.map((match) => Map<String, dynamic>.from(match)).toList();
        
        _logger.d('Retrieved ${matches.length} speed dating matches');
        return matches;
      } else {
        _logger.e('Failed to get speed dating results: ${response.statusMessage}');
        return [];
      }
    } catch (e) {
      _logger.e('Error getting speed dating results: $e');
      return [];
    }
  }
}
