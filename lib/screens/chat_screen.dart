import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/chat_bloc.dart';
import '../data/models/chat_model.dart';
import '../data/models/message.dart'; // Import for MessageType that matches chat_bloc
import '../widgets/chat/enhanced_message_bubble.dart';
import '../widgets/chat/reply_input_widget.dart';
import '../widgets/chat/contextual_action_button.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String participantName;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.participantName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  MessageModel? _replyToMessage;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _textController.addListener(_onTextChanged);
    _scrollController.addListener(_onScrollChanged);
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMessages() {
    context.read<ChatBloc>().add(LoadMessages(
      conversationId: widget.conversationId,
    ));
  }

  void _onTextChanged() {
    final isTyping = _textController.text.trim().isNotEmpty;
    if (isTyping != _isTyping) {
      setState(() {
        _isTyping = isTyping;
      });
      
      context.read<ChatBloc>().add(UpdateTypingStatus(
        conversationId: widget.conversationId,
        isTyping: isTyping,
      ));
    }
  }

  void _onScrollChanged() {
    // Load more messages when scrolled to top
    if (_scrollController.position.pixels == 0) {
      // Load more messages
      final state = context.read<ChatBloc>().state;
      if (state is MessagesLoaded && state.hasMoreMessages) {
        // Calculate next page
        final currentPage = (state.messages.length / 50).ceil();
        context.read<ChatBloc>().add(LoadMessages(
          conversationId: widget.conversationId,
          page: currentPage + 1,
        ));
      }
    }
  }

  void _sendMessage() {
    final content = _textController.text.trim();
    if (content.isEmpty) return;

    context.read<ChatBloc>().add(SendMessage(
      conversationId: widget.conversationId,
      type: MessageType.text, // Using the correct MessageType from entities
      content: content,
      replyToMessageId: _replyToMessage?.id,
    ));

    _textController.clear();
    _cancelReply();
    _scrollToBottom();
  }

  void _setReplyToMessage(MessageModel message) {
    setState(() {
      _replyToMessage = message;
    });
  }

  void _cancelReply() {
    setState(() {
      _replyToMessage = null;
    });
  }

  void _scrollToMessage(String messageId) {
    // Find message index and scroll to it
    final state = context.read<ChatBloc>().state;
    if (state is MessagesLoaded) {
      final index = state.messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        _scrollController.animateTo(
          index * 100.0, // Approximate message height
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _performContextualAction(String actionId, String actionType, Map<String, dynamic> actionData) {
    context.read<ChatBloc>().add(PerformContextualAction(
      actionId: actionId,
      actionType: actionType,
      actionData: actionData,
    ));
  }

  void _editMessage(MessageModel message) {
    showDialog(
      context: context,
      builder: (context) => _EditMessageDialog(
        message: message,
        onSave: (newContent) {
          context.read<ChatBloc>().add(EditMessage(
            messageId: message.id,
            newContent: newContent,
          ));
        },
      ),
    );
  }

  void _deleteMessage(MessageModel message) {
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
              context.read<ChatBloc>().add(DeleteMessage(messageId: message.id));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _copyMessage(MessageModel message) {
    context.read<ChatBloc>().add(CopyMessage(messageId: message.id));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Message copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.participantName),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {
              // TODO: Implement video call
            },
          ),
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {
              // TODO: Implement voice call
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Implement chat settings
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<ChatBloc, ChatState>(
              listener: (context, state) {
                if (state is MessageSent) {
                  _scrollToBottom();
                } else if (state is ChatError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is ChatLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is MessagesLoaded) {
                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) {
                      final message = state.messages[state.messages.length - 1 - index];
                      final isCurrentUser = message.senderId == 'current_user_id'; // TODO: Get from auth

                      return EnhancedMessageBubble(
                        message: message,
                        isCurrentUser: isCurrentUser,
                        onReply: () => _setReplyToMessage(message),
                        onEdit: () => _editMessage(message),
                        onCopy: () => _copyMessage(message),
                        onDelete: () => _deleteMessage(message),
                        onTapReply: _scrollToMessage,
                        contextualActions: _buildContextualActions(message),
                      );
                    },
                  );
                }

                return const Center(
                  child: Text('Start a conversation!'),
                );
              },
            ),
          ),
          BlocBuilder<ChatBloc, ChatState>(
            builder: (context, state) {
              final isLoading = state is ChatLoading;
              
              return ReplyInputWidget(
                replyToMessage: _replyToMessage,
                textController: _textController,
                onSend: _sendMessage,
                onCancelReply: _cancelReply,
                isLoading: isLoading,
              );
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _buildContextualActions(MessageModel message) {
    // Only show contextual actions for AI messages
    if (message.senderId == 'ai_companion_id') { // TODO: Get from constants
      return [
        AIContextualActions.askQuestion(() {
          _performContextualAction(
            'ask_question_${DateTime.now().millisecondsSinceEpoch}',
            'ask_question',
            {'originalMessageId': message.id},
          );
        }),
        AIContextualActions.explainMore(() {
          _performContextualAction(
            'explain_more_${DateTime.now().millisecondsSinceEpoch}',
            'explain_more',
            {'originalMessageId': message.id},
          );
        }),
        AIContextualActions.getAdvice(() {
          _performContextualAction(
            'get_advice_${DateTime.now().millisecondsSinceEpoch}',
            'get_advice',
            {'originalMessageId': message.id},
          );
        }),
      ];
    }
    return [];
  }
}

class _EditMessageDialog extends StatefulWidget {
  final MessageModel message;
  final ValueChanged<String> onSave;

  const _EditMessageDialog({
    required this.message,
    required this.onSave,
  });

  @override
  State<_EditMessageDialog> createState() => _EditMessageDialogState();
}

class _EditMessageDialogState extends State<_EditMessageDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.message.content ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Message'),
      content: TextField(
        controller: _controller,
        maxLines: null,
        keyboardType: TextInputType.multiline,
        decoration: const InputDecoration(
          hintText: 'Enter your message...',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final newContent = _controller.text.trim();
            if (newContent.isNotEmpty && newContent != widget.message.content) {
              widget.onSave(newContent);
            }
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}