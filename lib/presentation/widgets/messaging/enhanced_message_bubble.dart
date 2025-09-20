import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/message.dart';
import '../../../blocs/chat_bloc.dart';
import '../../theme/pulse_colors.dart';

/// Enhanced message bubble with action menu and reply support
class EnhancedMessageBubble extends StatefulWidget {
  const EnhancedMessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.replyToMessage,
    this.contextualActions = const [],
    this.onReplyTap,
    this.showReplyUI = false,
  });

  final Message message;
  final bool isCurrentUser;
  final Message? replyToMessage;
  final List<ContextualAction> contextualActions;
  final VoidCallback? onReplyTap;
  final bool showReplyUI;

  @override
  State<EnhancedMessageBubble> createState() => _EnhancedMessageBubbleState();
}

class _EnhancedMessageBubbleState extends State<EnhancedMessageBubble>
    with TickerProviderStateMixin {
  late AnimationController _actionMenuController;
  late AnimationController _replyAnimationController;
  late Animation<double> _actionMenuAnimation;
  late Animation<Offset> _replySlideAnimation;

  bool _showActionMenu = false;
  bool _isEditing = false;
  final TextEditingController _editController = TextEditingController();
  final FocusNode _editFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _actionMenuController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _replyAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _actionMenuAnimation = CurvedAnimation(
      parent: _actionMenuController,
      curve: Curves.easeInOut,
    );

    _replySlideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _replyAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _editController.text = widget.message.content;
  }

  @override
  void dispose() {
    _actionMenuController.dispose();
    _replyAnimationController.dispose();
    _editController.dispose();
    _editFocusNode.dispose();
    super.dispose();
  }

  bool get _canEdit {
    if (!widget.isCurrentUser) return false;
    final now = DateTime.now();
    final messageTime = widget.message.createdAt;
    final difference = now.difference(messageTime);
    return difference.inMinutes < 5; // 5-minute edit window
  }

  void _showMessageActions() {
    setState(() {
      _showActionMenu = true;
    });
    _actionMenuController.forward();
  }

  void _hideMessageActions() {
    _actionMenuController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _showActionMenu = false;
        });
      }
    });
  }

  void _copyMessage() {
    Clipboard.setData(ClipboardData(text: widget.message.content));
    context.read<ChatBloc>().add(CopyMessage(messageId: widget.message.id));
    _hideMessageActions();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _replyToMessage() {
    widget.onReplyTap?.call();
    _hideMessageActions();
  }

  void _editMessage() {
    setState(() {
      _isEditing = true;
    });
    _hideMessageActions();
    _editFocusNode.requestFocus();
  }

  void _saveEdit() {
    if (_editController.text.trim().isNotEmpty &&
        _editController.text != widget.message.content) {
      context.read<ChatBloc>().add(
            EditMessage(
              messageId: widget.message.id,
              newContent: _editController.text.trim(),
            ),
          );
    }
    _cancelEdit();
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
    });
    _editController.text = widget.message.content;
  }

  void _deleteMessage() {
    context.read<ChatBloc>().add(DeleteMessage(messageId: widget.message.id));
    _hideMessageActions();
  }

  void _performContextualAction(ContextualAction action) {
    context.read<ChatBloc>().add(
          PerformContextualAction(
            actionId: action.id,
            actionType: action.type,
            actionData: action.data,
          ),
        );
    _hideMessageActions();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _hideMessageActions,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: widget.isCurrentUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            // Reply preview if this message is a reply
            if (widget.replyToMessage != null)
              _buildReplyPreview(widget.replyToMessage!),

            // Main message row
            Row(
              mainAxisAlignment: widget.isCurrentUser
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!widget.isCurrentUser) ...[
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

                // Message bubble with actions
                Flexible(
                  child: Stack(
                    children: [
                      GestureDetector(
                        onLongPress: _showMessageActions,
                        onTap: () {
                          if (_showActionMenu) {
                            _hideMessageActions();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: widget.isCurrentUser
                                ? PulseColors.primary
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(20).copyWith(
                              bottomLeft: widget.isCurrentUser
                                  ? const Radius.circular(20)
                                  : const Radius.circular(4),
                              bottomRight: widget.isCurrentUser
                                  ? const Radius.circular(4)
                                  : const Radius.circular(20),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Message content
                              _isEditing
                                  ? _buildEditingField()
                                  : _buildMessageContent(),

                              // Message metadata
                              const SizedBox(height: 4),
                              _buildMessageMetadata(),
                            ],
                          ),
                        ),
                      ),

                      // Action menu
                      if (_showActionMenu) _buildActionMenu(),
                    ],
                  ),
                ),

                if (widget.isCurrentUser) const SizedBox(width: 8),
              ],
            ),

            // Contextual actions for AI messages
            if (widget.contextualActions.isNotEmpty && !widget.isCurrentUser)
              _buildContextualActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyPreview(Message replyMessage) {
    return SlideTransition(
      position: _replySlideAnimation,
      child: Container(
        margin: EdgeInsets.only(
          left: widget.isCurrentUser ? 50 : 40,
          right: widget.isCurrentUser ? 0 : 50,
          bottom: 4,
        ),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(
              color: PulseColors.primary,
              width: 3,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Replying to',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              replyMessage.content.length > 50
                  ? '${replyMessage.content.substring(0, 50)}...'
                  : replyMessage.content,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditingField() {
    return Column(
      children: [
        TextField(
          controller: _editController,
          focusNode: _editFocusNode,
          maxLines: null,
          style: TextStyle(
            color: widget.isCurrentUser ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'Edit message...',
            hintStyle: TextStyle(
              color: widget.isCurrentUser
                  ? Colors.white.withValues(alpha: 0.7)
                  : Colors.grey[500],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: _cancelEdit,
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _saveEdit,
              child: const Text('Save'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMessageContent() {
    return Text(
      widget.message.content,
      style: TextStyle(
        color: widget.isCurrentUser ? Colors.white : Colors.black87,
        fontSize: 16,
      ),
    );
  }

  Widget _buildMessageMetadata() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatTime(widget.message.createdAt),
          style: TextStyle(
            fontSize: 11,
            color: widget.isCurrentUser
                ? Colors.white.withValues(alpha: 0.8)
                : Colors.grey[600],
          ),
        ),
        if (widget.isCurrentUser) ...[
          const SizedBox(width: 4),
          Icon(
            widget.message.status == MessageStatus.read
                ? Icons.done_all
                : widget.message.status == MessageStatus.delivered
                    ? Icons.done_all
                    : Icons.access_time,
            size: 12,
            color: widget.message.status == MessageStatus.read
                ? Colors.blue[300]
                : Colors.white.withValues(alpha: 0.8),
          ),
        ],
        // Show edited indicator
        if (widget.message.status == MessageStatus.sent && _wasEdited()) ...[
          const SizedBox(width: 4),
          Text(
            '(edited)',
            style: TextStyle(
              fontSize: 10,
              color: widget.isCurrentUser
                  ? Colors.white.withValues(alpha: 0.6)
                  : Colors.grey[500],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionMenu() {
    return Positioned(
      top: widget.isCurrentUser ? -50 : -50,
      right: widget.isCurrentUser ? 0 : null,
      left: widget.isCurrentUser ? null : 0,
      child: ScaleTransition(
        scale: _actionMenuAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildActionButton(
                icon: Icons.content_copy,
                label: 'Copy',
                onTap: _copyMessage,
              ),
              if (widget.showReplyUI)
                _buildActionButton(
                  icon: Icons.reply,
                  label: 'Reply',
                  onTap: _replyToMessage,
                ),
              if (_canEdit)
                _buildActionButton(
                  icon: Icons.edit,
                  label: 'Edit',
                  onTap: _editMessage,
                ),
              if (widget.isCurrentUser)
                _buildActionButton(
                  icon: Icons.delete,
                  label: 'Delete',
                  onTap: _deleteMessage,
                  isDestructive: true,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isDestructive ? Colors.red : Colors.grey[700],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isDestructive ? Colors.red : Colors.grey[700],
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
        children: widget.contextualActions.take(3).map((action) {
          return GestureDetector(
            onTap: () => _performContextualAction(action),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: PulseColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: PulseColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getActionIcon(action.icon),
                    size: 14,
                    color: PulseColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    action.label,
                    style: TextStyle(
                      fontSize: 12,
                      color: PulseColors.primary,
                      fontWeight: FontWeight.w500,
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

  IconData _getActionIcon(String iconName) {
    switch (iconName) {
      case 'person_add':
        return Icons.person_add;
      case 'edit':
        return Icons.edit;
      case 'chat_bubble':
        return Icons.chat_bubble;
      case 'send':
        return Icons.send;
      case 'bookmark':
        return Icons.bookmark;
      case 'alarm':
        return Icons.alarm;
      case 'content_copy':
        return Icons.content_copy;
      case 'translate':
        return Icons.translate;
      case 'auto_fix_high':
        return Icons.auto_fix_high;
      default:
        return Icons.touch_app;
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

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

  bool _wasEdited() {
    // This would typically check against the original timestamp
    // For now, return false as we don't have edit tracking in the model yet
    return false;
  }
}

/// Contextual action data class
class ContextualAction {
  final String id;
  final String type;
  final String label;
  final String description;
  final String icon;
  final Map<String, dynamic> data;

  const ContextualAction({
    required this.id,
    required this.type,
    required this.label,
    required this.description,
    required this.icon,
    required this.data,
  });

  factory ContextualAction.fromJson(Map<String, dynamic> json) {
    return ContextualAction(
      id: json['id'] as String,
      type: json['type'] as String,
      label: json['label'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      data: json['data'] as Map<String, dynamic>? ?? {},
    );
  }
}