import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../blocs/messaging/messaging_bloc.dart';
import '../../theme/pulse_colors.dart';
import '../../widgets/chat/message_bubble.dart';
import '../../widgets/chat/message_input.dart';
import '../../widgets/chat/typing_indicator.dart';
import '../../../domain/entities/message.dart';
import '../../../domain/entities/conversation.dart';

class ChatScreen extends StatefulWidget {
  final Conversation conversation;

  const ChatScreen({
    super.key,
    required this.conversation,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    
    // Load messages for this conversation
    context.read<MessagingBloc>().add(
      LoadMessages(conversationId: widget.conversation.id),
    );
    
    // Mark conversation as read
    context.read<MessagingBloc>().add(
      MarkConversationAsRead(conversationId: widget.conversation.id),
    );
    
    // Auto-scroll to bottom when keyboard appears
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    // Load more messages when scrolled to top
    if (_scrollController.position.pixels == 
        _scrollController.position.maxScrollExtent) {
      context.read<MessagingBloc>().add(
        LoadMessages(conversationId: widget.conversation.id),
      );
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    context.read<MessagingBloc>().add(
      SendMessage(
        conversationId: widget.conversation.id,
        senderId: 'current_user_id', // TODO: Get actual current user ID from auth service
        content: text,
        type: MessageType.text,
      ),
    );

    _messageController.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<MessagingBloc, MessagingState>(
              listener: (context, state) {
                if (state.messagesStatus == MessagingStatus.loaded) {
                  _scrollToBottom();
                }
              },
              builder: (context, state) {
                return _buildMessagesList(state);
              },
            ),
          ),
          _buildTypingIndicator(),
          MessageInput(
            controller: _messageController,
            onSend: _sendMessage,
            onTyping: () {
              // TODO: Implement typing indicator
            },
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black87),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: widget.conversation.otherUser?.photos.isNotEmpty == true
                ? CachedNetworkImageProvider(widget.conversation.otherUser!.photos.first.url)
                : null,
            child: widget.conversation.otherUser?.photos.isEmpty != false
                ? Text(
                    widget.conversation.otherUser?.name[0].toUpperCase() ?? '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.conversation.otherUser?.name ?? 'Unknown User',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (widget.conversation.otherUser?.isOnline == true)
                  const Text(
                    'Online',
                    style: TextStyle(
                      color: PulseColors.success,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.videocam, color: Colors.black87),
          onPressed: () {
            // TODO: Start video call
          },
        ),
        IconButton(
          icon: const Icon(Icons.call, color: Colors.black87),
          onPressed: () {
            // TODO: Start voice call
          },
        ),
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.black87),
          onPressed: () {
            // TODO: Show chat options
          },
        ),
      ],
    );
  }

  Widget _buildMessagesList(MessagingState state) {
    if (state.messagesStatus == MessagingStatus.loading && state.messages.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(PulseColors.primary),
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
              color: Colors.grey,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              state.error ?? 'Failed to load messages',
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<MessagingBloc>().add(
                  LoadMessages(conversationId: widget.conversation.id),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: PulseColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.messages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              color: Colors.grey,
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              'No messages yet',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Send a message to start the conversation!',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: state.messages.length + (state.hasReachedMaxMessages ? 0 : 1),
      itemBuilder: (context, index) {
        if (index == state.messages.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(PulseColors.primary),
              ),
            ),
          );
        }

        final message = state.messages[index];
        final isCurrentUser = message.senderId == 'current_user_id'; // TODO: Get from auth
        
        return MessageBubble(
          message: message,
          isCurrentUser: isCurrentUser,
        );
      },
    );
  }

  Widget _buildTypingIndicator() {
    return BlocBuilder<MessagingBloc, MessagingState>(
      builder: (context, state) {
        // Check if other user is typing
        final isOtherUserTyping = state.isUserTyping(widget.conversation.otherUserId);
        if (isOtherUserTyping) {
          return const TypingIndicator();
        }
        return const SizedBox.shrink();
      },
    );
  }
}
