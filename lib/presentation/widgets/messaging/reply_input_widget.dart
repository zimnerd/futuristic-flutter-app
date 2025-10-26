import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/message.dart';
import '../../../domain/entities/message.dart' show MessageType;
import '../../../blocs/chat_bloc.dart';
import '../../theme/pulse_colors.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';

/// Reply input widget for threaded conversations
class ReplyInputWidget extends StatefulWidget {
  const ReplyInputWidget({
    super.key,
    required this.originalMessage,
    required this.conversationId,
    required this.onCancel,
    this.autoFocus = true,
  });

  final Message originalMessage;
  final String conversationId;
  final VoidCallback onCancel;
  final bool autoFocus;

  @override
  State<ReplyInputWidget> createState() => _ReplyInputWidgetState();
}

class _ReplyInputWidgetState extends State<ReplyInputWidget>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _replyPreviewController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _replyPreviewAnimation;

  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _replyPreviewController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _replyPreviewAnimation = CurvedAnimation(
      parent: _replyPreviewController,
      curve: Curves.easeInOut,
    );

    // Animate in
    _slideController.forward();
    _replyPreviewController.forward();

    // Auto focus if requested
    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _replyPreviewController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendReply() {
    final content = _textController.text.trim();
    if (content.isNotEmpty) {
      context.read<ChatBloc>().add(
        ReplyToMessage(
          originalMessageId: widget.originalMessage.id,
          conversationId: widget.conversationId,
          content: content,
          type: MessageType.text,
        ),
      );
      _animateOut();
    }
  }

  void _animateOut() {
    _replyPreviewController.reverse();
    _slideController.reverse().then((_) {
      widget.onCancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: context.onSurfaceColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reply preview
            ScaleTransition(
              scale: _replyPreviewAnimation,
              child: _buildReplyPreview(),
            ),

            // Input field
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Cancel button
                  GestureDetector(
                    onTap: _animateOut,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: context.outlineColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 20,
                        color: context.outlineColor,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Text input
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: context.outlineColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendReply(),
                        decoration: InputDecoration(
                          hintText: 'Reply to ${_getSenderName()}...',
                          hintStyle: TextStyle(
                            color: context.onSurfaceVariantColor.withValues(alpha: 0.6),
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Send button
                  GestureDetector(
                    onTap: _sendReply,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: PulseColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.send,
                        size: 20,
                        color: context.onSurfaceColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(
            color: context.outlineColor.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.reply, size: 16, color: PulseColors.primary),
              const SizedBox(width: 8),
              Text(
                'Replying to ${_getSenderName()}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: PulseColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.onSurfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border(
                left: BorderSide(color: PulseColors.primary, width: 3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getPreviewContent(),
                  style: TextStyle(
                    fontSize: 14,
                    color: context.onSurfaceVariantColor,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTimestamp(widget.originalMessage.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: context.onSurfaceVariantColor.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getSenderName() {
    // In a real app, you'd get this from user data
    // For now, assume it's either 'you' or the companion name
    return widget.originalMessage.isFromCurrentUser('current_user_id')
        ? 'yourself'
        : 'AI Companion';
  }

  String _getPreviewContent() {
    final content = widget.originalMessage.content;
    if (content.length > 100) {
      return '${content.substring(0, 100)}...';
    }
    return content;
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}

/// Overlay manager for reply input
class ReplyInputOverlay {
  static OverlayEntry? _currentEntry;

  static void show({
    required BuildContext context,
    required Message originalMessage,
    required String conversationId,
  }) {
    // Remove existing overlay if any
    hide();

    _currentEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: ReplyInputWidget(
            originalMessage: originalMessage,
            conversationId: conversationId,
            onCancel: hide,
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_currentEntry!);
  }

  static void hide() {
    _currentEntry?.remove();
    _currentEntry = null;
  }
}
