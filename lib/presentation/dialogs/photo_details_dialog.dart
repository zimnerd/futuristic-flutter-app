import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../domain/entities/user_profile.dart';
import '../theme/pulse_colors.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';

/// Dialog for viewing and editing photo details
///
/// Features:
/// - View full photo
/// - Set as primary photo
/// - Edit photo description
/// - Delete photo
/// - View photo analytics (views, likes) - if available
class PhotoDetailsDialog extends StatefulWidget {
  final ProfilePhoto photo;
  final bool isPrimary;
  final bool canSetPrimary;
  final Function()? onSetPrimary;
  final Function(String description)? onUpdateDescription;
  final Function()? onDelete;
  final PhotoAnalytics? analytics;

  const PhotoDetailsDialog({
    super.key,
    required this.photo,
    required this.isPrimary,
    this.canSetPrimary = true,
    this.onSetPrimary,
    this.onUpdateDescription,
    this.onDelete,
    this.analytics,
  });

  @override
  State<PhotoDetailsDialog> createState() => _PhotoDetailsDialogState();
}

class _PhotoDetailsDialogState extends State<PhotoDetailsDialog> {
  late TextEditingController _descriptionController;
  bool _isEditingDescription = false;

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

  void _handleSetPrimary() {
    if (widget.onSetPrimary != null) {
      widget.onSetPrimary!();
      Navigator.of(context).pop();
    }
  }

  void _handleSaveDescription() {
    if (widget.onUpdateDescription != null) {
      widget.onUpdateDescription!(_descriptionController.text.trim());
      setState(() {
        _isEditingDescription = false;
      });
    }
  }

  void _handleDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Photo'),
        content: Text(
          'Are you sure you want to delete this photo? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close confirmation dialog
              if (widget.onDelete != null) {
                widget.onDelete!();
              }
              Navigator.of(context).pop(); // Close details dialog
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Photo preview
            Container(
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: widget.photo.url,
                      width: double.infinity,
                      height: 300,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: context.surfaceVariantColor,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: context.surfaceVariantColor,
                        child: Icon(
                          Icons.broken_image,
                          size: 64,
                          color: context.onSurfaceVariantColor,
                        ),
                      ),
                    ),
                  ),

                  // Primary badge
                  if (widget.isPrimary)
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: PulseColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              color: Theme.of(context).colorScheme.onPrimary,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Primary Photo',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Close button
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: context.surfaceColor,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.close,
                          color: Theme.of(context).colorScheme.surface,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Analytics (if available)
                  if (widget.analytics != null) ...[
                    _buildAnalyticsSection(),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 20),
                  ],

                  // Description section
                  Row(
                    children: [
                      Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      if (!_isEditingDescription &&
                          widget.onUpdateDescription != null)
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _isEditingDescription = true;
                            });
                          },
                          icon: Icon(Icons.edit, size: 16),
                          label: Text('Edit'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_isEditingDescription) ...[
                    TextField(
                      controller: _descriptionController,
                      maxLines: 3,
                      maxLength: 200,
                      decoration: InputDecoration(
                        hintText: 'Add a description for this photo...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _descriptionController.text =
                                  widget.photo.description ?? '';
                              _isEditingDescription = false;
                            });
                          },
                          child: Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _handleSaveDescription,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PulseColors.primary,
                            foregroundColor: context.theme.colorScheme.onPrimary,
                          ),
                          child: Text('Save'),
                        ),
                      ],
                    ),
                  ] else ...[
                    Text(
                      widget.photo.description?.isNotEmpty == true
                          ? widget.photo.description!
                          : 'No description added',
                      style: TextStyle(
                        fontSize: 14,
                        color: widget.photo.description?.isNotEmpty == true
                            ? context.onSurfaceColor
                            : context.onSurfaceVariantColor,
                        fontStyle: widget.photo.description?.isNotEmpty == true
                            ? null
                            : FontStyle.italic,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Action buttons
                  Column(
                    children: [
                      if (!widget.isPrimary &&
                          widget.canSetPrimary &&
                          widget.onSetPrimary != null)
                        _buildActionButton(
                          icon: Icons.star_border,
                          label: 'Set as Primary Photo',
                          color: PulseColors.primary,
                          onTap: _handleSetPrimary,
                        ),

                      if (widget.onDelete != null) ...[
                        const SizedBox(height: 12),
                        _buildActionButton(
                          icon: Icons.delete_outline,
                          label: 'Delete Photo',
                          color: context.errorColor,
                          onTap: _handleDelete,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsSection() {
    final analytics = widget.analytics!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceVariantColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildAnalyticItem(
            icon: Icons.visibility,
            label: 'Views',
            value: _formatNumber(analytics.views),
          ),
          Container(
            width: 1,
            height: 40,
            color: context.dividerColor,
          ),
          _buildAnalyticItem(
            icon: Icons.favorite,
            label: 'Likes',
            value: _formatNumber(analytics.likes),
          ),
          if (analytics.swipeRightRate != null) ...[
            Container(
              width: 1,
              height: 40,
              color: context.dividerColor,
            ),
            _buildAnalyticItem(
              icon: Icons.trending_up,
              label: 'Match Rate',
              value: '${analytics.swipeRightRate!.toStringAsFixed(1)}%',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnalyticItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: PulseColors.primary, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: context.onSurfaceVariantColor),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

/// Photo analytics data model
class PhotoAnalytics {
  final int views;
  final int likes;
  final double? swipeRightRate;

  const PhotoAnalytics({
    required this.views,
    required this.likes,
    this.swipeRightRate,
  });
}
