import '../../models/user_model.dart';

/// Local data source interface for user-related operations using Hive and Drift
abstract class UserLocalDataSource {
  // User CRUD operations
  Future<void> cacheUser(UserModel user);
  Future<UserModel?> getCachedUser(String userId);
  Future<List<UserModel>> getCachedUsers({int? limit, int? offset});
  Future<void> updateCachedUser(UserModel user);
  Future<void> deleteCachedUser(String userId);
  Future<void> clearAllUsers();

  // Current logged-in user operations
  Future<void> cacheCurrentUser(UserModel user);
  Future<UserModel?> getCurrentUser();
  Future<void> clearCurrentUser();

  // User search and filtering
  Future<List<UserModel>> searchCachedUsers({
    String? query,
    int? minAge,
    int? maxAge,
    String? location,
    List<String>? interests,
    int? maxDistance,
  });

  // User preferences and settings
  Future<void> cacheUserPreferences(
    String userId,
    Map<String, dynamic> preferences,
  );
  Future<Map<String, dynamic>?> getUserPreferences(String userId);
  Future<void> updateUserPreferences(
    String userId,
    Map<String, dynamic> preferences,
  );

  // Profile completion and verification
  Future<void> cacheProfileCompletion(
    String userId,
    double completionPercentage,
  );
  Future<double?> getProfileCompletion(String userId);
  Future<void> cacheVerificationStatus(
    String userId,
    Map<String, bool> verificationStatus,
  );
  Future<Map<String, bool>?> getVerificationStatus(String userId);

  // User discovery and recommendations
  Future<void> cacheDiscoveredUsers(List<UserModel> users);
  Future<List<UserModel>> getDiscoveredUsers({int? limit});
  Future<void> markUserAsSeen(String userId);
  Future<List<String>> getSeenUserIds();

  // User blocking and reporting
  Future<void> cacheBlockedUser(String blockedUserId);
  Future<List<String>> getBlockedUserIds();
  Future<void> unblockUser(String blockedUserId);
  Future<bool> isUserBlocked(String userId);

  // User metadata and analytics
  Future<void> cacheUserActivity(String userId, Map<String, dynamic> activity);
  Future<Map<String, dynamic>?> getUserActivity(String userId);
  Future<void> cacheUserStats(String userId, Map<String, dynamic> stats);
  Future<Map<String, dynamic>?> getUserStats(String userId);

  // Offline support
  Future<List<UserModel>> getOfflineUsers();
  Future<void> markUserForSync(String userId);
  Future<List<String>> getUsersMarkedForSync();
  Future<void> clearSyncFlag(String userId);

  // Cache management
  Future<int> getCachedUserCount();
  Future<DateTime?> getLastSyncTime();
  Future<void> updateLastSyncTime(DateTime time);
  Future<void> cleanExpiredCache({Duration? maxAge});
}
