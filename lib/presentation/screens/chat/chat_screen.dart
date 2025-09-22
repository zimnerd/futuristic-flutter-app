import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../../blocs/chat_bloc.dart';
import '../../../data/models/message.dart' as msg;
import '../../../presentation/blocs/auth/auth_bloc.dart';
import '../../../presentation/blocs/auth/auth_state.dart';
import '../../../data/models/user_model.dart';
import '../../theme/pulse_colors.dart';
import '../../widgets/chat/message_bubble.dart';
import '../../widgets/chat/ai_message_input.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhoto;
  final UserModel? otherUserProfile;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhoto,
    this.otherUserProfile,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  Timer? _typingTimer;
  bool _isCurrentlyTyping = false;
  bool _hasMarkedAsRead =
      false; // Track if we've already marked this conversation as read
  
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
    
    // Debug information
    print('ChatScreen initialized with:');
    print('  conversationId: ${widget.conversationId}');
    print('  otherUserId: ${widget.otherUserId}');
    print('  otherUserName: ${widget.otherUserName}');
    
    // Check if this is a new conversation that needs to be created
    if (widget.conversationId == 'new') {
      _createNewConversation();
    } else {
      // Load messages for existing conversation
      context.read<ChatBloc>().add(
        LoadMessages(conversationId: widget.conversationId),
      );

      // ✅ We'll mark as read later only if there are actually unread messages
      // This will be handled when we receive MessagesLoaded state
    }
    
    // Auto-scroll to bottom when keyboard appears
    _scrollController.addListener(_scrollListener);
  }

  /// Create a new conversation with the other user
  void _createNewConversation() async {
    print('Creating new conversation with otherUserId: ${widget.otherUserId}');
    
    if (widget.otherUserId.isEmpty || widget.otherUserId == 'current_user_id') {
      // Handle error - no valid other user ID provided
      print('Error: Invalid otherUserId: ${widget.otherUserId}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Cannot create conversation - invalid user ID'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.of(context).pop(); // Go back
      return;
    }
    
    // Dispatch the create conversation event
    context.read<ChatBloc>().add(
      CreateConversation(participantId: widget.otherUserId),
    );
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

    // Don't allow sending messages to "new" conversation
    if (widget.conversationId == 'new') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for conversation to be created'),
        ),
      );
      return;
    }

    context.read<ChatBloc>().add(
      SendMessage(
        conversationId: widget.conversationId,
        type: msg.MessageType.text,
        content: text,
      ),
    );

    _messageController.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (didPop) {
        // Clean up when leaving chat screen
        if (_typingTimer?.isActive == true) {
          _typingTimer?.cancel();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(),
        body: Column(
        children: [
          Expanded(
            child: BlocConsumer<ChatBloc, ChatState>(
              listener: (context, state) {
                if (state is MessagesLoaded) {
                  _scrollToBottom();
                  
                    // ✅ Only mark as read if we haven't done so yet and there are unread messages
                    if (!_hasMarkedAsRead && _currentUserId != null) {
                      // Check if there are any unread messages from the other user
                      final unreadMessages = state.messages
                          .where(
                            (message) =>
                                message.senderId != _currentUserId &&
                                message.status != msg.MessageStatus.read,
                          )
                          .toList();

                      if (unreadMessages.isNotEmpty) {
                        context.read<ChatBloc>().add(
                          MarkConversationAsRead(
                            conversationId: widget.conversationId,
                          ),
                        );
                        _hasMarkedAsRead = true;
                        print(
                          '🐛 ChatScreen - Marked conversation as read (${unreadMessages.length} unread messages)',
                        );
                      } else {
                        print(
                          '🐛 ChatScreen - No unread messages, skipping mark as read',
                        );
                      }
                    }
                } else if (state is ConversationCreated) {
                  // Navigate to the actual conversation ID
                  final realConversationId = state.conversation.id;

                  // Replace current route with real conversation ID
                  context.go(
                    '/chat/$realConversationId',
                    extra: {
                      'otherUserId': widget.otherUserId,
                      'otherUserName': widget.otherUserName,
                      'otherUserPhoto': widget.otherUserPhoto,
                      'otherUserProfile': widget.otherUserProfile,
                    },
                  );
                }
              },
              builder: (context, state) {
                  print(
                    '🐛 UI Builder called with state: ${state.runtimeType}',
                  );
                  if (state is MessagesLoaded) {
                    print(
                      '🐛 UI Builder - MessagesLoaded with ${state.messages.length} messages',
                    );
                  }
                return _buildMessagesList(state);
              },
            ),
          ),
          _buildTypingIndicator(),
          AiMessageInput(
            controller: _messageController,
            chatId: widget.conversationId,
            onSend: _sendMessage,
            onCamera: _handleCameraAction,
            onGallery: _handleGalleryAction,
            onVoice: _handleVoiceAction,
            onTyping: () {
              // Debounce typing status to avoid spam
              // Only send typing_start if we're not already typing
              if (!_isCurrentlyTyping) {
                _isCurrentlyTyping = true;
                context.read<ChatBloc>().add(
                  UpdateTypingStatus(
                    conversationId: widget.conversationId,
                    isTyping: true,
                  ),
                );
              }

              // Reset the stop typing timer
              _typingTimer?.cancel();
              _typingTimer = Timer(const Duration(seconds: 2), () {
                if (_isCurrentlyTyping) {
                  _isCurrentlyTyping = false;
                  context.read<ChatBloc>().add(
                    UpdateTypingStatus(
                      conversationId: widget.conversationId,
                      isTyping: false,
                    ),
                  );
                }
              });
            },
          ),
        ],
      ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [PulseColors.primary, PulseColors.primary.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Back button
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),

                // Profile avatar with online indicator
                GestureDetector(
                  onTap: () => _viewFullProfile(context),
                  child: Stack(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: widget.otherUserPhoto != null
                              ? CachedNetworkImage(
                                  imageUrl: widget.otherUserPhoto!,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.person,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                        color: Colors.grey[300],
                                        child: const Icon(
                                          Icons.person,
                                          color: Colors.grey,
                                        ),
                                      ),
                                )
                              : Container(
                                  color: PulseColors.primary.withOpacity(0.3),
                                  child: Text(
                                    widget.otherUserName[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      // Online indicator
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: PulseColors.success,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // User info
                Expanded(
                  child: GestureDetector(
                    onTap: () => _viewFullProfile(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.otherUserName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        if (widget.otherUserProfile != null) ...[
                          Text(
                            '${widget.otherUserProfile!.age ?? 'Unknown'} • ${widget.otherUserProfile!.location ?? 'Location unknown'}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.otherUserProfile!.bio?.isNotEmpty == true)
                            Text(
                              widget.otherUserProfile!.bio!,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                        ] else
                          Text(
                            'Active now',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Action buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _initiateCall(context, false),
                      icon: const Icon(
                        Icons.phone,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _initiateCall(context, true),
                      icon: const Icon(
                        Icons.videocam,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert,
                        color: Colors.white,
                        size: 22,
                      ),
                      onSelected: (value) => _handleMenuAction(context, value),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'profile',
                          child: Row(
                            children: [
                              Icon(Icons.person, size: 20),
                              SizedBox(width: 12),
                              Text('View Profile'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'block',
                          child: Row(
                            children: [
                              Icon(Icons.block, size: 20, color: Colors.red),
                              SizedBox(width: 12),
                              Text(
                                'Block User',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'report',
                          child: Row(
                            children: [
                              Icon(
                                Icons.report,
                                size: 20,
                                color: Colors.orange,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Report User',
                                style: TextStyle(color: Colors.orange),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessagesList(ChatState state) {
    print('🐛 _buildMessagesList called with state: ${state.runtimeType}');
    
    if (state is ChatLoading) {
      print('🐛 _buildMessagesList - Showing loading indicator');
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(PulseColors.primary),
        ),
      );
    }

    if (state is ChatError) {
      print('🐛 _buildMessagesList - Showing error: ${state.message}');
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
      print(
        '🐛 _buildMessagesList - MessagesLoaded with ${state.messages.length} messages',
      );
      
      if (state.messages.isEmpty) {
        print('🐛 _buildMessagesList - Showing empty state');
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
        if (state is MessagesLoaded &&
            state.conversationId == widget.conversationId &&
            state.typingUsers.isNotEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundImage: widget.otherUserPhoto != null
                      ? CachedNetworkImageProvider(widget.otherUserPhoto!)
                      : null,
                  backgroundColor: PulseColors.primary,
                  child: widget.otherUserPhoto == null
                      ? Text(
                          widget.otherUserName[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  '${widget.otherUserName} is typing...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.grey[400]!,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _viewFullProfile(BuildContext context) {
    // Show a placeholder dialog since profile viewing needs to be implemented
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${widget.otherUserName}\'s Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.otherUserPhoto != null) ...[
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: CachedNetworkImageProvider(
                    widget.otherUserPhoto!,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (widget.otherUserProfile != null) ...[
              if (widget.otherUserProfile!.age != null)
                Text('Age: ${widget.otherUserProfile!.age}'),
              if (widget.otherUserProfile!.location != null)
                Text('Location: ${widget.otherUserProfile!.location}'),
              if (widget.otherUserProfile!.bio != null)
                Text('Bio: ${widget.otherUserProfile!.bio}'),
            ] else
              const Text('Profile information not available'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _initiateCall(BuildContext context, bool isVideo) {
    // Show a placeholder dialog since call functionality needs to be implemented
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isVideo ? 'Video Call' : 'Voice Call'),
        content: Text(
          '${isVideo ? 'Video' : 'Voice'} calling ${widget.otherUserName}...',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'profile':
        _viewFullProfile(context);
        break;
      case 'block':
        _showBlockDialog(context);
        break;
      case 'report':
        _showReportDialog(context);
        break;
    }
  }

  void _showBlockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: Text(
          'Are you sure you want to block ${widget.otherUserName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Implement block functionality
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${widget.otherUserName} has been blocked'),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report User'),
        content: Text(
          'Report ${widget.otherUserName} for inappropriate behavior?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Implement report functionality
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${widget.otherUserName} has been reported'),
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

  // ignore: unused_element
  void _showChatOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: Text('View ${widget.otherUserName}\'s Profile'),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to profile screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Opening ${widget.otherUserName}\'s profile',
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications_off),
                title: const Text('Mute Notifications'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notifications muted')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.block),
                title: Text('Block ${widget.otherUserName}'),
                onTap: () {
                  Navigator.pop(context);
                  _showBlockUserDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.report, color: Colors.red),
                title: const Text(
                  'Report User',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showReportUserDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Delete Conversation',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConversationDialog(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBlockUserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Block ${widget.otherUserName}?'),
          content: Text(
            'You won\'t receive messages from ${widget.otherUserName} anymore.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${widget.otherUserName} has been blocked'),
                  ),
                );
              },
              child: const Text('Block', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showReportUserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Report ${widget.otherUserName}'),
          content: const Text('Why are you reporting this user?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${widget.otherUserName} has been reported'),
                  ),
                );
              },
              child: const Text('Report', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConversationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Conversation'),
          content: const Text(
            'This conversation will be permanently deleted. This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context); // Close chat screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Conversation deleted')),
                );
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _handleCameraAction() {
    // Handle camera action - open camera for photo/video
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Camera feature will be implemented')),
    );
  }

  void _handleGalleryAction() {
    // Handle gallery action - open gallery for media selection
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gallery feature will be implemented')),
    );
  }

  void _handleVoiceAction() {
    // Handle voice message recording
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Voice message feature will be implemented'),
      ),
    );
  }
}
