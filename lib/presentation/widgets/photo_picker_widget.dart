import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';

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

  Future<void> _pickImage(ImageSource source, {bool multiple = false}) async {
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

      List<XFile> images = [];

      if (multiple && source == ImageSource.gallery) {
        // Multi-select from gallery
        images = await _picker.pickMultiImage(
          maxWidth: 1080,
          maxHeight: 1080,
          imageQuality: 80,
        );
      } else {
        // Single image from camera or gallery
        final XFile? image = await _picker.pickImage(
          source: source,
          maxWidth: 1080,
          maxHeight: 1080,
          imageQuality: 80,
        );
        if (image != null) {
          images = [image];
        }
      }

      if (images.isNotEmpty) {
        final List<File> newFiles = images
            .map((img) => File(img.path))
            .toList();

        // Check if we would exceed max photos
        if (widget.selectedPhotos.length + newFiles.length > widget.maxPhotos) {
          _showErrorDialog(
            'Maximum ${widget.maxPhotos} photos allowed. You can add ${widget.maxPhotos - widget.selectedPhotos.length} more.',
          );
          // Add only as many as we can
          final canAdd = widget.maxPhotos - widget.selectedPhotos.length;
          final filesToAdd = newFiles.take(canAdd).toList();
          if (filesToAdd.isNotEmpty) {
            final List<File> updatedPhotos = List.from(widget.selectedPhotos)
              ..addAll(filesToAdd);
            widget.onPhotosChanged(updatedPhotos);
          }
        } else {
          final List<File> updatedPhotos = List.from(widget.selectedPhotos)
            ..addAll(newFiles);
          widget.onPhotosChanged(updatedPhotos);
        }
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
                return _buildPhotoCard(
                  context,
                  widget.selectedPhotos[index],
                  index,
                );
              } else if (index == widget.selectedPhotos.length) {
                return _buildAddPhotoCard(context);
              } else {
                return _buildEmptyPhotoCard(context);
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
          ).textTheme.bodySmall?.copyWith(color: context.onSurfaceVariantColor),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPhotoCard(BuildContext context, File photo, int index) {
    return GestureDetector(
      onLongPress: () => _showPhotoOptions(index),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.borderColor),
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
                    color: context.textOnPrimary,
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

  Widget _buildAddPhotoCard(BuildContext context) {
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: context.borderColor,
            style: BorderStyle.solid,
          ),
          color: context.surfaceColor,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 32,
              color: context.onSurfaceVariantColor,
            ),
            const SizedBox(height: 4),
            Text(
              'Add Photo',
              style: TextStyle(
                color: context.onSurfaceVariantColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPhotoCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.borderColor,
          style: BorderStyle.solid,
        ),
        color: context.surfaceColor,
      ),
      child: Icon(
        Icons.image_outlined,
        color: context.onSurfaceVariantColor,
        size: 24,
      ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(
                Icons.camera_alt,
                color: context.textPrimary,
              ),
              title: Text(
                'Camera',
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(modalContext);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: context.textPrimary),
              title: Text(
                'Photo Library (Single)',
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(modalContext);
                _pickImage(ImageSource.gallery, multiple: false);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.photo_library,
                color: context.textOnPrimary,
              ),
              title: Text(
                'Photo Library (Multiple)',
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                'Select multiple photos at once',
                style: TextStyle(
                  color: context.onSurfaceVariantColor,
                  fontSize: 13,
                ),
              ),
              onTap: () {
                Navigator.pop(modalContext);
                _pickImage(ImageSource.gallery, multiple: true);
              },
            ),
            Divider(height: 1, color: context.borderColor),
            ListTile(
              leading: const Icon(Icons.close, color: Colors.red),
              title: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () => Navigator.pop(modalContext),
            ),
          ],
        ),
      ),
    );
  }

  void _showPhotoOptions(int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) => SafeArea(
        child: Wrap(
          children: [
            if (index > 0)
              ListTile(
                leading: Icon(Icons.star, color: context.textOnPrimary),
                title: Text(
                  'Make Primary',
                  style: TextStyle(color: context.textPrimary, fontSize: 16,
                  ),
                ),
                onTap: () {
                  Navigator.pop(modalContext);
                  _makePrimary(index);
                },
              ),
            ListTile(
              leading: Icon(Icons.delete, color: context.errorColor),
              title: Text(
                'Remove Photo',
                style: TextStyle(color: context.errorColor, fontSize: 16,
                ),
              ),
              onTap: () {
                Navigator.pop(modalContext);
                _removePhoto(index);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.cancel,
                color: context.onSurfaceVariantColor,
              ),
              title: Text(
                'Cancel',
                style: TextStyle(
                  color: context.onSurfaceVariantColor,
                  fontSize: 16,
                ),
              ),
              onTap: () => Navigator.pop(modalContext),
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
