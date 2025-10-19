import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

/// Service for managing JWT tokens securely
class TokenService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';

  static final _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  final Logger _logger = Logger();

  /// Store access and refresh tokens securely
  Future<void> storeTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    try {
      await Future.wait([
        _storage.write(key: _accessTokenKey, value: accessToken),
        _storage.write(key: _refreshTokenKey, value: refreshToken),
      ]);
      _logger.i('Tokens stored successfully');
    } catch (e) {
      _logger.e('Failed to store tokens: $e');
      rethrow;
    }
  }

  /// Get the stored access token
  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: _accessTokenKey);
    } catch (e) {
      _logger.e('Failed to read access token: $e');
      return null;
    }
  }

  /// Get the stored refresh token
  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _refreshTokenKey);
    } catch (e) {
      _logger.e('Failed to read refresh token: $e');
      return null;
    }
  }

  /// Store user data securely
  Future<void> storeUserData(Map<String, dynamic> userData) async {
    try {
      final jsonString = jsonEncode(userData);
      await _storage.write(key: _userDataKey, value: jsonString);
      _logger.i('User data stored successfully');
    } catch (e) {
      _logger.e('Failed to store user data: $e');
      rethrow;
    }
  }

  /// Get stored user data
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final jsonString = await _storage.read(key: _userDataKey);
      if (jsonString != null) {
        return jsonDecode(jsonString) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      _logger.e('Failed to read user data: $e');
      return null;
    }
  }

  /// Clear all stored authentication data
  Future<void> clearTokens() async {
    try {
      await Future.wait([
        _storage.delete(key: _accessTokenKey),
        _storage.delete(key: _refreshTokenKey),
        _storage.delete(key: _userDataKey),
      ]);
      _logger.i('All tokens cleared successfully');
    } catch (e) {
      _logger.e('Failed to clear tokens: $e');
      rethrow;
    }
  }

  /// Check if user has valid tokens
  Future<bool> hasValidTokens() async {
    try {
      final accessToken = await getAccessToken();
      final refreshToken = await getRefreshToken();

      return accessToken != null && refreshToken != null;
    } catch (e) {
      _logger.e('Failed to check token validity: $e');
      return false;
    }
  }

  /// Check if access token is expired (basic JWT parsing)
  bool isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      final payload = _decodeBase64(parts[1]);
      final payloadMap = jsonDecode(payload) as Map<String, dynamic>;

      if (payloadMap['exp'] != null) {
        final expiryDate = DateTime.fromMillisecondsSinceEpoch(
          (payloadMap['exp'] as int) * 1000,
        );
        return DateTime.now().isAfter(expiryDate);
      }

      return false;
    } catch (e) {
      _logger.e('Failed to parse token expiry: $e');
      return true;
    }
  }

  /// Extract user ID from JWT token payload
  String? extractUserIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        _logger.w('Invalid JWT format: expected 3 parts, got ${parts.length}');
        return null;
      }

      final payload = _decodeBase64(parts[1]);
      final payloadMap = jsonDecode(payload) as Map<String, dynamic>;

      // Try common user ID field names
      final userId =
          payloadMap['sub'] ?? // Standard JWT subject claim
          payloadMap['userId'] ??
          payloadMap['user_id'] ??
          payloadMap['id'];

      if (userId != null) {
        return userId.toString();
      }

      _logger.w('No user ID found in JWT payload');
      return null;
    } catch (e) {
      _logger.e('Failed to extract user ID from JWT: $e');
      return null;
    }
  }

  /// Decode base64 URL
  String _decodeBase64(String str) {
    String output = str.replaceAll('-', '+').replaceAll('_', '/');

    switch (output.length % 4) {
      case 0:
        break;
      case 2:
        output += '==';
        break;
      case 3:
        output += '=';
        break;
      default:
        throw Exception('Illegal base64url string!');
    }

    return utf8.decode(base64Url.decode(output));
  }
}
