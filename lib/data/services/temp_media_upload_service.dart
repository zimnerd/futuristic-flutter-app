import 'dart:io';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

/// Reusable service for temporary image uploads with confirm pattern
/// 
/// **Usage Pattern**:
/// 1. Upload images immediately when selected → temp storage
/// 2. Track temp media IDs in UI state
/// 3. When user saves (profile/event), call confirmUploads()
/// 4. If user cancels, temp files auto-cleanup after 24 hours
/// 
/// **Benefits**:
/// - Immediate upload provides instant feedback
/// - No orphaned files if user cancels
/// - Automatic cleanup of unconfirmed uploads
/// - Reusable across features (profiles, events, etc.)
class TempMediaUploadService {
  final Dio _apiClient;
  final Logger _logger = Logger();
  final Uuid _uuid = const Uuid();

  TempMediaUploadService(this._apiClient);

  /// Upload image to temporary storage
  /// Returns MediaUploadResult with mediaId for later confirmation
  Future<MediaUploadResult> uploadTemp({
    required File imageFile,
    required String type, // 'IMAGE', 'VIDEO', etc.
    required String category, // 'PROFILE', 'EVENT', etc.
    String? title,
    String? description,
    List<String>? tags,
    bool isPrimary = false,
    int order = 0,
  }) async {
    try {
      _logger.i('📤 Uploading temp image: ${imageFile.path}');

      // Compress image before upload
      final compressedImage = await _compressImage(imageFile);

      // Create multipart form data
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          compressedImage.path,
          filename: 'temp_${_uuid.v4()}.jpg',
        ),
        'type': type,
        'category': category,
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (tags != null) 'tags': tags.join(','),
        'isPrimary': isPrimary,
        'order': order,
      });

      final response = await _apiClient.post(
        '/media/upload-temp',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final mediaData = response.data['data'] ?? response.data;
        
        _logger.i('✅ Temp upload successful: ${mediaData['id']}');
        
        return MediaUploadResult(
          mediaId: mediaData['id'],
          url: mediaData['url'] ?? mediaData['originalUrl'],
          thumbnailUrl: mediaData['thumbnailUrl'],
          isTemporary: true,
        );
      } else {
        throw Exception('Failed to upload temp image: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _logger.e('❌ Network error uploading temp image: ${e.message}');
      throw Exception('Failed to upload temp image: ${e.message}');
    } catch (e) {
      _logger.e('❌ Unexpected error uploading temp image: $e');
      throw Exception('Failed to upload temp image: $e');
    }
  }

  /// Confirm temporary uploads - moves them to permanent storage
  /// Call this when user saves profile/event with images
  Future<ConfirmUploadResult> confirmUploads(List<String> mediaIds) async {
    try {
      _logger.i('✅ Confirming ${mediaIds.length} temp uploads');

      final response = await _apiClient.post(
        '/media/confirm-uploads',
        data: {'mediaIds': mediaIds},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'] ?? response.data;
        
        final confirmed = List<String>.from(data['confirmed'] ?? []);
        final failed = List<String>.from(data['failed'] ?? []);
        
        _logger.i('✅ Confirmed: ${confirmed.length}, Failed: ${failed.length}');
        
        return ConfirmUploadResult(
          confirmed: confirmed,
          failed: failed,
        );
      } else {
        throw Exception('Failed to confirm uploads: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _logger.e('❌ Network error confirming uploads: ${e.message}');
      throw Exception('Failed to confirm uploads: ${e.message}');
    } catch (e) {
      _logger.e('❌ Unexpected error confirming uploads: $e');
      throw Exception('Failed to confirm uploads: $e');
    }
  }

  /// Delete already saved/permanent media files
  /// Supports bulk deletion for managing multiple images
  Future<DeleteMediaResult> deleteMedia(List<String> mediaIds) async {
    try {
      _logger.i('🗑️ Deleting ${mediaIds.length} media files');

      final response = await _apiClient.delete(
        '/media/bulk',
        data: {'mediaIds': mediaIds},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        
        final deleted = List<String>.from(data['deleted'] ?? []);
        final failed = List<String>.from(data['failed'] ?? []);
        
        _logger.i('✅ Deleted: ${deleted.length}, Failed: ${failed.length}');
        
        return DeleteMediaResult(
          deleted: deleted,
          failed: failed,
        );
      } else {
        throw Exception('Failed to delete media: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _logger.e('❌ Network error deleting media: ${e.message}');
      throw Exception('Failed to delete media: ${e.message}');
    } catch (e) {
      _logger.e('❌ Unexpected error deleting media: $e');
      throw Exception('Failed to delete media: $e');
    }
  }

  /// Delete single media file (convenience method)
  Future<bool> deleteSingleMedia(String mediaId) async {
    final result = await deleteMedia([mediaId]);
    return result.deleted.contains(mediaId);
  }

  /// Compress image to reduce upload size
  Future<File> _compressImage(File file) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = '${dir.path}/compressed_${_uuid.v4()}.jpg';

      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 85,
        minWidth: 1080,
        minHeight: 1080,
        format: CompressFormat.jpeg,
      );

      if (compressedFile != null) {
        _logger.i('✅ Image compressed: ${file.lengthSync()} → ${File(compressedFile.path).lengthSync()} bytes');
        return File(compressedFile.path);
      }

      // If compression fails, return original
      return file;
    } catch (e) {
      _logger.w('⚠️ Image compression failed, using original: $e');
      return file;
    }
  }

  /// Upload multiple images in parallel
  Future<List<MediaUploadResult>> uploadMultipleTemp({
    required List<File> imageFiles,
    required String type,
    required String category,
    String? title,
    String? description,
    List<String>? tags,
  }) async {
    _logger.i('📤 Uploading ${imageFiles.length} images in parallel');

    final results = await Future.wait(
      imageFiles.asMap().entries.map((entry) {
        final index = entry.key;
        final file = entry.value;
        
        return uploadTemp(
          imageFile: file,
          type: type,
          category: category,
          title: title,
          description: description,
          tags: tags,
          order: index,
        );
      }),
    );

    _logger.i('✅ Uploaded ${results.length} images');
    return results;
  }
}

/// Result of temporary upload
class MediaUploadResult {
  final String mediaId;
  final String url;
  final String? thumbnailUrl;
  final bool isTemporary;

  MediaUploadResult({
    required this.mediaId,
    required this.url,
    this.thumbnailUrl,
    this.isTemporary = false,
  });
}

/// Result of confirming uploads
class ConfirmUploadResult {
  final List<String> confirmed;
  final List<String> failed;

  ConfirmUploadResult({
    required this.confirmed,
    required this.failed,
  });

  bool get hasFailures => failed.isNotEmpty;
  bool get allConfirmed => failed.isEmpty;
}

/// Result of deleting media
class DeleteMediaResult {
  final List<String> deleted;
  final List<String> failed;

  DeleteMediaResult({
    required this.deleted,
    required this.failed,
  });

  bool get hasFailures => failed.isNotEmpty;
  bool get allDeleted => failed.isEmpty;
}
