import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import '../../../domain/entities/message.dart';
import '../../theme/pulse_colors.dart';
import 'chat_image_viewer.dart';

/// Enhanced chat image message widget with upload status, captions, and actions
class ChatImageMessage extends StatelessWidget {
  final Message message;
  final bool isCurrentUser;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onRetryUpload;
  final VoidCallback? onDeleteUpload;

  const ChatImageMessage({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.onTap,
    this.onLongPress,
    this.onRetryUpload,
    this.onDeleteUpload,
  });

  @override
  Widget build(BuildContext context) {
    final mediaAttachment = message.mediaAttachment;
    if (mediaAttachment == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: mediaAttachment.uploadStatus == MediaUploadStatus.uploaded
          ? () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChatImageViewer(
                    images: [mediaAttachment],
                    initialIndex: 0,
                    heroTag: 'chat_image_${message.id}',
                  ),
                ),
              );
            }
          : null,
      onLongPress: onLongPress,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
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
        child: Column(
          crossAxisAlignment:
              isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Image with upload overlay
            Stack(
              children: [
                // The image
                ClipRRect(
                  borderRadius: mediaAttachment.caption != null
                      ? const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        )
                      : BorderRadius.circular(12),
                  child: _buildImage(mediaAttachment, context),
                ),

                // Upload status overlay
                if (mediaAttachment.uploadStatus != MediaUploadStatus.uploaded)
                  _buildUploadOverlay(mediaAttachment),

                // Failed upload retry button
                if (mediaAttachment.uploadStatus == MediaUploadStatus.failed)
                  _buildFailedOverlay(),
              ],
            ),

            // Caption (if present)
            if (mediaAttachment.caption != null &&
                mediaAttachment.caption!.isNotEmpty)
              _buildCaption(mediaAttachment.caption!, context),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(MediaAttachment attachment, BuildContext context) {
    // Show thumbnail if available and uploaded, otherwise show main url
    final imageUrl = attachment.uploadStatus == MediaUploadStatus.uploaded
        ? (attachment.thumbnailUrl ?? attachment.url)
        : attachment.url;

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      width: attachment.width?.toDouble() ?? 280,
      height: attachment.height?.toDouble() ?? 280,
      placeholder: (context, url) => _buildPlaceholder(),
      errorWidget: (context, url, error) => _buildError(),
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 100),
    );
  }

  Widget _buildPlaceholder() {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          color: Colors.grey[300],
          child: const Center(
            child: Icon(Icons.image_outlined, color: Colors.grey, size: 32),
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Container(
        color: Colors.grey[100],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image_rounded, color: Colors.grey[400], size: 32),
            const SizedBox(height: 8),
            Text(
              'Image unavailable',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadOverlay(MediaAttachment attachment) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: attachment.caption != null
              ? const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                )
              : BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (attachment.uploadStatus == MediaUploadStatus.uploading)
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              const SizedBox(height: 8),
              Text(
                attachment.uploadStatus == MediaUploadStatus.uploading
                    ? 'Uploading...'
                    : 'Upload failed',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFailedOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 48,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetryUpload,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PulseColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: onDeleteUpload,
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCaption(String caption, BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isCurrentUser ? PulseColors.primary : Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Text(
        caption,
        style: TextStyle(
          color: isCurrentUser ? Colors.white : Colors.black87,
          fontSize: 14,
        ),
      ),
    );
  }

  /// Show action sheet on long press
  static void showImageActions(
    BuildContext context, {
    required MediaAttachment attachment,
    required VoidCallback onViewFullScreen,
    VoidCallback? onRetryUpload,
    VoidCallback? onDeleteMessage,
    VoidCallback? onSaveToGallery,
  }) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // View full screen
            if (attachment.uploadStatus == MediaUploadStatus.uploaded)
              ListTile(
                leading: const Icon(Icons.fullscreen),
                title: const Text('View Full Screen'),
                onTap: () {
                  Navigator.pop(context);
                  onViewFullScreen();
                },
              ),

            // Save to gallery
            if (attachment.uploadStatus == MediaUploadStatus.uploaded &&
                onSaveToGallery != null)
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('Save to Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  onSaveToGallery();
                },
              ),

            // Retry upload
            if (attachment.uploadStatus == MediaUploadStatus.failed &&
                onRetryUpload != null)
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Retry Upload'),
                onTap: () {
                  Navigator.pop(context);
                  onRetryUpload();
                },
              ),

            // Delete message
            if (onDeleteMessage != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Message',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  onDeleteMessage();
                },
              ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
