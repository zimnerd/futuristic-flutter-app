import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../blocs/chat_bloc.dart';
import '../../../blocs/call_bloc.dart';
import '../../../presentation/blocs/auth/auth_bloc.dart';
import '../../../presentation/blocs/auth/auth_state.dart';
import '../../theme/pulse_colors.dart';
import '../../widgets/chat/message_bubble_new.dart';
import '../../widgets/chat/message_input_new.dart';
import '../../../data/models/call_model.dart';
import '../../../data/models/chat_model.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhoto;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhoto,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  
  String? get _currentUserId {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      return authState.user.id;
    }
    return null;
  }
  
  @override
  void initState() {
    super.initState();
    
    // Load messages for this conversation
    context.read<ChatBloc>().add(
      LoadMessages(conversationId: widget.conversationId),
    );
    
    // TODO: Mark conversation as read (not implemented in current bloc)
    // context.read<ChatBloc>().add(
    //   MarkChatAsRead(conversationId: widget.conversationId),
    // );
    
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
      context.read<ChatBloc>().add(
        LoadMessages(conversationId: widget.conversationId),
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

    context.read<ChatBloc>().add(
      SendMessage(
        conversationId: widget.conversationId,
        type: MessageType.text,
        content: text,
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
            child: BlocConsumer<ChatBloc, ChatState>(
              listener: (context, state) {
                if (state is MessagesLoaded) {
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
            backgroundImage: widget.otherUserPhoto != null
                ? CachedNetworkImageProvider(widget.otherUserPhoto!)
                : null,
            child: widget.otherUserPhoto == null
                ? Text(
                    widget.otherUserName[0].toUpperCase(),
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
                  widget.otherUserName,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Text(
                  'Online',
                  style: TextStyle(color: PulseColors.success, fontSize: 12),
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
            context.read<CallBloc>().add(
              InitiateCall(
                receiverId: widget.otherUserId,
                receiverName: widget.otherUserName,
                receiverAvatar: widget.otherUserPhoto,
                callType: CallType.video,
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.call, color: Colors.black87),
          onPressed: () {
            context.read<CallBloc>().add(
              InitiateCall(
                receiverId: widget.otherUserId,
                receiverName: widget.otherUserName,
                receiverAvatar: widget.otherUserPhoto,
                callType: CallType.audio,
              ),
            );
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

  Widget _buildMessagesList(ChatState state) {
    if (state is ChatLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(PulseColors.primary),
        ),
      );
    }

    if (state is ChatError) {
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
              state.message,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<ChatBloc>().add(
                  LoadMessages(conversationId: widget.conversationId),
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

    if (state is MessagesLoaded) {
      if (state.messages.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_bubble_outline, color: Colors.grey, size: 64),
              SizedBox(height: 16),
              Text(
                'No messages yet',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'Send a message to start the conversation!',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        controller: _scrollController,
        reverse: true,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: state.messages.length,
        itemBuilder: (context, index) {
          final message = state.messages[index];
          final currentUserId = _currentUserId;
          final isCurrentUser =
              currentUserId != null && message.senderId == currentUserId;

          return MessageBubble(message: message, isCurrentUser: isCurrentUser);
        },
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildTypingIndicator() {
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        // TODO: Implement typing indicator when available in state
        return const SizedBox.shrink();
      },
    );
  }
}
