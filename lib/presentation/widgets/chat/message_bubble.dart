import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import '../../theme/pulse_colors.dart';
import '../../../data/models/chat_model.dart';
import '../../../domain/entities/message.dart' as entities;
import '../media/media_grid.dart';
import '../media/media_viewer.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isCurrentUser;
  final VoidCallback? onLongPress;
  final Function(String)? onReaction;
  final VoidCallback? onReply;
  final VoidCallback? onMediaTap;
  final String? currentUserId;
  final bool isHighlighted;
  final String? searchQuery;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.onLongPress,
    this.onReaction,
    this.onReply,
    this.onMediaTap,
    this.currentUserId,
    this.isHighlighted = false,
    this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Column(
          children: [
            // Reply preview (if replying to another message)
            if (message.replyTo != null) _buildReplyPreview(context),

            // Main message row
            Row(
              mainAxisAlignment: isCurrentUser
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Avatar for received messages
                if (!isCurrentUser) _buildAvatar(),

                // Message bubble - keeping existing structure for now
                Flexible(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    padding: _hasMedia()
                        ? EdgeInsets.zero
                        : const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _hasMedia()
                          ? Colors.transparent
                          : isHighlighted
                          ? (isCurrentUser
                                ? PulseColors.primary.withValues(alpha: 0.9)
                                : PulseColors.secondary.withValues(alpha: 0.2))
                          : (isCurrentUser
                                ? PulseColors.primary
                                : Colors.grey[50]),
                      border: isHighlighted
                          ? Border.all(color: PulseColors.primary, width: 2)
                          : null,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(isCurrentUser ? 20 : 6),
                        bottomRight: Radius.circular(isCurrentUser ? 6 : 20),
                      ),
                      boxShadow: _hasMedia()
                          ? []
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Media content (images, videos, etc.)
                        if (_hasMedia()) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(20),
                              topRight: const Radius.circular(20),
                              bottomLeft: Radius.circular(
                                message.content?.isNotEmpty == true
                                    ? 4
                                    : (isCurrentUser ? 20 : 6),
                              ),
                              bottomRight: Radius.circular(
                                message.content?.isNotEmpty == true
                                    ? 4
                                    : (isCurrentUser ? 6 : 20),
                              ),
                            ),
                            child: _buildMediaContent(context),
                          ),
                        ],

                        // Text content with media
                        if (_hasMedia() &&
                            message.content != null &&
                            message.content!.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isCurrentUser
                                  ? PulseColors.primary
                                  : Colors.grey[50],
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(
                                  isCurrentUser ? 20 : 6,
                                ),
                                bottomRight: Radius.circular(
                                  isCurrentUser ? 6 : 20,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message.content!,
                                  style: TextStyle(
                                    color: isCurrentUser
                                        ? Colors.white
                                        : Colors.black87,
                                    fontSize: 16,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      DateFormat(
                                        'h:mm a',
                                      ).format(message.createdAt),
                                      style: TextStyle(
                                        color: isCurrentUser
                                            ? Colors.white.withValues(
                                                alpha: 0.7,
                                              )
                                            : Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (isCurrentUser) ...[
                                      const SizedBox(width: 4),
                                      Icon(
                                        message.status == MessageStatus.read
                                            ? Icons.done_all
                                            : Icons.done,
                                        size: 16,
                                        color:
                                            message.status == MessageStatus.read
                                            ? Colors.blue[300]
                                            : Colors.white.withValues(
                                                alpha: 0.7,
                                              ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ]
                        // Text-only content
                        else if (!_hasMedia() &&
                            message.content != null &&
                            message.content!.isNotEmpty) ...[
                          _buildHighlightedText(
                            message.content!,
                            isCurrentUser,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                DateFormat('h:mm a').format(message.createdAt),
                                style: TextStyle(
                                  color: isCurrentUser
                                      ? Colors.white.withValues(alpha: 0.7)
                                      : Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              if (isCurrentUser) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  message.status == MessageStatus.read
                                      ? Icons.done_all
                                      : Icons.done,
                                  size: 16,
                                  color: message.status == MessageStatus.read
                                      ? Colors.blue[300]
                                      : Colors.white.withValues(alpha: 0.7),
                                ),
                              ],
                            ],
                          ),
                        ],
                        
                        // Media-only content timestamp
                        if (_hasMedia() &&
                            (message.content == null ||
                                message.content!.isEmpty)) ...[
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
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
                                      Text(
                                        DateFormat(
                                          'h:mm a',
                                        ).format(message.createdAt),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (isCurrentUser) ...[
                                        const SizedBox(width: 4),
                                        Icon(
                                          message.status == MessageStatus.read
                                              ? Icons.done_all
                                              : Icons.done,
                                          size: 14,
                                          color:
                                              message.status ==
                                                  MessageStatus.read
                                              ? Colors.blue[300]
                                              : Colors.white,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                if (isCurrentUser) const SizedBox(width: 8),
              ],
            ),
            
            // Reactions row
            if (message.reactions?.isNotEmpty == true) _buildReactions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 4),
      child: CircleAvatar(
        radius: 16,
        backgroundColor: Colors.grey[300],
        backgroundImage: message.senderAvatar != null
            ? CachedNetworkImageProvider(message.senderAvatar!)
            : null,
        child: message.senderAvatar == null
            ? Text(
                message.senderUsername.isNotEmpty
                    ? message.senderUsername[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildReplyPreview(BuildContext context) {
    final replyTo = message.replyTo!;
    return Container(
      margin: EdgeInsets.only(
        left: isCurrentUser ? 60 : 40,
        right: isCurrentUser ? 16 : 60,
        bottom: 4,
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: isCurrentUser
                    ? PulseColors.primary.withValues(alpha: 0.8)
                    : Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      replyTo.senderUsername,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isCurrentUser
                            ? PulseColors.primary
                            : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getPreviewText(replyTo),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReactions(BuildContext context) {
    final reactions = message.reactions ?? [];
    if (reactions.isEmpty) return const SizedBox.shrink();

    // Group reactions by emoji
    final groupedReactions = <String, List<MessageReaction>>{};
    for (final reaction in reactions) {
      groupedReactions.putIfAbsent(reaction.emoji, () => []).add(reaction);
    }

    return Container(
      margin: EdgeInsets.only(
        left: isCurrentUser ? 60 : 40,
        right: isCurrentUser ? 16 : 60,
        top: 4,
      ),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: groupedReactions.entries.map((entry) {
          final emoji = entry.key;
          final reactionList = entry.value;
          final hasUserReacted =
              currentUserId != null &&
              reactionList.any((r) => r.userId == currentUserId);

          return GestureDetector(
            onTap: () => onReaction?.call(emoji),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: hasUserReacted
                    ? PulseColors.primary.withValues(alpha: 0.1)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: hasUserReacted
                    ? Border.all(color: PulseColors.primary, width: 1)
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 14)),
                  if (reactionList.length > 1) ...[
                    const SizedBox(width: 4),
                    Text(
                      reactionList.length.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        color: hasUserReacted
                            ? PulseColors.primary
                            : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Check if message has media content
  bool _hasMedia() {
    return message.mediaUrls != null &&
        message.mediaUrls!.isNotEmpty &&
        (message.type == entities.MessageType.image ||
            message.type == entities.MessageType.video ||
            message.type == entities.MessageType.gif);
  }

  /// Build media content widget
  Widget _buildMediaContent(BuildContext context) {
    if (!_hasMedia()) return const SizedBox.shrink();

    final mediaUrls = message.mediaUrls!;
    final heroTag = 'message_${message.id}';

    // Single image with optimized display
    if (mediaUrls.length == 1) {
      return _buildSingleImage(context, mediaUrls.first, heroTag);
    }

    // Multiple images with grid layout
    return MediaGrid(
      mediaUrls: mediaUrls,
      messageType: message.type,
      isCurrentUser: isCurrentUser,
      heroTagPrefix: heroTag,
    );
  }

  /// Build single image with modern styling
  Widget _buildSingleImage(
    BuildContext context,
    String imageUrl,
    String heroTag,
  ) {
    return GestureDetector(
      onTap: () => _openMediaViewer(context, [imageUrl], 0, heroTag),
      child: Hero(
        tag: '${heroTag}_0',
        child: Container(
          constraints: const BoxConstraints(maxWidth: 280, maxHeight: 300),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => _buildImagePlaceholder(),
              errorWidget: (context, url, error) => _buildImageError(),
              fadeInDuration: const Duration(milliseconds: 200),
              fadeOutDuration: const Duration(milliseconds: 100),
            ),
          ),
        ),
      ),
    );
  }

  /// Build shimmer placeholder for loading images
  Widget _buildImagePlaceholder() {
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

  /// Build error widget for failed image loading
  Widget _buildImageError() {
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

  /// Open media viewer for full-screen viewing
  void _openMediaViewer(
    BuildContext context,
    List<String> mediaUrls,
    int initialIndex,
    String heroTag,
  ) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) => MediaViewer(
          mediaUrls: mediaUrls,
          initialIndex: initialIndex,
          messageType: message.type,
          heroTag: heroTag,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  String _getPreviewText(MessageModel message) {
    switch (message.type) {
      case entities.MessageType.image:
        return '📷 Photo';
      case entities.MessageType.video:
        return '🎥 Video';
      case entities.MessageType.audio:
        return '🎵 Audio';
      case entities.MessageType.gif:
        return '🎭 GIF';
      case entities.MessageType.sticker:
        return '😊 Sticker';
      case entities.MessageType.location:
        return '📍 Location';
      case entities.MessageType.contact:
        return '👤 Contact';
      case entities.MessageType.file:
        return '📎 File';
      default:
        return message.content ?? '';
    }
  }
  
  Widget _buildHighlightedText(String content, bool isCurrentUser) {
    // If no search query or not highlighted, show normal text
    if (searchQuery == null || searchQuery!.isEmpty || !isHighlighted) {
      return Text(
        content,
        style: TextStyle(
          color: isCurrentUser ? Colors.white : Colors.black87,
          fontSize: 16,
          height: 1.3,
        ),
      );
    }
    
    // Build highlighted text
    final List<TextSpan> spans = [];
    final String lowerContent = content.toLowerCase();
    final String lowerQuery = searchQuery!.toLowerCase();
    
    int start = 0;
    int index = lowerContent.indexOf(lowerQuery, start);
    
    while (index != -1) {
      // Add text before the match
      if (index > start) {
        spans.add(TextSpan(
          text: content.substring(start, index),
          style: TextStyle(
            color: isCurrentUser ? Colors.white : Colors.black87,
            fontSize: 16,
            height: 1.3,
          ),
        ));
      }
      
      // Add highlighted match
      spans.add(TextSpan(
        text: content.substring(index, index + searchQuery!.length),
        style: TextStyle(
          color: isCurrentUser ? Colors.black : Colors.white,
          backgroundColor: isCurrentUser 
              ? Colors.yellow.withValues(alpha: 0.8) 
              : PulseColors.primary.withValues(alpha: 0.8),
          fontSize: 16,
          height: 1.3,
          fontWeight: FontWeight.bold,
        ),
      ));
      
      start = index + searchQuery!.length;
      index = lowerContent.indexOf(lowerQuery, start);
    }
    
    // Add remaining text
    if (start < content.length) {
      spans.add(TextSpan(
        text: content.substring(start),
        style: TextStyle(
          color: isCurrentUser ? Colors.white : Colors.black87,
          fontSize: 16,
          height: 1.3,
        ),
      ));
    }
    
    return RichText(
      text: TextSpan(children: spans),
    );
  }
}