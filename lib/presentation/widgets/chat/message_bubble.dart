import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../theme/pulse_colors.dart';
import '../../../data/models/chat_model.dart';
import '../../../domain/entities/message.dart' as entities;

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isCurrentUser;
  final VoidCallback? onLongPress;
  final Function(String)? onReaction;
  final VoidCallback? onReply;
  final VoidCallback? onMediaTap;
  final String? currentUserId;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.onLongPress,
    this.onReaction,
    this.onReply,
    this.onMediaTap,
    this.currentUserId,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isCurrentUser
                          ? PulseColors.primary
                          : Colors.grey[100],
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(isCurrentUser ? 20 : 4),
                        bottomRight: Radius.circular(isCurrentUser ? 4 : 20),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message.content != null) ...[
                          Text(
                            message.content!,
                            style: TextStyle(
                              color: isCurrentUser
                                  ? Colors.white
                                  : Colors.black87,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
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
}