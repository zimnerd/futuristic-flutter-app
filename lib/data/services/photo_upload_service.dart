import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/photo_upload_progress.dart';
import '../../core/utils/logger.dart';

/// Service for tracking photo upload progress
class PhotoUploadService {
  static final PhotoUploadService _instance = PhotoUploadService._internal();
  factory PhotoUploadService() => _instance;
  PhotoUploadService._internal();

  final Map<String, StreamController<PhotoUploadProgress>> _uploadControllers =
      {};
  final Map<String, StreamController<BatchUploadProgress>> _batchControllers =
      {};
  final Map<String, PhotoUploadProgress> _uploadProgress = {};

  /// Watch progress for a single upload
  Stream<PhotoUploadProgress> watchUploadProgress(String uploadId) {
    if (!_uploadControllers.containsKey(uploadId)) {
      _uploadControllers[uploadId] =
          StreamController<PhotoUploadProgress>.broadcast();
    }
    return _uploadControllers[uploadId]!.stream;
  }

  /// Watch progress for a batch upload
  Stream<BatchUploadProgress> watchBatchProgress(String batchId) {
    if (!_batchControllers.containsKey(batchId)) {
      _batchControllers[batchId] =
          StreamController<BatchUploadProgress>.broadcast();
    }
    return _batchControllers[batchId]!.stream;
  }

  /// Get current progress for an upload
  PhotoUploadProgress? getUploadProgress(String uploadId) {
    return _uploadProgress[uploadId];
  }

  /// Update progress for an upload
  void updateProgress(PhotoUploadProgress progress) {
    _uploadProgress[progress.uploadId] = progress;

    if (_uploadControllers.containsKey(progress.uploadId)) {
      _uploadControllers[progress.uploadId]!.add(progress);
    }

    AppLogger.debug('Upload progress updated: $progress');
  }

  /// Update batch progress
  void updateBatchProgress(BatchUploadProgress batchProgress) {
    if (_batchControllers.containsKey(batchProgress.batchId)) {
      _batchControllers[batchProgress.batchId]!.add(batchProgress);
    }

    AppLogger.debug('Batch progress updated: $batchProgress');
  }

  /// Upload a file with progress tracking
  Future<String> uploadWithProgress({
    required String uploadId,
    required String photoPath,
    required String uploadUrl,
    required Map<String, String> headers,
    required String fieldName,
  }) async {
    try {
      // Initialize progress
      updateProgress(
        PhotoUploadProgress(
          uploadId: uploadId,
          photoPath: photoPath,
          progress: 0.0,
          status: UploadStatus.pending,
        ),
      );

      final file = File(photoPath);
      final fileBytes = await file.readAsBytes();

      // Create multipart request
      final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
      request.headers.addAll(headers);

      final multipartFile = http.MultipartFile.fromBytes(
        fieldName,
        fileBytes,
        filename: file.path.split('/').last,
      );
      request.files.add(multipartFile);

      // Update to uploading status
      updateProgress(
        PhotoUploadProgress(
          uploadId: uploadId,
          photoPath: photoPath,
          progress: 0.1,
          status: UploadStatus.uploading,
        ),
      );

      // Send request with progress simulation
      // Note: http package doesn't support native progress, but we can estimate
      final streamedResponse = await request.send();

      // Simulate progress updates while waiting for response
      updateProgress(
        PhotoUploadProgress(
          uploadId: uploadId,
          photoPath: photoPath,
          progress: 0.5,
          status: UploadStatus.uploading,
        ),
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Extract URL from response (adjust based on your API)
        final responseData = response.body;

        updateProgress(
          PhotoUploadProgress(
            uploadId: uploadId,
            photoPath: photoPath,
            progress: 1.0,
            status: UploadStatus.completed,
            url: responseData, // Adjust based on actual response format
          ),
        );

        return responseData;
      } else {
        throw Exception('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      updateProgress(
        PhotoUploadProgress(
          uploadId: uploadId,
          photoPath: photoPath,
          progress: 0.0,
          status: UploadStatus.failed,
          error: e.toString(),
        ),
      );
      rethrow;
    }
  }

  /// Clean up progress tracking for an upload
  void cleanupUpload(String uploadId) {
    _uploadProgress.remove(uploadId);
    _uploadControllers[uploadId]?.close();
    _uploadControllers.remove(uploadId);
  }

  /// Clean up batch progress tracking
  void cleanupBatch(String batchId) {
    _batchControllers[batchId]?.close();
    _batchControllers.remove(batchId);
  }

  /// Dispose all resources
  void dispose() {
    for (final controller in _uploadControllers.values) {
      controller.close();
    }
    for (final controller in _batchControllers.values) {
      controller.close();
    }
    _uploadControllers.clear();
    _batchControllers.clear();
    _uploadProgress.clear();
  }
}
