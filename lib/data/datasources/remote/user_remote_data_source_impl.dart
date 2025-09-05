import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../../../domain/services/api_service.dart';
import '../../exceptions/app_exceptions.dart';
import '../../models/user_model.dart';
import 'user_remote_data_source.dart';

/// Concrete implementation of UserRemoteDataSource using REST API
class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final ApiService _apiService;
  final Logger _logger = Logger();

  UserRemoteDataSourceImpl({required ApiService apiService})
    : _apiService = apiService;

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      _logger.d('📡 Fetching current user profile');

      final response = await _apiService.get('/users/me');

      _logger.i('✅ Current user fetched successfully');
      return UserModel.fromJson(response.data);
    } catch (e) {
      _logger.e('❌ Error fetching current user: $e');
      rethrow;
    }
  }

  @override
  Future<UserModel> getUserById(String userId) async {
    try {
      _logger.d('📡 Fetching user by ID: $userId');

      final response = await _apiService.get('/users/$userId');

      _logger.i('✅ User fetched successfully: $userId');
      return UserModel.fromJson(response.data);
    } catch (e) {
      _logger.e('❌ Error fetching user $userId: $e');
      rethrow;
    }
  }

  @override
  Future<List<UserModel>> getUsers({
    int? page,
    int? limit,
    Map<String, dynamic>? filters,
  }) async {
    try {
      _logger.d('📡 Fetching users list');

      final queryParams = <String, dynamic>{
        if (page != null) 'page': page,
        if (limit != null) 'limit': limit,
        if (filters != null) ...filters,
      };

      final response = await _apiService.get(
        '/users',
        queryParameters: queryParams,
      );

      final List<dynamic> usersJson = response.data['users'] ?? response.data;
      final users = usersJson.map((json) => UserModel.fromJson(json)).toList();

      _logger.i('✅ Users fetched successfully: ${users.length} users');
      return users;
    } catch (e) {
      _logger.e('❌ Error fetching users: $e');
      rethrow;
    }
  }

  @override
  Future<UserModel> updateProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      _logger.d('📡 Updating user profile: $userId');

      final response = await _apiService.put('/users/$userId', data: updates);

      _logger.i('✅ Profile updated successfully: $userId');
      return UserModel.fromJson(response.data);
    } catch (e) {
      _logger.e('❌ Error updating profile $userId: $e');
      rethrow;
    }
  }

  @override
  Future<UserModel> updateProfilePicture(
    String userId,
    String imagePath,
  ) async {
    try {
      _logger.d('📡 Updating profile picture: $userId');

      final formData = FormData.fromMap({
        'profilePicture': await MultipartFile.fromFile(imagePath),
      });

      final response = await _apiService.post(
        '/users/$userId/profile-picture',
        data: formData,
      );

      _logger.i('✅ Profile picture updated successfully: $userId');
      return UserModel.fromJson(response.data);
    } catch (e) {
      _logger.e('❌ Error updating profile picture $userId: $e');
      rethrow;
    }
  }

  @override
  Future<List<String>> uploadProfileImages(
    String userId,
    List<String> imagePaths,
  ) async {
    try {
      _logger.d('📡 Uploading profile images: $userId');

      final formData = FormData.fromMap({
        'images': imagePaths
            .map((path) async => await MultipartFile.fromFile(path))
            .toList(),
      });

      final response = await _apiService.post(
        '/users/$userId/images',
        data: formData,
      );

      final List<String> imageUrls = List<String>.from(
        response.data['imageUrls'] ?? [],
      );

      _logger.i(
        '✅ Profile images uploaded successfully: $userId, ${imageUrls.length} images',
      );
      return imageUrls;
    } catch (e) {
      _logger.e('❌ Error uploading profile images $userId: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteProfileImage(String userId, String imageUrl) async {
    try {
      _logger.d('📡 Deleting profile image: $userId');

      await _apiService.delete(
        '/users/$userId/images',
        data: {'imageUrl': imageUrl},
      );

      _logger.i('✅ Profile image deleted successfully: $userId');
    } catch (e) {
      _logger.e('❌ Error deleting profile image $userId: $e');
      rethrow;
    }
  }

  @override
  Future<void> reorderProfileImages(
    String userId,
    List<String> imageUrls,
  ) async {
    try {
      _logger.d('📡 Reordering profile images: $userId');

      await _apiService.put(
        '/users/$userId/images/reorder',
        data: {'imageUrls': imageUrls},
      );

      _logger.i('✅ Profile images reordered successfully: $userId');
    } catch (e) {
      _logger.e('❌ Error reordering profile images $userId: $e');
      rethrow;
    }
  }

  @override
  Future<List<UserModel>> getRecommendedUsers({
    String? userId,
    int? limit,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      _logger.d('📡 Fetching recommended users');

      final queryParams = <String, dynamic>{
        if (userId != null) 'userId': userId,
        if (limit != null) 'limit': limit,
        if (preferences != null) ...preferences,
      };

      final response = await _apiService.get(
        '/matching/suggestions',
        queryParameters: queryParams,
      );

      final List<dynamic> usersJson = response.data['users'] ?? response.data;
      final users = usersJson.map((json) => UserModel.fromJson(json)).toList();

      _logger.i('✅ Recommended users fetched: ${users.length} users');
      return users;
    } catch (e) {
      _logger.e('❌ Error fetching recommended users: $e');
      rethrow;
    }
  }

  @override
  Future<List<UserModel>> getUsersNearby({
    required double latitude,
    required double longitude,
    double? radiusKm,
    int? limit,
  }) async {
    try {
      _logger.d('📡 Fetching nearby users');

      final queryParams = <String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
        if (radiusKm != null) 'radius': radiusKm,
        if (limit != null) 'limit': limit,
      };

      final response = await _apiService.get(
        '/users/nearby',
        queryParameters: queryParams,
      );

      final List<dynamic> usersJson = response.data['users'] ?? response.data;
      final users = usersJson.map((json) => UserModel.fromJson(json)).toList();

      _logger.i('✅ Nearby users fetched: ${users.length} users');
      return users;
    } catch (e) {
      _logger.e('❌ Error fetching nearby users: $e');
      rethrow;
    }
  }

  @override
  Future<List<UserModel>> searchUsers({
    String? query,
    int? minAge,
    int? maxAge,
    String? location,
    List<String>? interests,
    int? page,
    int? limit,
  }) async {
    try {
      _logger.d('📡 Searching users');

      final queryParams = <String, dynamic>{
        if (query != null) 'query': query,
        if (minAge != null) 'minAge': minAge,
        if (maxAge != null) 'maxAge': maxAge,
        if (location != null) 'location': location,
        if (interests != null) 'interests': interests.join(','),
        if (page != null) 'page': page,
        if (limit != null) 'limit': limit,
      };

      final response = await _apiService.get(
        '/users/search',
        queryParameters: queryParams,
      );

      final List<dynamic> usersJson = response.data['users'] ?? response.data;
      final users = usersJson.map((json) => UserModel.fromJson(json)).toList();

      _logger.i('✅ User search completed: ${users.length} users found');
      return users;
    } catch (e) {
      _logger.e('❌ Error searching users: $e');
      rethrow;
    }
  }

  // Authentication methods (simplified for this implementation)
  Future<UserModel> signIn(String email, String password) async {
    try {
      _logger.d('📡 Signing in user: $email');

      final response = await _apiService.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      // Store the auth token
      final token = response.data['access_token'];
      if (token != null) {
        _apiService.setAuthToken(token);
      }

      _logger.i('✅ User signed in successfully: $email');
      return UserModel.fromJson(response.data['user']);
    } catch (e) {
      _logger.e('❌ Error signing in user $email: $e');
      rethrow;
    }
  }

  Future<UserModel> signUp(
    String email,
    String password,
    String username,
  ) async {
    try {
      _logger.d('📡 Signing up user: $email');

      final response = await _apiService.post(
        '/auth/register',
        data: {'email': email, 'password': password, 'username': username},
      );

      // Store the auth token
      final token = response.data['access_token'];
      if (token != null) {
        _apiService.setAuthToken(token);
      }

      _logger.i('✅ User signed up successfully: $email');
      return UserModel.fromJson(response.data['user']);
    } catch (e) {
      _logger.e('❌ Error signing up user $email: $e');
      rethrow;
    }
  }

  // Placeholder implementations for other methods
  @override
  Future<void> likeUser(String userId, String targetUserId) async {
    await _apiService.post(
      '/matching/like',
      data: {'targetUserId': targetUserId},
    );
  }

  @override
  Future<void> passUser(String userId, String targetUserId) async {
    await _apiService.post(
      '/matching/pass',
      data: {'targetUserId': targetUserId},
    );
  }

  @override
  Future<void> superLikeUser(String userId, String targetUserId) async {
    await _apiService.post(
      '/matching/super-like',
      data: {'targetUserId': targetUserId},
    );
  }

  @override
  Future<void> undoLastAction(String userId) async {
    await _apiService.post('/matching/undo', data: {});
  }

  @override
  Future<Map<String, dynamic>> getInteractionHistory(
    String userId, {
    int? limit,
  }) async {
    final response = await _apiService.get(
      '/matching/history',
      queryParameters: {if (limit != null) 'limit': limit},
    );
    return response.data;
  }

  // Basic implementations for other required methods
  @override
  Future<Map<String, dynamic>> requestPhoneVerification(String phoneNumber) =>
      throw UnimplementedError();
  @override
  Future<bool> verifyPhoneNumber(String phoneNumber, String code) =>
      throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> requestEmailVerification(String email) =>
      throw UnimplementedError();
  @override
  Future<bool> verifyEmail(String email, String token) =>
      throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> requestPhotoVerification(String userId) =>
      throw UnimplementedError();
  @override
  Future<bool> submitPhotoVerification(String userId, String imagePath) =>
      throw UnimplementedError();
  @override
  Future<void> blockUser(String userId, String targetUserId) =>
      throw UnimplementedError();
  @override
  Future<void> unblockUser(String userId, String targetUserId) =>
      throw UnimplementedError();
  @override
  Future<List<String>> getBlockedUsers(String userId) =>
      throw UnimplementedError();
  @override
  Future<void> reportUser(
    String userId,
    String targetUserId,
    String reason, {
    String? details,
  }) => throw UnimplementedError();
  @override
  Future<void> updatePrivacySettings(
    String userId,
    Map<String, dynamic> settings,
  ) => throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> getPrivacySettings(String userId) =>
      throw UnimplementedError();
  @override
  Future<void> updateUserPreferences(
    String userId,
    Map<String, dynamic> preferences,
  ) => throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> getUserPreferences(String userId) =>
      throw UnimplementedError();
  @override
  Future<void> updateNotificationSettings(
    String userId,
    Map<String, dynamic> settings,
  ) => throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> getNotificationSettings(String userId) =>
      throw UnimplementedError();
  @override
  Future<void> updateUserLocation(
    String userId,
    double latitude,
    double longitude,
  ) => throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> getUserLocation(String userId) =>
      throw UnimplementedError();
  @override
  Future<void> updateLocationPreferences(
    String userId,
    Map<String, dynamic> preferences,
  ) => throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> getUserAnalytics(String userId) =>
      throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> getUserActivity(
    String userId, {
    DateTime? since,
  }) => throw UnimplementedError();
  @override
  Future<void> trackUserAction(
    String userId,
    String action,
    Map<String, dynamic>? metadata,
  ) => throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> getSubscriptionStatus(String userId) =>
      throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> getPremiumFeatures(String userId) =>
      throw UnimplementedError();
  @override
  Future<void> updateSubscription(String userId, String subscriptionType) =>
      throw UnimplementedError();
  @override
  Future<void> deactivateAccount(String userId, String reason) =>
      throw UnimplementedError();
  @override
  Future<void> reactivateAccount(String userId) => throw UnimplementedError();
  @override
  Future<void> deleteAccount(String userId, String password, String reason) =>
      throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> exportUserData(String userId) =>
      throw UnimplementedError();

  @override
  Future<T> handleApiCall<T>(Future<Response> Function() apiCall) async {
    try {
      final response = await apiCall();
      return response.data;
    } on DioException catch (e) {
      throw mapErrorToException(e);
    }
  }

  @override
  Exception mapErrorToException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutException();
      case DioExceptionType.connectionError:
        return const NetworkException('Connection failed');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data?['message'] ?? 'Server error';

        switch (statusCode) {
          case 400:
            return ValidationException(message);
          case 401:
            return const UnauthorizedException();
          case 403:
            return const UnauthorizedException();
          case 404:
            return const UserNotFoundException();
          case 500:
            return const ServerException('Internal server error');
          default:
            return ServerException(message);
        }
      default:
        return NetworkException(error.message ?? 'Unknown network error');
    }
  }
}
