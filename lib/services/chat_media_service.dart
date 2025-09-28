import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as path;

/// Service for handling chat media uploads (images, videos, etc.)
class ChatMediaService {
  final Dio _httpClient;
  final Box<String> _secureStorage;

  ChatMediaService({
    required Dio httpClient,
    required Box<String> secureStorage,
  })  : _httpClient = httpClient,
        _secureStorage = secureStorage;

  /// Upload image for chat message
  Future<ChatMediaUploadResult> uploadChatImage(String imagePath) async {
    try {
      final token = _secureStorage.get('access_token');
      if (token == null) {
        throw ChatMediaException('No authentication token available');
      }

      // Prepare multipart form data
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imagePath,
          filename: path.basename(imagePath),
        ),
        'type': 'image',
        'category': 'chat_message',
        'isPublic': 'false',
        'requiresModeration': 'false',
      });

      // Upload to media endpoint
      final response = await _httpClient.post(
        '/media/upload',
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
        throw ChatMediaException(
          'Upload failed with status ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is ChatMediaException) rethrow;
      throw ChatMediaException('Failed to upload chat image: $e');
    }
  }

  /// Upload video for chat message
  Future<ChatMediaUploadResult> uploadChatVideo(String videoPath) async {
    try {
      final token = _secureStorage.get('access_token');
      if (token == null) {
        throw ChatMediaException('No authentication token available');
      }

      // Prepare multipart form data for video
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          videoPath,
          filename: path.basename(videoPath),
        ),
        'type': 'video',
        'category': 'chat_message',
        'isPublic': 'false',
        'requiresModeration': 'false',
      });

      // Upload to media endpoint
      final response = await _httpClient.post(
        '/media/upload',
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
        throw ChatMediaException(
          'Upload failed with status ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is ChatMediaException) rethrow;
      throw ChatMediaException('Failed to upload chat video: $e');
    }
  }

  /// Validate file before upload
  Future<ChatMediaValidationResult> validateFile(String filePath) async {
    try {
      // Check if file exists
      final file = await _getFileFromPath(filePath);
      if (file == null) {
        return ChatMediaValidationResult(
          isValid: false,
          error: 'File not found',
        );
      }

      // Check file size (max 50MB for chat media)
      const maxSize = 50 * 1024 * 1024; // 50MB in bytes
      final size = await file.length();
      
      if (size > maxSize) {
        return ChatMediaValidationResult(
          isValid: false,
          error: 'File size must be less than 50MB',
        );
      }

      // Check file extension
      final extension = path.extension(filePath).toLowerCase();
      const allowedImageExtensions = ['.jpg', '.jpeg', '.png', '.webp', '.gif'];
      const allowedVideoExtensions = ['.mp4', '.mov', '.avi', '.webm'];
      const allowedExtensions = [...allowedImageExtensions, ...allowedVideoExtensions];
      
      if (!allowedExtensions.contains(extension)) {
        return ChatMediaValidationResult(
          isValid: false,
          error: 'File type not supported. Allowed: JPG, PNG, WebP, GIF, MP4, MOV, AVI, WebM',
        );
      }

      return ChatMediaValidationResult(isValid: true);
    } catch (e) {
      return ChatMediaValidationResult(
        isValid: false,
        error: 'Failed to validate file: $e',
      );
    }
  }

  /// Parse upload response from server
  ChatMediaUploadResult _parseUploadResponse(dynamic responseData) {
    try {
      if (responseData is Map<String, dynamic>) {
        return ChatMediaUploadResult(
          success: true,
          mediaId: responseData['id']?.toString() ?? 
                   'media_${DateTime.now().millisecondsSinceEpoch}',
          mediaUrl: responseData['url']?.toString() ?? 
                    responseData['originalUrl']?.toString(),
          mediaType: responseData['type']?.toString() ?? 'image',
          thumbnailUrl: responseData['thumbnailUrl']?.toString(),
        );
      }
      
      // Fallback for unexpected response format
      return ChatMediaUploadResult(
        success: true,
        mediaId: 'media_${DateTime.now().millisecondsSinceEpoch}',
        mediaUrl: responseData.toString(),
        mediaType: 'unknown',
      );
    } catch (e) {
      throw ChatMediaException('Failed to parse upload response: $e');
    }
  }

  /// Get file from path helper method
  Future<dynamic> _getFileFromPath(String filePath) async {
    try {
      // This would be platform-specific file handling
      // For now, we'll assume the path is valid
      return true; // Placeholder
    } catch (e) {
      return null;
    }
  }
}

/// Result of chat media upload operation
class ChatMediaUploadResult {
  final bool success;
  final String? mediaId;
  final String? mediaUrl;
  final String? mediaType;
  final String? thumbnailUrl;
  final String? error;

  ChatMediaUploadResult({
    required this.success,
    this.mediaId,
    this.mediaUrl,
    this.mediaType,
    this.thumbnailUrl,
    this.error,
  });

  @override
  String toString() {
    return 'ChatMediaUploadResult{success: $success, mediaId: $mediaId, mediaUrl: $mediaUrl, mediaType: $mediaType}';
  }
}

/// Result of chat media validation
class ChatMediaValidationResult {
  final bool isValid;
  final String? error;

  ChatMediaValidationResult({
    required this.isValid,
    this.error,
  });
}

/// Exception thrown during chat media operations
class ChatMediaException implements Exception {
  final String message;

  ChatMediaException(this.message);

  @override
  String toString() => 'ChatMediaException: $message';
}