import 'package:hive_flutter/hive_flutter.dart';

/// Web-compatible service for managing Hive-based local storage
/// Handles user preferences, auth tokens, and simple key-value data
class HiveStorageService {
  static const String _userPrefsBox = 'user_preferences';
  static const String _authBox = 'authentication';
  static const String _settingsBox = 'app_settings';
  static const String _cacheBox = 'api_cache';

  late Box<dynamic> _userPrefsStorage;
  late Box<dynamic> _authStorage;
  late Box<dynamic> _settingsStorage;
  late Box<dynamic> _cacheStorage;

  /// Initialize Hive storage for web
  Future<void> initialize() async {
    // Initialize Hive for web (no path needed)
    await Hive.initFlutter();

    // Open boxes
    _userPrefsStorage = await Hive.openBox(_userPrefsBox);
    _authStorage = await Hive.openBox(_authBox);
    _settingsStorage = await Hive.openBox(_settingsBox);
    _cacheStorage = await Hive.openBox(_cacheBox);
  }

  // User Preferences Methods
  Future<void> setUserPreference(String key, dynamic value) async {
    await _userPrefsStorage.put(key, value);
  }

  T? getUserPreference<T>(String key) {
    return _userPrefsStorage.get(key) as T?;
  }

  Future<void> removeUserPreference(String key) async {
    await _userPrefsStorage.delete(key);
  }

  Future<void> clearUserPreferences() async {
    await _userPrefsStorage.clear();
  }

  // Authentication Methods
  Future<void> setAuthToken(String token) async {
    await _authStorage.put('auth_token', token);
  }

  String? getAuthToken() {
    return _authStorage.get('auth_token') as String?;
  }

  Future<void> setRefreshToken(String token) async {
    await _authStorage.put('refresh_token', token);
  }

  String? getRefreshToken() {
    return _authStorage.get('refresh_token') as String?;
  }

  Future<void> setUserId(String userId) async {
    await _authStorage.put('user_id', userId);
  }

  String? getUserId() {
    return _authStorage.get('user_id') as String?;
  }

  Future<void> clearAuthData() async {
    await _authStorage.clear();
  }

  // App Settings Methods
  Future<void> setAppSetting(String key, dynamic value) async {
    await _settingsStorage.put(key, value);
  }

  T? getAppSetting<T>(String key) {
    return _settingsStorage.get(key) as T?;
  }

  Future<void> setThemeMode(String themeMode) async {
    await _settingsStorage.put('theme_mode', themeMode);
  }

  String? getThemeMode() {
    return _settingsStorage.get('theme_mode') as String?;
  }

  Future<void> setLanguage(String language) async {
    await _settingsStorage.put('language', language);
  }

  String? getLanguage() {
    return _settingsStorage.get('language') as String?;
  }

  // Cache Methods
  Future<void> setCacheData(
    String key,
    dynamic value, {
    Duration? duration,
  }) async {
    final cacheEntry = {
      'data': value,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'duration': duration?.inMilliseconds,
    };
    await _cacheStorage.put(key, cacheEntry);
  }

  T? getCacheData<T>(String key) {
    final cacheEntry = _cacheStorage.get(key) as Map<dynamic, dynamic>?;
    if (cacheEntry == null) return null;

    final timestamp = cacheEntry['timestamp'] as int;
    final duration = cacheEntry['duration'] as int?;

    if (duration != null) {
      final expirationTime = timestamp + duration;
      if (DateTime.now().millisecondsSinceEpoch > expirationTime) {
        _cacheStorage.delete(key);
        return null;
      }
    }

    return cacheEntry['data'] as T?;
  }

  Future<void> removeCacheData(String key) async {
    await _cacheStorage.delete(key);
  }

  Future<void> clearCache() async {
    await _cacheStorage.clear();
  }

  Future<void> clearExpiredCache() async {
    final keys = _cacheStorage.keys.toList();
    for (final key in keys) {
      getCacheData(key); // This will remove expired entries
    }
  }

  // Storage Information
  int get userPreferencesCount => _userPrefsStorage.length;
  int get cacheSize => _cacheStorage.length;
  bool get hasAuthToken => _authStorage.containsKey('auth_token');

  // Utility Methods
  Future<void> clearAll() async {
    await _userPrefsStorage.clear();
    await _authStorage.clear();
    await _settingsStorage.clear();
    await _cacheStorage.clear();
  }

  Map<String, dynamic> getDebugInfo() {
    return {
      'userPreferences': _userPrefsStorage.length,
      'authData': _authStorage.length,
      'settings': _settingsStorage.length,
      'cache': _cacheStorage.length,
      'hasAuthToken': hasAuthToken,
    };
  }
}
