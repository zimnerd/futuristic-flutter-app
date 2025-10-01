import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models.dart';

class MessageBubble extends StatelessWidget {
  final GroupMessage message;
  final bool isMe;
  final VoidCallback? onReply;
  final VoidCallback? onDelete;
  final Function(String emoji)? onAddReaction;
  final Function(String emoji)? onRemoveReaction;
  final VoidCallback? onTap;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onReply,
    this.onDelete,
    this.onAddReaction,
    this.onRemoveReaction,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showMessageOptions(context),
      onTap: onTap,
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // Reply-to preview
              if (message.replyTo != null) _buildReplyPreview(context),
              
              // Message bubble
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isMe
                      ? Theme.of(context).primaryColor
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sender name (for group messages)
                    if (!isMe)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            if (message.senderProfilePhoto != null)
                              CircleAvatar(
                                radius: 10,
                                backgroundImage: CachedNetworkImageProvider(
                                  message.senderProfilePhoto!,
                                ),
                              ),
                            if (message.senderProfilePhoto != null)
                              const SizedBox(width: 4),
                            Text(
                              message.senderFirstName ??
                                  message.senderUsername,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isMe ? Colors.white : Colors.black87,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Message content based on type
                    _buildMessageContent(context),
                    
                    // Timestamp and status
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTimestamp(message.timestamp),
                          style: TextStyle(
                            fontSize: 10,
                            color: isMe ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          _buildStatusIcon(),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              // Reactions
              if (message.reactions.isNotEmpty) _buildReactions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReplyPreview(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.replyTo!.senderUsername,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            message.replyTo!.content,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    switch (message.type) {
      case 'image':
        return _buildImageMessage();
      case 'voice':
        return _buildVoiceMessage();
      case 'text':
      default:
        return Text(
          message.content,
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black87,
          ),
        );
    }
  }

  Widget _buildImageMessage() {
    final imageUrl = message.metadata?['url'] as String?;
    if (imageUrl == null) return const Text('Image not available');

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: 200,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: 200,
          height: 200,
          color: Colors.grey[300],
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => Container(
          width: 200,
          height: 200,
          color: Colors.grey[300],
          child: const Icon(Icons.error),
        ),
      ),
    );
  }

  Widget _buildVoiceMessage() {
    final duration = message.metadata?['duration'] as int? ?? 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.play_circle_outline,
          color: isMe ? Colors.white : Colors.black87,
        ),
        const SizedBox(width: 8),
        Text(
          _formatDuration(duration),
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 2,
            color: isMe ? Colors.white54 : Colors.black26,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIcon() {
    IconData icon;
    Color color;

    switch (message.status) {
      case 'sending':
        icon = Icons.access_time;
        color = Colors.white54;
        break;
      case 'sent':
        icon = Icons.done;
        color = Colors.white70;
        break;
      case 'delivered':
        icon = Icons.done_all;
        color = Colors.white70;
        break;
      case 'read':
        icon = Icons.done_all;
        color = Colors.blue;
        break;
      default:
        icon = Icons.error_outline;
        color = Colors.red;
    }

    return Icon(icon, size: 14, color: color);
  }

  Widget _buildReactions(BuildContext context) {
    // Group reactions by emoji
    final reactionCounts = <String, List<MessageReaction>>{};
    for (final reaction in message.reactions) {
      reactionCounts.putIfAbsent(reaction.emoji, () => []).add(reaction);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: reactionCounts.entries.map((entry) {
          final emoji = entry.key;
          final reactions = entry.value;
          final hasMyReaction = reactions.any((r) => r.userId == 'currentUserId'); // TODO: Get from auth

          return GestureDetector(
            onTap: () {
              if (hasMyReaction) {
                onRemoveReaction?.call(emoji);
              } else {
                onAddReaction?.call(emoji);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: hasMyReaction
                    ? Theme.of(context).primaryColor.withOpacity(0.2)
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasMyReaction
                      ? Theme.of(context).primaryColor
                      : Colors.grey[300]!,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(
                    '${reactions.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          hasMyReaction ? FontWeight.bold : FontWeight.normal,
                      color: hasMyReaction
                          ? Theme.of(context).primaryColor
                          : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showMessageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            if (onReply != null)
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text('Reply'),
                onTap: () {
                  Navigator.pop(context);
                  onReply?.call();
                },
              ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: message.content));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_reaction_outlined),
              title: const Text('React'),
              onTap: () {
                Navigator.pop(context);
                _showReactionPicker(context);
              },
            ),
            if (isMe && onDelete != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title:
                    const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  onDelete?.call();
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showReactionPicker(BuildContext context) {
    final commonEmojis = ['❤️', '👍', '😂', '😮', '😢', '😡', '🎉', '🔥'];

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'React to message',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: commonEmojis.map((emoji) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      onAddReaction?.call(emoji);
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Center(
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
