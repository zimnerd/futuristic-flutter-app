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
  Future<UserModel?> getCurrentUser({bool forceRefresh = false});
  Future<void> requestPasswordReset(String email);
  Future<UserModel?> verifyTwoFactor({
    required String sessionId,
    required String code,
  });
  Future<UserModel?> signInWithBiometric();
  Future<void> refreshToken();

  // OTP Authentication
  Future<Map<String, dynamic>> sendOTP({
    String? email,
    String? phoneNumber,
    String? countryCode,
    required String type,
    String? preferredMethod,
  });

  /// Send verification OTP to authenticated user
  /// Uses JWT token to identify user - no need to pass email/phone
  /// [preferredMethod] can be 'email', 'whatsapp', or 'both'
  Future<Map<String, dynamic>> sendVerificationOTP({
    required String preferredMethod,
  });

  Future<Map<String, dynamic>> verifyOTP({
    required String sessionId,
    required String code,
    required String email,
  });
  Future<Map<String, dynamic>> resendOTP({required String sessionId});

  // Phone Validation
  Future<Map<String, dynamic>> validatePhone({
    required String phone,
    required String countryCode,
  });

  // User Profile
  Future<UserModel?> getUserById(String userId);
  Future<UserModel> updateUserProfile(
    String userId,
    Map<String, dynamic> updates,
  );
  Future<String> uploadProfilePhoto(String userId, String photoPath);
  Future<void> deleteProfilePhoto(String userId, String photoUrl);
  Future<Map<String, dynamic>> updateRelationshipGoals(
    List<String> relationshipGoals,
  );
  Future<void> updateUserLocation(
    String userId,
    double latitude,
    double longitude,
  );

  // Photo Management
  Future<Map<String, dynamic>> uploadMultiplePhotos(
    String userId,
    List<String> photoPaths,
  );
  Future<void> deletePhoto(String userId, String photoId);
  Future<void> reorderPhotos(String userId, List<String> photoIds);
  Future<void> setMainPhoto(String userId, String photoId);
  Future<Map<String, dynamic>> getPhotoUploadProgress(String uploadId);

  // User Discovery
  Future<List<UserModel>> getNearbyUsers({
    required double latitude,
    required double longitude,
    double radiusKm = 50.0,
    int limit = 20,
  });
  Future<List<UserModel>> getUserRecommendations(
    String userId, {
    int limit = 10,
  });

  // User Preferences
  Future<void> updateUserPreferences(
    String userId,
    Map<String, dynamic> preferences,
  );
  Future<Map<String, dynamic>?> getUserPreferences(String userId);

  // User Actions
  Future<void> reportUser(
    String reporterId,
    String reportedUserId,
    String reason,
  );
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

  // Notification Preferences
  Future<Map<String, dynamic>> getNotificationPreferences(String userId);
  Future<void> updateNotificationPreferences(
    String userId,
    Map<String, dynamic> preferences,
  );
  Future<void> testNotification(String userId, String type);
}
