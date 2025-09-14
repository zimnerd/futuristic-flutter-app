import 'package:logger/logger.dart';

import '../../models/user_model.dart';
import '../../../core/network/api_client.dart';
import '../../exceptions/app_exceptions.dart';
import '../../../core/services/service_locator.dart';

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

  // OTP Authentication
  Future<Map<String, dynamic>> sendOTP({
    required String email,
    String? phoneNumber,
    required String type,
    String? preferredMethod,
  });
  Future<Map<String, dynamic>> verifyOTP({
    required String sessionId,
    required String code,
    required String email,
  });
  Future<Map<String, dynamic>> resendOTP({required String sessionId});

  // User Profile
  Future<UserModel> getUserById(String userId);
  Future<UserModel> updateUserProfile(
    String userId,
    Map<String, dynamic> updates,
  );
  Future<String> uploadProfilePhoto(String userId, String photoPath);
  Future<void> deleteProfilePhoto(String userId, String photoUrl);
  Future<void> updateUserLocation(String userId, double latitude, double longitude);

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
  final ApiClient _apiClient;
  final Logger _logger = Logger();

  UserRemoteDataSourceImpl(this._apiClient);

  @override
  Future<UserModel> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      _logger.i('Signing in user with email: $email');

      final response = await _apiClient.login(email: email, password: password,
      );

      if (response.statusCode == 200) {
        final responseData = response.data['data'];
        final userData = responseData['user'];
        final accessToken = responseData['accessToken'];
        final refreshToken = responseData['refreshToken'];

        // Store auth tokens for future requests
        if (accessToken != null) {
          _apiClient.setAuthToken(accessToken);
          // Also set the token in the service locator for all services
          try {
            await ServiceLocator.instance.setAuthToken(accessToken);
          } catch (e) {
            _logger.w('Failed to set auth token in service locator: $e');
          }
        }
        
        // Store refresh token securely for automatic token refresh
        if (refreshToken != null && accessToken != null) {
          try {
            final tokenService = ServiceLocator.instance.token;
            await tokenService.storeTokens(
              accessToken: accessToken,
              refreshToken: refreshToken,
            );
            _logger.d('Tokens stored securely');
          } catch (e) {
            _logger.w('Failed to store tokens securely: $e');
          }
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

      final response = await _apiClient.register(
        email: email,
        password: password,
        username: username,
        phone: phone,
        firstName: firstName,
        lastName: lastName,
        birthdate: birthdate,
        gender: gender,
        location: location,
      );

      if (response.statusCode == 201) {
        final responseData = response.data['data'];
        final userData = responseData['user'];
        final accessToken = responseData['accessToken'];
        final refreshToken = responseData['refreshToken'];

        // Store auth token for future requests
        if (accessToken != null) {
          _apiClient.setAuthToken(accessToken);
          
          // Also set the token in the service locator for all services
          try {
            await ServiceLocator.instance.setAuthToken(accessToken);
          } catch (e) {
            _logger.w('Failed to set auth token in service locator: $e');
          }

          // Store tokens securely if both are available
          if (refreshToken != null) {
            try {
              final tokenService = ServiceLocator.instance.token;
              await tokenService.storeTokens(
                accessToken: accessToken,
                refreshToken: refreshToken,
              );
              _logger.d('Registration tokens stored securely');
            } catch (e) {
              _logger.w('Failed to store registration tokens: $e');
            }
          }
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

      await _apiClient.logout();
      _apiClient.clearAuthToken();
      
      // Clear securely stored tokens
      try {
        final tokenService = ServiceLocator.instance.token;
        await tokenService.clearTokens();
        _logger.d('Stored tokens cleared successfully');
      } catch (e) {
        _logger.w('Failed to clear stored tokens: $e');
      }

      _logger.i('User signed out successfully');
    } catch (e) {
      _logger.e('Sign out error: $e');
      // Even if logout fails on server, clear local tokens
      _apiClient.clearAuthToken();
      try {
        final tokenService = ServiceLocator.instance.token;
        await tokenService.clearTokens();
      } catch (clearError) {
        _logger.w(
          'Failed to clear stored tokens during error handling: $clearError',
        );
      }
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      _logger.i('Getting current user');

      final response = await _apiClient.getCurrentUser();

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

      await _apiClient.requestPasswordReset(email);

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

      final response = await _apiClient.rawPost(
        '/auth/verify-2fa',
        data: {'sessionId': sessionId, 'code': code},
      );

      if (response.statusCode == 200) {
        final responseData = response.data['data'];
        final userData = responseData['user'];
        final accessToken = responseData['accessToken'];
        final refreshToken = responseData['refreshToken'];

        if (accessToken != null) {
          _apiClient.setAuthToken(accessToken);
          
          // Also set the token in the service locator for all services
          try {
            await ServiceLocator.instance.setAuthToken(accessToken);
          } catch (e) {
            _logger.w('Failed to set auth token in service locator: $e');
          }

          // Store tokens securely if both are available
          if (refreshToken != null) {
            try {
              final tokenService = ServiceLocator.instance.token;
              await tokenService.storeTokens(
                accessToken: accessToken,
                refreshToken: refreshToken,
              );
              _logger.d('2FA verification tokens stored securely');
            } catch (e) {
              _logger.w('Failed to store 2FA tokens: $e');
            }
          }
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

      // Get the stored refresh token
      final tokenService = ServiceLocator.instance.token;
      final storedRefreshToken = await tokenService.getRefreshToken();

      if (storedRefreshToken == null) {
        throw ApiException('No refresh token available');
      }

      final response = await _apiClient.refreshToken(storedRefreshToken);

      if (response.statusCode == 200) {
        final responseData = response.data['data'] ?? response.data;
        final newAccessToken = responseData['accessToken'];
        final newRefreshToken = responseData['refreshToken'];

        if (newAccessToken != null) {
          // Update access token in API service
          _apiClient.setAuthToken(newAccessToken);

          // Update tokens in service locator
          try {
            await ServiceLocator.instance.setAuthToken(newAccessToken);
          } catch (e) {
            _logger.w('Failed to set auth token in service locator: $e');
          }

          // Store new tokens securely if refresh token is also provided
          if (newRefreshToken != null) {
            try {
              await tokenService.storeTokens(
                accessToken: newAccessToken,
                refreshToken: newRefreshToken,
              );
              _logger.d('New tokens stored securely after refresh');
            } catch (e) {
              _logger.w('Failed to store new tokens: $e');
            }
          }
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
  Future<Map<String, dynamic>> sendOTP({
    required String email,
    String? phoneNumber,
    required String type,
    String? preferredMethod,
  }) async {
    try {
      _logger.i('Sending OTP to email: $email, type: $type');

      final response = await _apiClient.sendOTP(
        email: email,
        phoneNumber: phoneNumber,
        type: type,
        preferredMethod: preferredMethod,
      );

      if (response.statusCode == 200) {
        return {
          'sessionId': response.data['sessionId'],
          'deliveryMethods': response.data['deliveryMethods'],
          'expiresAt': response.data['expiresAt'],
        };
      } else {
        throw ApiException('Failed to send OTP: ${response.statusMessage}');
      }
    } catch (e) {
      _logger.e('Send OTP error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to send OTP: ${e.toString()}');
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

      final response = await _apiClient.verifyOTP(
        sessionId: sessionId,
        code: code,
        email: email,
      );

      if (response.statusCode == 200) {
        final responseData = response.data['data'] ?? response.data;
        final verified = responseData['verified'] ?? false;

        if (verified) {
          // Store tokens if verification successful
          final tokens = responseData['tokens'];
          if (tokens != null && tokens['accessToken'] != null) {
            _apiClient.setAuthToken(tokens['accessToken']);
            
            // Also set the token in the service locator for all services
            try {
              await ServiceLocator.instance.setAuthToken(tokens['accessToken']);
            } catch (e) {
              _logger.w('Failed to set auth token in service locator: $e');
            }

            // Store tokens securely if both are available
            if (tokens['refreshToken'] != null) {
              try {
                final tokenService = ServiceLocator.instance.token;
                await tokenService.storeTokens(
                  accessToken: tokens['accessToken'],
                  refreshToken: tokens['refreshToken'],
                );
                _logger.d('OTP verification tokens stored securely');
              } catch (e) {
                _logger.w('Failed to store OTP tokens: $e');
              }
            }
          }

          return {
            'verified': true,
            'user': responseData['user'],
            'tokens': tokens,
          };
        } else {
          return {
            'verified': false,
            'attemptsRemaining': responseData['attemptsRemaining'],
          };
        }
      } else {
        throw ApiException('Failed to verify OTP: ${response.statusMessage}');
      }
    } catch (e) {
      _logger.e('Verify OTP error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to verify OTP: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> resendOTP({required String sessionId}) async {
    try {
      _logger.i('Resending OTP for session: $sessionId');

      final response = await _apiClient.rawPost(
        '/auth/resend-otp',
        data: {'sessionId': sessionId},
      );

      if (response.statusCode == 200) {
        return {
          'sessionId': response.data['sessionId'],
          'deliveryMethods': response.data['deliveryMethods'],
          'expiresAt': response.data['expiresAt'],
        };
      } else {
        throw ApiException('Failed to resend OTP: ${response.statusMessage}');
      }
    } catch (e) {
      _logger.e('Resend OTP error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to resend OTP: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> getUserById(String userId) async {
    try {
      _logger.i('Getting user by ID: $userId');

      final response = await _apiClient.getUserById(userId);

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

      final response = await _apiClient.updateProfile(updates);

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

      final response = await _apiClient.rawPost(
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

      await _apiClient.delete(
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
  Future<void> updateUserLocation(String userId, double latitude, double longitude) async {
    try {
      _logger.i('Updating user location for user: $userId');

      await _apiClient.put(
        '/users/$userId/location',
        data: {
          'latitude': latitude,
          'longitude': longitude,
        },
      );

      _logger.i('User location updated successfully');
    } catch (e) {
      _logger.e('Update user location error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to update user location: ${e.toString()}');
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

      final response = await _apiClient.get(
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

      final response = await _apiClient.get(
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

      await _apiClient.patch('/users/$userId/preferences', data: preferences);

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

      final response = await _apiClient.get('/users/$userId/preferences');

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

      await _apiClient.rawPost(
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

      final response = await _apiClient.rawPost(
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

      await _apiClient.rawPost('/users/$userId/verify-email');

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

      final response = await _apiClient.rawPost(
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

      await _apiClient.rawPost(
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

      await _apiClient.rawPost(
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

      await _apiClient.delete('/users/$userId/block/$blockedUserId');

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

      final response = await _apiClient.get('/users/$userId/blocked');

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

      await _apiClient.patch(
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

      await _apiClient.patch(
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
