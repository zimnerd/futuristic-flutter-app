import 'package:logger/logger.dart';

import '../../models/user_model.dart';
import '../../../domain/services/api_service.dart';
import '../../exceptions/app_exceptions.dart';

/// Remote data source for user-related API operations
/// Handles all HTTP requests to the backend user endpoints
abstract class UserRemoteDataSource {
  // Authentication
  Future<UserModel> signInWithEmailPassword(String email, String password);
  Future<UserModel> signUpWithEmailPassword(
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
  Future<UserModel> getCurrentUser();
  Future<void> requestPasswordReset(String email);
  Future<UserModel> verifyTwoFactor({
    required String sessionId,
    required String code,
  });
  Future<void> refreshToken();

  // User Profile
  Future<UserModel> getUserById(String userId);
  Future<UserModel> updateUserProfile(
    String userId,
    Map<String, dynamic> updates,
  );
  Future<String> uploadProfilePhoto(String userId, String photoPath);
  Future<void> deleteProfilePhoto(String userId, String photoUrl);

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
  Future<Map<String, dynamic>> getUserPreferences(String userId);

  // User Verification
  Future<void> requestPhoneVerification(String userId, String phoneNumber);
  Future<UserModel> verifyPhoneNumber(String userId, String verificationCode);
  Future<void> requestEmailVerification(String userId);
  Future<UserModel> verifyEmail(String userId, String verificationToken);

  // User Actions
  Future<void> reportUser(String userId, String reportedUserId, String reason);
  Future<void> blockUser(String userId, String blockedUserId);
  Future<void> unblockUser(String userId, String blockedUserId);
  Future<List<UserModel>> getBlockedUsers(String userId);

  // User Status
  Future<void> updateOnlineStatus(String userId, bool isOnline);
  Future<void> updateLocation(String userId, double latitude, double longitude);
}

/// Implementation of UserRemoteDataSource using API service
class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final ApiService _apiService;
  final Logger _logger = Logger();

  UserRemoteDataSourceImpl(this._apiService);

  @override
  Future<UserModel> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      _logger.i('Signing in user with email: $email');

      final response = await _apiService.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final userData = response.data['user'];
        final accessToken = response.data['accessToken'];

        // Store auth token for future requests
        if (accessToken != null) {
          _apiService.setAuthToken(accessToken);
        }

        return UserModel.fromJson(userData);
      } else {
        throw ApiException('Login failed: ${response.statusMessage}');
      }
    } catch (e) {
      _logger.e('Sign in error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Sign in failed: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> signUpWithEmailPassword(
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

      final response = await _apiService.post(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
          'username': username,
          'phone': phone,
          if (firstName != null) 'firstName': firstName,
          if (lastName != null) 'lastName': lastName,
          if (birthdate != null) 'birthdate': birthdate,
          if (gender != null) 'gender': gender,
          if (location != null) 'location': location,
        },
      );

      if (response.statusCode == 201) {
        final userData = response.data['user'];
        final accessToken = response.data['accessToken'];

        // Store auth token for future requests
        if (accessToken != null) {
          _apiService.setAuthToken(accessToken);
        }

        return UserModel.fromJson(userData);
      } else {
        throw ApiException('Registration failed: ${response.statusMessage}');
      }
    } catch (e) {
      _logger.e('Sign up error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Sign up failed: ${e.toString()}');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      _logger.i('Signing out user');

      await _apiService.post('/auth/logout');
      _apiService.clearAuthToken();

      _logger.i('User signed out successfully');
    } catch (e) {
      _logger.e('Sign out error: $e');
      // Even if logout fails on server, clear local token
      _apiService.clearAuthToken();
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      _logger.i('Getting current user');

      final response = await _apiService.get('/users/me');

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data);
      } else {
        throw ApiException(
          'Failed to get current user: ${response.statusMessage}',
        );
      }
    } catch (e) {
      _logger.e('Get current user error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to get current user: ${e.toString()}');
    }
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    try {
      _logger.i('Requesting password reset for email: $email');

      await _apiService.post('/auth/password-reset', data: {'email': email});

      _logger.i('Password reset requested successfully');
    } catch (e) {
      _logger.e('Password reset request error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Password reset request failed: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> verifyTwoFactor({
    required String sessionId,
    required String code,
  }) async {
    try {
      _logger.i('Verifying two-factor authentication');

      final response = await _apiService.post(
        '/auth/verify-2fa',
        data: {'sessionId': sessionId, 'code': code},
      );

      if (response.statusCode == 200) {
        final userData = response.data['user'];
        final accessToken = response.data['accessToken'];

        if (accessToken != null) {
          _apiService.setAuthToken(accessToken);
        }

        return UserModel.fromJson(userData);
      } else {
        throw ApiException(
          '2FA verification failed: ${response.statusMessage}',
        );
      }
    } catch (e) {
      _logger.e('2FA verification error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('2FA verification failed: ${e.toString()}');
    }
  }

  @override
  Future<void> refreshToken() async {
    try {
      _logger.i('Refreshing auth token');

      final response = await _apiService.post('/auth/refresh');

      if (response.statusCode == 200) {
        final accessToken = response.data['accessToken'];
        if (accessToken != null) {
          _apiService.setAuthToken(accessToken);
        }
      } else {
        throw ApiException('Token refresh failed: ${response.statusMessage}');
      }
    } catch (e) {
      _logger.e('Token refresh error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Token refresh failed: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> getUserById(String userId) async {
    try {
      _logger.i('Getting user by ID: $userId');

      final response = await _apiService.get('/users/$userId');

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data);
      } else {
        throw ApiException('Failed to get user: ${response.statusMessage}');
      }
    } catch (e) {
      _logger.e('Get user by ID error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to get user: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> updateUserProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      _logger.i('Updating user profile for ID: $userId');

      final response = await _apiService.patch('/users/$userId', data: updates);

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data);
      } else {
        throw ApiException(
          'Failed to update profile: ${response.statusMessage}',
        );
      }
    } catch (e) {
      _logger.e('Update user profile error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to update profile: ${e.toString()}');
    }
  }

  @override
  Future<String> uploadProfilePhoto(String userId, String photoPath) async {
    try {
      _logger.i('Uploading profile photo for user: $userId');

      final response = await _apiService.post(
        '/users/$userId/photos',
        data: {'photoPath': photoPath},
      );

      if (response.statusCode == 201) {
        return response.data['photoUrl'];
      } else {
        throw ApiException('Failed to upload photo: ${response.statusMessage}');
      }
    } catch (e) {
      _logger.e('Upload profile photo error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to upload photo: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteProfilePhoto(String userId, String photoUrl) async {
    try {
      _logger.i('Deleting profile photo for user: $userId');

      await _apiService.delete(
        '/users/$userId/photos',
        data: {'photoUrl': photoUrl},
      );

      _logger.i('Profile photo deleted successfully');
    } catch (e) {
      _logger.e('Delete profile photo error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to delete photo: ${e.toString()}');
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

      final response = await _apiService.get(
        '/users/nearby',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'radius': radiusKm,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> usersData = response.data['users'];
        return usersData.map((json) => UserModel.fromJson(json)).toList();
      } else {
        throw ApiException(
          'Failed to get nearby users: ${response.statusMessage}',
        );
      }
    } catch (e) {
      _logger.e('Get nearby users error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to get nearby users: ${e.toString()}');
    }
  }

  @override
  Future<List<UserModel>> getUserRecommendations(
    String userId, {
    int limit = 10,
  }) async {
    try {
      _logger.i('Getting user recommendations for: $userId');

      final response = await _apiService.get(
        '/users/$userId/recommendations',
        queryParameters: {'limit': limit},
      );

      if (response.statusCode == 200) {
        final List<dynamic> usersData = response.data['recommendations'];
        return usersData.map((json) => UserModel.fromJson(json)).toList();
      } else {
        throw ApiException(
          'Failed to get recommendations: ${response.statusMessage}',
        );
      }
    } catch (e) {
      _logger.e('Get user recommendations error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to get recommendations: ${e.toString()}');
    }
  }

  @override
  Future<void> updateUserPreferences(
    String userId,
    Map<String, dynamic> preferences,
  ) async {
    try {
      _logger.i('Updating user preferences for: $userId');

      await _apiService.patch('/users/$userId/preferences', data: preferences);

      _logger.i('User preferences updated successfully');
    } catch (e) {
      _logger.e('Update user preferences error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to update preferences: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> getUserPreferences(String userId) async {
    try {
      _logger.i('Getting user preferences for: $userId');

      final response = await _apiService.get('/users/$userId/preferences');

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data);
      } else {
        throw ApiException(
          'Failed to get preferences: ${response.statusMessage}',
        );
      }
    } catch (e) {
      _logger.e('Get user preferences error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to get preferences: ${e.toString()}');
    }
  }

  @override
  Future<void> requestPhoneVerification(
    String userId,
    String phoneNumber,
  ) async {
    try {
      _logger.i('Requesting phone verification for user: $userId');

      await _apiService.post(
        '/users/$userId/verify-phone',
        data: {'phoneNumber': phoneNumber},
      );

      _logger.i('Phone verification requested successfully');
    } catch (e) {
      _logger.e('Request phone verification error: $e');
      if (e is ApiException) rethrow;
      throw ApiException(
        'Failed to request phone verification: ${e.toString()}',
      );
    }
  }

  @override
  Future<UserModel> verifyPhoneNumber(
    String userId,
    String verificationCode,
  ) async {
    try {
      _logger.i('Verifying phone number for user: $userId');

      final response = await _apiService.post(
        '/users/$userId/verify-phone/confirm',
        data: {'verificationCode': verificationCode},
      );

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data);
      } else {
        throw ApiException(
          'Phone verification failed: ${response.statusMessage}',
        );
      }
    } catch (e) {
      _logger.e('Verify phone number error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Phone verification failed: ${e.toString()}');
    }
  }

  @override
  Future<void> requestEmailVerification(String userId) async {
    try {
      _logger.i('Requesting email verification for user: $userId');

      await _apiService.post('/users/$userId/verify-email');

      _logger.i('Email verification requested successfully');
    } catch (e) {
      _logger.e('Request email verification error: $e');
      if (e is ApiException) rethrow;
      throw ApiException(
        'Failed to request email verification: ${e.toString()}',
      );
    }
  }

  @override
  Future<UserModel> verifyEmail(String userId, String verificationToken) async {
    try {
      _logger.i('Verifying email for user: $userId');

      final response = await _apiService.post(
        '/users/$userId/verify-email/confirm',
        data: {'verificationToken': verificationToken},
      );

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data);
      } else {
        throw ApiException(
          'Email verification failed: ${response.statusMessage}',
        );
      }
    } catch (e) {
      _logger.e('Verify email error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Email verification failed: ${e.toString()}');
    }
  }

  @override
  Future<void> reportUser(
    String userId,
    String reportedUserId,
    String reason,
  ) async {
    try {
      _logger.i('Reporting user $reportedUserId by user $userId');

      await _apiService.post(
        '/users/$userId/report',
        data: {'reportedUserId': reportedUserId, 'reason': reason},
      );

      _logger.i('User reported successfully');
    } catch (e) {
      _logger.e('Report user error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to report user: ${e.toString()}');
    }
  }

  @override
  Future<void> blockUser(String userId, String blockedUserId) async {
    try {
      _logger.i('Blocking user $blockedUserId by user $userId');

      await _apiService.post(
        '/users/$userId/block',
        data: {'blockedUserId': blockedUserId},
      );

      _logger.i('User blocked successfully');
    } catch (e) {
      _logger.e('Block user error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to block user: ${e.toString()}');
    }
  }

  @override
  Future<void> unblockUser(String userId, String blockedUserId) async {
    try {
      _logger.i('Unblocking user $blockedUserId by user $userId');

      await _apiService.delete('/users/$userId/block/$blockedUserId');

      _logger.i('User unblocked successfully');
    } catch (e) {
      _logger.e('Unblock user error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to unblock user: ${e.toString()}');
    }
  }

  @override
  Future<List<UserModel>> getBlockedUsers(String userId) async {
    try {
      _logger.i('Getting blocked users for: $userId');

      final response = await _apiService.get('/users/$userId/blocked');

      if (response.statusCode == 200) {
        final List<dynamic> usersData = response.data['blockedUsers'];
        return usersData.map((json) => UserModel.fromJson(json)).toList();
      } else {
        throw ApiException(
          'Failed to get blocked users: ${response.statusMessage}',
        );
      }
    } catch (e) {
      _logger.e('Get blocked users error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to get blocked users: ${e.toString()}');
    }
  }

  @override
  Future<void> updateOnlineStatus(String userId, bool isOnline) async {
    try {
      _logger.i('Updating online status for user $userId: $isOnline');

      await _apiService.patch(
        '/users/$userId/status',
        data: {'isOnline': isOnline},
      );

      _logger.i('Online status updated successfully');
    } catch (e) {
      _logger.e('Update online status error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to update online status: ${e.toString()}');
    }
  }

  @override
  Future<void> updateLocation(
    String userId,
    double latitude,
    double longitude,
  ) async {
    try {
      _logger.i(
        'Updating location for user $userId: lat=$latitude, lng=$longitude',
      );

      await _apiService.patch(
        '/users/$userId/location',
        data: {'latitude': latitude, 'longitude': longitude},
      );

      _logger.i('Location updated successfully');
    } catch (e) {
      _logger.e('Update location error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to update location: ${e.toString()}');
    }
  }
}
