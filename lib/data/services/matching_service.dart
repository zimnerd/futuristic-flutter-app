import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../domain/entities/user_profile.dart';

/// Service for matching operations that matches BLoC expectations
class MatchingService {
  final ApiClient _apiClient;

  MatchingService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Get potential matches for current user
  Future<List<UserProfile>> getPotentialMatches({
    int limit = 10,
    int offset = 0,
    Map<String, dynamic>? filters,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        'offset': offset,
        if (filters != null) ...filters,
      };

      final response = await _apiClient.get(
        ApiConstants.discover,
        queryParameters: queryParams,
      );

      final data = response.data as Map<String, dynamic>;
      final profiles = data['profiles'] as List<dynamic>;

      return profiles
          .map((profile) => _userProfileFromJson(profile as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Swipe on a profile (like or pass)
  Future<Map<String, dynamic>> swipeProfile({
    required String profileId,
    required bool isLike,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.swipe,
        data: {
          'profileId': profileId,
          'action': isLike ? 'like' : 'pass',
        },
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get user's matches
  Future<List<UserProfile>> getMatches({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.matches,
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final matches = data['matches'] as List<dynamic>;

      return matches
          .map((match) => _userProfileFromJson(match as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get a specific profile
  Future<UserProfile> getProfile(String profileId) async {
    try {
      final response = await _apiClient.get('${ApiConstants.users}/$profileId');
      return _userProfileFromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Report a profile
  Future<void> reportProfile({
    required String profileId,
    required String reason,
    String? description,
  }) async {
    try {
      await _apiClient.post(
        ApiConstants.reportProfile,
        data: {
          'profileId': profileId,
          'reason': reason,
          'description': description,
        },
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Block a profile
  Future<void> blockProfile(String profileId) async {
    try {
      await _apiClient.post(
        ApiConstants.blockProfile,
        data: {'profileId': profileId},
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Unblock a profile
  Future<void> unblockProfile(String profileId) async {
    try {
      await _apiClient.delete('${ApiConstants.blockProfile}/$profileId');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Convert JSON to UserProfile entity
  UserProfile _userProfileFromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      age: json['age'] as int,
      bio: json['bio'] as String? ?? '',
      photos: (json['photos'] as List<dynamic>?)
              ?.map((photo) => _profilePhotoFromJson(photo as Map<String, dynamic>))
              .toList() ??
          [],
      location: _userLocationFromJson(json['location'] as Map<String, dynamic>),
      isVerified: json['isVerified'] as bool? ?? false,
      interests: (json['interests'] as List<dynamic>?)
              ?.map((interest) => interest as String)
              .toList() ??
          [],
      occupation: json['occupation'] as String?,
      education: json['education'] as String?,
      height: json['height'] as int?,
      zodiacSign: json['zodiacSign'] as String?,
      lifestyle: json['lifestyle'] as Map<String, dynamic>? ?? {},
      preferences: json['preferences'] as Map<String, dynamic>? ?? {},
      lastActiveAt: json['lastActiveAt'] != null
          ? DateTime.parse(json['lastActiveAt'] as String)
          : null,
      distanceKm: json['distanceKm']?.toDouble(),
    );
  }

  /// Convert JSON to ProfilePhoto entity
  ProfilePhoto _profilePhotoFromJson(Map<String, dynamic> json) {
    return ProfilePhoto(
      id: json['id'] as String,
      url: json['url'] as String,
      order: json['order'] as int,
      isVerified: json['isVerified'] as bool? ?? false,
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.parse(json['uploadedAt'] as String)
          : null,
    );
  }

  /// Convert JSON to UserLocation entity
  UserLocation _userLocationFromJson(Map<String, dynamic> json) {
    return UserLocation(
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      city: json['city'] as String?,
      country: json['country'] as String?,
      address: json['address'] as String?,
    );
  }

  /// Handle Dio errors and convert them to meaningful exceptions
  Exception _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return Exception('Request timeout. Please check your internet connection.');
      case DioExceptionType.connectionError:
        return Exception('No internet connection. Please check your network settings.');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['message'] ?? 'An error occurred';
        switch (statusCode) {
          case 400:
            return Exception('Bad request: $message');
          case 401:
            return Exception('Unauthorized: Please login again');
          case 403:
            return Exception('Forbidden: $message');
          case 404:
            return Exception('Not found: $message');
          case 429:
            return Exception('Too many requests. Please try again later.');
          case 500:
            return Exception('Server error. Please try again later.');
          default:
            return Exception('HTTP $statusCode: $message');
        }
      default:
        return Exception('An unexpected error occurred: ${e.message}');
    }
  }
}
