import '../../models/user_model.dart';
import 'user_local_data_source.dart';

/// Simplified mock implementation of UserLocalDataSource for development
/// This provides a minimal local storage layer to avoid type casting issues
class MockUserLocalDataSource implements UserLocalDataSource {
  // In-memory storage for development
  final Map<String, UserModel> _users = {};
  final Map<String, Map<String, dynamic>> _preferences = {};
  UserModel? _currentUser;

  @override
  Future<void> cacheUser(UserModel user) async {
    _users[user.id] = user;
  }

  @override
  Future<UserModel?> getCachedUser(String userId) async {
    return _users[userId];
  }

  @override
  Future<List<UserModel>> getCachedUsers({int? limit, int? offset}) async {
    final users = _users.values.toList();
    if (offset != null) {
      if (offset >= users.length) return [];
      final start = offset;
      final end = limit != null
          ? (start + limit).clamp(0, users.length)
          : users.length;
      return users.sublist(start, end);
    }
    if (limit != null) {
      return users.take(limit).toList();
    }
    return users;
  }

  @override
  Future<void> updateCachedUser(UserModel user) async {
    _users[user.id] = user;
  }

  @override
  Future<void> deleteCachedUser(String userId) async {
    _users.remove(userId);
  }

  @override
  Future<void> clearAllUsers() async {
    _users.clear();
  }

  @override
  Future<void> cacheCurrentUser(UserModel user) async {
    _currentUser = user;
    _users[user.id] = user;
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    return _currentUser;
  }

  @override
  Future<void> clearCurrentUser() async {
    _currentUser = null;
  }

  @override
  Future<List<UserModel>> searchCachedUsers({
    String? query,
    int? minAge,
    int? maxAge,
    String? location,
    List<String>? interests,
    int? maxDistance,
  }) async {
    var users = _users.values.toList();

    if (query != null && query.isNotEmpty) {
      users = users
          .where(
            (user) =>
                user.username.toLowerCase().contains(query.toLowerCase()) ||
                (user.bio?.toLowerCase().contains(query.toLowerCase()) ??
                    false),
          )
          .toList();
    }

    if (minAge != null) {
      users = users.where((user) => (user.age ?? 0) >= minAge).toList();
    }

    if (maxAge != null) {
      users = users.where((user) => (user.age ?? 0) <= maxAge).toList();
    }

    return users;
  }

  @override
  Future<void> cacheUserPreferences(
    String userId,
    Map<String, dynamic> preferences,
  ) async {
    _preferences[userId] = preferences;
  }

  @override
  Future<Map<String, dynamic>?> getUserPreferences(String userId) async {
    return _preferences[userId];
  }

  @override
  Future<void> updateUserPreferences(
    String userId,
    Map<String, dynamic> preferences,
  ) async {
    _preferences[userId] = {..._preferences[userId] ?? {}, ...preferences};
  }

  @override
  Future<void> cacheProfileCompletion(
    String userId,
    double completionPercentage,
  ) async {
    // Mock implementation - store in preferences
    await cacheUserPreferences(userId, {
      'profileCompletion': completionPercentage,
    });
  }

  @override
  Future<double?> getProfileCompletion(String userId) async {
    final prefs = await getUserPreferences(userId);
    return prefs?['profileCompletion']?.toDouble();
  }

  @override
  Future<void> cacheVerificationStatus(
    String userId,
    Map<String, bool> verificationStatus,
  ) async {
    await cacheUserPreferences(userId, {
      'verificationStatus': verificationStatus,
    });
  }

  @override
  Future<Map<String, bool>?> getVerificationStatus(String userId) async {
    final prefs = await getUserPreferences(userId);
    final status = prefs?['verificationStatus'];
    return status != null ? Map<String, bool>.from(status) : null;
  }

  // For methods not yet used, provide minimal implementations that won't crash
  @override
  dynamic noSuchMethod(Invocation invocation) {
    // For any unimplemented method, return appropriate defaults
    final methodName = invocation.memberName.toString();

    if (methodName.contains('Future')) {
      if (methodName.contains('List')) {
        return Future.value(<dynamic>[]);
      }
      if (methodName.contains('Map')) {
        return Future.value(<String, dynamic>{});
      }
      if (methodName.contains('bool')) {
        return Future.value(false);
      }
      if (methodName.contains('double')) {
        return Future.value(0.0);
      }
      if (methodName.contains('int')) {
        return Future.value(0);
      }
      if (methodName.contains('String')) {
        return Future.value('');
      }
      return Future.value(null);
    }

    return super.noSuchMethod(invocation);
  }
}
