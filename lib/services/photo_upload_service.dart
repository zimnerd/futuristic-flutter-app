import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

/// Service for handling photo uploads and management
class PhotoUploadService {
  final ImagePicker _picker = ImagePicker();
  final Dio _httpClient;
  final Box<String> _secureStorage;

  PhotoUploadService({
    required Dio httpClient,
    required Box<String> secureStorage,
  }) : _httpClient = httpClient,
       _secureStorage = secureStorage;

  /// Pick image from gallery
  Future<XFile?> pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      throw PhotoUploadException('Failed to pick image from gallery: $e');
    }
  }

  /// Pick image from camera
  Future<XFile?> pickFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      throw PhotoUploadException('Failed to capture image from camera: $e');
    }
  }

  /// Pick multiple images from gallery
  Future<List<XFile>> pickMultipleFromGallery({int maxImages = 6}) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (images.length > maxImages) {
        return images.take(maxImages).toList();
      }

      return images;
    } catch (e) {
      throw PhotoUploadException('Failed to pick multiple images: $e');
    }
  }

  /// Upload photo to server
  Future<PhotoUploadResult> uploadPhoto(XFile imageFile) async {
    try {
      final token = _secureStorage.get('access_token');
      if (token == null) {
        throw PhotoUploadException('No authentication token available');
      }

      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(
          imageFile.path,
          filename: path.basename(imageFile.path),
        ),
      });

      final response = await _httpClient.post(
        '/photos/upload',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = _parseUploadResponse(response.data);
        return result;
      } else {
        throw PhotoUploadException(
          'Upload failed with status ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is PhotoUploadException) rethrow;
      throw PhotoUploadException('Failed to upload photo: $e');
    }
  }

  /// Upload multiple photos
  Future<List<PhotoUploadResult>> uploadMultiplePhotos(
    List<XFile> imageFiles,
  ) async {
    final results = <PhotoUploadResult>[];

    for (final imageFile in imageFiles) {
      try {
        final result = await uploadPhoto(imageFile);
        results.add(result);
      } catch (e) {
        // Continue with other uploads even if one fails
        results.add(PhotoUploadResult(success: false, error: e.toString()));
      }
    }

    return results;
  }

  /// Delete photo from server
  Future<bool> deletePhoto(String photoId) async {
    try {
      final token = _secureStorage.get('access_token');
      if (token == null) {
        throw PhotoUploadException('No authentication token available');
      }

      final response = await _httpClient.delete(
        '/photos/$photoId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      throw PhotoUploadException('Failed to delete photo: $e');
    }
  }

  /// Get image file size
  Future<int> getImageSize(XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      return bytes.length;
    } catch (e) {
      throw PhotoUploadException('Failed to get image size: $e');
    }
  }

  /// Validate image file
  Future<ValidationResult> validateImage(XFile imageFile) async {
    try {
      // Check file size (max 10MB)
      const maxSize = 10 * 1024 * 1024; // 10MB in bytes
      final size = await getImageSize(imageFile);

      if (size > maxSize) {
        return ValidationResult(
          isValid: false,
          error: 'Image size must be less than 10MB',
        );
      }

      // Check file extension
      final extension = path.extension(imageFile.path).toLowerCase();
      const allowedExtensions = ['.jpg', '.jpeg', '.png', '.webp'];

      if (!allowedExtensions.contains(extension)) {
        return ValidationResult(
          isValid: false,
          error: 'Only JPG, PNG, and WebP images are allowed',
        );
      }

      return ValidationResult(isValid: true);
    } catch (e) {
      return ValidationResult(
        isValid: false,
        error: 'Failed to validate image: $e',
      );
    }
  }

  PhotoUploadResult _parseUploadResponse(dynamic responseData) {
    try {
      // Parse response data to extract photo URL and ID
      if (responseData is Map<String, dynamic>) {
        return PhotoUploadResult(
          success: true,
          photoId:
              responseData['id']?.toString() ??
              'photo_${DateTime.now().millisecondsSinceEpoch}',
          photoUrl:
              responseData['url']?.toString() ??
              responseData['photoUrl']?.toString(),
        );
      }

      // Fallback for other response formats
      return PhotoUploadResult(
        success: true,
        photoId: 'photo_${DateTime.now().millisecondsSinceEpoch}',
        photoUrl: responseData.toString(),
      );
    } catch (e) {
      throw PhotoUploadException('Failed to parse upload response: $e');
    }
  }
}

/// Result of photo upload operation
class PhotoUploadResult {
  final bool success;
  final String? photoId;
  final String? photoUrl;
  final String? error;

  PhotoUploadResult({
    required this.success,
    this.photoId,
    this.photoUrl,
    this.error,
  });
}

/// Result of image validation
class ValidationResult {
  final bool isValid;
  final String? error;

  ValidationResult({required this.isValid, this.error});
}

/// Exception thrown during photo upload operations
class PhotoUploadException implements Exception {
  final String message;

  PhotoUploadException(this.message);

  @override
  String toString() => 'PhotoUploadException: $message';
}
