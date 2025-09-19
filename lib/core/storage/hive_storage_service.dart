import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

/// Service for managing Hive-based local storage
/// Handles user preferences, auth tokens, and simple key-value data
class HiveStorageService {
  static const String _userPrefsBox = 'user_preferences';
  static const String _authBox = 'authentication';
  static const String _settingsBox = 'app_settings';
  static const String _cacheBox = 'api_cache';
  static const String _secureStorageBox = 'secure_storage';

  late Box<dynamic> _userPrefsStorage;
  late Box<dynamic> _authStorage;
  late Box<dynamic> _settingsStorage;
  late Box<dynamic> _cacheStorage;
  late Box<String> _secureStorage;

  /// Initialize Hive storage
  Future<void> initialize() async {
    // Get application documents directory
    final appDocumentDir = await getApplicationDocumentsDirectory();

    // Initialize Hive
    await Hive.initFlutter(appDocumentDir.path);

    // Open boxes
    _userPrefsStorage = await Hive.openBox(_userPrefsBox);
    _authStorage = await Hive.openBox(_authBox);
    _settingsStorage = await Hive.openBox(_settingsBox);
    _cacheStorage = await Hive.openBox(_cacheBox);
    _secureStorage = await Hive.openBox<String>(_secureStorageBox);
  }

  /// Close all boxes
  Future<void> close() async {
    await _userPrefsStorage.close();
    await _authStorage.close();
    await _settingsStorage.close();
    await _cacheStorage.close();
    await _secureStorage.close();
  }

  /// Clear all stored data (for logout)
  Future<void> clearAll() async {
    await _userPrefsStorage.clear();
    await _authStorage.clear();
    await _settingsStorage.clear();
    await _cacheStorage.clear();
    await _secureStorage.clear();
  }

  // Authentication methods
  Future<void> saveAuthToken(String token) async {
    await _authStorage.put('auth_token', token);
  }

  String? getAuthToken() {
    return _authStorage.get('auth_token');
  }

  Future<void> saveRefreshToken(String token) async {
    await _authStorage.put('refresh_token', token);
  }

  String? getRefreshToken() {
    return _authStorage.get('refresh_token');
  }

  Future<void> clearAuthTokens() async {
    await _authStorage.delete('auth_token');
    await _authStorage.delete('refresh_token');
  }

  // User preferences methods
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    await _userPrefsStorage.put('user_data', userData);
  }

  Map<String, dynamic>? getUserData() {
    final data = _userPrefsStorage.get('user_data');
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

  Future<void> clearUserData() async {
    await _userPrefsStorage.delete('user_data');
  }

  Future<void> saveUserPreference(String key, dynamic value) async {
    await _userPrefsStorage.put(key, value);
  }

  T? getUserPreference<T>(String key) {
    return _userPrefsStorage.get(key);
  }

  // App settings methods
  Future<void> saveAppSetting(String key, dynamic value) async {
    await _settingsStorage.put(key, value);
  }

  T? getAppSetting<T>(String key) {
    return _settingsStorage.get(key);
  }

  Future<void> saveDarkMode(bool isDarkMode) async {
    await _settingsStorage.put('dark_mode', isDarkMode);
  }

  bool? getDarkMode() {
    return _settingsStorage.get('dark_mode');
  }

  Future<void> saveNotificationsEnabled(bool enabled) async {
    await _settingsStorage.put('notifications_enabled', enabled);
  }

  bool? getNotificationsEnabled() {
    return _settingsStorage.get('notifications_enabled');
  }

  // Cache methods
  Future<void> cacheApiResponse(
    String key,
    Map<String, dynamic> data, {
    Duration? expiry,
  }) async {
    final cacheData = {
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'expiry': expiry?.inMilliseconds,
    };
    await _cacheStorage.put(key, cacheData);
  }

  Map<String, dynamic>? getCachedApiResponse(String key) {
    final cached = _cacheStorage.get(key);
    if (cached == null) return null;

    final cacheData = Map<String, dynamic>.from(cached);
    final timestamp = cacheData['timestamp'] as int;
    final expiry = cacheData['expiry'] as int?;

    // Check if cache is expired
    if (expiry != null) {
      final expiryTime = DateTime.fromMillisecondsSinceEpoch(
        timestamp + expiry,
      );
      if (DateTime.now().isAfter(expiryTime)) {
        _cacheStorage.delete(key);
        return null;
      }
    }

    return Map<String, dynamic>.from(cacheData['data']);
  }

  Future<void> clearExpiredCache() async {
    final keys = _cacheStorage.keys.toList();
    for (final key in keys) {
      getCachedApiResponse(key); // This will auto-remove expired items
    }
  }

  // Utility methods
  List<String> getAllKeys(String boxType) {
    switch (boxType) {
      case 'auth':
        return _authStorage.keys.cast<String>().toList();
      case 'preferences':
        return _userPrefsStorage.keys.cast<String>().toList();
      case 'settings':
        return _settingsStorage.keys.cast<String>().toList();
      case 'cache':
        return _cacheStorage.keys.cast<String>().toList();
      default:
        return [];
    }
  }

  bool containsKey(String key, String boxType) {
    switch (boxType) {
      case 'auth':
        return _authStorage.containsKey(key);
      case 'preferences':
        return _userPrefsStorage.containsKey(key);
      case 'settings':
        return _settingsStorage.containsKey(key);
      case 'cache':
        return _cacheStorage.containsKey(key);
      default:
        return false;
    }
  }

  Future<void> deleteKey(String key, String boxType) async {
    switch (boxType) {
      case 'auth':
        await _authStorage.delete(key);
        break;
      case 'preferences':
        await _userPrefsStorage.delete(key);
        break;
      case 'settings':
        await _settingsStorage.delete(key);
        break;
      case 'cache':
        await _cacheStorage.delete(key);
        break;
    }
  }

  /// Get the secure storage box for AuthService
  Box<String> get secureStorage => _secureStorage;
}
