import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/utils/logger.dart';

/// Global service for handling camera and gallery image picking
/// Used across the app for profile photos, chat images, etc.
class ImagePickerService {
  static final ImagePickerService _instance = ImagePickerService._internal();
  factory ImagePickerService() => _instance;
  ImagePickerService._internal();

  final ImagePicker _picker = ImagePicker();

  /// Pick image from camera
  /// Returns null if user cancels or permission denied
  Future<File?> pickFromCamera({
    int imageQuality = 85,
    double? maxWidth,
    double? maxHeight,
  }) async {
    try {
      // Check camera permission
      final cameraPermission = await Permission.camera.status;
      if (cameraPermission.isDenied) {
        final result = await Permission.camera.request();
        if (!result.isGranted) {
          AppLogger.warning('Camera permission denied');
          return null;
        }
      }

      // Pick image from camera
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (image != null) {
        AppLogger.debug('Image picked from camera: ${image.path}');
        return File(image.path);
      }

      return null;
    } catch (e) {
      AppLogger.error('Error picking image from camera: $e');
      return null;
    }
  }

  /// Pick image from gallery
  /// Returns null if user cancels or permission denied
  Future<File?> pickFromGallery({
    int imageQuality = 85,
    double? maxWidth,
    double? maxHeight,
  }) async {
    try {
      // Check photo permission (iOS) or storage permission (Android)
      PermissionStatus permission;
      if (Platform.isIOS) {
        permission = await Permission.photos.status;
        if (permission.isDenied) {
          permission = await Permission.photos.request();
        }
      } else {
        permission = await Permission.storage.status;
        if (permission.isDenied) {
          permission = await Permission.storage.request();
        }
      }

      if (!permission.isGranted) {
        AppLogger.warning('Gallery permission denied');
        return null;
      }

      // Pick image from gallery
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );

      if (image != null) {
        AppLogger.debug('Image picked from gallery: ${image.path}');
        return File(image.path);
      }

      return null;
    } catch (e) {
      AppLogger.error('Error picking image from gallery: $e');
      return null;
    }
  }

  /// Pick multiple images from gallery
  /// Returns empty list if user cancels or permission denied
  Future<List<File>> pickMultipleFromGallery({
    int imageQuality = 85,
    double? maxWidth,
    double? maxHeight,
    int? limit,
  }) async {
    try {
      // Check photo permission (iOS) or storage permission (Android)
      PermissionStatus permission;
      if (Platform.isIOS) {
        permission = await Permission.photos.status;
        if (permission.isDenied) {
          permission = await Permission.photos.request();
        }
      } else {
        permission = await Permission.storage.status;
        if (permission.isDenied) {
          permission = await Permission.storage.request();
        }
      }

      if (!permission.isGranted) {
        AppLogger.warning('Gallery permission denied');
        return [];
      }

      // Pick multiple images from gallery
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        limit: limit,
      );

      final List<File> files = images.map((image) => File(image.path)).toList();
      
      AppLogger.debug('${files.length} images picked from gallery');
      return files;
    } catch (e) {
      AppLogger.error('Error picking multiple images from gallery: $e');
      return [];
    }
  }

  /// Show bottom sheet to choose between camera and gallery
  /// Returns null if user cancels
  Future<File?> showImageSourceBottomSheet(
    BuildContext context, {
    int imageQuality = 85,
    double? maxWidth,
    double? maxHeight,
    bool allowMultiple = false,
  }) async {
    return showModalBottomSheet<File?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Select Image Source',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildSourceOption(
                    context: context,
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    color: Colors.blue,
                    onTap: () async {
                      Navigator.pop(context);
                      final file = await pickFromCamera(
                        imageQuality: imageQuality,
                        maxWidth: maxWidth,
                        maxHeight: maxHeight,
                      );
                      if (file != null && context.mounted) {
                        Navigator.pop(context, file);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSourceOption(
                    context: context,
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    color: Colors.green,
                    onTap: () async {
                      Navigator.pop(context);
                      final file = await pickFromGallery(
                        imageQuality: imageQuality,
                        maxWidth: maxWidth,
                        maxHeight: maxHeight,
                      );
                      if (file != null && context.mounted) {
                        Navigator.pop(context, file);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}