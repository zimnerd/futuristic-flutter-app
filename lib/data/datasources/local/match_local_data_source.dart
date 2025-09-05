import '../../models/match_model.dart';

/// Local data source interface for match-related operations using Hive and Drift
abstract class MatchLocalDataSource {
  // Match CRUD operations
  Future<void> cacheMatch(MatchModel match);
  Future<MatchModel?> getCachedMatch(String matchId);
  Future<List<MatchModel>> getCachedMatches({
    String? userId,
    int? limit,
    int? offset,
  });
  Future<void> updateCachedMatch(MatchModel match);
  Future<void> deleteCachedMatch(String matchId);

  // User matches
  Future<List<MatchModel>> getUserMatches(String userId, {int? limit});
  Future<void> cacheUserMatches(String userId, List<MatchModel> matches);
  Future<int> getUserMatchCount(String userId);

  // Match discovery and recommendations
  Future<void> cachePotentialMatches(String userId, List<MatchModel> matches);
  Future<List<MatchModel>> getPotentialMatches(String userId, {int? limit});
  Future<void> markMatchAsSeen(String userId, String targetUserId);
  Future<List<String>> getSeenMatchIds(String userId);

  // Swiping and interactions
  Future<void> cacheSwipeAction(
    String userId,
    String targetUserId,
    String action,
  );
  Future<Map<String, String>> getSwipeHistory(String userId);
  Future<void> cacheLikeAction(String userId, String targetUserId);
  Future<void> cachePassAction(String userId, String targetUserId);
  Future<void> cacheSuperLikeAction(String userId, String targetUserId);

  // Match compatibility and scoring
  Future<void> cacheCompatibilityScore(String matchId, double score);
  Future<double?> getCompatibilityScore(String matchId);
  Future<void> cacheCompatibilityDetails(
    String matchId,
    Map<String, dynamic> details,
  );
  Future<Map<String, dynamic>?> getCompatibilityDetails(String matchId);

  // Match status and lifecycle
  Future<void> updateMatchStatus(String matchId, String status);
  Future<String?> getMatchStatus(String matchId);
  Future<List<MatchModel>> getMatchesByStatus(String userId, String status);
  Future<void> markMatchAsExpired(String matchId);

  // Match preferences and filters
  Future<void> cacheMatchPreferences(
    String userId,
    Map<String, dynamic> preferences,
  );
  Future<Map<String, dynamic>?> getMatchPreferences(String userId);
  Future<void> updateMatchFilters(String userId, Map<String, dynamic> filters);
  Future<Map<String, dynamic>?> getMatchFilters(String userId);

  // Match analytics and insights
  Future<void> cacheMatchAnalytics(
    String userId,
    Map<String, dynamic> analytics,
  );
  Future<Map<String, dynamic>?> getMatchAnalytics(String userId);
  Future<void> cacheMatchingInsights(
    String userId,
    Map<String, dynamic> insights,
  );
  Future<Map<String, dynamic>?> getMatchingInsights(String userId);

  // Mutual matches and connections
  Future<List<MatchModel>> getMutualMatches(String userId);
  Future<void> cacheMutualMatch(MatchModel match);
  Future<bool> isMutualMatch(String userId, String targetUserId);

  // Blocked and reported matches
  Future<void> cacheBlockedMatch(String userId, String blockedUserId);
  Future<List<String>> getBlockedMatchIds(String userId);
  Future<void> unblockMatch(String userId, String blockedUserId);
  Future<bool> isMatchBlocked(String userId, String targetUserId);

  // Match queue and recommendations
  Future<void> queueMatchRecommendation(String userId, MatchModel match);
  Future<List<MatchModel>> getMatchQueue(String userId, {int? limit});
  Future<void> removeFromMatchQueue(String userId, String matchId);
  Future<void> clearMatchQueue(String userId);

  // Offline support
  Future<void> markMatchForSync(String matchId);
  Future<List<String>> getMatchesMarkedForSync();
  Future<void> clearSyncFlag(String matchId);
  Future<List<MatchModel>> getOfflineMatches(String userId);

  // Cache management
  Future<int> getCachedMatchCount({String? userId});
  Future<DateTime?> getLastMatchTime(String userId);
  Future<void> cleanExpiredMatches({Duration? maxAge});
  Future<void> optimizeMatchStorage();
}
