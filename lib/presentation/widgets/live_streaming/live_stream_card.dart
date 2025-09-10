import 'package:flutter/material.dart';
import '../../theme/pulse_colors.dart';

/// Widget to display a live stream card
class LiveStreamCard extends StatelessWidget {
  final Map<String, dynamic> stream;
  final VoidCallback onTap;
  final VoidCallback? onReport;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isOwner;

  const LiveStreamCard({
    super.key,
    required this.stream,
    required this.onTap,
    this.onReport,
    this.onEdit,
    this.onDelete,
    this.isOwner = false,
  });

  @override
  Widget build(BuildContext context) {
    final String title = stream['title'] ?? 'Live Stream';
    final String streamerName = stream['streamerName'] ?? 'Unknown';
    final int viewerCount = stream['viewerCount'] ?? 0;
    final String category = stream['category'] ?? 'General';
    final bool isLive = stream['isLive'] ?? true;
    final String thumbnailUrl = stream['thumbnailUrl'] ?? '';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Stack(
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    color: Colors.grey[300],
                    image: thumbnailUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(thumbnailUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: thumbnailUrl.isEmpty
                      ? const Center(
                          child: Icon(
                            Icons.videocam,
                            size: 50,
                            color: Colors.grey,
                          ),
                        )
                      : null,
                ),
                // Live indicator
                if (isLive)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Viewer count
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.visibility,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatViewerCount(viewerCount),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Menu button for owner
                if (isOwner)
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            onEdit?.call();
                            break;
                          case 'delete':
                            onDelete?.call();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        if (onEdit != null)
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                        if (onDelete != null)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete'),
                              ],
                            ),
                          ),
                      ],
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.more_vert,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            
            // Stream info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!isOwner && onReport != null)
                        IconButton(
                          onPressed: onReport,
                          icon: const Icon(
                            Icons.flag_outlined,
                            size: 20,
                            color: Colors.grey,
                          ),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: PulseColors.primary.withValues(alpha: 0.2),
                        child: const Icon(
                          Icons.person,
                          size: 16,
                          color: PulseColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          streamerName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: PulseColors.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            fontSize: 12,
                            color: PulseColors.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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

  String _formatViewerCount(int count) {
    if (count < 1000) {
      return count.toString();
    } else if (count < 1000000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
  }
}
