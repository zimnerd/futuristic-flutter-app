import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

import '../../theme/pulse_colors.dart';

class PhotoGrid extends StatelessWidget {
  final List<String> photos;
  final Function(List<String>) onPhotosChanged;
  final int maxPhotos;

  const PhotoGrid({
    super.key,
    required this.photos,
    required this.onPhotosChanged,
    this.maxPhotos = 6,
  });

  Future<void> _pickImage(BuildContext context) async {
    if (photos.length >= maxPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum $maxPhotos photos allowed'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final ImagePicker picker = ImagePicker();
    
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                await _requestCameraPermissionAndPick(context, picker);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                await _requestGalleryPermissionAndPick(context, picker);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestCameraPermissionAndPick(
    BuildContext context,
    ImagePicker picker,
  ) async {
    final cameraPermission = await Permission.camera.request();

    if (cameraPermission.isGranted) {
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 80,
      );
      if (image != null) {
        _addPhoto(image.path);
      }
    } else if (cameraPermission.isDenied) {
      _showPermissionDeniedDialog(context);
    } else if (cameraPermission.isPermanentlyDenied) {
      _showPermissionPermanentlyDeniedDialog(context);
    }
  }

  Future<void> _requestGalleryPermissionAndPick(
    BuildContext context,
    ImagePicker picker,
  ) async {
    Permission galleryPermission;

    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        galleryPermission = Permission.photos;
      } else {
        galleryPermission = Permission.storage;
      }
    } else {
      galleryPermission = Permission.photos;
    }

    final permission = await galleryPermission.request();

    if (permission.isGranted) {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 80,
      );
      if (image != null) {
        _addPhoto(image.path);
      }
    } else if (permission.isDenied) {
      _showPermissionDeniedDialog(context);
    } else if (permission.isPermanentlyDenied) {
      _showPermissionPermanentlyDeniedDialog(context);
    }
  }

  void _showPermissionDeniedDialog(BuildContext context) {
    // Show a simple snackbar for permission denied
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Permission denied. Please grant camera/photos access to upload photos.',
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showPermissionPermanentlyDeniedDialog(BuildContext context) {
    // Show dialog with option to open app settings
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'To upload photos, please grant camera and photo library access in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _addPhoto(String photoPath) {
    final updatedPhotos = List<String>.from(photos)..add(photoPath);
    onPhotosChanged(updatedPhotos);
  }

  void _removePhoto(int index) {
    final updatedPhotos = List<String>.from(photos)..removeAt(index);
    onPhotosChanged(updatedPhotos);
  }

  void _reorderPhotos(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final updatedPhotos = List<String>.from(photos);
    final item = updatedPhotos.removeAt(oldIndex);
    updatedPhotos.insert(newIndex, item);
    onPhotosChanged(updatedPhotos);
  }

  @override
  Widget build(BuildContext context) {
    return ReorderableGridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      onReorder: _reorderPhotos,
      children: [
        ...photos.asMap().entries.map((entry) {
          final index = entry.key;
          final photo = entry.value;
          return _buildPhotoItem(context, photo, index);
        }),
        if (photos.length < maxPhotos)
          _buildAddPhotoItem(context),
      ],
    );
  }

  Widget _buildPhotoItem(BuildContext context, String photo, int index) {
    return Container(
      key: ValueKey(photo),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: index == 0 
            ? Border.all(color: PulseColors.primary, width: 2)
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: _buildImage(photo),
            ),
            if (index == 0)
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: PulseColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'MAIN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _removePhoto(index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String photo) {
    if (photo.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: photo,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[200],
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[200],
          child: const Icon(Icons.error),
        ),
      );
    } else {
      return Image.file(
        File(photo),
        fit: BoxFit.cover,
      );
    }
  }

  Widget _buildAddPhotoItem(BuildContext context) {
    return Container(
      key: const ValueKey('add_photo'),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
      ),
      child: InkWell(
        onTap: () => _pickImage(context),
        borderRadius: BorderRadius.circular(12),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_a_photo,
              color: Colors.grey,
              size: 32,
            ),
            SizedBox(height: 4),
            Text(
              'Add Photo',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Simple ReorderableGridView implementation
class ReorderableGridView extends StatefulWidget {
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final Function(int, int) onReorder;
  final List<Widget> children;

  const ReorderableGridView.count({
    super.key,
    required this.crossAxisCount,
    required this.onReorder,
    required this.children,
    this.mainAxisSpacing = 0,
    this.crossAxisSpacing = 0,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  State<ReorderableGridView> createState() => _ReorderableGridViewState();
}

class _ReorderableGridViewState extends State<ReorderableGridView> {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: widget.crossAxisCount,
      mainAxisSpacing: widget.mainAxisSpacing,
      crossAxisSpacing: widget.crossAxisSpacing,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      children: widget.children,
    );
  }
}
