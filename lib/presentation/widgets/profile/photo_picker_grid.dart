import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../services/photo_upload_service.dart';
import '../../theme/pulse_colors.dart';

/// Widget for selecting and uploading profile photos
class PhotoPickerGrid extends StatefulWidget {
  final List<String> initialPhotos;
  final Function(List<String>) onPhotosChanged;
  final int maxPhotos;
  final bool isRequired;
  final PhotoUploadService photoUploadService;

  const PhotoPickerGrid({
    super.key,
    this.initialPhotos = const [],
    required this.onPhotosChanged,
    this.maxPhotos = 6,
    this.isRequired = false,
    required this.photoUploadService,
  });

  @override
  State<PhotoPickerGrid> createState() => _PhotoPickerGridState();
}

class _PhotoPickerGridState extends State<PhotoPickerGrid> {
  List<String> _photos = [];
  final Set<int> _uploadingIndices = {};

  @override
  void initState() {
    super.initState();
    _photos = List.from(widget.initialPhotos);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.isRequired) ...[
          Text(
            'Add at least 2 photos to continue',
            style: PulseTextStyles.bodyMedium.copyWith(
              color: _photos.length < 2 ? PulseColors.error : PulseColors.success,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: PulseSpacing.md),
        ],
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: PulseSpacing.md,
              mainAxisSpacing: PulseSpacing.md,
              childAspectRatio: 1,
            ),
            itemCount: widget.maxPhotos,
            itemBuilder: (context, index) {
              return _buildPhotoSlot(index);
            },
          ),
        ),
        if (_photos.isNotEmpty) ...[
          const SizedBox(height: PulseSpacing.md),
          _buildPhotoActions(),
        ],
      ],
    );
  }

  Widget _buildPhotoSlot(int index) {
    final hasPhoto = index < _photos.length;
    final isUploading = _uploadingIndices.contains(index);

    return GestureDetector(
      onTap: () => _handlePhotoSlotTap(index),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(PulseRadii.lg),
          border: Border.all(
            color: hasPhoto ? PulseColors.primary : PulseColors.outline,
            width: hasPhoto ? 2 : 1,
          ),
          color: hasPhoto ? null : PulseColors.surfaceVariant,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(PulseRadii.lg - 1),
          child: Stack(
            children: [
              if (hasPhoto) ...[
                // Photo display
                _buildPhotoDisplay(_photos[index]),
                // Delete button
                _buildDeleteButton(index),
                // Primary photo indicator
                if (index == 0) _buildPrimaryIndicator(),
              ] else ...[
                // Add photo placeholder
                _buildAddPhotoPlaceholder(index),
              ],
              
              // Upload progress overlay
              if (isUploading) _buildUploadOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoDisplay(String photoUrl) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(photoUrl),
          fit: BoxFit.cover,
          onError: (error, stackTrace) {
            // Handle image loading error
          },
        ),
      ),
    );
  }

  Widget _buildDeleteButton(int index) {
    return Positioned(
      top: PulseSpacing.xs,
      right: PulseSpacing.xs,
      child: GestureDetector(
        onTap: () => _removePhoto(index),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: PulseColors.error,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.close,
            color: Colors.white,
            size: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryIndicator() {
    return Positioned(
      top: PulseSpacing.xs,
      left: PulseSpacing.xs,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: PulseSpacing.xs,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: PulseColors.primary,
          borderRadius: BorderRadius.circular(PulseRadii.sm),
        ),
        child: Text(
          'PRIMARY',
          style: PulseTextStyles.labelSmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      ),
    );
  }

  Widget _buildAddPhotoPlaceholder(int index) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            index == 0 ? Icons.add_a_photo : Icons.add_photo_alternate,
            size: 40,
            color: PulseColors.onSurfaceVariant,
          ),
          const SizedBox(height: PulseSpacing.xs),
          Text(
            index == 0 ? 'Add Primary Photo' : 'Add Photo',
            style: PulseTextStyles.bodySmall.copyWith(
              color: PulseColors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUploadOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.6),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: PulseSpacing.sm),
            Text(
              'Uploading...',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _addMultiplePhotos(),
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('Add Multiple'),
          ),
        ),
        const SizedBox(width: PulseSpacing.md),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _reorderPhotos(),
            icon: const Icon(Icons.swap_vert),
            label: const Text('Reorder'),
          ),
        ),
      ],
    );
  }

  void _handlePhotoSlotTap(int index) {
    if (index < _photos.length) {
      _showPhotoOptions(index);
    } else {
      _showAddPhotoOptions(index);
    }
  }

  void _showAddPhotoOptions(int index) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(PulseRadii.xl),
        ),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(PulseSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: PulseColors.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: PulseSpacing.lg),
            Text(
              'Add Photo',
              style: PulseTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: PulseSpacing.lg),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(PulseSpacing.sm),
                decoration: BoxDecoration(
                  color: PulseColors.primaryContainer,
                  borderRadius: BorderRadius.circular(PulseRadii.md),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: PulseColors.primary,
                ),
              ),
              title: const Text('Take Photo'),
              subtitle: const Text('Use camera to capture a new photo'),
              onTap: () {
                Navigator.pop(context);
                _pickFromCamera(index);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(PulseSpacing.sm),
                decoration: BoxDecoration(
                  color: PulseColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(PulseRadii.md),
                ),
                child: const Icon(
                  Icons.photo_library,
                  color: PulseColors.secondary,
                ),
              ),
              title: const Text('Choose from Gallery'),
              subtitle: const Text('Select from your photo library'),
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery(index);
              },
            ),
            const SizedBox(height: PulseSpacing.lg),
          ],
        ),
      ),
    );
  }

  void _showPhotoOptions(int index) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(PulseRadii.xl),
        ),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(PulseSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: PulseColors.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: PulseSpacing.lg),
            Text(
              'Photo Options',
              style: PulseTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: PulseSpacing.lg),
            if (index != 0)
              ListTile(
                leading: const Icon(Icons.star),
                title: const Text('Make Primary'),
                subtitle: const Text('Set as your main profile photo'),
                onTap: () {
                  Navigator.pop(context);
                  _makePrimary(index);
                },
              ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Replace Photo'),
              subtitle: const Text('Choose a different photo'),
              onTap: () {
                Navigator.pop(context);
                _showAddPhotoOptions(index);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: PulseColors.error),
              title: Text('Remove Photo', style: TextStyle(color: PulseColors.error)),
              subtitle: const Text('Delete this photo'),
              onTap: () {
                Navigator.pop(context);
                _removePhoto(index);
              },
            ),
            const SizedBox(height: PulseSpacing.lg),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromCamera(int index) async {
    try {
      final imageFile = await widget.photoUploadService.pickFromCamera();
      if (imageFile != null) {
        await _uploadPhoto(imageFile, index);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to capture photo: $e');
    }
  }

  Future<void> _pickFromGallery(int index) async {
    try {
      final imageFile = await widget.photoUploadService.pickFromGallery();
      if (imageFile != null) {
        await _uploadPhoto(imageFile, index);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to select photo: $e');
    }
  }

  Future<void> _addMultiplePhotos() async {
    try {
      final remainingSlots = widget.maxPhotos - _photos.length;
      if (remainingSlots <= 0) {
        _showErrorSnackBar('Maximum number of photos reached');
        return;
      }

      final imageFiles = await widget.photoUploadService.pickMultipleFromGallery(
        maxImages: remainingSlots,
      );
      
      for (final imageFile in imageFiles) {
        final currentIndex = _photos.length;
        await _uploadPhoto(imageFile, currentIndex);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to select photos: $e');
    }
  }

  Future<void> _uploadPhoto(XFile imageFile, int targetIndex) async {
    // Validate image first
    final validation = await widget.photoUploadService.validateImage(imageFile);
    if (!validation.isValid) {
      _showErrorSnackBar(validation.error ?? 'Invalid image');
      return;
    }

    setState(() {
      _uploadingIndices.add(targetIndex);
    });

    try {
      final result = await widget.photoUploadService.uploadPhoto(imageFile);
      
      if (result.success && result.photoUrl != null) {
        setState(() {
          if (targetIndex < _photos.length) {
            _photos[targetIndex] = result.photoUrl!;
          } else {
            _photos.add(result.photoUrl!);
          }
          _uploadingIndices.remove(targetIndex);
        });
        
        widget.onPhotosChanged(_photos);
        _showSuccessSnackBar('Photo uploaded successfully');
      } else {
        throw Exception(result.error ?? 'Upload failed');
      }
    } catch (e) {
      setState(() {
        _uploadingIndices.remove(targetIndex);
      });
      _showErrorSnackBar('Upload failed: $e');
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
    widget.onPhotosChanged(_photos);
  }

  void _makePrimary(int index) {
    if (index > 0 && index < _photos.length) {
      setState(() {
        final photo = _photos.removeAt(index);
        _photos.insert(0, photo);
      });
      widget.onPhotosChanged(_photos);
      _showSuccessSnackBar('Primary photo updated');
    }
  }

  void _reorderPhotos() {
    // TODO: Implement drag-and-drop reordering
    _showErrorSnackBar('Reordering feature coming soon');
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: PulseColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: PulseColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}