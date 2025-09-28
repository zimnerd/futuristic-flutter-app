import 'dart:io';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

/// Progress callback for upload operations
typedef ProgressCallback = void Function(int sent, int total, double percentage);

/// Upload task for queue management
class UploadTask {
  final String id;
  final String filePath;
  final MediaCategory category;
  final MediaType type;
  final Map<String, dynamic> metadata;
  final ProgressCallback? onProgress;
  final Completer<MediaUploadResult> completer;
  
  UploadTask({
    required this.id,
    required this.filePath,
    required this.category,
    required this.type,
    required this.metadata,
    this.onProgress,
    required this.completer,
  });
}

/// Central media upload service for all app components
/// Supports images, videos, documents for profiles, chat, events, stories, etc.
class MediaUploadService {
  final Dio _httpClient;
  final Box<String> _secureStorage;
  final ImagePicker _picker = ImagePicker();
  
  // Upload queue management
  final List<UploadTask> _uploadQueue = [];
  final Map<String, CancelToken> _activeCancelTokens = {};
  final StreamController<List<UploadTask>> _queueController = StreamController.broadcast();
  
  /// Stream of current upload queue
  Stream<List<UploadTask>> get uploadQueueStream => _queueController.stream;

  MediaUploadService({
    required Dio httpClient,
    required Box<String> secureStorage,
  })  : _httpClient = httpClient,
        _secureStorage = secureStorage;

  // ===========================================
  // MEDIA PICKING METHODS
  // ===========================================

  /// Pick single image from camera
  Future<XFile?> pickImageFromCamera({
    int maxWidth = 1920,
    int maxHeight = 1920,
    int imageQuality = 85,
  }) async {
    try {
      return await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: imageQuality,
      );
    } catch (e) {
      throw MediaUploadException('Failed to capture image from camera: $e');
    }
  }

  /// Pick single image from gallery
  Future<XFile?> pickImageFromGallery({
    int maxWidth = 1920,
    int maxHeight = 1920,
    int imageQuality = 85,
  }) async {
    try {
      return await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: imageQuality,
      );
    } catch (e) {
      throw MediaUploadException('Failed to pick image from gallery: $e');
    }
  }

  /// Pick multiple images from gallery
  Future<List<XFile>> pickMultipleImagesFromGallery({
    int maxImages = 6,
    int maxWidth = 1920,
    int maxHeight = 1920,
    int imageQuality = 85,
  }) async {
    try {
      final images = await _picker.pickMultiImage(
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: imageQuality,
      );
      
      if (images.length > maxImages) {
        return images.take(maxImages).toList();
      }
      
      return images;
    } catch (e) {
      throw MediaUploadException('Failed to pick multiple images: $e');
    }
  }

  /// Pick video from camera
  Future<XFile?> pickVideoFromCamera({
    Duration maxDuration = const Duration(minutes: 5),
  }) async {
    try {
      return await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: maxDuration,
      );
    } catch (e) {
      throw MediaUploadException('Failed to capture video from camera: $e');
    }
  }

  /// Pick video from gallery
  Future<XFile?> pickVideoFromGallery({
    Duration maxDuration = const Duration(minutes: 5),
  }) async {
    try {
      return await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: maxDuration,
      );
    } catch (e) {
      throw MediaUploadException('Failed to pick video from gallery: $e');
    }
  }

  // ===========================================
  // MEDIA UPLOAD METHODS
  // ===========================================

  /// Upload media with advanced progress tracking and queue management
  Future<MediaUploadResult> uploadMediaWithProgress({
    required String filePath,
    required MediaCategory category,
    required MediaType type,
    ProgressCallback? onProgress,
    String? title,
    String? description,
    List<String>? tags,
    bool isPublic = false,
    bool requiresModeration = true,
    MediaProcessingOptions? processingOptions,
  }) async {
    final taskId = DateTime.now().millisecondsSinceEpoch.toString();
    final cancelToken = CancelToken();
    final completer = Completer<MediaUploadResult>();
    
    final task = UploadTask(
      id: taskId,
      filePath: filePath,
      category: category,
      type: type,
      onProgress: onProgress,
      completer: completer,
      metadata: {
        'title': title,
        'description': description,
        'tags': tags,
        'isPublic': isPublic,
        'requiresModeration': requiresModeration,
        'processingOptions': processingOptions,
      },
    );
    
    // Add to queue and notify listeners
    _uploadQueue.add(task);
    _activeCancelTokens[taskId] = cancelToken;
    _queueController.add(List.from(_uploadQueue));
    
    try {
      final result = await _performUpload(task, cancelToken);
      completer.complete(result);
      return result;
    } catch (e) {
      completer.completeError(e);
      rethrow;
    } finally {
      // Clean up
      _uploadQueue.removeWhere((t) => t.id == taskId);
      _activeCancelTokens.remove(taskId);
      _queueController.add(List.from(_uploadQueue));
    }
  }

  /// Internal method to perform the actual upload
  Future<MediaUploadResult> _performUpload(UploadTask task, CancelToken cancelToken) async {
    final token = _secureStorage.get('access_token');
    if (token == null) {
      throw MediaUploadException('No authentication token available');
    }

    // Validate file before upload
    final validation = await validateMediaFile(task.filePath, task.type);
    if (!validation.isValid) {
      throw MediaUploadException(validation.error ?? 'File validation failed');
    }

    // Prepare multipart form data
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        task.filePath,
        filename: path.basename(task.filePath),
      ),
      'type': task.type.value,
      'category': task.category.value,
      'isPublic': task.metadata['isPublic'].toString(),
      'requiresModeration': task.metadata['requiresModeration'].toString(),
      if (task.metadata['title'] != null) 'title': task.metadata['title'],
      if (task.metadata['description'] != null) 'description': task.metadata['description'],
      if (task.metadata['tags'] != null) 'tags': task.metadata['tags'],
      if (task.metadata['processingOptions'] != null) 
        'processingOptions': task.metadata['processingOptions'].toJson(),
    });

    // Upload with progress tracking
    final response = await _httpClient.post(
      '/media/upload',
      data: formData,
      cancelToken: cancelToken,
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'multipart/form-data',
        },
      ),
      onSendProgress: (int sent, int total) {
        final percentage = (sent / total) * 100;
        task.onProgress?.call(sent, total, percentage);
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return MediaUploadResult.fromJson(response.data);
    } else {
      throw MediaUploadException(
        'Upload failed with status ${response.statusCode}: ${response.data}',
      );
    }
  }

  /// Cancel upload by task ID
  Future<void> cancelUpload(String taskId) async {
    final cancelToken = _activeCancelTokens[taskId];
    if (cancelToken != null && !cancelToken.isCancelled) {
      cancelToken.cancel('Upload cancelled by user');
    }
  }

  /// Cancel all active uploads
  Future<void> cancelAllUploads() async {
    for (final cancelToken in _activeCancelTokens.values) {
      if (!cancelToken.isCancelled) {
        cancelToken.cancel('All uploads cancelled');
      }
    }
    _activeCancelTokens.clear();
    _uploadQueue.clear();
    _queueController.add([]);
  }

  /// Upload media file to backend with specified category (legacy method)
  Future<MediaUploadResult> uploadMedia({
    required String filePath,
    required MediaCategory category,
    required MediaType type,
    String? title,
    String? description,
    List<String>? tags,
    bool isPublic = false,
    bool requiresModeration = true,
    MediaProcessingOptions? processingOptions,
  }) async {
    try {
      final token = _secureStorage.get('access_token');
      if (token == null) {
        throw MediaUploadException('No authentication token available');
      }

      // Validate file before upload
      final validation = await validateMediaFile(filePath, type);
      if (!validation.isValid) {
        throw MediaUploadException(validation.error ?? 'File validation failed');
      }

      // Prepare multipart form data
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: path.basename(filePath),
        ),
        'type': type.value,
        'category': category.value,
        'isPublic': isPublic.toString(),
        'requiresModeration': requiresModeration.toString(),
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (tags != null) 'tags': tags,
        if (processingOptions != null) 
          'processingOptions': processingOptions.toJson(),
      });

      // Upload to unified media endpoint
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
        return _parseUploadResponse(response.data);
      } else {
        throw MediaUploadException(
          'Upload failed with status ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is MediaUploadException) rethrow;
      throw MediaUploadException('Failed to upload media: $e');
    }
  }

  // ===========================================
  // CONVENIENCE METHODS FOR SPECIFIC USE CASES
  // ===========================================

  /// Upload profile photo with progress tracking
  Future<MediaUploadResult> uploadProfilePhoto(
    String imagePath, {
    ProgressCallback? onProgress,
  }) async {
    return uploadMediaWithProgress(
      filePath: imagePath,
      category: MediaCategory.profilePhoto,
      type: MediaType.image,
      isPublic: false,
      requiresModeration: true,
      onProgress: onProgress,
    );
  }

  /// Upload chat image with progress tracking
  Future<MediaUploadResult> uploadChatImage(
    String imagePath, {
    ProgressCallback? onProgress,
  }) async {
    return uploadMediaWithProgress(
      filePath: imagePath,
      category: MediaCategory.chatMessage,
      type: MediaType.image,
      isPublic: false,
      requiresModeration: false,
      onProgress: onProgress,
    );
  }

  /// Upload chat video with progress tracking
  Future<MediaUploadResult> uploadChatVideo(
    String videoPath, {
    ProgressCallback? onProgress,
  }) async {
    return uploadMediaWithProgress(
      filePath: videoPath,
      category: MediaCategory.chatMessage,
      type: MediaType.video,
      isPublic: false,
      requiresModeration: false,
      onProgress: onProgress,
    );
  }

  /// Upload event photo
  Future<MediaUploadResult> uploadEventPhoto(
    String imagePath, {
    String? title,
    String? description,
  }) async {
    return uploadMedia(
      filePath: imagePath,
      category: MediaCategory.eventPhoto,
      type: MediaType.image,
      title: title,
      description: description,
      isPublic: true,
      requiresModeration: true,
    );
  }

  /// Upload story media
  Future<MediaUploadResult> uploadStoryMedia(
    String filePath,
    MediaType type,
  ) async {
    return uploadMedia(
      filePath: filePath,
      category: MediaCategory.story,
      type: type,
      isPublic: true,
      requiresModeration: true,
    );
  }

  // ===========================================
  // VALIDATION AND UTILITY METHODS
  // ===========================================

  /// Validate media file before upload
  Future<MediaValidationResult> validateMediaFile(
    String filePath,
    MediaType type,
  ) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return MediaValidationResult(
          isValid: false,
          error: 'File not found',
        );
      }

      // Check file size based on type
      final size = await file.length();
      final maxSize = _getMaxSizeForType(type);
      
      if (size > maxSize) {
        final maxSizeMB = (maxSize / (1024 * 1024)).toStringAsFixed(1);
        return MediaValidationResult(
          isValid: false,
          error: 'File size must be less than ${maxSizeMB}MB',
        );
      }

      // Check file extension
      final extension = path.extension(filePath).toLowerCase();
      final allowedExtensions = _getAllowedExtensionsForType(type);
      
      if (!allowedExtensions.contains(extension)) {
        return MediaValidationResult(
          isValid: false,
          error: 'File type not supported. Allowed: ${allowedExtensions.join(", ")}',
        );
      }

      return MediaValidationResult(isValid: true);
    } catch (e) {
      return MediaValidationResult(
        isValid: false,
        error: 'Failed to validate file: $e',
      );
    }
  }

  /// Get maximum file size for media type
  int _getMaxSizeForType(MediaType type) {
    switch (type) {
      case MediaType.image:
        return 10 * 1024 * 1024; // 10MB for images
      case MediaType.video:
        return 100 * 1024 * 1024; // 100MB for videos
      case MediaType.audio:
        return 25 * 1024 * 1024; // 25MB for audio
      case MediaType.document:
        return 50 * 1024 * 1024; // 50MB for documents
    }
  }

  /// Get allowed file extensions for media type
  List<String> _getAllowedExtensionsForType(MediaType type) {
    switch (type) {
      case MediaType.image:
        return ['.jpg', '.jpeg', '.png', '.webp', '.gif'];
      case MediaType.video:
        return ['.mp4', '.mov', '.avi', '.webm', '.mkv'];
      case MediaType.audio:
        return ['.mp3', '.wav', '.aac', '.ogg', '.m4a'];
      case MediaType.document:
        return ['.pdf', '.doc', '.docx', '.txt', '.rtf'];
    }
  }

  /// Parse upload response from server
  MediaUploadResult _parseUploadResponse(dynamic responseData) {
    try {
      if (responseData is Map<String, dynamic>) {
        return MediaUploadResult(
          success: true,
          mediaId: responseData['id']?.toString() ?? 
                   'media_${DateTime.now().millisecondsSinceEpoch}',
          mediaUrl: responseData['url']?.toString() ?? 
                    responseData['originalUrl']?.toString(),
          thumbnailUrl: responseData['thumbnailUrl']?.toString(),
          mediaType: responseData['type']?.toString() ?? 'unknown',
          category: responseData['category']?.toString(),
          fileSize: responseData['fileSize'],
          mimeType: responseData['mimeType']?.toString(),
          metadata: responseData['metadata'] as Map<String, dynamic>?,
        );
      }
      
      throw MediaUploadException('Invalid response format');
    } catch (e) {
      throw MediaUploadException('Failed to parse upload response: $e');
    }
  }
}

// ===========================================
// ENUMS AND MODELS
// ===========================================

/// Media type enumeration (matches backend)
enum MediaType {
  image('image'),
  video('video'),
  audio('audio'),
  document('document');

  const MediaType(this.value);
  final String value;
}

/// Media category enumeration (matches backend)
enum MediaCategory {
  profilePhoto('profile_photo'),
  verificationPhoto('verification_photo'),
  chatMessage('chat_message'),
  arAsset('ar_asset'),
  eventPhoto('event_photo'),
  story('story');

  const MediaCategory(this.value);
  final String value;
}

/// Processing options for media
class MediaProcessingOptions {
  final ResizeOptions? resize;
  final WatermarkOptions? watermark;
  final BlurOptions? blur;
  final CompressOptions? compress;

  MediaProcessingOptions({
    this.resize,
    this.watermark,
    this.blur,
    this.compress,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (resize != null) json['resize'] = resize!.toJson();
    if (watermark != null) json['watermark'] = watermark!.toJson();
    if (blur != null) json['blur'] = blur!.toJson();
    if (compress != null) json['compress'] = compress!.toJson();
    return json;
  }
}

class ResizeOptions {
  final int width;
  final int height;
  final int quality;

  ResizeOptions({
    required this.width,
    required this.height,
    this.quality = 85,
  });

  Map<String, dynamic> toJson() => {
    'width': width,
    'height': height,
    'quality': quality,
  };
}

class WatermarkOptions {
  final String text;
  final String position;
  final double opacity;

  WatermarkOptions({
    required this.text,
    required this.position,
    this.opacity = 0.5,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'position': position,
    'opacity': opacity,
  };
}

class BlurOptions {
  final int radius;

  BlurOptions({required this.radius});

  Map<String, dynamic> toJson() => {'radius': radius};
}

class CompressOptions {
  final int quality;

  CompressOptions({required this.quality});

  Map<String, dynamic> toJson() => {'quality': quality};
}

/// Result of media upload operation
class MediaUploadResult {
  final bool success;
  final String? mediaId;
  final String? mediaUrl;
  final String? thumbnailUrl;
  final String? mediaType;
  final String? category;
  final int? fileSize;
  final String? mimeType;
  final Map<String, dynamic>? metadata;
  final String? error;

  MediaUploadResult({
    required this.success,
    this.mediaId,
    this.mediaUrl,
    this.thumbnailUrl,
    this.mediaType,
    this.category,
    this.fileSize,
    this.mimeType,
    this.metadata,
    this.error,
  });

  factory MediaUploadResult.fromJson(Map<String, dynamic> json) {
    return MediaUploadResult(
      success: json['success'] ?? false,
      mediaId: json['mediaId'],
      mediaUrl: json['mediaUrl'],
      thumbnailUrl: json['thumbnailUrl'],
      mediaType: json['mediaType'],
      category: json['category'],
      fileSize: json['fileSize'],
      mimeType: json['mimeType'],
      metadata: json['metadata'],
      error: json['error'],
    );
  }

  @override
  String toString() {
    return 'MediaUploadResult{success: $success, mediaId: $mediaId, mediaUrl: $mediaUrl}';
  }
}

/// Result of media validation
class MediaValidationResult {
  final bool isValid;
  final String? error;

  MediaValidationResult({
    required this.isValid,
    this.error,
  });
}

/// Exception thrown during media operations
class MediaUploadException implements Exception {
  final String message;

  MediaUploadException(this.message);

  @override
  String toString() => 'MediaUploadException: $message';
}