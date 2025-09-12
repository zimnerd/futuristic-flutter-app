import 'package:flutter/material.dart';
import '../../../domain/entities/message.dart';
import '../../theme/pulse_colors.dart';

/// Message bubble widget for chat interface
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.onLongPress,
  });

  final Message message;
  final bool isCurrentUser;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isCurrentUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: PulseColors.primary.withValues(alpha: 0.1),
              child: Text(
                'U',
                style: TextStyle(
                  color: PulseColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: GestureDetector(
              onLongPress: onLongPress,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isCurrentUser 
                      ? PulseColors.primary 
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(20).copyWith(
                    bottomLeft: isCurrentUser 
                        ? const Radius.circular(20) 
                        : const Radius.circular(4),
                    bottomRight: isCurrentUser 
                        ? const Radius.circular(4) 
                        : const Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Message content based on type
                    _buildMessageContent(),
                    
                    // Message metadata
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(message.timestamp),
                          style: TextStyle(
                            fontSize: 11,
                            color: isCurrentUser 
                                ? Colors.white.withValues(alpha: 0.8)
                                : Colors.grey[600],
                          ),
                        ),
                        if (isCurrentUser) ...[
                          const SizedBox(width: 4),
                          Icon(
                            message.isRead 
                                ? Icons.done_all
                                : message.isDelivered
                                    ? Icons.done_all
                                    : Icons.access_time,
                            size: 12,
                            color: message.isRead 
                                ? Colors.blue[300]
                                : Colors.white.withValues(alpha: 0.8),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          if (isCurrentUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: PulseColors.primary,
              child: const Text(
                'M',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageContent() {
    switch (message.type) {
      case MessageType.text:
        return Text(
          message.content,
          style: TextStyle(
            fontSize: 16,
            color: isCurrentUser ? Colors.white : Colors.black87,
          ),
        );
        
      case MessageType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                message.mediaUrl ?? '',
                width: 200,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.broken_image, size: 40),
                ),
              ),
            ),
            if (message.content.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                message.content,
                style: TextStyle(
                  fontSize: 16,
                  color: isCurrentUser ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ],
        );

      case MessageType.audio:
        return Container(
          width: 200,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isCurrentUser 
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.play_arrow,
                color: isCurrentUser ? Colors.white : PulseColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Voice Message',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isCurrentUser ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      _formatDuration(message.mediaDuration ?? 0),
                      style: TextStyle(
                        fontSize: 12,
                        color: isCurrentUser 
                            ? Colors.white.withValues(alpha: 0.8)
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

      case MessageType.video:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 200,
                    height: 150,
                    color: Colors.black,
                    child: const Icon(
                      Icons.video_library,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
            if (message.content.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                message.content,
                style: TextStyle(
                  fontSize: 16,
                  color: isCurrentUser ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ],
        );

      default:
        return Text(
          message.content,
          style: TextStyle(
            fontSize: 16,
            color: isCurrentUser ? Colors.white : Colors.black87,
          ),
        );
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${timestamp.day}/${timestamp.month}';
    } else if (difference.inHours > 0) {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
