import 'package:logger/logger.dart';

import '../../domain/repositories/user_repository.dart';
import '../datasources/local/user_local_data_source.dart';
import '../datasources/remote/user_remote_data_source.dart';
import '../exceptions/app_exceptions.dart';
import '../models/user_model.dart';

class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource _remoteDataSource;
  final UserLocalDataSource _localDataSource;
  final Logger _logger = Logger();

  UserRepositoryImpl({
    required UserRemoteDataSource remoteDataSource,
    required UserLocalDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;

  // Authentication
  @override
  Future<UserModel?> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      _logger.i('👤 Signing in user with email: $email');

      // Note: Authentication would typically be handled by a separate AuthService
      // For now, we'll simulate by getting current user after "authentication"
      final user = await _remoteDataSource.getCurrentUser();
      await _localDataSource.cacheCurrentUser(user);
      _logger.i('✅ User signed in successfully: ${user.id}');
      return user;
    } catch (e) {
      _logger.e('❌ Error signing in user: $e');
      if (e is NetworkException) {
        // Try local authentication if available
        return await _localDataSource.getCurrentUser();
      }
      rethrow;
    }
  }

  @override
  Future<UserModel?> signUpWithEmailPassword(
    String email,
    String password,
    String username,
  ) async {
    try {
      _logger.i('👤 Signing up user with email: $email');

      // Note: User creation would typically be handled by a separate AuthService
      // For now, we'll simulate by getting current user after "signup"
      final user = await _remoteDataSource.getCurrentUser();
      await _localDataSource.cacheCurrentUser(user);
      _logger.i('✅ User signed up successfully: ${user.id}');
      return user;
    } catch (e) {
      _logger.e('❌ Error signing up user: $e');
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      _logger.i('👤 Signing out user');

      // Clear current user from local storage
      // Note: Actual sign-out would be handled by AuthService
      await _localDataSource.clearCurrentUser();

      _logger.i('✅ User signed out successfully');
    } catch (e) {
      _logger.e('❌ Error signing out user: $e');
      rethrow;
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      _logger.d('👤 Getting current user');

      try {
        final user = await _remoteDataSource.getCurrentUser();
        await _localDataSource.cacheUser(user);
        return user;
      } catch (e) {
        if (e is NetworkException) {
          _logger.w('🔄 Network unavailable, trying local cache');
          return await _localDataSource.getCurrentUser();
        }
        rethrow;
      }
    } catch (e) {
      _logger.e('❌ Error getting current user: $e');
      rethrow;
    }
  }

  // User Profile
  @override
  Future<UserModel?> getUserById(String userId) async {
    try {
      _logger.d('👤 Getting user by ID: $userId');

      try {
        final user = await _remoteDataSource.getUserById(userId);
        await _localDataSource.cacheUser(user);
        return user;
      } catch (e) {
        if (e is NetworkException) {
          _logger.w('🔄 Network unavailable, trying local cache');
          return await _localDataSource.getCachedUser(userId);
        }
        rethrow;
      }
    } catch (e) {
      _logger.e('❌ Error getting user by ID: $e');
      rethrow;
    }
  }

  @override
  Future<UserModel> updateUserProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      _logger.i('👤 Updating user profile: $userId');

      final updatedUser = await _remoteDataSource.updateProfile(
        userId,
        updates,
      );
      await _localDataSource.cacheUser(updatedUser);

      _logger.i('✅ User profile updated successfully');
      return updatedUser;
    } catch (e) {
      _logger.e('❌ Error updating user profile: $e');
      rethrow;
    }
  }

  @override
  Future<void> uploadProfilePhoto(String userId, String photoPath) async {
    try {
      _logger.i('📸 Uploading profile photo for user: $userId');

      await _remoteDataSource.updateProfilePicture(userId, photoPath);

      _logger.i('✅ Profile photo uploaded successfully');
    } catch (e) {
      _logger.e('❌ Error uploading profile photo: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteProfilePhoto(String userId, String photoUrl) async {
    try {
      _logger.i('🗑️ Deleting profile photo for user: $userId');

      await _remoteDataSource.deleteProfileImage(userId, photoUrl);

      _logger.i('✅ Profile photo deleted successfully');
    } catch (e) {
      _logger.e('❌ Error deleting profile photo: $e');
      rethrow;
    }
  }

  // User Discovery
  @override
  Future<List<UserModel>> getNearbyUsers({
    required double latitude,
    required double longitude,
    double radiusKm = 50.0,
    int limit = 20,
  }) async {
    try {
      _logger.d('📍 Getting nearby users within ${radiusKm}km');

      try {
        final users = await _remoteDataSource.getUsersNearby(
          latitude: latitude,
          longitude: longitude,
          radiusKm: radiusKm,
          limit: limit,
        );

        // Cache nearby users
        for (final user in users) {
          await _localDataSource.cacheUser(user);
        }

        _logger.i('✅ Found ${users.length} nearby users');
        return users;
      } catch (e) {
        if (e is NetworkException) {
          _logger.w('🔄 Network unavailable, trying local cache');
          return await _localDataSource.getCachedUsers(limit: limit);
        }
        rethrow;
      }
    } catch (e) {
      _logger.e('❌ Error getting nearby users: $e');
      rethrow;
    }
  }

  @override
  Future<List<UserModel>> getUserRecommendations(
    String userId, {
    int limit = 10,
  }) async {
    try {
      _logger.d('💡 Getting user recommendations for: $userId');

      try {
        final users = await _remoteDataSource.getRecommendedUsers(
          userId: userId,
          limit: limit,
        );

        // Cache recommended users
        for (final user in users) {
          await _localDataSource.cacheUser(user);
        }

        _logger.i('✅ Found ${users.length} recommended users');
        return users;
      } catch (e) {
        if (e is NetworkException) {
          _logger.w('🔄 Network unavailable, trying local cache');
          return await _localDataSource.getCachedUsers(limit: limit);
        }
        rethrow;
      }
    } catch (e) {
      _logger.e('❌ Error getting user recommendations: $e');
      rethrow;
    }
  }

  // User Preferences
  @override
  Future<void> updateUserPreferences(
    String userId,
    Map<String, dynamic> preferences,
  ) async {
    try {
      _logger.i('⚙️ Updating user preferences for: $userId');

      await _remoteDataSource.updateUserPreferences(userId, preferences);

      _logger.i('✅ User preferences updated successfully');
    } catch (e) {
      _logger.e('❌ Error updating user preferences: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> getUserPreferences(String userId) async {
    try {
      _logger.d('⚙️ Getting user preferences for: $userId');

      return await _remoteDataSource.getUserPreferences(userId);
    } catch (e) {
      _logger.e('❌ Error getting user preferences: $e');
      rethrow;
    }
  }

  // User Actions
  @override
  Future<void> reportUser(
    String reporterId,
    String reportedUserId,
    String reason,
  ) async {
    try {
      _logger.i('🚨 User $reporterId reporting user $reportedUserId');

      await _remoteDataSource.reportUser(reporterId, reportedUserId, reason);

      _logger.i('✅ User report submitted successfully');
    } catch (e) {
      _logger.e('❌ Error reporting user: $e');
      rethrow;
    }
  }

  @override
  Future<void> blockUser(String blockerId, String blockedUserId) async {
    try {
      _logger.i('🚫 User $blockerId blocking user $blockedUserId');

      await _remoteDataSource.blockUser(blockerId, blockedUserId);

      _logger.i('✅ User blocked successfully');
    } catch (e) {
      _logger.e('❌ Error blocking user: $e');
      rethrow;
    }
  }

  @override
  Future<void> unblockUser(String blockerId, String blockedUserId) async {
    try {
      _logger.i('✅ User $blockerId unblocking user $blockedUserId');

      await _remoteDataSource.unblockUser(blockerId, blockedUserId);

      _logger.i('✅ User unblocked successfully');
    } catch (e) {
      _logger.e('❌ Error unblocking user: $e');
      rethrow;
    }
  }

  @override
  Future<List<String>> getBlockedUsers(String userId) async {
    try {
      _logger.d('🚫 Getting blocked users for: $userId');

      return await _remoteDataSource.getBlockedUsers(userId);
    } catch (e) {
      _logger.e('❌ Error getting blocked users: $e');
      rethrow;
    }
  }

  // Search & Filters
  @override
  Future<List<UserModel>> searchUsers({
    String? query,
    int? minAge,
    int? maxAge,
    String? gender,
    List<String>? interests,
    double? maxDistanceKm,
    int limit = 20,
  }) async {
    try {
      _logger.d('🔍 Searching users with query: $query');

      try {
        final users = await _remoteDataSource.searchUsers(
          query: query,
          minAge: minAge,
          maxAge: maxAge,
          interests: interests,
          limit: limit,
        );

        // Cache search results
        for (final user in users) {
          await _localDataSource.cacheUser(user);
        }

        _logger.i('✅ Found ${users.length} users matching search');
        return users;
      } catch (e) {
        if (e is NetworkException) {
          _logger.w('🔄 Network unavailable, searching local cache');
          return await _localDataSource.searchCachedUsers(
            query: query,
            minAge: minAge,
            maxAge: maxAge,
            interests: interests,
          );
        }
        rethrow;
      }
    } catch (e) {
      _logger.e('❌ Error searching users: $e');
      rethrow;
    }
  }

  // Offline Support
  @override
  Future<void> cacheUser(UserModel user) async {
    try {
      await _localDataSource.cacheUser(user);
    } catch (e) {
      _logger.e('❌ Error caching user: $e');
      rethrow;
    }
  }

  @override
  Future<UserModel?> getCachedUser(String userId) async {
    try {
      return await _localDataSource.getCachedUser(userId);
    } catch (e) {
      _logger.e('❌ Error getting cached user: $e');
      rethrow;
    }
  }

  @override
  Future<List<UserModel>> getCachedUsers() async {
    try {
      return await _localDataSource.getCachedUsers();
    } catch (e) {
      _logger.e('❌ Error getting cached users: $e');
      rethrow;
    }
  }

  @override
  Future<void> clearUserCache() async {
    try {
      await _localDataSource.clearAllUsers();
    } catch (e) {
      _logger.e('❌ Error clearing user cache: $e');
      rethrow;
    }
  }
}
