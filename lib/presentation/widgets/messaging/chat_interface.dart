import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../../domain/entities/conversation.dart';
import '../../../domain/entities/message.dart';
import '../../blocs/messaging/messaging_bloc.dart';
import '../../theme/pulse_colors.dart';
import '../common/pulse_button.dart';
import 'message_bubble.dart';
import 'typing_indicator.dart';
import 'message_input.dart';

/// Enhanced chat interface with typing indicators and real-time messaging
class ChatInterface extends StatefulWidget {
  const ChatInterface({
    super.key,
    required this.conversation,
  });

  final Conversation conversation;

  @override
  State<ChatInterface> createState() => _ChatInterfaceState();
}

class _ChatInterfaceState extends State<ChatInterface>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final Logger _logger = Logger();

  late AnimationController _typingAnimationController;
  late AnimationController _sendButtonAnimationController;
  
  bool _isTyping = false;
  bool _isAtBottom = true;
  bool _showScrollToBottom = false;

  @override
  void initState() {
    super.initState();
    
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _sendButtonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scrollController.addListener(_onScroll);
    _messageController.addListener(_onMessageChanged);
    _messageFocusNode.addListener(_onFocusChanged);

    // Load messages for this conversation
    context.read<MessagingBloc>().add(
      LoadMessages(conversationId: widget.conversation.id),
    );

    // Mark conversation as read when opening
    context.read<MessagingBloc>().add(
      MarkConversationAsRead(conversationId: widget.conversation.id),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    _messageFocusNode.dispose();
    _typingAnimationController.dispose();
    _sendButtonAnimationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final isAtBottom = _scrollController.offset >= 
        _scrollController.position.maxScrollExtent - 100;
    
    if (isAtBottom != _isAtBottom) {
      setState(() {
        _isAtBottom = isAtBottom;
        _showScrollToBottom = !isAtBottom;
      });
    }

    // Load more messages if near the top
    if (_scrollController.offset <= 200) {
      final currentMessages = context.read<MessagingBloc>().state.currentMessages;
      if (currentMessages.length >= 50) { // Assume more messages if we have a full page
        context.read<MessagingBloc>().add(
          LoadMessages(conversationId: widget.conversation.id),
        );
      }
    }
  }

  void _onMessageChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    
    if (hasText && !_isTyping) {
      setState(() => _isTyping = true);
      _sendButtonAnimationController.forward();
      
      // TODO: Implement typing indicator sending
      // context.read<MessagingBloc>().add(
      //   SendTypingIndicator(conversationId: widget.conversation.id),
      // );
      
      _typingAnimationController.forward();
    } else if (!hasText && _isTyping) {
      setState(() => _isTyping = false);
      _sendButtonAnimationController.reverse();
      
      // TODO: Implement stop typing indicator
      // context.read<MessagingBloc>().add(
      //   StopTypingIndicator(conversationId: widget.conversation.id),
      // );
      
      _typingAnimationController.reverse();
    }
  }

  void _onFocusChanged() {
    if (_messageFocusNode.hasFocus) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom({bool animated = true}) {
    if (_scrollController.hasClients) {
      if (animated) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    }
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    // Send message
    context.read<MessagingBloc>().add(
      SendMessage(
        conversationId: widget.conversation.id,
        senderId: 'current_user', // Will be filled by the bloc
        content: content,
        type: MessageType.text,
      ),
    );

    // Clear input and reset state
    _messageController.clear();
    setState(() => _isTyping = false);
    _sendButtonAnimationController.reverse();
    
    // Haptic feedback
    HapticFeedback.lightImpact();
    
    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollToBottom();
    });
  }

  void _onMessageLongPress(Message message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildMessageActions(message),
    );
  }

  Widget _buildMessageActions(Message message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            // Message actions
            Text(
              'Message Options',
              style: PulseTextStyles.titleMedium,
            ),
            const SizedBox(height: 20),
            
            _buildActionTile(
              icon: Icons.copy,
              title: 'Copy Message',
              onTap: () {
                Clipboard.setData(ClipboardData(text: message.content));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Message copied to clipboard')),
                );
              },
            ),
            
            _buildActionTile(
              icon: Icons.reply,
              title: 'Reply',
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement reply functionality
              },
            ),
            
            if (message.senderId == 'current_user') // Current user's message
              _buildActionTile(
                icon: Icons.delete,
                title: 'Delete Message',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(message);
                },
              ),
            
            _buildActionTile(
              icon: Icons.report,
              title: 'Report Message',
              color: Colors.orange,
              onTap: () {
                Navigator.pop(context);
                _showReportDialog(message);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? PulseColors.primary),
      title: Text(
        title,
        style: TextStyle(color: color ?? Colors.black87),
      ),
      onTap: onTap,
    );
  }

  void _showDeleteConfirmation(Message message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement message deletion
              // context.read<MessagingBloc>().add(
              //   DeleteMessage(messageId: message.id),
              // );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(Message message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Message'),
        content: const Text('Report this message as inappropriate?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement message reporting
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Message reported')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: widget.conversation.otherUserAvatar.isNotEmpty
                  ? NetworkImage(widget.conversation.otherUserAvatar)
                  : null,
              child: widget.conversation.otherUserAvatar.isEmpty
                  ? Text(widget.conversation.otherUserName[0].toUpperCase())
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.conversation.otherUserName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  BlocBuilder<MessagingBloc, MessagingState>(
                    builder: (context, state) {
                      if (state.messagesStatus == MessagingStatus.loaded &&
                          state.typingUsers.containsKey(widget.conversation.id)) {
                        return const Text(
                          'typing...',
                          style: TextStyle(
                            fontSize: 12,
                            color: PulseColors.primary,
                            fontStyle: FontStyle.italic,
                          ),
                        );
                      }
                      return const Text(
                        'online',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: PulseColors.surface,
        foregroundColor: Colors.black87,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {
              // TODO: Implement video call
              _logger.d('Video call requested');
            },
          ),
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {
              // TODO: Implement audio call
              _logger.d('Audio call requested');
            },
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'block',
                child: Text('Block User'),
              ),
              const PopupMenuItem(
                value: 'report',
                child: Text('Report Conversation'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete Conversation'),
              ),
            ],
            onSelected: (value) {
              switch (value) {
                case 'block':
                  _showBlockUserDialog();
                  break;
                case 'report':
                  _showReportConversationDialog();
                  break;
                case 'delete':
                  _showDeleteConversationDialog();
                  break;
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: BlocBuilder<MessagingBloc, MessagingState>(
              builder: (context, state) {
                if (state.messagesStatus == MessagingStatus.loading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: PulseColors.primary,
                    ),
                  );
                }

                if (state.messagesStatus == MessagingStatus.error) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load messages',
                          style: PulseTextStyles.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.error ?? 'Unknown error occurred',
                          style: const TextStyle(fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        PulseButton(
                          text: 'Retry',
                          onPressed: () {
                            context.read<MessagingBloc>().add(
                              LoadMessages(conversationId: widget.conversation.id),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                }

                if (state.messagesStatus == MessagingStatus.loaded) {
                  final messages = state.currentMessages;
                  
                  if (messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: PulseColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chat_bubble_outline,
                              size: 60,
                              color: PulseColors.primary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Start your conversation',
                            style: PulseTextStyles.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Send a message to break the ice!',
                            style: PulseTextStyles.bodyMedium.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Stack(
                    children: [
                      ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length + 
                            (state.typingUsers.isNotEmpty ? 1 : 0),
                        itemBuilder: (context, index) {
                          // Show typing indicator as last item
                          if (index == messages.length && 
                              state.typingUsers.isNotEmpty) {
                            return const Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: TypingIndicator(),
                            );
                          }

                          final message = messages[index];
                          final isCurrentUser = message.senderId == 'current_user';
                          final showDateHeader = index == 0 || 
                              !_isSameDay(messages[index - 1].timestamp, message.timestamp);

                          return Column(
                            children: [
                              if (showDateHeader)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  child: Text(
                                    _formatDateHeader(message.timestamp),
                                    style: PulseTextStyles.bodySmall.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              MessageBubble(
                                message: message,
                                isCurrentUser: isCurrentUser,
                                onLongPress: () => _onMessageLongPress(message),
                              ),
                            ],
                          );
                        },
                      ),

                      // Scroll to bottom button
                      if (_showScrollToBottom)
                        Positioned(
                          bottom: 16,
                          right: 16,
                          child: FloatingActionButton.small(
                            backgroundColor: PulseColors.primary,
                            foregroundColor: Colors.white,
                            onPressed: () => _scrollToBottom(),
                            child: const Icon(Icons.keyboard_arrow_down),
                          ),
                        ),
                    ],
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),

          // Message input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: PulseColors.surface,
              border: Border(
                top: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: SafeArea(
              child: MessageInput(
                controller: _messageController,
                focusNode: _messageFocusNode,
                onSend: _sendMessage,
                onVoiceMessage: () {
                  // TODO: Implement voice message recording
                  _logger.d('Voice message requested');
                },
                onAttachment: () {
                  // TODO: Implement file attachment
                  _logger.d('Attachment requested');
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showBlockUserDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: Text('Block ${widget.conversation.otherUserName}? They won\'t be able to message you anymore.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<MessagingBloc>().add(
                BlockUser(userId: widget.conversation.otherUserId),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  void _showReportConversationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Conversation'),
        content: const Text('Report this conversation as inappropriate?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<MessagingBloc>().add(
                ReportConversation(
                  conversationId: widget.conversation.id,
                  reason: 'Inappropriate content',
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConversationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: const Text('Delete this conversation? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<MessagingBloc>().add(
                DeleteConversation(conversationId: widget.conversation.id),
              );
              Navigator.pop(context); // Go back to conversations list
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
