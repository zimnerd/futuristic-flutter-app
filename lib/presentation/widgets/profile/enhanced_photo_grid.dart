import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../theme/pulse_colors.dart';
import '../../../domain/entities/user_profile.dart';

/// Enhanced photo grid widget with drag-to-reorder and advanced management
class EnhancedPhotoGrid extends StatefulWidget {
  final List<ProfilePhoto> photos;
  final Function(List<ProfilePhoto>) onPhotosChanged;
  final Function(File)?
  onPhotoUpload; // Callback to upload photo to temp storage
  final Function(ProfilePhoto)? onPhotoDelete; // Callback to delete photo
  final int maxPhotos;
  final bool isEditing;

  const EnhancedPhotoGrid({
    super.key,
    required this.photos,
    required this.onPhotosChanged,
    this.onPhotoUpload,
    this.onPhotoDelete,
    this.maxPhotos = 6,
    this.isEditing = true,
  });

  @override
  State<EnhancedPhotoGrid> createState() => _EnhancedPhotoGridState();
}

class _EnhancedPhotoGridState extends State<EnhancedPhotoGrid> {
  final ImagePicker _picker = ImagePicker();
  List<ProfilePhoto> _photos = [];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _photos = List.from(widget.photos);
  }

  @override
  void didUpdateWidget(EnhancedPhotoGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('🔄 EnhancedPhotoGrid.didUpdateWidget called');
    print('📊 Old photos count: ${oldWidget.photos.length}');
    print('📊 New photos count: ${widget.photos.length}');
    
    if (oldWidget.photos != widget.photos) {
      print('✅ Photos changed, updating internal _photos list');
      _photos = List.from(widget.photos);
      print('📊 Internal _photos count after update: ${_photos.length}');

      // Log each photo URL
      for (var i = 0; i < _photos.length; i++) {
        print(
          '📸 Photo $i: id=${_photos[i].id}, url=${_photos[i].url}, isLocal=${_photos[i].isLocal}',
        );
      }
    } else {
      print('⚠️ Photos unchanged, skipping update');
    }
  }

  Future<void> _addPhoto() async {
    if (_photos.length >= widget.maxPhotos) {
      _showMaxPhotosReachedDialog();
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        final imageFile = File(image.path);

        // If upload callback provided, trigger upload to temp storage
        if (widget.onPhotoUpload != null) {
          setState(() {
            _isUploading = true;
          });

          try {
            // Call parent to upload via BLoC (will return photo with mediaId)
            await widget.onPhotoUpload!(imageFile);
            // BLoC will update photos list via onPhotosChanged
          } catch (uploadError) {
            _showErrorDialog('Failed to upload photo: $uploadError');
          } finally {
            if (mounted) {
              setState(() {
                _isUploading = false;
              });
            }
          }
        } else {
          // Fallback: just add local file path (old behavior)
          final newPhoto = ProfilePhoto(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            url: image.path,
            order: _photos.length,
          );
          setState(() {
            _photos.add(newPhoto);
          });
          widget.onPhotosChanged(_photos);
        }
      }
    } catch (e) {
      _showErrorDialog('Failed to select photo: $e');
    }
  }

  void _deletePhoto(int index) {
    final photoToDelete = _photos[index];

    // If delete callback provided, trigger proper deletion via BLoC
    if (widget.onPhotoDelete != null) {
      widget.onPhotoDelete!(photoToDelete);
      // BLoC will update photos list via onPhotosChanged
    } else {
      // Fallback: just remove locally (old behavior)
      setState(() {
        _photos.removeAt(index);
        // Update order for remaining photos
        for (int i = 0; i < _photos.length; i++) {
          _photos[i] = _photos[i].copyWith(order: i);
        }
      });
      widget.onPhotosChanged(_photos);
    }
  }

  void _setAsPrimary(int index) {
    if (index == 0) return; // Already primary

    setState(() {
      final photo = _photos.removeAt(index);
      _photos.insert(0, photo);
      // Update order for all photos
      for (int i = 0; i < _photos.length; i++) {
        _photos[i] = _photos[i].copyWith(order: i);
      }
    });
    widget.onPhotosChanged(_photos);
  }

  void _reorderPhotos(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    setState(() {
      final photo = _photos.removeAt(oldIndex);
      _photos.insert(newIndex, photo);
      // Update order for all photos
      for (int i = 0; i < _photos.length; i++) {
        _photos[i] = _photos[i].copyWith(order: i);
      }
    });
    widget.onPhotosChanged(_photos);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Photos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            Text(
              '${_photos.length}/${widget.maxPhotos}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Add ${widget.maxPhotos - _photos.length} more photos to increase your chances',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        
        if (widget.isEditing)
          ReorderableGridView(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: _photos.length + (_photos.length < widget.maxPhotos ? 1 : 0),
            onReorder: _reorderPhotos,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            children: [
              ..._photos.asMap().entries.map((entry) {
                final index = entry.key;
                final photo = entry.value;
                return _buildPhotoCard(photo, index, key: ValueKey(photo.id));
              }),
              if (_photos.length < widget.maxPhotos)
                _buildAddPhotoCard(key: const ValueKey('add_photo')),
            ],
          )
        else
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: _photos.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemBuilder: (context, index) {
              return _buildPhotoCard(_photos[index], index);
            },
          ),
      ],
    );
  }

  Widget _buildPhotoCard(ProfilePhoto photo, int index, {Key? key}) {
    return Container(
      key: key,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Photo
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.grey[200],
              child: photo.isLocal
                  ? Image.file(
                      File(photo.url),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildErrorPlaceholder();
                      },
                    )
                  : Image.network(
                      photo.url,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return _buildLoadingPlaceholder();
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return _buildErrorPlaceholder();
                      },
                    ),
            ),
          ),

          // Primary badge
          if (index == 0)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: PulseColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'PRIMARY',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          // Action buttons (only in editing mode)
          if (widget.isEditing)
            Positioned(
              top: 8,
              right: 8,
              child: Column(
                children: [
                  _buildActionButton(
                    icon: Icons.close,
                    onTap: () => _deletePhoto(index),
                    backgroundColor: Colors.red,
                  ),
                  const SizedBox(height: 8),
                  if (index != 0)
                    _buildActionButton(
                      icon: Icons.star,
                      onTap: () => _setAsPrimary(index),
                      backgroundColor: PulseColors.primary,
                    ),
                ],
              ),
            ),

          // Drag handle (only in editing mode)
          if (widget.isEditing)
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.drag_handle,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAddPhotoCard({Key? key}) {
    return InkWell(
      key: key,
      onTap: _isUploading ? null : _addPhoto, // Disable during upload
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isUploading ? PulseColors.primary : Colors.grey[300]!,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: _isUploading
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      PulseColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Uploading...',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: PulseColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add_a_photo,
                      color: PulseColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Add Photo',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color backgroundColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.grey[500],
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            'Failed to load',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _showMaxPhotosReachedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Maximum Photos Reached'),
        content: Text('You can only have up to ${widget.maxPhotos} photos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// Simple implementation of ReorderableGridView
class ReorderableGridView extends StatefulWidget {
  final int itemCount;
  final ReorderCallback onReorder;
  final SliverGridDelegate gridDelegate;
  final List<Widget> children;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  const ReorderableGridView({
    super.key,
    required this.itemCount,
    required this.onReorder,
    required this.gridDelegate,
    required this.children,
    this.physics,
    this.shrinkWrap = false,
  });

  @override
  State<ReorderableGridView> createState() => _ReorderableGridViewState();
}

class _ReorderableGridViewState extends State<ReorderableGridView> {
  @override
  Widget build(BuildContext context) {
    // For now, use a regular GridView - can be enhanced with proper reordering
    return GridView(
      physics: widget.physics,
      shrinkWrap: widget.shrinkWrap,
      gridDelegate: widget.gridDelegate,
      children: widget.children,
    );
  }
}

// Extension for ProfilePhoto
extension ProfilePhotoExtension on ProfilePhoto {
  ProfilePhoto copyWith({
    String? id,
    String? url,
    int? order,
    bool? isVerified,
    DateTime? uploadedAt,
  }) {
    return ProfilePhoto(
      id: id ?? this.id,
      url: url ?? this.url,
      order: order ?? this.order,
      isVerified: isVerified ?? this.isVerified,
      uploadedAt: uploadedAt ?? this.uploadedAt,
    );
  }

  bool get isLocal => url.startsWith('/') || url.startsWith('file://');
}
