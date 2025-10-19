import 'package:logger/logger.dart';

import '../../models/user_model.dart';
import '../../../core/storage/hive_storage_service.dart';
import '../../exceptions/app_exceptions.dart';

/// Local data source for user-related operations
/// Handles caching and offline storage of user data
abstract class UserLocalDataSource {
  // User caching
  Future<void> cacheUser(UserModel user);
  Future<UserModel?> getCurrentUser();
  Future<UserModel?> getUserById(String userId);
  Future<UserModel?> getCachedUser(String userId);
  Future<List<UserModel>> getCachedUsers();
  Future<void> clearUserCache();

  // Authentication tokens
  Future<void> saveAuthToken(String token);
  Future<String?> getAuthToken();
  Future<void> clearAuthToken();

  // User preferences
  Future<void> saveUserPreferences(
    String userId,
    Map<String, dynamic> preferences,
  );
  Future<Map<String, dynamic>?> getUserPreferences(String userId);
}

/// Implementation of UserLocalDataSource using Hive storage
class UserLocalDataSourceImpl implements UserLocalDataSource {
  final HiveStorageService _storageService;
  final Logger _logger = Logger();

  static const String _currentUserKey = 'current_user';
  static const String _cachedUsersKey = 'cached_users';

  UserLocalDataSourceImpl(this._storageService);

  @override
  Future<void> cacheUser(UserModel user) async {
    try {
      _logger.i('Caching user: ${user.id}');

      // Save as current user
      await _storageService.saveUserData(user.toJson());

      // Also add to cached users list
      final cachedUsers = await getCachedUsers();
      final existingIndex = cachedUsers.indexWhere((u) => u.id == user.id);

      if (existingIndex >= 0) {
        cachedUsers[existingIndex] = user;
      } else {
        cachedUsers.add(user);
      }

      // Store updated list
      final cachedUsersJson = cachedUsers.map((u) => u.toJson()).toList();
      await _storageService.saveUserPreference(
        _cachedUsersKey,
        cachedUsersJson,
      );

      _logger.i('User cached successfully: ${user.id}');
    } catch (e) {
      _logger.e('Failed to cache user: $e');
      throw UserException('Failed to cache user: ${e.toString()}');
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      _logger.i('Getting current user from cache');

      final userJson = _storageService.getUserData();
      if (userJson == null) {
        return null;
      }

      final user = UserModel.fromJson(userJson);
      _logger.i('Found cached current user: ${user.id}');
      return user;
    } catch (e) {
      _logger.e('Failed to get current user: $e');
      return null;
    }
  }

  @override
  Future<UserModel?> getUserById(String userId) async {
    try {
      _logger.i('Getting cached user by ID: $userId');

      final cachedUsers = await getCachedUsers();
      try {
        final user = cachedUsers.firstWhere((u) => u.id == userId);
        _logger.i('Found cached user: $userId');
        return user;
      } catch (e) {
        _logger.i('User not found in cache: $userId');
        return null;
      }
    } catch (e) {
      _logger.e('Failed to get user by ID: $e');
      return null;
    }
  }

  @override
  Future<UserModel?> getCachedUser(String userId) async {
    return getUserById(userId);
  }

  @override
  Future<List<UserModel>> getCachedUsers() async {
    try {
      _logger.i('Getting all cached users');

      final cachedUsersJson = _storageService.getUserPreference<List<dynamic>>(
        _cachedUsersKey,
      );
      if (cachedUsersJson == null) {
        return [];
      }

      final users = cachedUsersJson
          .map((json) => UserModel.fromJson(Map<String, dynamic>.from(json)))
          .toList();

      _logger.i('Found ${users.length} cached users');
      return users;
    } catch (e) {
      _logger.e('Failed to get cached users: $e');
      return [];
    }
  }

  @override
  Future<void> clearUserCache() async {
    try {
      _logger.i('Clearing user cache');

      // Clear cached users data
      await _storageService.deleteKey(_currentUserKey, 'preferences');
      await _storageService.deleteKey(_cachedUsersKey, 'preferences');

      // Clear stored user data (used by getCurrentUser)
      await _storageService.clearUserData();

      _logger.i('User cache cleared successfully');
    } catch (e) {
      _logger.e('Failed to clear user cache: $e');
      throw UserException('Failed to clear user cache: ${e.toString()}');
    }
  }

  @override
  Future<void> saveAuthToken(String token) async {
    try {
      _logger.i('Saving auth token');

      await _storageService.saveAuthToken(token);

      _logger.i('Auth token saved successfully');
    } catch (e) {
      _logger.e('Failed to save auth token: $e');
      throw AuthException('Failed to save auth token: ${e.toString()}');
    }
  }

  @override
  Future<String?> getAuthToken() async {
    try {
      _logger.i('Getting auth token');

      final token = _storageService.getAuthToken();
      return token;
    } catch (e) {
      _logger.e('Failed to get auth token: $e');
      return null;
    }
  }

  @override
  Future<void> clearAuthToken() async {
    try {
      _logger.i('Clearing auth token');

      await _storageService.clearAuthTokens();

      _logger.i('Auth token cleared successfully');
    } catch (e) {
      _logger.e('Failed to clear auth token: $e');
      throw AuthException('Failed to clear auth token: ${e.toString()}');
    }
  }

  @override
  Future<void> saveUserPreferences(
    String userId,
    Map<String, dynamic> preferences,
  ) async {
    try {
      _logger.i('Saving user preferences for: $userId');

      final key = 'user_preferences_$userId';
      await _storageService.saveUserPreference(key, preferences);

      _logger.i('User preferences saved successfully');
    } catch (e) {
      _logger.e('Failed to save user preferences: $e');
      throw UserException('Failed to save user preferences: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>?> getUserPreferences(String userId) async {
    try {
      _logger.i('Getting user preferences for: $userId');

      final key = 'user_preferences_$userId';
      final preferences = _storageService
          .getUserPreference<Map<String, dynamic>>(key);

      return preferences;
    } catch (e) {
      _logger.e('Failed to get user preferences: $e');
      return null;
    }
  }
}
