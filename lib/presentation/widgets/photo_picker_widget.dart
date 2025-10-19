import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

/// Widget for picking and managing profile photos
class PhotoPickerWidget extends StatefulWidget {
  final List<File> selectedPhotos;
  final Function(List<File>) onPhotosChanged;
  final int maxPhotos;

  const PhotoPickerWidget({
    super.key,
    required this.selectedPhotos,
    required this.onPhotosChanged,
    this.maxPhotos = 6,
  });

  @override
  State<PhotoPickerWidget> createState() => _PhotoPickerWidgetState();
}

class _PhotoPickerWidgetState extends State<PhotoPickerWidget> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      // Check permissions
      if (source == ImageSource.camera) {
        final cameraStatus = await Permission.camera.request();
        if (cameraStatus.isDenied) {
          _showPermissionDialog('Camera');
          return;
        }
      } else {
        final photosStatus = await Permission.photos.request();
        if (photosStatus.isDenied) {
          _showPermissionDialog('Photos');
          return;
        }
      }

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 80,
      );

      if (image != null) {
        final File file = File(image.path);
        final List<File> updatedPhotos = List.from(widget.selectedPhotos)
          ..add(file);
        widget.onPhotosChanged(updatedPhotos);
      }
    } catch (e) {
      _showErrorDialog('Failed to pick image: $e');
    }
  }

  void _removePhoto(int index) {
    final List<File> updatedPhotos = List.from(widget.selectedPhotos)
      ..removeAt(index);
    widget.onPhotosChanged(updatedPhotos);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Photo grid
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: widget.maxPhotos,
            itemBuilder: (context, index) {
              if (index < widget.selectedPhotos.length) {
                return _buildPhotoCard(widget.selectedPhotos[index], index);
              } else if (index == widget.selectedPhotos.length) {
                return _buildAddPhotoCard();
              } else {
                return _buildEmptyPhotoCard();
              }
            },
          ),
        ),
        const SizedBox(height: 16),
        // Instructions
        Text(
          'Tap + to add photos. Long press to reorder.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPhotoCard(File photo, int index) {
    return GestureDetector(
      onLongPress: () => _showPhotoOptions(index),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image.file(
                photo,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            if (index == 0)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Primary',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _removePhoto(index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddPhotoCard() {
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[300]!,
            style: BorderStyle.solid,
          ),
          color: Colors.grey[50],
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 32,
              color: Colors.grey,
            ),
            SizedBox(height: 4),
            Text(
              'Add Photo',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPhotoCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, style: BorderStyle.solid),
        color: Colors.grey[50],
      ),
      child: const Icon(Icons.image_outlined, color: Colors.grey, size: 24),
    );
  }

  void _showImageSourceDialog() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor:
          theme.bottomSheetTheme.backgroundColor ??
          (isDark ? const Color(0xFF1E1E1E) : Colors.white),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(
                Icons.camera_alt,
                color:
                    theme.iconTheme.color ??
                    (isDark ? Colors.white : Colors.black87),
              ),
              title: Text(
                'Camera',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color:
                      theme.textTheme.bodyLarge?.color ??
                      (isDark ? Colors.white : Colors.black87),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.photo_library,
                color:
                    theme.iconTheme.color ??
                    (isDark ? Colors.white : Colors.black87),
              ),
              title: Text(
                'Photo Library',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color:
                      theme.textTheme.bodyLarge?.color ??
                      (isDark ? Colors.white : Colors.black87),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Icon(Icons.cancel, color: theme.colorScheme.error),
              title: Text(
                'Cancel',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showPhotoOptions(int index) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor:
          theme.bottomSheetTheme.backgroundColor ??
          (isDark ? const Color(0xFF1E1E1E) : Colors.white),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            if (index > 0)
              ListTile(
                leading: Icon(Icons.star, color: theme.colorScheme.primary),
                title: Text(
                  'Make Primary',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color:
                        theme.textTheme.bodyLarge?.color ??
                        (isDark ? Colors.white : Colors.black87),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _makePrimary(index);
                },
              ),
            ListTile(
              leading: Icon(Icons.delete, color: theme.colorScheme.error),
              title: Text(
                'Remove Photo',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _removePhoto(index);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.cancel,
                color:
                    theme.iconTheme.color ??
                    (isDark ? Colors.white70 : Colors.black54),
              ),
              title: Text(
                'Cancel',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color:
                      theme.textTheme.bodyLarge?.color ??
                      (isDark ? Colors.white70 : Colors.black54),
                ),
              ),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _makePrimary(int index) {
    if (index > 0 && index < widget.selectedPhotos.length) {
      final List<File> updatedPhotos = List.from(widget.selectedPhotos);
      final File primaryPhoto = updatedPhotos.removeAt(index);
      updatedPhotos.insert(0, primaryPhoto);
      widget.onPhotosChanged(updatedPhotos);
    }
  }

  void _showPermissionDialog(String permissionType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$permissionType Permission Required'),
        content: Text(
          'Please grant $permissionType permission to add photos to your profile.',
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
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
