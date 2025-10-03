import 'dart:io';

import 'package:logger/logger.dart';

import 'temp_media_upload_service.dart';

/// Service for managing profile photos with temporary upload pattern
/// 
/// **Usage Pattern**:
/// 1. User picks photo → uploadTempPhoto() → Store mediaId
/// 2. User removes photo → markPhotoForDeletion(mediaId)
/// 3. User saves profile → confirmPhotos() + deleteMarkedPhotos()
/// 4. User cancels → temp files auto-cleanup after 24 hours
/// 
/// **Example**:
/// ```dart
/// final photoManager = PhotoManagerService(
///   uploadService: tempMediaUploadService,
/// );
/// 
/// // User picks new photo
/// final result = await photoManager.uploadTempPhoto(imageFile);
/// _tempPhotoIds.add(result.mediaId);
/// 
/// // User removes existing photo
/// photoManager.markPhotoForDeletion(existingPhotoId);
/// 
/// // User saves profile
/// await photoManager.confirmPhotos(_tempPhotoIds);
/// await photoManager.deleteMarkedPhotos();
/// ```
class PhotoManagerService {
  final TempMediaUploadService _uploadService;
  final Logger _logger;
  final List<String> _photosToDelete = [];

  PhotoManagerService({
    required TempMediaUploadService uploadService,
    Logger? logger,
  })  : _uploadService = uploadService,
        _logger = logger ?? Logger();

  /// Upload photo to temporary storage (instant upload on selection)
  /// Returns media ID and temporary URL for preview
  Future<MediaUploadResult> uploadTempPhoto(File imageFile) async {
    try {
      _logger.i('📸 Uploading temp photo');
      
      final result = await _uploadService.uploadTemp(
        imageFile: imageFile,
        type: 'IMAGE',
        category: 'PROFILE',
        title: 'Profile Photo',
      );

      _logger.i('✅ Temp photo uploaded: ${result.mediaId}');
      return result;
    } catch (e) {
      _logger.e('❌ Failed to upload temp photo: $e');
      rethrow;
    }
  }

  /// Upload multiple photos in parallel
  Future<List<MediaUploadResult>> uploadMultipleTempPhotos(
    List<File> imageFiles,
  ) async {
    try {
      _logger.i('📸 Uploading ${imageFiles.length} temp photos');
      
      final results = await _uploadService.uploadMultipleTemp(
        imageFiles: imageFiles,
        type: 'IMAGE',
        category: 'PROFILE',
      );

      _logger.i('✅ ${results.length} temp photos uploaded');
      return results;
    } catch (e) {
      _logger.e('❌ Failed to upload temp photos: $e');
      rethrow;
    }
  }

  /// Mark photo for deletion (will be deleted when saving profile)
  void markPhotoForDeletion(String mediaId) {
    if (!_photosToDelete.contains(mediaId)) {
      _photosToDelete.add(mediaId);
      _logger.i('🗑️ Marked photo for deletion: $mediaId');
    }
  }

  /// Unmark photo for deletion (user changed their mind)
  void unmarkPhotoForDeletion(String mediaId) {
    _photosToDelete.remove(mediaId);
    _logger.i('↩️ Unmarked photo for deletion: $mediaId');
  }

  /// Get list of photos marked for deletion
  List<String> getPhotosToDelete() {
    return List.unmodifiable(_photosToDelete);
  }

  /// Clear deletion list (after save or cancel)
  void clearDeletionList() {
    _photosToDelete.clear();
    _logger.i('🧹 Cleared deletion list');
  }

  /// Confirm temporary photos (move to permanent storage)
  /// Call this when user saves profile
  Future<ConfirmUploadResult> confirmPhotos(List<String> tempPhotoIds) async {
    if (tempPhotoIds.isEmpty) {
      _logger.i('ℹ️ No temp photos to confirm');
      return ConfirmUploadResult(confirmed: [], failed: []);
    }

    try {
      _logger.i('✅ Confirming ${tempPhotoIds.length} temp photos');
      
      final result = await _uploadService.confirmUploads(tempPhotoIds);

      if (result.hasFailures) {
        _logger.w('⚠️ Some photos failed to confirm: ${result.failed}');
      } else {
        _logger.i('✅ All photos confirmed successfully');
      }

      return result;
    } catch (e) {
      _logger.e('❌ Failed to confirm photos: $e');
      rethrow;
    }
  }

  /// Delete photos marked for deletion
  /// Call this when user saves profile (after confirming temp photos)
  Future<DeleteMediaResult> deleteMarkedPhotos() async {
    if (_photosToDelete.isEmpty) {
      _logger.i('ℹ️ No photos to delete');
      return DeleteMediaResult(deleted: [], failed: []);
    }

    try {
      _logger.i('🗑️ Deleting ${_photosToDelete.length} marked photos');
      
      final result = await _uploadService.deleteMedia(_photosToDelete);

      if (result.hasFailures) {
        _logger.w('⚠️ Some photos failed to delete: ${result.failed}');
      } else {
        _logger.i('✅ All marked photos deleted successfully');
      }

      // Clear deletion list after attempting to delete
      clearDeletionList();

      return result;
    } catch (e) {
      _logger.e('❌ Failed to delete photos: $e');
      rethrow;
    }
  }

  /// Delete single photo immediately (for one-off deletions)
  Future<bool> deletePhotoImmediately(String mediaId) async {
    try {
      _logger.i('🗑️ Deleting photo immediately: $mediaId');
      
      final success = await _uploadService.deleteSingleMedia(mediaId);

      if (success) {
        _logger.i('✅ Photo deleted successfully');
        // Also remove from deletion list if it was marked
        _photosToDelete.remove(mediaId);
      } else {
        _logger.w('⚠️ Photo deletion failed');
      }

      return success;
    } catch (e) {
      _logger.e('❌ Failed to delete photo: $e');
      return false;
    }
  }

  /// Save photos (confirm temp uploads + delete marked photos)
  /// Call this when user saves profile
  Future<PhotoSaveResult> savePhotos({
    required List<String> tempPhotoIds,
  }) async {
    _logger.i('💾 Saving photos...');

    try {
      // Confirm temp uploads
      final confirmResult = await confirmPhotos(tempPhotoIds);

      // Delete marked photos
      final deleteResult = await deleteMarkedPhotos();

      _logger.i('✅ Photos saved successfully');
      
      return PhotoSaveResult(
        confirmResult: confirmResult,
        deleteResult: deleteResult,
      );
    } catch (e) {
      _logger.e('❌ Failed to save photos: $e');
      rethrow;
    }
  }

  /// Cancel photo changes (clear temp and deletion lists)
  /// Temp files will auto-cleanup after 24 hours
  void cancelPhotoChanges() {
    clearDeletionList();
    _logger.i('↩️ Photo changes cancelled');
  }
}

/// Result of photo save operation
class PhotoSaveResult {
  final ConfirmUploadResult confirmResult;
  final DeleteMediaResult deleteResult;

  PhotoSaveResult({
    required this.confirmResult,
    required this.deleteResult,
  });

  /// Check if all operations succeeded
  bool get allSucceeded =>
      confirmResult.allConfirmed && deleteResult.allDeleted;

  /// Check if any operations failed
  bool get hasFailures => confirmResult.hasFailures || deleteResult.hasFailures;

  /// Get all failed operations
  List<String> get allFailures => [
        ...confirmResult.failed,
        ...deleteResult.failed,
      ];

  /// Get summary message
  String getSummaryMessage() {
    if (allSucceeded) {
      return 'All photos saved successfully';
    } else if (hasFailures) {
      return '${allFailures.length} photos failed to save';
    } else {
      return 'Photos saved';
    }
  }
}
