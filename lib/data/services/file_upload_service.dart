import 'package:dio/dio.dart';
import 'dart:io';

import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class FileUploadService {
  final ApiClient _apiClient;

  FileUploadService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<String> uploadImage(
    String filePath, {
    Function(int, int)? onProgress,
  }) async {
    try {
      final file = File(filePath);
      final fileName = file.path.split('/').last;

      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final response = await _apiClient.post(
        ApiConstants.mediaUpload,
        data: formData,
      );

      final data = response.data as Map<String, dynamic>;
      return data['imageUrl'] as String;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<String> uploadVideo(
    String filePath, {
    Function(int, int)? onProgress,
  }) async {
    try {
      final file = File(filePath);
      final fileName = file.path.split('/').last;

      final formData = FormData.fromMap({
        'video': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final response = await _apiClient.post(
        ApiConstants.mediaUpload,
        data: formData,
      );

      final data = response.data as Map<String, dynamic>;
      return data['videoUrl'] as String;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<String> uploadAudio(
    String filePath, {
    Function(int, int)? onProgress,
  }) async {
    try {
      final file = File(filePath);
      final fileName = file.path.split('/').last;

      final formData = FormData.fromMap({
        'audio': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final response = await _apiClient.post(
        ApiConstants.mediaUpload,
        data: formData,
      );

      final data = response.data as Map<String, dynamic>;
      return data['audioUrl'] as String;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<String> uploadFile(
    String filePath, {
    Function(int, int)? onProgress,
  }) async {
    try {
      final file = File(filePath);
      final fileName = file.path.split('/').last;

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final response = await _apiClient.post(
        ApiConstants.mediaUpload,
        data: formData,
      );

      final data = response.data as Map<String, dynamic>;
      return data['fileUrl'] as String;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> deleteFile(String fileUrl) async {
    try {
      await _apiClient.delete(
        ApiConstants.mediaDelete,
        data: {'fileUrl': fileUrl},
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
        return Exception(
          'Upload timeout. Please check your internet connection.',
        );
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 413) {
          return Exception('File too large. Please choose a smaller file.');
        }
        final message = e.response?.data?['message'] ?? 'Upload failed';
        return Exception('Upload error ($statusCode): $message');
      case DioExceptionType.cancel:
        return Exception('Upload was cancelled');
      case DioExceptionType.unknown:
        return Exception(
          'Network error. Please check your internet connection.',
        );
      default:
        return Exception('Upload failed. Please try again.');
    }
  }
}
