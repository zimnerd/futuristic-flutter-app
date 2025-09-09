import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../domain/entities/user_profile.dart';

class ProfileService {
  final ApiClient _apiClient;

  ProfileService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<UserProfile> getCurrentProfile() async {
    try {
      final response = await _apiClient.get(ApiConstants.getCurrentProfile);
      final data = response.data as Map<String, dynamic>;
      return UserProfile.fromJson(data['profile']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<UserProfile> updateProfile(UserProfile profile) async {
    try {
      final response = await _apiClient.put(
        ApiConstants.updateProfile,
        data: profile.toJson(),
      );
      final data = response.data as Map<String, dynamic>;
      return UserProfile.fromJson(data['profile']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<String> uploadPhoto(String photoPath) async {
    try {
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(photoPath),
      });

      final response = await _apiClient.post(
        ApiConstants.uploadPhoto,
        data: formData,
      );

      final data = response.data as Map<String, dynamic>;
      return data['photoUrl'] as String;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> deletePhoto(String photoUrl) async {
    try {
      await _apiClient.delete(
        ApiConstants.deletePhoto,
        data: {'photoUrl': photoUrl},
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Connection timeout. Please check your internet connection.');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['message'] ?? 'Unknown error occurred';
        return Exception('Server error ($statusCode): $message');
      case DioExceptionType.cancel:
        return Exception('Request was cancelled');
      case DioExceptionType.unknown:
        return Exception('Network error. Please check your internet connection.');
      default:
        return Exception('An unexpected error occurred');
    }
  }
}
