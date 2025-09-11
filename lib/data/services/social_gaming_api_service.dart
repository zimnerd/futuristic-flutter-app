import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../core/utils/logger.dart';
import '../models/achievement.dart';
import '../models/leaderboard_entry.dart';

/// Service for social gaming API integration with NestJS backend
class SocialGamingApiService {
  static SocialGamingApiService? _instance;
  static SocialGamingApiService get instance => _instance ??= SocialGamingApiService._();
  SocialGamingApiService._();

  String? _authToken;

  /// Set authentication token
  void setAuthToken(String token) {
    _authToken = token;
  }

  /// Get user achievements
  Future<List<Achievement>> getUserAchievements(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.socialGaming}/achievements/$userId'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['achievements'] as List)
            .map((json) => Achievement.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load achievements: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error fetching user achievements: $e');
      rethrow;
    }
  }

  /// Get all available achievements
  Future<List<Achievement>> getAllAchievements() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.socialGaming}/achievements'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['achievements'] as List)
            .map((json) => Achievement.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load all achievements: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error fetching all achievements: $e');
      rethrow;
    }
  }

  /// Unlock achievement
  Future<Achievement> unlockAchievement({
    required String achievementId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.socialGaming}/achievements/$achievementId/unlock'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'metadata': metadata,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return Achievement.fromJson(data['achievement']);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to unlock achievement');
      }
    } catch (e) {
      AppLogger.error('Error unlocking achievement: $e');
      rethrow;
    }
  }

  /// Get leaderboard
  Future<List<LeaderboardEntry>> getLeaderboard({
    String category = 'overall',
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.socialGaming}/leaderboard')
            .replace(queryParameters: {
          'category': category,
          'page': page.toString(),
          'limit': limit.toString(),
        }),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['leaderboard'] as List)
            .map((json) => LeaderboardEntry.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load leaderboard: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error fetching leaderboard: $e');
      rethrow;
    }
  }

  /// Get user's leaderboard position
  Future<LeaderboardEntry?> getUserLeaderboardPosition({
    required String userId,
    String category = 'overall',
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.socialGaming}/leaderboard/$userId')
            .replace(queryParameters: {
          'category': category,
        }),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['position'] != null
            ? LeaderboardEntry.fromJson(data['position'])
            : null;
      } else if (response.statusCode == 404) {
        return null; // User not on leaderboard
      } else {
        throw Exception('Failed to load user position: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error fetching user leaderboard position: $e');
      rethrow;
    }
  }

  /// Update user score
  Future<void> updateUserScore({
    required String category,
    required int points,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.socialGaming}/score'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'category': category,
          'points': points,
          'metadata': metadata,
        }),
      );

      if (response.statusCode != 201) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update score');
      }
    } catch (e) {
      AppLogger.error('Error updating user score: $e');
      rethrow;
    }
  }

  /// Get user stats
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.socialGaming}/stats/$userId'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['stats'] as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load user stats: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error fetching user stats: $e');
      rethrow;
    }
  }

  /// Get leaderboard categories
  Future<List<String>> getLeaderboardCategories() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.socialGaming}/leaderboard/categories'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['categories'] as List).cast<String>();
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error fetching leaderboard categories: $e');
      rethrow;
    }
  }

  /// Challenge user
  Future<Map<String, dynamic>> challengeUser({
    required String targetUserId,
    required String challengeType,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.socialGaming}/challenge'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'targetUserId': targetUserId,
          'challengeType': challengeType,
          'parameters': parameters,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['challenge'] as Map<String, dynamic>;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to create challenge');
      }
    } catch (e) {
      AppLogger.error('Error creating challenge: $e');
      rethrow;
    }
  }

  /// Get user challenges
  Future<List<Map<String, dynamic>>> getUserChallenges(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.socialGaming}/challenges/$userId'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['challenges'] as List).cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load challenges: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error fetching user challenges: $e');
      rethrow;
    }
  }
}
