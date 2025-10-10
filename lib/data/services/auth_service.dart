import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:local_auth/local_auth.dart';
import 'package:logger/logger.dart';

import '../../core/network/api_client.dart';
import '../exceptions/app_exceptions.dart';
import '../models/user_model.dart';

/// Authentication service handling JWT tokens, biometric auth, and device fingerprinting
class AuthService {
  AuthService({
    required ApiClient apiClient,
    required Box<String> secureStorage,
    LocalAuthentication? localAuth,
    Logger? logger,
  }) : _apiClient = apiClient,
        _secureStorage = secureStorage,
        _localAuth = localAuth ?? LocalAuthentication(),
        _logger = logger ?? Logger();

  final ApiClient _apiClient;
  final Box<String> _secureStorage;
  final LocalAuthentication _localAuth;
  final Logger _logger;

  // Storage keys
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';
  static const String _deviceFingerprintKey = 'device_fingerprint';
  static const String _biometricEnabledKey = 'biometric_enabled';

  /// Sign in with email and password
  Future<AuthResult> signIn({
    required String email,
    required String password,
    bool rememberMe = false,
    bool trustDevice = false,
  }) async {
    try {
      _logger.i('🔐 Attempting sign in for: $email');

      // Generate device fingerprint
      final deviceFingerprint = await _generateDeviceFingerprint();

      final response = await _apiClient.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
          'rememberMe': rememberMe,
          'deviceFingerprint': deviceFingerprint,
          'trustDevice': trustDevice,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // Check if 2FA is required
        if (data['requiresTwoFactor'] == true) {
          _logger.i('🔒 Two-factor authentication required');
          return AuthResult.twoFactorRequired(
            sessionId: data['sessionId'],
            message: data['message'],
          );
        }

        // Store tokens and user data
        await _storeAuthData(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
          user: UserModel.fromJson(data['user']),
        );

        // Store device fingerprint
        await _secureStorage.put(_deviceFingerprintKey, deviceFingerprint);

        _logger.i('✅ Sign in successful');
        return AuthResult.success(user: UserModel.fromJson(data['user']));
      }

      throw ServerException('Login failed: ${response.statusMessage}');
    } on DioException catch (e) {
      _logger.e('❌ Sign in failed: ${e.message}');
      if (e.response?.statusCode == 401) {
        throw InvalidCredentialsException();
      } else if (e.response?.statusCode == 429) {
        throw NetworkException('Too many login attempts. Please try again later.');
      }
      throw NetworkException('Network error during sign in');
    } catch (e) {
      _logger.e('❌ Unexpected sign in error: $e');
      throw AuthException('Sign in failed: $e');
    }
  }

  /// Verify 2FA code
  Future<AuthResult> verify2FA({
    required String sessionId,
    required String code,
  }) async {
    try {
      _logger.i('🔐 Verifying 2FA code...');

      final response = await _apiClient.post(
        '/auth/verify-2fa',
        data: {
          'sessionId': sessionId,
          'code': code,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // Store tokens and user data
        await _storeAuthData(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
          user: UserModel.fromJson(data['user']),
        );

        _logger.i('✅ 2FA verification successful');
        return AuthResult.success(user: UserModel.fromJson(data['user']));
      }

      throw ServerException('2FA verification failed');
    } on DioException catch (e) {
      _logger.e('❌ 2FA verification failed: ${e.message}');
      if (e.response?.statusCode == 401) {
        throw InvalidCredentialsException();
      }
      throw NetworkException('Network error during 2FA verification');
    }
  }

  /// Sign up with email and password
  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String username,
    required String firstName,
    required String lastName,
    required DateTime dateOfBirth,
  }) async {
    try {
      _logger.i('📝 Attempting sign up for: $email');

      // Generate device fingerprint
      final deviceFingerprint = await _generateDeviceFingerprint();

      final response = await _apiClient.post(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
          'username': username,
          'firstName': firstName,
          'lastName': lastName,
          'dateOfBirth': dateOfBirth.toIso8601String(),
          'deviceFingerprint': deviceFingerprint,
        },
      );

      if (response.statusCode == 201) {
        final data = response.data;

        // Store tokens and user data
        await _storeAuthData(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
          user: UserModel.fromJson(data['user']),
        );

        // Store device fingerprint
        await _secureStorage.put(_deviceFingerprintKey, deviceFingerprint);

        _logger.i('✅ Sign up successful');
        return AuthResult.success(user: UserModel.fromJson(data['user']));
      }

      throw ServerException('Registration failed: ${response.statusMessage}');
    } on DioException catch (e) {
      _logger.e('❌ Sign up failed: ${e.message}');
      if (e.response?.statusCode == 409) {
        throw AuthException('Email already exists');
      }
      throw NetworkException('Network error during sign up');
    } catch (e) {
      _logger.e('❌ Unexpected sign up error: $e');
      throw AuthException('Sign up failed: $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      _logger.i('🚪 Signing out...');

      final accessToken = await _getAccessToken();
      if (accessToken != null) {
        // ApiClient automatically adds auth token via interceptors
        // Inform server about logout
        await _apiClient.logout();
      }

      // Clear all stored data
      await _clearAuthData();

      _logger.i('✅ Sign out successful');
    } catch (e) {
      _logger.w('⚠️ Sign out error (clearing local data): $e');
      // Clear local data even if server request fails
      await _clearAuthData();
    }
  }

  /// Get current user
  Future<UserModel?> getCurrentUser() async {
    try {
      final userData = _secureStorage.get(_userDataKey);
      if (userData == null) return null;

      final user = UserModel.fromJson(jsonDecode(userData));
      
      // Validate token is still valid
      final isValid = await _validateToken();
      if (!isValid) {
        await _clearAuthData();
        return null;
      }

      return user;
    } catch (e) {
      _logger.e('❌ Error getting current user: $e');
      return null;
    }
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final accessToken = await _getAccessToken();
    if (accessToken == null) return false;

    return await _validateToken();
  }

  /// Refresh access token
  Future<String?> refreshToken() async {
    try {
      final refreshToken = await _getRefreshToken();
      if (refreshToken == null) {
        throw TokenExpiredException();
      }

      _logger.i('🔄 Refreshing access token...');

      final response = await _apiClient.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        
        // Store new tokens
        await _secureStorage.put(_accessTokenKey, data['accessToken']);
        if (data['refreshToken'] != null) {
          await _secureStorage.put(_refreshTokenKey, data['refreshToken']);
        }

        _logger.i('✅ Token refresh successful');
        return data['accessToken'];
      }

      throw ServerException('Token refresh failed');
    } on DioException catch (e) {
      _logger.e('❌ Token refresh failed: ${e.message}');
      if (e.response?.statusCode == 401) {
        // Refresh token is invalid, clear auth data
        await _clearAuthData();
      }
      throw AuthException('Token refresh failed');
    }
  }

  /// Request password reset
  Future<void> requestPasswordReset(String email) async {
    try {
      _logger.i('📧 Requesting password reset for: $email');

      final response = await _apiClient.post(
        '/auth/forgot-password',
        data: {'email': email},
      );

      if (response.statusCode == 200) {
        _logger.i('✅ Password reset email sent');
        return;
      }

      throw ServerException('Password reset request failed');
    } on DioException catch (e) {
      _logger.e('❌ Password reset request failed: ${e.message}');
      throw NetworkException('Network error during password reset request');
    }
  }

  /// Reset password with token
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      _logger.i('🔑 Resetting password...');

      final response = await _apiClient.post(
        '/auth/reset-password',
        data: {
          'token': token,
          'newPassword': newPassword,
        },
      );

      if (response.statusCode == 200) {
        _logger.i('✅ Password reset successful');
        return;
      }

      throw ServerException('Password reset failed');
    } on DioException catch (e) {
      _logger.e('❌ Password reset failed: ${e.message}');
      if (e.response?.statusCode == 400) {
        throw AuthException('Invalid or expired reset token');
      }
      throw NetworkException('Network error during password reset');
    }
  }

  /// Enable biometric authentication
  Future<bool> enableBiometricAuth() async {
    try {
      _logger.i('👤 Checking biometric availability...');

      final isAvailable = await _localAuth.canCheckBiometrics;
      if (!isAvailable) {
        throw BiometricException('Biometric authentication not available');
      }

      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        throw BiometricException('No biometric methods available');
      }

      _logger.i('✅ Biometric authentication enabled');
      await _secureStorage.put(_biometricEnabledKey, 'true');
      return true;
    } catch (e) {
      _logger.e('❌ Failed to enable biometric auth: $e');
      return false;
    }
  }

  /// Authenticate with biometrics
  Future<bool> authenticateWithBiometrics() async {
    try {
      final isBiometricEnabled = await _isBiometricEnabled();
      if (!isBiometricEnabled) {
        throw BiometricException('Biometric authentication not enabled');
      }

      _logger.i('👤 Authenticating with biometrics...');

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access your account',
      );

      if (didAuthenticate) {
        _logger.i('✅ Biometric authentication successful');
        return true;
      }

      _logger.w('⚠️ Biometric authentication failed');
      return false;
    } catch (e) {
      _logger.e('❌ Biometric authentication error: $e');
      return false;
    }
  }

  /// Disable biometric authentication
  Future<void> disableBiometricAuth() async {
    await _secureStorage.delete(_biometricEnabledKey);
    _logger.i('🔓 Biometric authentication disabled');
  }

  /// Check if biometric authentication is enabled
  Future<bool> _isBiometricEnabled() async {
    final enabled = _secureStorage.get(_biometricEnabledKey);
    return enabled == 'true';
  }

  /// Get access token
  Future<String?> _getAccessToken() async {
    return _secureStorage.get(_accessTokenKey);
  }

  /// Get refresh token
  Future<String?> _getRefreshToken() async {
    return _secureStorage.get(_refreshTokenKey);
  }

  /// Get current access token (public method)
  Future<String?> getAccessToken() async {
    return _getAccessToken();
  }

  /// Store authentication data
  Future<void> _storeAuthData({
    required String accessToken,
    required String refreshToken,
    required UserModel user,
  }) async {
    await Future.wait([
      _secureStorage.put(_accessTokenKey, accessToken),
      _secureStorage.put(_refreshTokenKey, refreshToken),
      _secureStorage.put(_userDataKey, jsonEncode(user.toJson())),
    ]);
  }

  /// Clear all authentication data
  Future<void> _clearAuthData() async {
    await Future.wait([
      _secureStorage.delete(_accessTokenKey),
      _secureStorage.delete(_refreshTokenKey),
      _secureStorage.delete(_userDataKey),
      _secureStorage.delete(_deviceFingerprintKey),
      _secureStorage.delete(_biometricEnabledKey),
    ]);
  }

  /// Validate current token
  Future<bool> _validateToken() async {
    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null) return false;

      // ApiClient automatically adds auth token via interceptors
      final response = await _apiClient.dio.get('/auth/validate');

      return response.statusCode == 200;
    } catch (e) {
      _logger.w('⚠️ Token validation failed: $e');
      return false;
    }
  }

  /// Generate device fingerprint
  Future<String> _generateDeviceFingerprint() async {
    try {
      // Get device information
      final platform = Platform.operatingSystem;
      final version = Platform.operatingSystemVersion;
      final isPhysicalDevice = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
      
      // Create a unique fingerprint based on device characteristics
      final fingerprint = {
        'platform': platform,
        'version': version,
        'isPhysicalDevice': isPhysicalDevice,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      // Convert to base64 encoded string
      final fingerprintString = jsonEncode(fingerprint);
      final bytes = utf8.encode(fingerprintString);
      final base64String = base64Encode(bytes);

      // Take first 32 characters for a manageable fingerprint
      final deviceFingerprint = base64String.substring(0, 32);
      
      _logger.d('🔍 Generated device fingerprint: $deviceFingerprint');
      return deviceFingerprint;
    } catch (e) {
      _logger.e('❌ Error generating device fingerprint: $e');
      // Fallback to timestamp-based fingerprint
      final fallback = DateTime.now().millisecondsSinceEpoch.toString();
      return base64Encode(utf8.encode(fallback)).substring(0, 32);
    }
  }
}

/// Authentication result wrapper
class AuthResult {
  const AuthResult._({
    required this.isSuccess,
    this.user,
    this.requiresTwoFactor = false,
    this.sessionId,
    this.message,
    this.error,
  });

  final bool isSuccess;
  final UserModel? user;
  final bool requiresTwoFactor;
  final String? sessionId;
  final String? message;
  final String? error;

  /// Success result
  factory AuthResult.success({required UserModel user}) {
    return AuthResult._(
      isSuccess: true,
      user: user,
    );
  }

  /// Two-factor authentication required
  factory AuthResult.twoFactorRequired({
    required String sessionId,
    String? message,
  }) {
    return AuthResult._(
      isSuccess: false,
      requiresTwoFactor: true,
      sessionId: sessionId,
      message: message,
    );
  }

  /// Failure result
  factory AuthResult.failure({required String error}) {
    return AuthResult._(
      isSuccess: false,
      error: error,
    );
  }
}

/// Biometric authentication exception
class BiometricException implements Exception {
  const BiometricException(this.message);
  final String message;

  @override
  String toString() => 'BiometricException: $message';
}
