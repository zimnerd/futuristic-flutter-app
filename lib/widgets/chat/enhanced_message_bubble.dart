import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/chat_model.dart';
import '../../presentation/theme/pulse_colors.dart';

class EnhancedMessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isCurrentUser;
  final VoidCallback? onReply;
  final VoidCallback? onEdit;
  final VoidCallback? onCopy;
  final VoidCallback? onDelete;
  final Function(String)? onTapReply;
  final List<Widget>? contextualActions;

  const EnhancedMessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.onReply,
    this.onEdit,
    this.onCopy,
    this.onDelete,
    this.onTapReply,
    this.contextualActions,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: isCurrentUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          // Reply thread indicator
          if (message.replyTo != null) _buildReplyIndicator(context),
          
          // Main message bubble
          GestureDetector(
            onLongPress: () => _showMessageActions(context),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                gradient: isCurrentUser
                    ? LinearGradient(
                        colors: [
                          PulseColors.primary,
                          PulseColors.primary.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isCurrentUser ? null : PulseColors.receivedMessage,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Message content
                  Text(
                    message.content ?? '',
                    style: PulseTextStyles.chatMessage.copyWith(
                      color: isCurrentUser ? Colors.white : Colors.black87,
                    ),
                  ),
                  
                  // Contextual actions
                  if (contextualActions != null && contextualActions!.isNotEmpty)
                    _buildContextualActions(),
                  
                  // Message metadata
                  const SizedBox(height: 4),
                  _buildMessageMetadata(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyIndicator(BuildContext context) {
    final replyMessage = message.replyTo!;
    
    return GestureDetector(
      onTap: () => onTapReply?.call(replyMessage.id),
      child: Container(
        margin: EdgeInsets.only(
          bottom: 4,
          left: isCurrentUser ? 40 : 0,
          right: isCurrentUser ? 0 : 40,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 3,
              height: 40,
              decoration: BoxDecoration(
                color: PulseColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.senderUsername,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: PulseColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _truncateReplyContent(replyMessage.content ?? ''),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
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

  Widget _buildContextualActions() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: contextualActions!,
      ),
    );
  }

  Widget _buildMessageMetadata(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (message.editedAt != null)
          Container(
            margin: const EdgeInsets.only(right: 4),
            child: Text(
              'edited',
              style: TextStyle(
                fontSize: 10,
                color: isCurrentUser
                    ? Colors.white.withValues(alpha: 0.7)
                    : Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        Text(
          _formatTime(message.createdAt),
          style: TextStyle(
            fontSize: 10,
            color: isCurrentUser
                ? Colors.white.withValues(alpha: 0.7)
                : Colors.grey,
          ),
        ),
        if (isCurrentUser) ...[
          const SizedBox(width: 4),
          _buildMessageStatusIcon(),
        ],
      ],
    );
  }

  Widget _buildMessageStatusIcon() {
    IconData icon;
    Color color = Colors.white.withValues(alpha: 0.7);

    switch (message.status) {
      case MessageStatus.sending:
        icon = Icons.access_time;
        break;
      case MessageStatus.sent:
        icon = Icons.check;
        break;
      case MessageStatus.delivered:
        icon = Icons.done_all;
        break;
      case MessageStatus.read:
        icon = Icons.done_all;
        color = PulseColors.secondary;
        break;
      case MessageStatus.failed:
        icon = Icons.error_outline;
        color = Colors.red;
        break;
    }

    return Icon(
      icon,
      size: 12,
      color: color,
    );
  }

  void _showMessageActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildActionTile(
              icon: Icons.reply,
              title: 'Reply',
              onTap: () {
                Navigator.pop(context);
                onReply?.call();
              },
            ),
            _buildActionTile(
              icon: Icons.copy,
              title: 'Copy',
              onTap: () {
                Navigator.pop(context);
                _copyToClipboard();
                onCopy?.call();
              },
            ),
            if (isCurrentUser && _canEditMessage()) ...[
              _buildActionTile(
                icon: Icons.edit,
                title: 'Edit',
                onTap: () {
                  Navigator.pop(context);
                  onEdit?.call();
                },
              ),
              _buildActionTile(
                icon: Icons.delete,
                title: 'Delete',
                onTap: () {
                  Navigator.pop(context);
                  onDelete?.call();
                },
                isDestructive: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : PulseColors.primary,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: message.content ?? ''));
  }

  bool _canEditMessage() {
    // Allow editing within 5 minutes
    final now = DateTime.now();
    final difference = now.difference(message.createdAt);
    return difference.inMinutes < 5; // Removed isDeleted check since it's not available
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  String _truncateReplyContent(String content) {
    if (content.length <= 50) return content;
    return '${content.substring(0, 50)}...';
  }
}