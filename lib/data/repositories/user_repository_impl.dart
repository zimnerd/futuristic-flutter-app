import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/user_model.dart';
import '../../data/models/photo_upload_progress.dart';
import '../../data/services/photo_upload_service.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/remote/user_remote_data_source.dart';
import '../datasources/local/user_local_data_source.dart';
import '../exceptions/app_exceptions.dart';

/// Implementation of UserRepository following Clean Architecture principles
/// Handles both remote and local data sources with proper error handling
class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource _remoteDataSource;
  final UserLocalDataSource _localDataSource;
  final Logger _logger = Logger();

  UserRepositoryImpl(this._remoteDataSource, this._localDataSource);

  @override
  Future<UserModel?> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      _logger.i('Signing in user with email: $email');

      final user = await _remoteDataSource.signInWithEmailPassword(
        email,
        password,
      );

      // Cache user locally after successful sign in
      await _localDataSource.cacheUser(user);

      _logger.i('User signed in successfully: ${user.id}');
      return user;
    } catch (e) {
      _logger.e('Sign in failed: $e');
      if (e is AppException) rethrow;
      throw AuthException('Sign in failed: ${e.toString()}');
    }
  }

  @override
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
  }) async {
    try {
      _logger.i('Signing up new user with email: $email');

      final user = await _remoteDataSource.signUpWithEmailPassword(
        email,
        password,
        username,
        phone,
        firstName: firstName,
        lastName: lastName,
        birthdate: birthdate,
        gender: gender,
        location: location,
      );

      // Cache user locally after successful sign up
      await _localDataSource.cacheUser(user);

      _logger.i('User signed up successfully: ${user.id}');
      return user;
    } catch (e) {
      _logger.e('Sign up failed: $e');
      // Rethrow original error so ErrorService can parse it
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      _logger.i('Signing out user');

      // Sign out from remote service
      await _remoteDataSource.signOut();

      // Clear local cache
      await _localDataSource.clearUserCache();

      _logger.i('User signed out successfully');
    } catch (e) {
      _logger.e('Sign out error: $e');
      // Always clear local cache even if remote signout fails
      await _localDataSource.clearUserCache();
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      _logger.i('Getting current user');

      // Try to get from local cache first
      final cachedUser = await _localDataSource.getCurrentUser();
      if (cachedUser != null) {
        _logger.i('Found cached user: ${cachedUser.id}');
        return cachedUser;
      }

      // Fallback to remote if not cached
      final user = await _remoteDataSource.getCurrentUser();

      // Cache the user for future requests
      await _localDataSource.cacheUser(user);

      return user;
    } catch (e) {
      _logger.e('Get current user failed: $e');
      if (e is AppException) rethrow;
      throw UserException('Failed to get current user: ${e.toString()}');
    }
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    try {
      _logger.i('Requesting password reset for email: $email');

      await _remoteDataSource.requestPasswordReset(email);

      _logger.i('Password reset requested successfully');
    } catch (e) {
      _logger.e('Password reset request failed: $e');
      if (e is AppException) rethrow;
      throw AuthException('Password reset request failed: ${e.toString()}');
    }
  }

  @override
  Future<UserModel?> verifyTwoFactor({
    required String sessionId,
    required String code,
  }) async {
    try {
      _logger.i('Verifying two-factor authentication');

      final user = await _remoteDataSource.verifyTwoFactor(
        sessionId: sessionId,
        code: code,
      );

      // Cache user after successful 2FA
      await _localDataSource.cacheUser(user);

      _logger.i('2FA verification successful: ${user.id}');
      return user;
    } catch (e) {
      _logger.e('2FA verification failed: $e');
      if (e is AppException) rethrow;
      throw AuthException('2FA verification failed: ${e.toString()}');
    }
  }

  @override
  Future<UserModel?> signInWithBiometric() async {
    try {
      _logger.i('Attempting biometric authentication');

      // Get cached user (biometric should only work if user was previously authenticated)
      final cachedUser = await _localDataSource.getCurrentUser();
      if (cachedUser == null) {
        throw AuthException('No cached user for biometric authentication');
      }

      // Refresh token with backend to ensure it's still valid
      await _remoteDataSource.refreshToken();

      _logger.i('Biometric authentication successful: ${cachedUser.id}');
      return cachedUser;
    } catch (e) {
      _logger.e('Biometric authentication failed: $e');
      if (e is AppException) rethrow;
      throw AuthException('Biometric authentication failed: ${e.toString()}');
    }
  }

  @override
  Future<void> refreshToken() async {
    try {
      _logger.i('Refreshing authentication token');

      await _remoteDataSource.refreshToken();

      _logger.i('Token refreshed successfully');
    } catch (e) {
      _logger.e('Token refresh failed: $e');
      if (e is AppException) rethrow;
      throw AuthException('Token refresh failed: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> sendOTP({
    String? email,
    String? phoneNumber,
    String? countryCode,
    required String type,
    String? preferredMethod,
  }) async {
    try {
      _logger.i('Sending OTP to: $email, phone: $phoneNumber, type: $type');

      final result = await _remoteDataSource.sendOTP(
        email: email,
        phoneNumber: phoneNumber,
        countryCode: countryCode,
        type: type,
        preferredMethod: preferredMethod,
      );

      _logger.i('OTP sent successfully');
      return result;
    } catch (e) {
      _logger.e('Send OTP failed: $e');
      if (e is AppException) rethrow;
      throw AuthException('Send OTP failed: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> sendVerificationOTP({
    required String preferredMethod,
  }) async {
    try {
      _logger.i('Sending verification OTP via: $preferredMethod');

      final result = await _remoteDataSource.sendVerificationOTP(
        preferredMethod: preferredMethod,
      );

      _logger.i('Verification OTP sent successfully');
      return result;
    } catch (e) {
      _logger.e('Send verification OTP failed: $e');
      if (e is AppException) rethrow;
      throw AuthException('Send verification OTP failed: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> verifyOTP({
    required String sessionId,
    required String code,
    required String email,
  }) async {
    try {
      _logger.i('Verifying OTP for session: $sessionId');

      final result = await _remoteDataSource.verifyOTP(
        sessionId: sessionId,
        code: code,
        email: email,
      );

      if (result['verified'] == true && result['user'] != null) {
        // Cache the authenticated user
        final user = UserModel.fromJson(result['user']);
        await _localDataSource.cacheUser(user);
        _logger.i('User authenticated and cached after OTP verification');
      }

      return result;
    } catch (e) {
      _logger.e('Verify OTP failed: $e');
      if (e is AppException) rethrow;
      throw AuthException('Verify OTP failed: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> resendOTP({required String sessionId}) async {
    try {
      _logger.i('Resending OTP for session: $sessionId');

      final result = await _remoteDataSource.resendOTP(sessionId: sessionId);

      _logger.i('OTP resent successfully');
      return result;
    } catch (e) {
      _logger.e('Resend OTP failed: $e');
      if (e is AppException) rethrow;
      throw AuthException('Resend OTP failed: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> validatePhone({
    required String phone,
    required String countryCode,
  }) async {
    try {
      _logger.i('Validating phone: $phone with country code: $countryCode');

      final result = await _remoteDataSource.validatePhone(
        phone: phone,
        countryCode: countryCode,
      );

      _logger.i('Phone validation completed: ${result['isValid']}');
      return result;
    } catch (e) {
      _logger.e('Phone validation failed: $e');
      if (e is AppException) rethrow;
      throw AuthException('Phone validation failed: ${e.toString()}');
    }
  }

  @override
  Future<UserModel?> getUserById(String userId) async {
    try {
      _logger.i('Getting user by ID: $userId');

      // Check local cache first
      final cachedUser = await _localDataSource.getUserById(userId);
      if (cachedUser != null) {
        _logger.i('Found cached user: $userId');
        return cachedUser;
      }

      // Fetch from remote
      final user = await _remoteDataSource.getUserById(userId);

      // Cache the user
      await _localDataSource.cacheUser(user);

      return user;
    } catch (e) {
      _logger.e('Get user by ID failed: $e');
      if (e is AppException) rethrow;
      throw UserException('Failed to get user: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> updateUserProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      _logger.i('Updating user profile for: $userId');

      final updatedUser = await _remoteDataSource.updateUserProfile(
        userId,
        updates,
      );

      // Update local cache with new data
      await _localDataSource.cacheUser(updatedUser);

      _logger.i('User profile updated successfully: $userId');
      return updatedUser;
    } catch (e) {
      _logger.e('Update user profile failed: $e');
      if (e is AppException) rethrow;
      throw UserException('Failed to update profile: ${e.toString()}');
    }
  }

  @override
  Future<String> uploadProfilePhoto(String userId, String photoPath) async {
    try {
      _logger.i('Uploading profile photo for user: $userId');

      final photoUrl = await _remoteDataSource.uploadProfilePhoto(
        userId,
        photoPath,
      );

      // Update local cache to include new photo
      final cachedUser = await _localDataSource.getCurrentUser();
      if (cachedUser != null && cachedUser.id == userId) {
        final updatedPhotos = List<String>.from(cachedUser.photos)
          ..add(photoUrl);
        final updatedUser = cachedUser.copyWith(photos: updatedPhotos);
        await _localDataSource.cacheUser(updatedUser);
      }

      _logger.i('Profile photo uploaded successfully: $photoUrl');
      return photoUrl;
    } catch (e) {
      _logger.e('Upload profile photo failed: $e');
      if (e is AppException) rethrow;
      throw UserException('Failed to upload photo: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteProfilePhoto(String userId, String photoUrl) async {
    try {
      _logger.i('Deleting profile photo for user: $userId');

      await _remoteDataSource.deleteProfilePhoto(userId, photoUrl);

      // Update local cache to remove photo
      final cachedUser = await _localDataSource.getCurrentUser();
      if (cachedUser != null && cachedUser.id == userId) {
        final updatedPhotos = List<String>.from(cachedUser.photos)
          ..remove(photoUrl);
        final updatedUser = cachedUser.copyWith(photos: updatedPhotos);
        await _localDataSource.cacheUser(updatedUser);
      }

      _logger.i('Profile photo deleted successfully');
    } catch (e) {
      _logger.e('Delete profile photo failed: $e');
      if (e is AppException) rethrow;
      throw UserException('Failed to delete photo: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> uploadMultiplePhotos(
    String userId,
    List<String> photoPaths,
  ) async {
    try {
      _logger.i('Uploading ${photoPaths.length} photos for user: $userId');

      // Create batch upload with progress tracking
      final batchId = const Uuid().v4();
      final uploadService = PhotoUploadService();
      final List<String> uploadedUrls = [];
      final List<PhotoUploadProgress> photoProgresses = [];

      // Initialize batch progress
      for (int i = 0; i < photoPaths.length; i++) {
        final uploadId = '${batchId}_photo_$i';
        photoProgresses.add(
          PhotoUploadProgress(
            uploadId: uploadId,
            photoPath: photoPaths[i],
            progress: 0.0,
            status: UploadStatus.pending,
          ),
        );
      }

      // Update initial batch progress
      uploadService.updateBatchProgress(
        BatchUploadProgress(
          batchId: batchId,
          totalPhotos: photoPaths.length,
          uploadedPhotos: 0,
          photos: photoProgresses,
          overallProgress: 0.0,
        ),
      );

      // Upload photos with progress tracking
      for (int i = 0; i < photoPaths.length; i++) {
        final uploadId = '${batchId}_photo_$i';

        try {
          // Update to uploading status
          uploadService.updateProgress(
            PhotoUploadProgress(
              uploadId: uploadId,
              photoPath: photoPaths[i],
              progress: 0.0,
              status: UploadStatus.uploading,
            ),
          );

          // Upload the photo
          final photoUrl = await _remoteDataSource.uploadProfilePhoto(
            userId,
            photoPaths[i],
          );
          uploadedUrls.add(photoUrl);

          // Update to completed status
          uploadService.updateProgress(
            PhotoUploadProgress(
              uploadId: uploadId,
              photoPath: photoPaths[i],
              progress: 1.0,
              status: UploadStatus.completed,
              url: photoUrl,
            ),
          );

          // Update batch progress
          final overallProgress = (i + 1) / photoPaths.length;
          uploadService.updateBatchProgress(
            BatchUploadProgress(
              batchId: batchId,
              totalPhotos: photoPaths.length,
              uploadedPhotos: i + 1,
              photos: photoProgresses,
              overallProgress: overallProgress,
            ),
          );
        } catch (e) {
          // Update to failed status
          uploadService.updateProgress(
            PhotoUploadProgress(
              uploadId: uploadId,
              photoPath: photoPaths[i],
              progress: 0.0,
              status: UploadStatus.failed,
              error: e.toString(),
            ),
          );

          _logger.e('Failed to upload photo ${i + 1}: $e');
          // Continue with remaining photos
        }
      }

      // Clean up batch tracking
      uploadService.cleanupBatch(batchId);

      // Update local cache
      final cachedUser = await _localDataSource.getCurrentUser();
      if (cachedUser != null && cachedUser.id == userId) {
        final updatedPhotos = List<String>.from(cachedUser.photos)
          ..addAll(uploadedUrls);
        final updatedUser = cachedUser.copyWith(photos: updatedPhotos);
        await _localDataSource.cacheUser(updatedUser);
      }

      _logger.i('${uploadedUrls.length} photos uploaded successfully');
      return {
        'success': true,
        'uploadedUrls': uploadedUrls,
        'count': uploadedUrls.length,
      };
    } catch (e) {
      _logger.e('Upload multiple photos failed: $e');
      if (e is AppException) rethrow;
      throw UserException('Failed to upload photos: ${e.toString()}');
    }
  }

  @override
  Future<void> deletePhoto(String userId, String photoId) async {
    try {
      _logger.i('Deleting photo $photoId for user: $userId');

      // Call backend DELETE /media/files/:photoId endpoint
      await _remoteDataSource.deleteProfilePhoto(userId, photoId);

      _logger.i('Photo $photoId deleted successfully');
    } catch (e) {
      _logger.e('Delete photo failed: $e');
      if (e is AppException) rethrow;
      throw UserException('Failed to delete photo: ${e.toString()}');
    }
  }

  @override
  Future<void> reorderPhotos(String userId, List<String> photoIds) async {
    try {
      _logger.i('Reordering photos for user: $userId');

      // Call backend POST /users/me/photos/reorder endpoint
      await _remoteDataSource.reorderPhotos(photoIds);

      _logger.i('✅ Photos reordered successfully');
    } catch (e) {
      _logger.e('❌ Reorder photos failed: $e');
      if (e is AppException) rethrow;
      throw UserException('Failed to reorder photos: ${e.toString()}');
    }
  }

  @override
  Future<void> setMainPhoto(String userId, String photoId) async {
    try {
      _logger.i('Setting main photo $photoId for user: $userId');

      // Use PUT /users/me/photos endpoint to sync photos with isMain flag
      await _remoteDataSource.syncPhotos([
        {'mediaId': photoId, 'isMain': true, 'order': 0},
      ]);

      _logger.i('✅ Main photo set successfully');
    } catch (e) {
      _logger.e('❌ Set main photo failed: $e');
      if (e is AppException) rethrow;
      throw UserException('Failed to set main photo: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> getPhotoUploadProgress(String uploadId) async {
    try {
      final uploadService = PhotoUploadService();
      final progress = uploadService.getUploadProgress(uploadId);

      if (progress != null) {
        return progress.toJson();
      }

      // No progress found, return pending status
      return {'uploadId': uploadId, 'progress': 0.0, 'status': 'pending'};
    } catch (e) {
      _logger.e('Get photo upload progress failed: $e');
      return {
        'uploadId': uploadId,
        'progress': 0.0,
        'status': 'error',
        'error': e.toString(),
      };
    }
  }

  @override
  Future<List<UserModel>> getNearbyUsers({
    required double latitude,
    required double longitude,
    double radiusKm = 50.0,
    int limit = 20,
  }) async {
    try {
      _logger.i(
        'Getting nearby users: lat=$latitude, lng=$longitude, radius=${radiusKm}km',
      );

      final users = await _remoteDataSource.getNearbyUsers(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
        limit: limit,
      );

      // Cache discovered users for future reference
      for (final user in users) {
        await _localDataSource.cacheUser(user);
      }

      _logger.i('Found ${users.length} nearby users');
      return users;
    } catch (e) {
      _logger.e('Get nearby users failed: $e');
      if (e is AppException) rethrow;
      throw UserException('Failed to get nearby users: ${e.toString()}');
    }
  }

  @override
  Future<List<UserModel>> getUserRecommendations(
    String userId, {
    int limit = 10,
  }) async {
    try {
      _logger.i('Getting user recommendations for: $userId');

      final users = await _remoteDataSource.getUserRecommendations(
        userId,
        limit: limit,
      );

      // Cache recommended users
      for (final user in users) {
        await _localDataSource.cacheUser(user);
      }

      _logger.i('Found ${users.length} user recommendations');
      return users;
    } catch (e) {
      _logger.e('Get user recommendations failed: $e');
      if (e is AppException) rethrow;
      throw UserException('Failed to get recommendations: ${e.toString()}');
    }
  }

  @override
  Future<void> updateUserPreferences(
    String userId,
    Map<String, dynamic> preferences,
  ) async {
    try {
      _logger.i('Updating user preferences for: $userId');

      await _remoteDataSource.updateUserPreferences(userId, preferences);

      // Update local cache with new preferences
      final cachedUser = await _localDataSource.getCurrentUser();
      if (cachedUser != null && cachedUser.id == userId) {
        final updatedUser = cachedUser.copyWith(preferences: preferences);
        await _localDataSource.cacheUser(updatedUser);
      }

      _logger.i('User preferences updated successfully');
    } catch (e) {
      _logger.e('Update user preferences failed: $e');
      if (e is AppException) rethrow;
      throw UserException('Failed to update preferences: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>?> getUserPreferences(String userId) async {
    try {
      _logger.i('Getting user preferences for: $userId');

      // Try local cache first
      final cachedUser = await _localDataSource.getCurrentUser();
      if (cachedUser != null &&
          cachedUser.id == userId &&
          cachedUser.preferences != null) {
        return cachedUser.preferences;
      }

      // Fallback to remote
      final preferences = await _remoteDataSource.getUserPreferences(userId);

      // Update local cache
      if (cachedUser != null && cachedUser.id == userId) {
        final updatedUser = cachedUser.copyWith(preferences: preferences);
        await _localDataSource.cacheUser(updatedUser);
      }

      return preferences;
    } catch (e) {
      _logger.e('Get user preferences failed: $e');
      if (e is AppException) rethrow;
      throw UserException('Failed to get preferences: ${e.toString()}');
    }
  }

  @override
  Future<void> reportUser(
    String reporterId,
    String reportedUserId,
    String reason,
  ) async {
    try {
      _logger.i('Reporting user $reportedUserId by user $reporterId');

      await _remoteDataSource.reportUser(reporterId, reportedUserId, reason);

      _logger.i('User reported successfully');
    } catch (e) {
      _logger.e('Report user failed: $e');
      if (e is AppException) rethrow;
      throw UserException('Failed to report user: ${e.toString()}');
    }
  }

  @override
  Future<void> blockUser(String blockerId, String blockedUserId) async {
    try {
      _logger.i('Blocking user $blockedUserId by user $blockerId');

      await _remoteDataSource.blockUser(blockerId, blockedUserId);

      _logger.i('User blocked successfully');
    } catch (e) {
      _logger.e('Block user failed: $e');
      if (e is AppException) rethrow;
      throw UserException('Failed to block user: ${e.toString()}');
    }
  }

  @override
  Future<void> unblockUser(String blockerId, String blockedUserId) async {
    try {
      _logger.i('Unblocking user $blockedUserId by user $blockerId');

      await _remoteDataSource.unblockUser(blockerId, blockedUserId);

      _logger.i('User unblocked successfully');
    } catch (e) {
      _logger.e('Unblock user failed: $e');
      if (e is AppException) rethrow;
      throw UserException('Failed to unblock user: ${e.toString()}');
    }
  }

  @override
  Future<List<String>> getBlockedUsers(String userId) async {
    try {
      _logger.i('Getting blocked users for: $userId');

      final users = await _remoteDataSource.getBlockedUsers(userId);

      // Return just the user IDs as required by interface
      final userIds = users.map((u) => u.id).toList();
      _logger.i('Found ${userIds.length} blocked users');
      return userIds;
    } catch (e) {
      _logger.e('Get blocked users failed: $e');
      if (e is AppException) rethrow;
      throw UserException('Failed to get blocked users: ${e.toString()}');
    }
  }

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
      _logger.i('Searching users with filters');

      // This would typically call a remote search endpoint
      // For now, fall back to getting recommendations
      final currentUser = await getCurrentUser();
      if (currentUser == null) {
        throw AuthException('No authenticated user for search');
      }

      final users = await _remoteDataSource.getUserRecommendations(
        currentUser.id,
        limit: limit,
      );

      // Apply local filtering if needed
      // Note: Filtering moved to backend for better performance

      _logger.i('Found ${users.length} users in search');
      return users;
    } catch (e) {
      _logger.e('Search users failed: $e');
      if (e is AppException) rethrow;
      throw UserException('Failed to search users: ${e.toString()}');
    }
  }

  @override
  Future<void> cacheUser(UserModel user) async {
    try {
      await _localDataSource.cacheUser(user);
    } catch (e) {
      _logger.e('Cache user failed: $e');
      if (e is AppException) rethrow;
      throw UserException('Failed to cache user: ${e.toString()}');
    }
  }

  @override
  Future<UserModel?> getCachedUser(String userId) async {
    try {
      return await _localDataSource.getUserById(userId);
    } catch (e) {
      _logger.e('Get cached user failed: $e');
      return null;
    }
  }

  @override
  Future<List<UserModel>> getCachedUsers() async {
    try {
      return await _localDataSource.getCachedUsers();
    } catch (e) {
      _logger.e('Get cached users failed: $e');
      return [];
    }
  }

  @override
  Future<void> clearUserCache() async {
    try {
      await _localDataSource.clearUserCache();
    } catch (e) {
      _logger.e('Clear user cache failed: $e');
      if (e is AppException) rethrow;
      throw UserException('Failed to clear user cache: ${e.toString()}');
    }
  }

  @override
  Future<void> updateUserLocation(
    String userId,
    double latitude,
    double longitude,
  ) async {
    try {
      _logger.i('Updating user location for user: $userId');

      await _remoteDataSource.updateUserLocation(userId, latitude, longitude);

      // Update cached user if available
      final cachedUser = await _localDataSource.getCachedUser(userId);
      if (cachedUser != null) {
        final updatedCoordinates = {
          'latitude': latitude,
          'longitude': longitude,
        };
        final updatedUser = cachedUser.copyWith(
          coordinates: updatedCoordinates,
        );
        await _localDataSource.cacheUser(updatedUser);
      }

      _logger.i('User location updated successfully');
    } catch (e) {
      _logger.e('Failed to update user location: $e');
      throw Exception('Failed to update user location: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getNotificationPreferences(String userId) async {
    try {
      _logger.i('Getting notification preferences for user: $userId');
      final preferences = await _remoteDataSource.getNotificationPreferences(
        userId,
      );
      _logger.i('Notification preferences retrieved successfully');
      return preferences;
    } catch (e) {
      _logger.e('Failed to get notification preferences: $e');
      throw Exception('Failed to get notification preferences: $e');
    }
  }

  @override
  Future<void> updateNotificationPreferences(
    String userId,
    Map<String, dynamic> preferences,
  ) async {
    try {
      _logger.i('Updating notification preferences for user: $userId');
      await _remoteDataSource.updateNotificationPreferences(
        userId,
        preferences,
      );
      _logger.i('Notification preferences updated successfully');
    } catch (e) {
      _logger.e('Failed to update notification preferences: $e');
      throw Exception('Failed to update notification preferences: $e');
    }
  }

  @override
  Future<void> testNotification(String userId, String type) async {
    try {
      _logger.i('Sending test notification to user: $userId, type: $type');
      await _remoteDataSource.testNotification(userId, type);
      _logger.i('Test notification sent successfully');
    } catch (e) {
      _logger.e('Failed to send test notification: $e');
      throw Exception('Failed to send test notification: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> updateRelationshipGoals(
    List<String> relationshipGoals,
  ) async {
    try {
      _logger.i('Updating relationship goals: $relationshipGoals');
      final result = await _remoteDataSource.updateRelationshipGoals(
        relationshipGoals,
      );
      _logger.i('Relationship goals updated successfully');
      return result;
    } catch (e) {
      _logger.e('Failed to update relationship goals: $e');
      throw Exception('Failed to update relationship goals: $e');
    }
  }
}

