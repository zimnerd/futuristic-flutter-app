import '../../data/models/match_model.dart';
import '../../data/models/user_model.dart';

/// Repository interface for matching system operations
abstract class MatchRepository {
  // Swiping & Matching
  Future<void> swipeUser(String swiperId, String swipedUserId, bool isLike);
  Future<MatchModel?> createMatch(
    String user1Id,
    String user2Id,
    double compatibilityScore,
  );
  Future<List<MatchModel>> getUserMatches(String userId);
  Future<MatchModel?> getMatchById(String matchId);

  // Match Discovery
  Future<List<UserModel>> getPotentialMatches(String userId, {int limit = 10});
  Future<List<UserModel>> getCompatibleUsers(
    String userId, {
    double minCompatibilityScore = 0.7,
    int limit = 20,
  });

  // Match Status
  Future<void> updateMatchStatus(String matchId, String status);
  Future<void> unmatcha(String user1Id, String user2Id);
  Future<bool> isMatched(String user1Id, String user2Id);
  Future<Map<String, dynamic>> getMatchStatistics(String userId);

  // Match Preferences & Filters
  Future<void> updateMatchPreferences(
    String userId,
    Map<String, dynamic> preferences,
  );
  Future<Map<String, dynamic>?> getMatchPreferences(String userId);

  // Swipe History & Analytics
  Future<List<Map<String, dynamic>>> getSwipeHistory(
    String userId, {
    int limit = 100,
  });
  Future<void> recordSwipeAction(
    String swiperId,
    String swipedUserId,
    bool isLike,
  );
  Future<Map<String, dynamic>> getSwipeStatistics(String userId);

  // Super Likes & Premium Features
  Future<void> sendSuperLike(String senderId, String receiverId);
  Future<List<String>> getSuperLikesReceived(String userId);
  Future<int> getRemainingSwipes(String userId);
  Future<void> resetSwipeLimit(String userId);

  // Boost & Visibility
  Future<void> boostProfile(String userId, Duration duration);
  Future<bool> isProfileBoosted(String userId);
  Future<DateTime?> getBoostExpiryTime(String userId);

  // Offline Support
  Future<void> cacheMatch(MatchModel match);
  Future<MatchModel?> getCachedMatch(String matchId);
  Future<List<MatchModel>> getCachedMatches(String userId);
  Future<void> clearMatchCache();

  // Compatibility Algorithm
  Future<double> calculateCompatibilityScore(String user1Id, String user2Id);
  Future<Map<String, dynamic>> getMatchReasons(String user1Id, String user2Id);
}
