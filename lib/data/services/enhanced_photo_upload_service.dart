import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;

import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

/// Enhanced photo upload service with error handling and progress tracking
class PhotoUploadService {
  final ApiClient _apiClient;
  final ImagePicker _picker = ImagePicker();

  PhotoUploadService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Pick an image from gallery or camera
  Future<File?> pickImage({
    required ImageSource source,
    double maxWidth = 1080,
    double maxHeight = 1080,
    int imageQuality = 85,
  }) async {
    try {
      // Check and request permissions
      await _requestPermissions(source);

      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error picking image: $e');
      rethrow;
    }
  }

  /// Pick multiple images from gallery
  Future<List<File>> pickMultipleImages({
    int maxImages = 6,
    int imageQuality = 85,
  }) async {
    try {
      // Check gallery permissions
      await _requestPermissions(ImageSource.gallery);

      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: imageQuality,
      );

      if (pickedFiles.length > maxImages) {
        // Take only the first maxImages
        return pickedFiles
            .take(maxImages)
            .map((xFile) => File(xFile.path))
            .toList();
      }

      return pickedFiles.map((xFile) => File(xFile.path)).toList();
    } catch (e) {
      debugPrint('Error picking multiple images: $e');
      rethrow;
    }
  }

  /// Upload a single image file to the server
  Future<String> uploadImage(
    File imageFile, {
    Function(double)? onProgress,
    String? userId,
  }) async {
    try {
      if (!imageFile.existsSync()) {
        throw Exception('Image file does not exist');
      }

      // Validate file size (max 10MB)
      final fileSizeInBytes = await imageFile.length();
      const maxSizeInBytes = 10 * 1024 * 1024; // 10MB
      if (fileSizeInBytes > maxSizeInBytes) {
        throw Exception('Image size must be less than 10MB');
      }

      // Validate file extension
      final fileExtension = path.extension(imageFile.path).toLowerCase();
      const allowedExtensions = ['.jpg', '.jpeg', '.png', '.webp'];
      if (!allowedExtensions.contains(fileExtension)) {
        throw Exception('Only JPG, PNG, and WebP images are supported');
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}$fileExtension';
      
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
        if (userId != null) 'userId': userId,
      });

      final response = await _apiClient.post(
        ApiConstants.uploadImage,
        data: formData,
        onSendProgress: (sent, total) {
          if (onProgress != null && total > 0) {
            onProgress(sent / total);
          }
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data['imageUrl'] as String;
      } else {
        throw Exception('Failed to upload image: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error uploading image: $e');
      rethrow;
    }
  }

  /// Upload multiple images with progress tracking
  Future<List<String>> uploadMultipleImages(
    List<File> imageFiles, {
    Function(int completed, int total)? onProgress,
    String? userId,
  }) async {
    final List<String> uploadedUrls = [];
    
    for (int i = 0; i < imageFiles.length; i++) {
      try {
        final url = await uploadImage(
          imageFiles[i],
          userId: userId,
          onProgress: (progress) {
            // Individual file progress can be tracked here if needed
          },
        );
        uploadedUrls.add(url);
        onProgress?.call(i + 1, imageFiles.length);
      } catch (e) {
        debugPrint('Failed to upload image ${i + 1}: $e');
        // Continue with other uploads even if one fails
        continue;
      }
    }

    return uploadedUrls;
  }

  /// Delete an uploaded image
  Future<bool> deleteImage(String imageUrl) async {
    try {
      final response = await _apiClient.delete(
        '${ApiConstants.uploadImage}/$imageUrl',
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error deleting image: $e');
      return false;
    }
  }

  /// Request appropriate permissions based on image source
  Future<void> _requestPermissions(ImageSource source) async {
    if (source == ImageSource.camera) {
      final cameraStatus = await Permission.camera.request();
      if (cameraStatus.isDenied) {
        throw PhotoPickerException('Camera permission denied');
      }
    } else {
      // For gallery access
      Permission permission;
      if (Platform.isIOS) {
        permission = Permission.photos;
      } else {
        // Android 13+ uses different permissions
        permission = Permission.photos;
      }

      final status = await permission.request();
      if (status.isDenied) {
        throw PhotoPickerException('Gallery permission denied');
      }
    }
  }

  /// Show photo source selection dialog
  static Future<ImageSource?> showImageSourceDialog(BuildContext context) async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        'Select Photo Source',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ListTile(
                        leading: const Icon(Icons.camera_alt),
                        title: const Text('Camera'),
                        subtitle: const Text('Take a new photo'),
                        onTap: () => Navigator.of(context).pop(ImageSource.camera),
                      ),
                      ListTile(
                        leading: const Icon(Icons.photo_library),
                        title: const Text('Gallery'),
                        subtitle: const Text('Choose from existing photos'),
                        onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Custom exception for photo picker errors
class PhotoPickerException implements Exception {
  final String message;
  PhotoPickerException(this.message);

  @override
  String toString() => 'PhotoPickerException: $message';
}

/// Data class for photo upload result
class PhotoUploadResult {
  final String imageUrl;
  final String localPath;
  final DateTime uploadedAt;

  PhotoUploadResult({
    required this.imageUrl,
    required this.localPath,
    required this.uploadedAt,
  });
}