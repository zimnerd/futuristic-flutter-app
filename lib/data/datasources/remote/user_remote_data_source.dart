import 'package:dio/dio.dart';

import '../../models/user_model.dart';

/// Remote data source interface for user-related API operations
abstract class UserRemoteDataSource {
  // Authentication & User Management
  Future<UserModel> getCurrentUser();
  Future<UserModel> getUserById(String userId);
  Future<List<UserModel>> getUsers({
    int? page,
    int? limit,
    Map<String, dynamic>? filters,
  });

  // Profile Management
  Future<UserModel> updateProfile(String userId, Map<String, dynamic> updates);
  Future<UserModel> updateProfilePicture(String userId, String imagePath);
  Future<List<String>> uploadProfileImages(String userId, List<String> imagePaths);
  Future<void> deleteProfileImage(String userId, String imageUrl);
  Future<void> reorderProfileImages(String userId, List<String> imageUrls);

  // User Discovery & Recommendations
  Future<List<UserModel>> getRecommendedUsers({
    String? userId,
    int? limit,
    Map<String, dynamic>? preferences,
  });
  Future<List<UserModel>> getUsersNearby({
    required double latitude,
    required double longitude,
    double? radiusKm,
    int? limit,
  });
  Future<List<UserModel>> searchUsers({
    String? query,
    int? minAge,
    int? maxAge,
    String? location,
    List<String>? interests,
    int? page,
    int? limit,
  });

  // User Interactions
  Future<void> likeUser(String userId, String targetUserId);
  Future<void> passUser(String userId, String targetUserId);
  Future<void> superLikeUser(String userId, String targetUserId);
  Future<void> undoLastAction(String userId);
  Future<Map<String, dynamic>> getInteractionHistory(String userId, {int? limit});

  // User Verification
  Future<Map<String, dynamic>> requestPhoneVerification(String phoneNumber);
  Future<bool> verifyPhoneNumber(String phoneNumber, String code);
  Future<Map<String, dynamic>> requestEmailVerification(String email);
  Future<bool> verifyEmail(String email, String token);
  Future<Map<String, dynamic>> requestPhotoVerification(String userId);
  Future<bool> submitPhotoVerification(String userId, String imagePath);

  // Privacy & Security
  Future<void> blockUser(String userId, String targetUserId);
  Future<void> unblockUser(String userId, String targetUserId);
  Future<List<String>> getBlockedUsers(String userId);
  Future<void> reportUser(String userId, String targetUserId, String reason, {String? details});
  Future<void> updatePrivacySettings(String userId, Map<String, dynamic> settings);
  Future<Map<String, dynamic>> getPrivacySettings(String userId);

  // User Preferences & Settings
  Future<void> updateUserPreferences(String userId, Map<String, dynamic> preferences);
  Future<Map<String, dynamic>> getUserPreferences(String userId);
  Future<void> updateNotificationSettings(String userId, Map<String, dynamic> settings);
  Future<Map<String, dynamic>> getNotificationSettings(String userId);

  // Location Services
  Future<void> updateUserLocation(String userId, double latitude, double longitude);
  Future<Map<String, dynamic>> getUserLocation(String userId);
  Future<void> updateLocationPreferences(String userId, Map<String, dynamic> preferences);

  // User Activity & Analytics
  Future<Map<String, dynamic>> getUserAnalytics(String userId);
  Future<Map<String, dynamic>> getUserActivity(String userId, {DateTime? since});
  Future<void> trackUserAction(String userId, String action, Map<String, dynamic>? metadata);

  // Subscription & Premium Features
  Future<Map<String, dynamic>> getSubscriptionStatus(String userId);
  Future<Map<String, dynamic>> getPremiumFeatures(String userId);
  Future<void> updateSubscription(String userId, String subscriptionType);

  // Account Management
  Future<void> deactivateAccount(String userId, String reason);
  Future<void> reactivateAccount(String userId);
  Future<void> deleteAccount(String userId, String password, String reason);
  Future<Map<String, dynamic>> exportUserData(String userId);

  // Error Handling
  Future<T> handleApiCall<T>(Future<Response> Function() apiCall);
  Exception mapErrorToException(DioException error);
}
