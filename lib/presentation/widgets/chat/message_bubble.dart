import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../../theme/pulse_colors.dart';
import '../../../domain/entities/message.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isCurrentUser;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isCurrentUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser) _buildAvatar(),
          if (!isCurrentUser) const SizedBox(width: 8),
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
                  _buildMessageContent(),
                  const SizedBox(height: 4),
                  _buildMessageInfo(),
                ],
              ),
            ),
          ),
          if (isCurrentUser) const SizedBox(width: 8),
          if (isCurrentUser) _buildAvatar(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 16,
      backgroundColor: isCurrentUser ? PulseColors.primary : Colors.grey[300],
      child: Text(
        isCurrentUser ? 'M' : 'U',
        style: TextStyle(
          color: isCurrentUser ? Colors.white : Colors.grey[600],
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMessageContent() {
    switch (message.type) {
      case MessageType.text:
        return Text(
          message.content,
          style: TextStyle(
            color: isCurrentUser ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
        );
      case MessageType.image:
        return _buildImageMessage();
      case MessageType.audio:
        return _buildAudioMessage();
      case MessageType.video:
        return _buildVideoMessage();
      case MessageType.file:
        return _buildFileMessage();
      default:
        return Text(
          'Unsupported message type',
          style: TextStyle(
            color: isCurrentUser ? Colors.white70 : Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        );
    }
  }

  Widget _buildImageMessage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        imageUrl: message.content,
        width: 200,
        height: 200,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: 200,
          height: 200,
          color: Colors.grey[200],
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: 200,
          height: 200,
          color: Colors.grey[200],
          child: const Icon(Icons.error),
        ),
      ),
    );
  }

  Widget _buildAudioMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentUser ? Colors.white24 : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.play_arrow,
            color: isCurrentUser ? Colors.white : PulseColors.primary,
          ),
          const SizedBox(width: 8),
          Text(
            'Audio message',
            style: TextStyle(
              color: isCurrentUser ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoMessage() {
    return Container(
      width: 200,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.play_circle_filled,
        color: Colors.white,
        size: 48,
      ),
    );
  }

  Widget _buildFileMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentUser ? Colors.white24 : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.attach_file,
            color: isCurrentUser ? Colors.white : PulseColors.primary,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message.content.split('/').last,
              style: TextStyle(
                color: isCurrentUser ? Colors.white : Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInfo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          DateFormat('HH:mm').format(message.createdAt ?? message.timestamp),
          style: TextStyle(
            color: isCurrentUser ? Colors.white70 : Colors.grey[600],
            fontSize: 12,
          ),
        ),
        if (isCurrentUser) ...[
          const SizedBox(width: 4),
          Icon(
            _getStatusIcon(),
            size: 16,
            color: Colors.white70,
          ),
        ],
      ],
    );
  }

  IconData _getStatusIcon() {
    switch (message.status) {
      case MessageStatus.sent:
        return Icons.check;
      case MessageStatus.delivered:
        return Icons.done_all;
      case MessageStatus.read:
        return Icons.done_all;
      case MessageStatus.failed:
        return Icons.error_outline;
      default:
        return Icons.schedule;
    }
  }
}
