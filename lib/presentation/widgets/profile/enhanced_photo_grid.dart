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
      // Support multi-select up to remaining photo slots
      final int remainingSlots = widget.maxPhotos - _photos.length;

      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        // Limit to remaining slots
        final imagesToUpload = images.take(remainingSlots).toList();

        if (images.length > remainingSlots) {
          _showErrorDialog(
            'Only $remainingSlots photo(s) can be added. ${images.length - remainingSlots} photo(s) were not uploaded.',
          );
        }

        // If upload callback provided, trigger direct upload
        if (widget.onPhotoUpload != null) {
          setState(() {
            _isUploading = true;
          });

          try {
            // Upload each photo directly to permanent storage
            for (final image in imagesToUpload) {
              final imageFile = File(image.path);
              await widget.onPhotoUpload!(imageFile);
            }
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
          // Fallback: Add all selected images locally (old behavior)
          for (final selectedImage in imagesToUpload) {
            final newPhoto = ProfilePhoto(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              url: selectedImage.path,
              order: _photos.length,
            );
            setState(() {
              _photos.add(newPhoto);
            });
          }
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
    return GestureDetector(
      onTap: () => _showPhotoViewer(index),
      child: Container(
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

            // Info icon for metadata (bottom left)
            Positioned(
              bottom: 8,
              left: 8,
              child: GestureDetector(
                onTap: () => _showPhotoDetails(photo, index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),

            // Drag handle (only in editing mode)
            if (widget.isEditing)
              Positioned(
                bottom: 8,
                right: 8,
                child: GestureDetector(
                  onLongPressStart: (_) {
                    // Visual feedback that drag is ready
                  },
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
              ),
          ],
        ),
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

  void _showPhotoViewer(int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _PhotoViewerScreen(
          photos: _photos,
          initialIndex: initialIndex,
          onDescriptionChanged: (index, description) {
            setState(() {
              _photos[index] = _photos[index].copyWith(description: description);
            });
            widget.onPhotosChanged(_photos);
          },
        ),
      ),
    );
  }

  void _showPhotoDetails(ProfilePhoto photo, int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PhotoDetailsSheet(
        photo: photo,
        index: index,
        totalPhotos: _photos.length,
        onDescriptionChanged: (description) {
          setState(() {
            _photos[index] = _photos[index].copyWith(description: description);
          });
          widget.onPhotosChanged(_photos);
        },
      ),
    );
  }
}

// Full-Screen Photo Viewer
class _PhotoViewerScreen extends StatefulWidget {
  final List<ProfilePhoto> photos;
  final int initialIndex;
  final Function(int index, String description)? onDescriptionChanged;

  const _PhotoViewerScreen({
    required this.photos,
    required this.initialIndex,
    this.onDescriptionChanged,
  });

  @override
  State<_PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<_PhotoViewerScreen> {
  late PageController _pageController;
  late TextEditingController _descriptionController;
  int _currentIndex = 0;
  bool _showDescription = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _descriptionController = TextEditingController(
      text: widget.photos[_currentIndex].description ?? '',
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
      _descriptionController.text = widget.photos[index].description ?? '';
    });
  }

  void _saveDescription() {
    final description = _descriptionController.text.trim();
    if (description != widget.photos[_currentIndex].description) {
      widget.onDescriptionChanged?.call(_currentIndex, description);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Photo PageView
          PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: widget.photos.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => setState(() => _showDescription = !_showDescription),
                child: InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: Center(
                    child: Image.network(
                      widget.photos[index].url,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                    ),
                  ),
                ),
              );
            },
          ),

          // Top bar with close button and counter
          if (!_showDescription)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 28),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_currentIndex + 1} / ${widget.photos.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Bottom description editor
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              transform: Matrix4.translationValues(
                0,
                _showDescription ? 0 : 200,
                0,
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.9),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Add Description',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => setState(() => _showDescription = false),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _descriptionController,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Add a caption...',
                          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (_) => _saveDescription(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Photo Details Bottom Sheet
class _PhotoDetailsSheet extends StatefulWidget {
  final ProfilePhoto photo;
  final int index;
  final int totalPhotos;
  final Function(String) onDescriptionChanged;

  const _PhotoDetailsSheet({
    required this.photo,
    required this.index,
    required this.totalPhotos,
    required this.onDescriptionChanged,
  });

  @override
  State<_PhotoDetailsSheet> createState() => _PhotoDetailsSheetState();
}

class _PhotoDetailsSheetState extends State<_PhotoDetailsSheet> {
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.photo.description ?? '',
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Text(
                    'Photo ${widget.index + 1} Details',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Photo preview
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.photo.url,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),

              // Metadata
              _buildInfoRow('Position', '${widget.index + 1} of ${widget.totalPhotos}'),
              _buildInfoRow('Status', widget.photo.isVerified ? 'Verified ✓' : 'Pending'),
              if (widget.photo.uploadedAt != null)
                _buildInfoRow(
                  'Uploaded',
                  _formatDate(widget.photo.uploadedAt!),
                ),
              const SizedBox(height: 20),

              // Description editor
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  hintText: 'Add a caption or description...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                maxLines: 3,
                onChanged: widget.onDescriptionChanged,
              ),
              const SizedBox(height: 20),

              // Done button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PulseColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}

// Reorderable Grid View with drag-to-reorder support
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
  int? _draggingIndex;
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: widget.physics,
      shrinkWrap: widget.shrinkWrap,
      gridDelegate: widget.gridDelegate,
      itemCount: widget.itemCount,
      itemBuilder: (context, index) {
        final child = widget.children[index];
        
        return LongPressDraggable<int>(
          data: index,
          feedback: Transform.scale(
            scale: 1.1,
            child: Opacity(
              opacity: 0.8,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 120,
                  height: 160,
                  child: child,
                ),
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: child,
          ),
          onDragStarted: () {
            setState(() => _draggingIndex = index);
          },
          onDragEnd: (_) {
            setState(() {
              _draggingIndex = null;
              _hoveredIndex = null;
            });
          },
          child: DragTarget<int>(
            onWillAcceptWithDetails: (details) {
              setState(() => _hoveredIndex = index);
              return true;
            },
            onLeave: (_) {
              setState(() => _hoveredIndex = null);
            },
            onAcceptWithDetails: (details) {
              final fromIndex = details.data;
              if (fromIndex != index) {
                widget.onReorder(fromIndex, index);
              }
              setState(() {
                _hoveredIndex = null;
                _draggingIndex = null;
              });
            },
            builder: (context, candidateData, rejectedData) {
              final isHovered = _hoveredIndex == index && _draggingIndex != index;
              
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: isHovered
                      ? Border.all(color: PulseColors.primary, width: 2)
                      : null,
                ),
                child: child,
              );
            },
          ),
        );
      },
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
