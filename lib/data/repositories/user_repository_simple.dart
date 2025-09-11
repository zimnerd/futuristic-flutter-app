import '../../domain/repositories/user_repository.dart';
import '../../domain/services/api_service.dart';
import '../models/user_model.dart';

/// Simple user repository implementation using API service directly
/// Part of the clean architecture - no complex data sources or adapters
class UserRepositorySimple implements UserRepository {
  final ApiService _apiService;

  UserRepositorySimple({
    required ApiService apiService,
  }) : _apiService = apiService;

  // Authentication
  @override
  Future<UserModel?> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      final response = await _apiService.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data['user']);
      }
      return null;
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
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
      final response = await _apiService.post('/auth/register', data: {
        'email': email,
        'password': password,
        'username': username,
        'phone': phone,
        'firstName': firstName,
        'lastName': lastName,
        'birthdate': birthdate,
        'gender': gender,
        'location': location,
      });

      if (response.statusCode == 201) {
        return UserModel.fromJson(response.data['user']);
      }
      return null;
    } catch (e) {
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _apiService.post('/auth/logout');
    } catch (e) {
      throw Exception('Logout failed: ${e.toString()}');
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final response = await _apiService.get('/auth/me');
      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data['user']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    try {
      final response = await _apiService.post(
        '/auth/forgot-password',
        data: {'email': email},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to send password reset email');
      }
    } catch (e) {
      throw Exception('Password reset request failed: ${e.toString()}');
    }
  }

  // User Profile
  @override
  Future<UserModel?> getUserById(String userId) async {
    try {
      final response = await _apiService.get('/users/$userId');
      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data['user']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<UserModel> updateUserProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _apiService.put('/users/$userId', data: updates);
      return UserModel.fromJson(response.data['user']);
    } catch (e) {
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  @override
  Future<void> uploadProfilePhoto(String userId, String photoPath) async {
    try {
      await _apiService.post('/users/$userId/photos', data: {
        'photoPath': photoPath,
      });
    } catch (e) {
      throw Exception('Failed to upload photo: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteProfilePhoto(String userId, String photoUrl) async {
    try {
      await _apiService.delete('/users/$userId/photos', data: {
        'photoUrl': photoUrl,
      });
    } catch (e) {
      throw Exception('Failed to delete photo: ${e.toString()}');
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
      final response = await _apiService.get('/users/nearby', queryParameters: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'radiusKm': radiusKm.toString(),
        'limit': limit.toString(),
      });

      if (response.statusCode == 200) {
        final List<dynamic> users = response.data['users'];
        return users.map((user) => UserModel.fromJson(user)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<UserModel>> getUserRecommendations(
    String userId, {
    int limit = 10,
  }) async {
    try {
      final response = await _apiService.get('/users/recommendations', queryParameters: {
        'userId': userId,
        'limit': limit.toString(),
      });

      if (response.statusCode == 200) {
        final List<dynamic> users = response.data['users'];
        return users.map((user) => UserModel.fromJson(user)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // User Preferences
  @override
  Future<void> updateUserPreferences(
    String userId,
    Map<String, dynamic> preferences,
  ) async {
    try {
      await _apiService.put('/users/$userId/preferences', data: preferences);
    } catch (e) {
      throw Exception('Failed to update preferences: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>?> getUserPreferences(String userId) async {
    try {
      final response = await _apiService.get('/users/$userId/preferences');
      if (response.statusCode == 200) {
        return response.data['preferences'];
      }
      return null;
    } catch (e) {
      return null;
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
      await _apiService.post('/users/report', data: {
        'reporterId': reporterId,
        'reportedUserId': reportedUserId,
        'reason': reason,
      });
    } catch (e) {
      throw Exception('Failed to report user: ${e.toString()}');
    }
  }

  @override
  Future<void> blockUser(String blockerId, String blockedUserId) async {
    try {
      await _apiService.post('/users/block', data: {
        'blockerId': blockerId,
        'blockedUserId': blockedUserId,
      });
    } catch (e) {
      throw Exception('Failed to block user: ${e.toString()}');
    }
  }

  @override
  Future<void> unblockUser(String blockerId, String blockedUserId) async {
    try {
      await _apiService.delete('/users/block', data: {
        'blockerId': blockerId,
        'blockedUserId': blockedUserId,
      });
    } catch (e) {
      throw Exception('Failed to unblock user: ${e.toString()}');
    }
  }

  @override
  Future<List<String>> getBlockedUsers(String userId) async {
    try {
      final response = await _apiService.get('/users/$userId/blocked');
      if (response.statusCode == 200) {
        final List<dynamic> blockedIds = response.data['blockedUsers'];
        return blockedIds.cast<String>();
      }
      return [];
    } catch (e) {
      return [];
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
      final queryParams = <String, String>{};
      if (query != null) queryParams['query'] = query;
      if (minAge != null) queryParams['minAge'] = minAge.toString();
      if (maxAge != null) queryParams['maxAge'] = maxAge.toString();
      if (gender != null) queryParams['gender'] = gender;
      if (interests != null) queryParams['interests'] = interests.join(',');
      if (maxDistanceKm != null) queryParams['maxDistanceKm'] = maxDistanceKm.toString();
      queryParams['limit'] = limit.toString();

      final response = await _apiService.get('/users/search', queryParameters: queryParams);

      if (response.statusCode == 200) {
        final List<dynamic> users = response.data['users'];
        return users.map((user) => UserModel.fromJson(user)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Offline Support - Simple in-memory cache for this implementation
  final Map<String, UserModel> _userCache = {};

  @override
  Future<void> cacheUser(UserModel user) async {
    _userCache[user.id] = user;
  }

  @override
  Future<UserModel?> getCachedUser(String userId) async {
    return _userCache[userId];
  }

  @override
  Future<List<UserModel>> getCachedUsers() async {
    return _userCache.values.toList();
  }

  @override
  Future<void> clearUserCache() async {
    _userCache.clear();
  }
}
