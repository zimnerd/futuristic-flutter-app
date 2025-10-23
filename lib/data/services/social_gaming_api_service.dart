import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/logger.dart';
import '../models/achievement.dart';
import '../models/leaderboard_entry.dart';

/// Service for social gaming API integration with NestJS backend
class SocialGamingApiService {
  static SocialGamingApiService? _instance;
  static SocialGamingApiService get instance =>
      _instance ??= SocialGamingApiService._();
  SocialGamingApiService._();

  final ApiClient _apiClient = ApiClient.instance;

  /// Set authentication token
  void setAuthToken(String token) {
    // ApiClient handles authentication internally
  }

  /// Get user achievements
  Future<List<Achievement>> getUserAchievements(String userId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.socialGaming}/achievements/$userId',
      );

      final data = response.data as Map<String, dynamic>;
      return (data['achievements'] as List)
          .map((json) => Achievement.fromJson(json))
          .toList();
    } on DioException catch (e) {
      AppLogger.error('Error fetching user achievements: $e');
      rethrow;
    }
  }

  /// Get all available achievements
  Future<List<Achievement>> getAllAchievements() async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.socialGaming}/achievements',
      );

      final data = response.data as Map<String, dynamic>;
      return (data['achievements'] as List)
          .map((json) => Achievement.fromJson(json))
          .toList();
    } on DioException catch (e) {
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
      final response = await _apiClient.post(
        '${ApiConstants.socialGaming}/achievements/$achievementId/unlock',
        data: {'metadata': metadata},
      );

      final data = response.data as Map<String, dynamic>;
      return Achievement.fromJson(data['achievement']);
    } on DioException catch (e) {
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
      final response = await _apiClient.get(
        '${ApiConstants.socialGaming}/leaderboard',
        queryParameters: {'category': category,
          'page': page, 'limit': limit,
        },
      );

      final data = response.data as Map<String, dynamic>;
      return (data['leaderboard'] as List)
          .map((json) => LeaderboardEntry.fromJson(json))
          .toList();
    } on DioException catch (e) {
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
      final response = await _apiClient.get(
        '${ApiConstants.socialGaming}/leaderboard/$userId',
        queryParameters: {'category': category},
      );

      final data = response.data as Map<String, dynamic>;
      return data['position'] != null
          ? LeaderboardEntry.fromJson(data['position'])
          : null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null; // User not on leaderboard
      }
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
      await _apiClient.post(
        '${ApiConstants.socialGaming}/score',
        data: {
          'category': category,
          'points': points,
          'metadata': metadata,
        },
      );
    } on DioException catch (e) {
      AppLogger.error('Error updating user score: $e');
      rethrow;
    }
  }

  /// Get user stats
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.socialGaming}/stats/$userId',
      );

      final data = response.data as Map<String, dynamic>;
      return data['stats'] as Map<String, dynamic>;
    } on DioException catch (e) {
      AppLogger.error('Error fetching user stats: $e');
      rethrow;
    }
  }

  /// Get leaderboard categories
  Future<List<String>> getLeaderboardCategories() async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.socialGaming}/leaderboard/categories',
      );

      final data = response.data as Map<String, dynamic>;
      return (data['categories'] as List).cast<String>();
    } on DioException catch (e) {
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
      final response = await _apiClient.post(
        '${ApiConstants.socialGaming}/challenge',
        data: {
          'targetUserId': targetUserId,
          'challengeType': challengeType,
          'parameters': parameters,
        },
      );

      final data = response.data as Map<String, dynamic>;
      return data['challenge'] as Map<String, dynamic>;
    } on DioException catch (e) {
      AppLogger.error('Error creating challenge: $e');
      rethrow;
    }
  }

  /// Get user challenges
  Future<List<Map<String, dynamic>>> getUserChallenges(String userId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.socialGaming}/challenges/$userId',
      );

      final data = response.data as Map<String, dynamic>;
      return (data['challenges'] as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      AppLogger.error('Error fetching user challenges: $e');
      rethrow;
    }
  }
}
