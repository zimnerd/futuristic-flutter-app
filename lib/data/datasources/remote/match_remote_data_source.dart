import 'package:dio/dio.dart';

import '../../models/match_model.dart';
import '../../models/user_model.dart';

/// Remote data source interface for match-related API operations
abstract class MatchRemoteDataSource {
  // Match Discovery
  Future<List<MatchModel>> getRecommendedMatches({
    required String userId,
    int? limit,
    Map<String, dynamic>? preferences,
  });

  Future<List<UserModel>> getPotentialMatches({
    required String userId,
    int? limit,
    double? maxDistance,
    int? minAge,
    int? maxAge,
  });

  Future<List<MatchModel>> getUserMatches(String userId, {int? page, int? limit});
  Future<MatchModel> getMatchById(String matchId);

  // Swiping & Interactions
  Future<Map<String, dynamic>> swipeUser({
    required String userId,
    required String targetUserId,
    required String action, // 'like', 'pass', 'super_like'
    Map<String, dynamic>? metadata,
  });

  Future<void> likeUser(String userId, String targetUserId);
  Future<void> passUser(String userId, String targetUserId);
  Future<void> superLikeUser(String userId, String targetUserId);
  Future<void> undoLastSwipe(String userId);

  // Match Management
  Future<MatchModel> createMatch(String user1Id, String user2Id);
  Future<void> unmatchUser(String userId, String matchedUserId);
  Future<List<MatchModel>> getMutualMatches(String userId);
  Future<bool> isMutualMatch(String userId, String targetUserId);

  // Match Analytics & Compatibility
  Future<Map<String, dynamic>> getCompatibilityScore(String userId, String targetUserId);
  Future<Map<String, dynamic>> getMatchAnalytics(String matchId);
  Future<Map<String, dynamic>> getUserMatchingStats(String userId);
  Future<List<Map<String, dynamic>>> getMatchingInsights(String userId);

  // Match Preferences & Filters
  Future<void> updateMatchPreferences(String userId, Map<String, dynamic> preferences);
  Future<Map<String, dynamic>> getMatchPreferences(String userId);
  Future<void> updateDiscoverySettings(String userId, Map<String, dynamic> settings);
  Future<Map<String, dynamic>> getDiscoverySettings(String userId);

  // Location-Based Matching
  Future<List<UserModel>> getNearbyUsers({
    required String userId,
    required double latitude,
    required double longitude,
    double? radiusKm,
    int? limit,
  });

  Future<void> updateUserLocation(String userId, double latitude, double longitude);
  Future<Map<String, dynamic>> getLocationPreferences(String userId);

  // Super Likes & Premium Features
  Future<int> getSuperLikesCount(String userId);
  Future<void> purchaseSuperLikes(String userId, int count);
  Future<List<UserModel>> getWhoLikedYou(String userId);
  Future<void> boostProfile(String userId, int duration);

  // Match Queue & Recommendations
  Future<List<UserModel>> getMatchQueue(String userId, {int? limit});
  Future<void> refreshMatchQueue(String userId);
  Future<Map<String, dynamic>> getRecommendationSettings(String userId);
  Future<void> updateRecommendationSettings(String userId, Map<String, dynamic> settings);

  // Blocking & Reporting
  Future<void> blockUser(String userId, String targetUserId);
  Future<void> unblockUser(String userId, String targetUserId);
  Future<List<String>> getBlockedUsers(String userId);
  Future<void> reportUser(String userId, String targetUserId, String reason);

  // Match History & Statistics
  Future<List<Map<String, dynamic>>> getSwipeHistory(String userId, {int? limit});
  Future<Map<String, dynamic>> getMatchingHistory(String userId);
  Future<Map<String, dynamic>> getDailyMatchStats(String userId);
  Future<Map<String, dynamic>> getWeeklyMatchStats(String userId);

  // AI-Powered Matching
  Future<List<UserModel>> getAIRecommendations({
    required String userId,
    String? algorithm,
    int? limit,
  });

  Future<Map<String, dynamic>> getPersonalityCompatibility(String userId, String targetUserId);
  Future<void> updateMatchingAlgorithmPreferences(String userId, Map<String, dynamic> preferences);

  // Social Features
  Future<List<UserModel>> getMutualFriends(String userId, String targetUserId);
  Future<List<UserModel>> getCommonInterests(String userId, String targetUserId);
  Future<Map<String, dynamic>> getSocialConnectionScore(String userId, String targetUserId);

  // Match Events & Activities
  Future<List<Map<String, dynamic>>> getMatchEvents(String userId);
  Future<void> createMatchEvent(String userId, Map<String, dynamic> eventData);
  Future<void> joinMatchEvent(String userId, String eventId);
  Future<void> leaveMatchEvent(String userId, String eventId);

  // Video & Voice Features
  Future<Map<String, dynamic>> initiateVideoCall(String userId, String targetUserId);
  Future<Map<String, dynamic>> initiateVoiceCall(String userId, String targetUserId);
  Future<void> sendVoiceMessage(String userId, String targetUserId, String audioPath);

  // Gamification
  Future<Map<String, dynamic>> getUserMatchingLevel(String userId);
  Future<List<Map<String, dynamic>>> getMatchingAchievements(String userId);
  Future<void> unlockMatchingBadge(String userId, String badgeId);

  // Bulk Operations
  Future<void> batchSwipeUsers(String userId, List<Map<String, String>> swipes);
  Future<List<MatchModel>> batchGetMatches(List<String> matchIds);

  // Error Handling
  Future<T> handleApiCall<T>(Future<Response> Function() apiCall);
  Exception mapErrorToException(DioException error);
}
