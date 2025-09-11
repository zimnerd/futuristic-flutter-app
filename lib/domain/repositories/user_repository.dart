import '../../data/models/user_model.dart';

/// Repository interface for user data operations
/// Defines the contract that both local and remote data sources must implement
abstract class UserRepository {
  // Authentication
  Future<UserModel?> signInWithEmailPassword(String email, String password);
  Future<UserModel?> signUpWithEmailPassword(
    String email,
    String password,
    String username,
    String phone, {
    String? firstName,
    String? lastName,
    String? birthdate,
    String? gender,
    String? location,
  });
  Future<void> signOut();
  Future<UserModel?> getCurrentUser();
  Future<void> requestPasswordReset(String email);

  // User Profile
  Future<UserModel?> getUserById(String userId);
  Future<UserModel> updateUserProfile(
      String userId, Map<String, dynamic> updates);
  Future<void> uploadProfilePhoto(String userId, String photoPath);
  Future<void> deleteProfilePhoto(String userId, String photoUrl);

  // User Discovery
  Future<List<UserModel>> getNearbyUsers({
    required double latitude,
    required double longitude,
    double radiusKm = 50.0,
    int limit = 20,
  });
  Future<List<UserModel>> getUserRecommendations(String userId,
      {int limit = 10});

  // User Preferences
  Future<void> updateUserPreferences(
      String userId, Map<String, dynamic> preferences);
  Future<Map<String, dynamic>?> getUserPreferences(String userId);

  // User Actions
  Future<void> reportUser(
      String reporterId, String reportedUserId, String reason);
  Future<void> blockUser(String blockerId, String blockedUserId);
  Future<void> unblockUser(String blockerId, String blockedUserId);
  Future<List<String>> getBlockedUsers(String userId);

  // Search & Filters
  Future<List<UserModel>> searchUsers({
    String? query,
    int? minAge,
    int? maxAge,
    String? gender,
    List<String>? interests,
    double? maxDistanceKm,
    int limit = 20,
  });

  // Offline Support
  Future<void> cacheUser(UserModel user);
  Future<UserModel?> getCachedUser(String userId);
  Future<List<UserModel>> getCachedUsers();
  Future<void> clearUserCache();
}
