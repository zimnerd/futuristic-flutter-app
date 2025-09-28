import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../blocs/chat_bloc.dart';
import '../../../data/models/chat_model.dart';
import '../../../data/services/service_locator.dart';
import '../../../services/media_upload_service.dart' as media_service;
import '../../../domain/entities/message.dart' show MessageType;
import '../../../presentation/blocs/auth/auth_bloc.dart';
import '../../../presentation/blocs/auth/auth_state.dart';
import '../../../data/models/user_model.dart';
import '../../../core/utils/logger.dart';
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
    AppLogger.debug('ChatScreen initialized with:');
    AppLogger.debug('  conversationId: ${widget.conversationId}');
    AppLogger.debug('  otherUserId: ${widget.otherUserId}');
    AppLogger.debug('  otherUserName: ${widget.otherUserName}');
    
    // Check if this is a new conversation that needs to be created
    if (widget.conversationId == 'new') {
      _createNewConversation();
    } else {
      // Load latest messages for existing conversation (fast cache response)
      context.read<ChatBloc>().add(
        LoadLatestMessages(conversationId: widget.conversationId),
      );

      // ✅ We'll mark as read later only if there are actually unread messages
      // This will be handled when we receive MessagesLoaded state
    }
    
    // Auto-scroll to bottom when keyboard appears
    _scrollController.addListener(_scrollListener);
  }

  /// Create a new conversation with the other user
  void _createNewConversation() async {
    AppLogger.debug(
      'Creating new conversation with otherUserId: ${widget.otherUserId}',
    );
    
    if (widget.otherUserId.isEmpty || widget.otherUserId == 'current_user_id') {
      // Handle error - no valid other user ID provided
      AppLogger.warning('Error: Invalid otherUserId: ${widget.otherUserId}');
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

    final currentUserId = _currentUserId;
    AppLogger.debug('Sending message with currentUserId: $currentUserId');

    context.read<ChatBloc>().add(
      SendMessage(
        conversationId: widget.conversationId,
        type: MessageType.text,
        content: text,
        currentUserId: currentUserId,
      ),
    );

    _messageController.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
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
                  AppLogger.debug(
                    'ChatScreen BlocConsumer listener - State: ${state.runtimeType}',
                  );
                
                if (state is MessagesLoaded) {
                    AppLogger.debug(
                      'ChatScreen - MessagesLoaded with ${state.messages.length} messages',
                    );
                  _scrollToBottom();
                  
                    // ✅ Only mark as read if we haven't done so yet and there are unread messages
                    if (!_hasMarkedAsRead && _currentUserId != null) {
                      // Check if there are any unread messages from the other user
                      final unreadMessages = state.messages
                          .where(
                            (message) =>
                                message.senderId != _currentUserId &&
                                message.status != MessageStatus.read,
                          )
                          .toList();

                      if (unreadMessages.isNotEmpty) {
                        context.read<ChatBloc>().add(
                          MarkConversationAsRead(
                            conversationId: widget.conversationId,
                          ),
                        );
                        _hasMarkedAsRead = true;
                        AppLogger.debug(
                          'ChatScreen - Marked conversation as read (${unreadMessages.length} unread messages)',
                        );
                      } else {
                        AppLogger.debug(
                          'ChatScreen - No unread messages, skipping mark as read',
                        );
                      }
                    }
                } else if (state is ConversationCreated) {
                    AppLogger.debug(
                      'ChatScreen - ConversationCreated: ${state.conversation.id}',
                    );
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
                  } else if (state is MessageSent) {
                    AppLogger.debug(
                      'ChatScreen - MessageSent: ${state.message.id}',
                    );
                    // Note: MessageSent should rarely occur if we're in MessagesLoaded state
                    _scrollToBottom();
                  } else if (state is ChatError) {
                    AppLogger.error('ChatScreen - ChatError: ${state.message}');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.red,
                      ),
                    );
                }
              },
              builder: (context, state) {
                  AppLogger.debug(
                    'UI Builder called with state: ${state.runtimeType}',
                  );
                  if (state is MessagesLoaded) {
                    AppLogger.debug(
                      'UI Builder - MessagesLoaded with ${state.messages.length} messages',
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
            colors: [PulseColors.primary, PulseColors.primary.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
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
                              color: Colors.black.withValues(alpha: 0.2),
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
                                  color: PulseColors.primary.withValues(alpha: 0.3),
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
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.otherUserProfile!.bio?.isNotEmpty == true)
                            Text(
                              widget.otherUserProfile!.bio!,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                        ] else
                          Text(
                            'Active now',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
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
                          value: 'unmatch',
                          child: Row(
                            children: [
                              Icon(
                                Icons.heart_broken,
                                size: 20,
                                color: Colors.red,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Unmatch',
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
    AppLogger.debug(
      '_buildMessagesList called with state: ${state.runtimeType}',
    );
    
    if (state is ChatLoading) {
      AppLogger.debug('_buildMessagesList - Showing loading indicator');
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(PulseColors.primary),
        ),
      );
    }

    if (state is ChatError) {
      AppLogger.error('_buildMessagesList - Showing error: ${state.message}');
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
                  LoadLatestMessages(conversationId: widget.conversationId),
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
      AppLogger.debug(
        '_buildMessagesList - MessagesLoaded with ${state.messages.length} messages',
      );
      
      if (state.messages.isEmpty) {
        AppLogger.debug('_buildMessagesList - Showing empty state');
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

      return RefreshIndicator(
        onRefresh: () async {
          context.read<ChatBloc>().add(
            RefreshMessages(conversationId: widget.conversationId),
          );

          // Wait for refresh to complete
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: NotificationListener<ScrollNotification>(
          onNotification: (scrollNotification) {
            // Check if user scrolled to the bottom (where older messages are)
            if (scrollNotification.metrics.pixels >=
                    scrollNotification.metrics.maxScrollExtent * 0.9 &&
                state.hasMoreMessages &&
                !state.isLoadingMore) {
              AppLogger.debug(
                'Loading more messages - user scrolled to bottom',
              );

              // Get the oldest message ID for pagination
              final oldestMessageId = state.messages.isNotEmpty
                  ? state.messages.last.id
                  : null;

              context.read<ChatBloc>().add(
                LoadMoreMessages(
                  conversationId: widget.conversationId,
                  oldestMessageId: oldestMessageId,
                ),
              );
            }
            return false;
          },
          child: ListView.builder(
            controller: _scrollController,
            reverse: true,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount:
                state.messages.length +
                (state.hasMoreMessages
                    ? 1
                    : 0) + // Add loading indicator at bottom
                (state.isRefreshing ? 1 : 0), // Add refresh indicator at top
            itemBuilder: (context, index) {
              // Show refresh indicator at top (index 0 in reverse list)
              if (state.isRefreshing && index == 0) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Refreshing...',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Adjust index for refresh indicator
              final messageIndex = state.isRefreshing ? index - 1 : index;

              // Show load more indicator at bottom (last index in reverse list)
              if (state.hasMoreMessages &&
                  messageIndex >= state.messages.length) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: state.isLoadingMore
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Loading more messages...',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          )
                        : GestureDetector(
                            onTap: () {
                              AppLogger.debug(
                                'Manual load more messages triggered',
                              );
                              final oldestMessageId = state.messages.isNotEmpty
                                  ? state.messages.last.id
                                  : null;

                              context.read<ChatBloc>().add(
                                LoadMoreMessages(
                                  conversationId: widget.conversationId,
                                  oldestMessageId: oldestMessageId,
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Tap to load older messages',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                  ),
                );
              }

              // Regular message item
              if (messageIndex < state.messages.length) {
                final message = state.messages[messageIndex];
                final currentUserId = _currentUserId;
                final isCurrentUser =
                    currentUserId != null && message.senderId == currentUserId;

                AppLogger.debug(
                  '_buildMessagesList - Message ${message.id}: senderId=${message.senderId}, currentUserId=$currentUserId, isCurrentUser=$isCurrentUser, content="${message.content}", status=${message.status}',
                );

                return MessageBubble(
                  message: message,
                  isCurrentUser: isCurrentUser,
                  currentUserId: currentUserId,
                  onLongPress: () => _onLongPress(message),
                  onReaction: (emoji) => _onReaction(message, emoji),
                  onReply: () => _onReply(message),
                  onMediaTap: () => _onMediaTap(message),
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      );
    }

    // Handle MessageSent state for fresh conversations
    if (state is MessageSent) {
      AppLogger.debug(
        '_buildMessagesList - MessageSent for fresh conversation, showing single message: ${state.message.id}',
      );

      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                reverse: true,
                children: [
                  MessageBubble(
                    message: state.message,
                    isCurrentUser:
                        true, // MessageSent is always from current user
                    currentUserId: _currentUserId ?? '',
                    onLongPress: () => _onLongPress(state.message),
                    onReaction: (emoji) => _onReaction(state.message, emoji),
                    onReply: () => _onReply(state.message),
                    onMediaTap: () => _onMediaTap(state.message),
                  ),
                ],
              ),
            ),
          ],
        ),
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
      case 'unmatch':
        _showUnmatchDialog(context);
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

  void _showUnmatchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unmatch User'),
        content: Text(
          'Are you sure you want to unmatch with ${widget.otherUserName}? This will remove them from your matches and delete this conversation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Implement unmatch functionality
              Navigator.pop(context);
              // Close the chat screen and go back
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Unmatched with ${widget.otherUserName}'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Unmatch'),
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

  void _handleCameraAction() async {
    try {
      AppLogger.debug('Opening camera for photo capture');

      final picker = ImagePicker();
      final imageFile = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (imageFile != null) {
        AppLogger.debug('Image captured from camera: ${imageFile.path}');
        await _sendImageMessage(File(imageFile.path));
      } else {
        AppLogger.debug('Camera capture cancelled by user');
      }
    } catch (e) {
      AppLogger.error('Error capturing image from camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to capture image. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleGalleryAction() async {
    try {
      AppLogger.debug('Opening gallery for photo selection');

      final picker = ImagePicker();
      final imageFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (imageFile != null) {
        AppLogger.debug('Image selected from gallery: ${imageFile.path}');
        await _sendImageMessage(File(imageFile.path));
      } else {
        AppLogger.debug('Gallery selection cancelled by user');
      }
    } catch (e) {
      AppLogger.error('Error selecting image from gallery: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to select image. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleVoiceAction() {
    // Handle voice message recording
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Voice message feature will be implemented'),
      ),
    );
  }

  Future<void> _sendImageMessage(File imageFile) async {
    try {
      AppLogger.debug('Preparing to send image message: ${imageFile.path}');

      // Don't allow sending messages to "new" conversation
      if (widget.conversationId == 'new') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please wait for conversation to be created'),
          ),
        );
        return;
      }

      final currentUserId = _currentUserId;
      if (currentUserId == null) {
        AppLogger.warning('Cannot send image - no current user ID');
        return;
      }

      AppLogger.debug(
        'Sending image message with currentUserId: $currentUserId',
      );

      // Show uploading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('Uploading image...'),
              ],
            ),
            duration: Duration(seconds: 30),
          ),
        );
      }

      // Upload image using MediaUploadService
      final mediaUploadService = ServiceLocator().mediaUploadService;
      final uploadResult = await mediaUploadService.uploadMedia(
        filePath: imageFile.path,
        category: media_service.MediaCategory.chatMessage,
        type: media_service.MediaType.image,
        isPublic: false,
        requiresModeration: false,
      );

      if (uploadResult.success && uploadResult.mediaId != null) {
        AppLogger.debug('Image uploaded successfully: ${uploadResult.mediaId}');

        // Send message with uploaded media
        context.read<ChatBloc>().add(
          SendMessage(
            conversationId: widget.conversationId,
            type: MessageType.image,
            content: '', // No text content for image messages
            currentUserId: currentUserId,
            mediaIds: [uploadResult.mediaId!],
          ),
        );

        _scrollToBottom();

        // Show success feedback
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image sent successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception('Upload failed: ${uploadResult.error ?? "Unknown error"}');
      }
    } catch (e) {
      AppLogger.error('Error sending image message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showMessageOptions(BuildContext context, MessageModel message) {
    final currentUserId = _currentUserId;
    final isMyMessage = currentUserId != null && message.senderId == currentUserId;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            // Quick reactions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  '❤️', '😂', '😢', '😡', '👍', '👎'
                ].map((emoji) => GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _addReaction(message.id, emoji);
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                )).toList(),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Action options
            _buildOptionTile(
              icon: Icons.reply,
              title: 'Reply',
              onTap: () {
                Navigator.pop(context);
                _replyToMessage(message);
              },
            ),
            _buildOptionTile(
              icon: Icons.copy,
              title: 'Copy',
              onTap: () {
                Navigator.pop(context);
                _copyMessage(message);
              },
            ),
            if (message.type == MessageType.image ||
                message.type == MessageType.video ||
                message.type == MessageType.gif) 
              _buildOptionTile(
                icon: Icons.download,
                title: 'Save to Gallery',
                onTap: () {
                  Navigator.pop(context);
                  _saveMedia(message);
                },
              ),
            _buildOptionTile(
              icon: Icons.forward,
              title: 'Forward',
              onTap: () {
                Navigator.pop(context);
                _forwardMessage(message);
              },
            ),
            if (isMyMessage) ...[
              _buildOptionTile(
                icon: Icons.edit,
                title: 'Edit',
                onTap: () {
                  Navigator.pop(context);
                  _editMessage(message);
                },
              ),
              _buildOptionTile(
                icon: Icons.delete,
                title: 'Delete',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(message);
                },
              ),
            ] else ...[
              _buildOptionTile(
                icon: Icons.report,
                title: 'Report',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  _reportMessage(message);
                },
              ),
            ],
            
            SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.grey[700]),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  void _addReaction(String messageId, String emoji) {
    // Add reaction logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added reaction: $emoji')),
    );
  }

  void _replyToMessage(MessageModel message) {
    // Set reply context
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Replying to: ${message.content ?? "message"}')),
    );
  }

  void _openMedia(MessageModel message) {
    if (message.mediaUrls?.isNotEmpty == true) {
      // Open media viewer
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Opening media viewer...')),
      );
    }
  }

  void _copyMessage(MessageModel message) {
    if (message.content?.isNotEmpty == true) {
      Clipboard.setData(ClipboardData(text: message.content!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message copied to clipboard')),
      );
    }
  }

  void _saveMedia(MessageModel message) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saving media to gallery...')),
    );
  }

  void _forwardMessage(MessageModel message) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Forward feature will be implemented')),
    );
  }

  void _editMessage(MessageModel message) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit feature will be implemented')),
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Message deleted')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _reportMessage(MessageModel message) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report feature will be implemented')),
    );
  }

  // Callback methods for MessageBubble
  void _onLongPress(MessageModel message) {
    _showMessageOptions(context, message);
  }

  void _onReaction(MessageModel message, String emoji) {
    // Add reaction to message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added reaction: $emoji')),
    );
  }

  void _onReply(MessageModel message) {
    // Set reply-to message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reply feature coming soon')),
    );
  }

  void _onMediaTap(MessageModel message) {
    _openMedia(message);
  }
}
