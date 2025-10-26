import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';

import '../../domain/entities/user_profile.dart';
import '../theme/pulse_colors.dart';

/// Bottom sheet for reordering profile photos with drag-and-drop
///
/// Features:
/// - Drag and drop to reorder photos
/// - Visual feedback during drag (elevation, scale)
/// - Primary photo indicator (first position)
/// - Save/Cancel buttons
/// - Responsive grid layout
class PhotoReorderSheet extends StatefulWidget {
  final List<ProfilePhoto> photos;
  final Function(List<ProfilePhoto>) onReorder;

  const PhotoReorderSheet({
    super.key,
    required this.photos,
    required this.onReorder,
  });

  @override
  State<PhotoReorderSheet> createState() => _PhotoReorderSheetState();
}

class _PhotoReorderSheetState extends State<PhotoReorderSheet> {
  late List<ProfilePhoto> _reorderedPhotos;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    // Create mutable copy of photos
    _reorderedPhotos = List.from(widget.photos);
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final photo = _reorderedPhotos.removeAt(oldIndex);
      _reorderedPhotos.insert(newIndex, photo);

      // Update order values
      for (int i = 0; i < _reorderedPhotos.length; i++) {
        _reorderedPhotos[i] = _reorderedPhotos[i].copyWith(order: i);
      }

      _hasChanges = true;
    });
  }

  void _handleSave() {
    widget.onReorder(_reorderedPhotos);
    Navigator.of(context).pop(true);
  }

  void _handleCancel() {
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.8,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.outlineColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reorder Photos',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Long press and drag to reorder',
                        style: TextStyle(
                          fontSize: 14,
                          color: context.onSurfaceVariantColor,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: _handleCancel,
                ),
              ],
            ),
          ),

          // Info banner
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: PulseColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: PulseColors.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your first photo will be your primary profile photo',
                    style: TextStyle(
                      color: PulseColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Reorderable grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: ReorderableGridView(
                onReorder: _onReorder,
                children: _reorderedPhotos.asMap().entries.map((entry) {
                  final index = entry.key;
                  final photo = entry.value;
                  return _buildPhotoCard(photo, index, key: ValueKey(photo.id));
                }).toList(),
              ),
            ),
          ),

          // Action buttons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  offset: const Offset(0, -2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _handleCancel,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _hasChanges ? _handleSave : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PulseColors.primary,
                        foregroundColor: context.onSurfaceColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: context.outlineColor
                            .withValues(alpha: 0.3),
                      ),
                      child: Text(
                        'Save Order',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCard(ProfilePhoto photo, int index, {required Key key}) {
    final isPrimary = index == 0;

    return Container(
      key: key,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: isPrimary
            ? Border.all(color: PulseColors.primary, width: 3)
            : null,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Photo
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: photo.url,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: context.outlineColor.withValues(alpha: 0.15),
                child: Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                color: context.outlineColor.withValues(alpha: 0.3),
                child: Icon(
                  Icons.broken_image,
                  size: 40,
                  color: context.onSurfaceVariantColor,
                ),
              ),
            ),
          ),

          // Primary badge
          if (isPrimary)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: PulseColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, color: context.onSurfaceColor, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Primary',
                      style: TextStyle(
                        color: context.onSurfaceColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Position number
          if (!isPrimary)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: context.onSurfaceColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

          // Drag handle
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.drag_indicator,
                color: context.onSurfaceColor,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom reorderable grid view widget
class ReorderableGridView extends StatelessWidget {
  final List<Widget> children;
  final void Function(int oldIndex, int newIndex) onReorder;

  const ReorderableGridView({
    super.key,
    required this.children,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) {
        return LongPressDraggable<int>(
          data: index,
          feedback: Material(
            color: Colors.transparent,
            child: Transform.scale(
              scale: 1.1,
              child: Container(
                width: 100,
                height: 133,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: children[index],
              ),
            ),
          ),
          childWhenDragging: Opacity(opacity: 0.3, child: children[index]),
          child: DragTarget<int>(
            onAcceptWithDetails: (details) {
              onReorder(details.data, index);
            },
            builder: (context, candidateData, rejectedData) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: candidateData.isNotEmpty
                      ? Border.all(color: PulseColors.primary, width: 2)
                      : null,
                ),
                child: children[index],
              );
            },
          ),
        );
      },
    );
  }
}
