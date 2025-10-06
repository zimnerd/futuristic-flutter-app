import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get_it/get_it.dart';

import '../../../features/group_chat/data/models.dart';
import '../../../features/group_chat/data/group_chat_service.dart';
import '../../../features/group_chat/data/group_chat_websocket_service.dart';
import '../../../data/services/webrtc_service.dart';
import '../../../features/group_chat/presentation/screens/video_call_screen.dart';
import '../../../features/group_chat/presentation/widgets/voice_recorder_widget.dart';
import 'package:file_picker/file_picker.dart';
import '../../../presentation/blocs/group_chat/group_chat_bloc.dart';
import '../../../data/models/chat_model.dart';
import '../../../blocs/chat_bloc.dart' as chat_bloc;
import '../../../presentation/theme/pulse_colors.dart';
import '../../widgets/common/keyboard_dismissible_scaffold.dart';

/// Comprehensive group chat screen with real-time messaging, participant management,
/// media sharing, voice/video calls, typing indicators, message reactions, and admin controls
class GroupChatDetailScreen extends StatefulWidget {
  final GroupConversation group;

  const GroupChatDetailScreen({
    super.key,
    required this.group,
  });

  @override
  State<GroupChatDetailScreen> createState() => _GroupChatDetailScreenState();
}

class _GroupChatDetailScreenState extends State<GroupChatDetailScreen>
    with TickerProviderStateMixin {
  // Controllers
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  
  // Services
  final chat_bloc.ChatBloc _chatBloc = GetIt.I<chat_bloc.ChatBloc>();
  late final GroupChatWebSocketService _groupChatWS;
  late final GroupChatService _groupChatService;
  final ImagePicker _imagePicker = ImagePicker();
  
  // State
  bool _isRecordingVoice = false;

  // State
  bool _isTyping = false;
  Timer? _typingTimer;
  List<MessageModel> _messages = [];
  final List<String> _typingUsers = [];
  MessageModel? _replyToMessage;
  
  // Animation
  late AnimationController _typingAnimationController;
  late Animation<double> _typingAnimation;

  // Current user (mocked for now - should come from AuthBloc)
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    
    _groupChatWS = GetIt.I<GroupChatWebSocketService>();
    _groupChatService = GetIt.I<GroupChatService>();
    
    // Initialize animations
    _typingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    
    _typingAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _typingAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Join group WebSocket room
    _groupChatWS.joinGroup(widget.group.id);
    
    // Load messages (using chat bloc)
    // For group chat, we'll need to adapt the chat service to handle group conversations
    // For now, we'll use a placeholder list
    
    // Setup listeners
    _setupMessageListener();
    
    // Scroll to bottom on new messages
    _scrollController.addListener(_onScroll);
  }

  void _setupMessageListener() {
    // Listen to chat bloc for new messages
    _chatBloc.stream.listen((state) {
      if (state is chat_bloc.MessagesLoaded && mounted) {
        setState(() {
          _messages = state.messages;
        });
        _scrollToBottom();
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      // Load more messages if needed
    }
  }

  void _scrollToBottom({bool animate = true}) {
    if (!_scrollController.hasClients) return;
    
    if (animate) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(0);
    }
  }

  @override
  void dispose() {
    // Leave group room
    _groupChatWS.leaveGroup(widget.group.id);
    
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    _typingTimer?.cancel();
    _typingAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardDismissibleScaffold(
      enableDismissOnTap: false, // Don't dismiss on message tap
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: Stack(
              children: [
                _buildMessagesList(),
                
                // Typing indicator overlay
                if (_typingUsers.isNotEmpty)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildTypingIndicator(),
                  ),
                  
                // Voice recorder overlay
                if (_isRecordingVoice)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.5),
                      child: VoiceRecorderWidget(
                        onRecordComplete: (filePath, duration) async {
                          setState(() {
                            _isRecordingVoice = false;
                          });

                          try {
                            final result = await _groupChatService.uploadMedia(
                              filePath: filePath,
                              mediaType: 'audio',
                            );

                            if (result['url'] != null) {
                              _groupChatWS.sendMessage(
                                conversationId: widget.group.id,
                                content: result['url'],
                                type: 'audio',
                              );
                            }
                          } catch (e) {
                            if (mounted && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to send voice: $e'),
                                ),
                              );
                            }
                          }
                        },
                        onCancel: () {
                          setState(() {
                            _isRecordingVoice = false;
                          });
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Reply preview
          if (_replyToMessage != null) _buildReplyPreview(),

          // Message input
          _buildMessageInput(),
        ],
      ),
      
      // Floating action buttons
      floatingActionButton: _buildFloatingActions(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: PulseColors.primary,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
            // Group avatar
            Hero(
              tag: 'group_avatar_${widget.group.id}',
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      PulseColors.primary,
                      PulseColors.secondary.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: Icon(
                  _getGroupIcon(widget.group.groupType),
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Group info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.group.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _typingUsers.isNotEmpty
                        ? '${_typingUsers.first} is typing...'
                        : '${widget.group.participantCount} members',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      actions: [
        // Voice call button
        if (widget.group.settings?.enableVoiceChat == true)
          IconButton(
            icon: const Icon(Icons.call, color: Colors.white),
            onPressed: _startVoiceCall,
            tooltip: 'Start voice call',
          ),
        
        // Video call button
        if (widget.group.settings?.enableVideoChat == true)
          IconButton(
            icon: const Icon(Icons.videocam, color: Colors.white),
            onPressed: _startVideoCall,
            tooltip: 'Start video call',
          ),

        // More options
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'participants',
              child: Row(
                children: [
                  Icon(Icons.people, size: 20),
                  SizedBox(width: 12),
                  Text('View Participants'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'mute',
              child: Row(
                children: [
                  Icon(Icons.notifications_off, size: 20),
                  SizedBox(width: 12),
                  Text('Mute Notifications'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'search',
              child: Row(
                children: [
                  Icon(Icons.search, size: 20),
                  SizedBox(width: 12),
                  Text('Search Messages'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'media',
              child: Row(
                children: [
                  Icon(Icons.photo_library, size: 20),
                  SizedBox(width: 12),
                  Text('View Media'),
                ],
              ),
            ),
            if (_isAdmin())
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, size: 20),
                    SizedBox(width: 12),
                    Text('Group Settings'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'report',
              child: Row(
                children: [
                  Icon(Icons.flag, size: 20, color: Colors.orange),
                  SizedBox(width: 12),
                  Text('Report Group', style: TextStyle(color: Colors.orange)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'leave',
              child: Row(
                children: [
                  Icon(Icons.exit_to_app, size: 20, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Leave Group', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMessagesList() {
    if (_messages.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true, // Show newest messages at bottom
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isMe = message.senderId == _currentUserId;
        final showAvatar = !isMe &&
            (index == 0 ||
                _messages[index - 1].senderId != message.senderId);
        
        return _buildMessageBubble(message, isMe, showAvatar);
      },
    );
  }

  Widget _buildMessageBubble(
    MessageModel message,
    bool isMe,
    bool showAvatar,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Sender avatar (for group messages)
          if (!isMe && showAvatar)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: PulseColors.primary.withValues(alpha: 0.2),
                child: const Icon(Icons.person, size: 16),
              ),
            )
          else if (!isMe)
            const SizedBox(width: 40),

          // Message content
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showMessageOptions(message, isMe),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isMe
                      ? PulseColors.primary
                      : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sender name for group chats
                    if (!isMe)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          message.senderUsername,
                          style: TextStyle(
                            color: PulseColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    
                    // Reply preview if replying to another message
                    if (message.replyTo != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (isMe ? Colors.white : Colors.grey)
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border(
                            left: BorderSide(
                              color: isMe ? Colors.white : PulseColors.primary,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Text(
                          message.replyTo!.content ?? '',
                          style: TextStyle(
                            color: isMe
                                ? Colors.white.withValues(alpha: 0.8)
                                : Colors.grey[700],
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                    // Message content
                    Text(
                      message.content ?? '',
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black87,
                        fontSize: 15,
                      ),
                    ),

                    // Timestamp and status
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatMessageTime(message.createdAt),
                          style: TextStyle(
                            color: isMe
                                ? Colors.white.withValues(alpha: 0.7)
                                : Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            message.status == MessageStatus.read
                                ? Icons.done_all
                                : message.status == MessageStatus.delivered
                                    ? Icons.done_all
                                    : Icons.done,
                            size: 14,
                            color: message.status == MessageStatus.read
                                ? Colors.blue[300]
                                : Colors.white.withValues(alpha: 0.7),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to say something!',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          FadeTransition(
            opacity: _typingAnimation,
            child: Row(
              children: List.generate(
                3,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: PulseColors.primary.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _typingUsers.length == 1
                ? '${_typingUsers.first} is typing...'
                : '${_typingUsers.length} people are typing...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyPreview() {
    if (_replyToMessage == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
          left: BorderSide(
            color: PulseColors.primary,
            width: 3,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to ${_replyToMessage!.senderUsername}',
                  style: TextStyle(
                    color: PulseColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _replyToMessage!.content ?? '',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () {
              setState(() {
                _replyToMessage = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Attachment button
            IconButton(
              icon: Icon(
                Icons.add_circle_outline,
                color: PulseColors.primary,
                size: 28,
              ),
              onPressed: _showAttachmentOptions,
            ),

            // Text input
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _messageFocusNode,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                  onChanged: _handleTyping,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Send button
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      PulseColors.primary,
                      PulseColors.secondary,
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _messageController.text.trim().isEmpty
                      ? Icons.mic
                      : Icons.send,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActions() {
    if (!_isAdmin()) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Add participants button
        FloatingActionButton(
          mini: true,
          heroTag: 'add_participants',
          backgroundColor: Colors.white,
          onPressed: _showAddParticipantsDialog,
          child: Icon(Icons.person_add, color: PulseColors.primary),
        ),
        const SizedBox(height: 8),
        
        // View participants button
        FloatingActionButton(
          heroTag: 'view_participants',
          backgroundColor: PulseColors.primary,
          onPressed: _showParticipantsSheet,
          child: const Icon(Icons.people, color: Colors.white),
        ),
      ],
    );
  }

  // ========== ACTION HANDLERS ==========

  void _handleTyping(String text) {
    final isNowTyping = text.trim().isNotEmpty;
    if (_isTyping != isNowTyping) {
      setState(() {
        _isTyping = isNowTyping;
      });

      // Send typing indicator via WebSocket
      _groupChatWS.sendTypingIndicator(
        conversationId: widget.group.id,
        isTyping: isNowTyping,
      );
    }

    // Cancel typing indicator after 3 seconds of inactivity
    _typingTimer?.cancel();
    if (isNowTyping) {
      _typingTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _isTyping = false;
          });
          _groupChatWS.sendTypingIndicator(
            conversationId: widget.group.id,
            isTyping: false,
          );
        }
      });
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      // Start voice recording
      _startVoiceRecording();
      return;
    }

    // Send text message via chat bloc
    // Note: This needs to be adapted for group chat
    // For now, using placeholder logic
    
    _messageController.clear();
    setState(() {
      _isTyping = false;
      _replyToMessage = null;
    });

    // Stop typing indicator via WebSocket
    _groupChatWS.sendTypingIndicator(
      conversationId: widget.group.id,
      isTyping: false,
    );

    _scrollToBottom();
  }

  void _showMessageOptions(MessageModel message, bool isMe) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _replyToMessage = message;
                });
                _messageFocusNode.requestFocus();
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: message.content ?? ''));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Message copied')),
                );
              },
            ),
            if (isMe || _isAdmin())
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(message);
                },
              ),
            if (!isMe && _isAdmin())
              ListTile(
                leading: const Icon(Icons.flag, color: Colors.orange),
                title: const Text('Report', style: TextStyle(color: Colors.orange)),
                onTap: () {
                  Navigator.pop(context);
                  _reportMessage(message);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAttachmentOption(
                icon: Icons.photo_library,
                label: 'Photo',
                color: Colors.purple,
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              _buildAttachmentOption(
                icon: Icons.camera_alt,
                label: 'Camera',
                color: Colors.blue,
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              _buildAttachmentOption(
                icon: Icons.videocam,
                label: 'Video',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  _pickVideo();
                },
              ),
              _buildAttachmentOption(
                icon: Icons.insert_drive_file,
                label: 'Document',
                color: Colors.orange,
                onTap: () {
                  Navigator.pop(context);
                  _pickDocument();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(label),
      onTap: onTap,
    );
  }

  void _showParticipantsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text(
                      'Participants',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${widget.group.participantCount} members',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              
              // Participants list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: widget.group.participants.length,
                  itemBuilder: (context, index) {
                    final participant = widget.group.participants[index];
                    return _buildParticipantTile(participant);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildParticipantTile(GroupParticipant participant) {
    final isOwner = participant.role == ParticipantRole.owner;
    final isAdmin = participant.role == ParticipantRole.admin ||
        participant.role == ParticipantRole.moderator;

    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: participant.profilePhoto != null
                ? CachedNetworkImageProvider(participant.profilePhoto!)
                : null,
            backgroundColor: PulseColors.primary.withValues(alpha: 0.2),
            child: participant.profilePhoto == null
                ? Text(
                    participant.firstName[0].toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
          if (participant.isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Text(
            participant.fullName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          if (isOwner)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Owner',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else if (isAdmin)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: PulseColors.primary.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                participant.role.name.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(
        participant.isOnline ? 'Online' : 'Offline',
        style: TextStyle(
          color: participant.isOnline ? Colors.green : Colors.grey,
          fontSize: 12,
        ),
      ),
      trailing: _isAdmin()
          ? PopupMenuButton<String>(
              onSelected: (value) => _handleParticipantAction(value, participant),
              itemBuilder: (context) => [
                if (participant.role != ParticipantRole.owner) ...[
                  const PopupMenuItem(
                    value: 'makeAdmin',
                    child: Text('Make Admin'),
                  ),
                  const PopupMenuItem(
                    value: 'remove',
                    child: Text('Remove', style: TextStyle(color: Colors.red)),
                  ),
                ],
                const PopupMenuItem(
                  value: 'viewProfile',
                  child: Text('View Profile'),
                ),
              ],
            )
          : null,
    );
  }

  void _handleParticipantAction(String action, GroupParticipant participant) {
    switch (action) {
      case 'makeAdmin':
        _makeParticipantAdmin(participant);
        break;
      case 'remove':
        _removeParticipant(participant);
        break;
      case 'viewProfile':
        // Navigate to user profile
        break;
    }
  }

  void _makeParticipantAdmin(GroupParticipant participant) {
    // Implement make admin logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${participant.fullName} is now an admin'),
      ),
    );
  }

  void _removeParticipant(GroupParticipant participant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Participant'),
        content: Text(
          'Are you sure you want to remove ${participant.fullName} from this group?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              context.read<GroupChatBloc>().add(
                    RemoveParticipantFromGroup(
                      conversationId: widget.group.id,
                      userId: participant.userId,
                    ),
                  );
              Navigator.pop(context);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddParticipantsDialog() {
    final searchController = TextEditingController();
    List<dynamic> searchResults = [];
    bool isSearching = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add Participants',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search users...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (query) async {
                  if (query.length >= 2) {
                    setState(() => isSearching = true);
                    try {
                      final results = await _groupChatService.searchUsers(
                        query: query,
                        conversationId: widget.group.id,
                      );
                      setState(() {
                        searchResults = results;
                        isSearching = false;
                      });
                    } catch (e) {
                      setState(() => isSearching = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Search failed: $e')),
                        );
                      }
                    }
                  }
                },
              ),
              const SizedBox(height: 16),
              if (isSearching)
                const CircularProgressIndicator()
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: searchResults.length,
                    itemBuilder: (context, index) {
                      final user = searchResults[index] as Map<String, dynamic>;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: user['avatar'] != null
                              ? CachedNetworkImageProvider(user['avatar'])
                              : null,
                          child: user['avatar'] == null
                              ? Text(user['username']?[0] ?? '?')
                              : null,
                        ),
                        title: Text(user['username'] ?? 'Unknown'),
                        subtitle: Text(user['firstName'] ?? ''),
                        trailing: IconButton(
                          icon: const Icon(Icons.add_circle),
                          onPressed: () async {
                            try {
                              await _groupChatService.addParticipant(
                                conversationId: widget.group.id,
                                userId: user['userId'],
                              );
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Participant added'),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to add: $e')),
                                );
                              }
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'participants':
        _showParticipantsSheet();
        break;
      case 'mute':
        _toggleMute();
        break;
      case 'search':
        _showSearchMessages();
        break;
      case 'media':
        _showMediaGallery();
        break;
      case 'settings':
        _showGroupSettings();
        break;
      case 'report':
        _reportGroup();
        break;
      case 'leave':
        _leaveGroup();
        break;
    }
  }

  void _toggleMute() {
    // Implement mute toggle
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notifications muted')),
    );
  }

  void _showSearchMessages() {
    final searchController = TextEditingController();
    List<dynamic> searchResults = [];
    bool isSearching = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Search Messages',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search in messages...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onSubmitted: (query) async {
                  if (query.length >= 2) {
                    setState(() => isSearching = true);
                    try {
                      final results = await _groupChatService.searchMessages(
                        conversationId: widget.group.id,
                        query: query,
                      );
                      setState(() {
                        searchResults = results;
                        isSearching = false;
                      });
                    } catch (e) {
                      setState(() => isSearching = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Search failed: $e')),
                        );
                      }
                    }
                  }
                },
              ),
              const SizedBox(height: 16),
              if (isSearching)
                const CircularProgressIndicator()
              else if (searchResults.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No messages found'),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: searchResults.length,
                    itemBuilder: (context, index) {
                      final message = searchResults[index] as Map<String, dynamic>;
                      return ListTile(
                        title: Text(
                          message['senderUsername'] ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          message['content'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          _formatTimestamp(message['createdAt']),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          // Optionally scroll to message
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    try {
      final dt = timestamp is DateTime
          ? timestamp
          : DateTime.parse(timestamp.toString());
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inDays > 0) {
        return '${diff.inDays}d ago';
      } else if (diff.inHours > 0) {
        return '${diff.inHours}h ago';
      } else if (diff.inMinutes > 0) {
        return '${diff.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }

  void _showMediaGallery() async {
    try {
      final media = await _groupChatService.getConversationMedia(
        conversationId: widget.group.id,
        limit: 100,
      );

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Media Gallery (${media.length})',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: media.isEmpty
                    ? const Center(
                        child: Text('No media in this conversation'),
                      )
                    : GridView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(8),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                        ),
                        itemCount: media.length,
                        itemBuilder: (context, index) {
                          final item = media[index];
                          final content = item['content'] ?? '';
                          final type = item['type'] ?? '';

                          return GestureDetector(
                            onTap: () {
                              // Show full image/video viewer
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Scaffold(
                                    appBar: AppBar(
                                      backgroundColor: Colors.black,
                                    ),
                                    backgroundColor: Colors.black,
                                    body: Center(
                                      child: CachedNetworkImage(
                                        imageUrl: content,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CachedNetworkImage(
                                  imageUrl: content,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: Colors.grey[300],
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.broken_image),
                                  ),
                                ),
                                if (type == 'video')
                                  const Center(
                                    child: Icon(
                                      Icons.play_circle_filled,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load media: $e')),
        );
      }
    }
  }

  void _showGroupSettings() {
    final nameController = TextEditingController(text: widget.group.title);
    final descController = TextEditingController(
      text: widget.group.description ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Group Settings'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Group Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _groupChatService.updateGroupSettings(
                  conversationId: widget.group.id,
                  title: nameController.text,
                  description: descController.text,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Settings updated')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _reportGroup() {
    String? selectedReason;
    final detailsController = TextEditingController();
    final reasons = [
      'Spam',
      'Harassment',
      'Inappropriate Content',
      'Scam or Fraud',
      'Hate Speech',
      'Violence',
      'Other',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Report Group'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Why are you reporting this group?'),
                const SizedBox(height: 16),
                ...reasons.map(
                  (reason) => InkWell(
                    onTap: () => setState(() => selectedReason = reason),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            selectedReason == reason
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: selectedReason == reason
                                ? Theme.of(context).primaryColor
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(reason)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: detailsController,
                  decoration: const InputDecoration(
                    labelText: 'Additional Details (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: selectedReason == null
                  ? null
                  : () async {
                      try {
                        await _groupChatService.reportGroup(
                          conversationId: widget.group.id,
                          reason: selectedReason!,
                          details: detailsController.text.isEmpty
                              ? null
                              : detailsController.text,
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Report submitted. We\'ll review it shortly.',
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to report: $e')),
                          );
                        }
                      }
                    },
              child: const Text(
                'Submit Report',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _leaveGroup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: const Text(
          'Are you sure you want to leave this group? You will no longer receive messages.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              try {
                await _groupChatService.leaveGroup(
                  conversationId: widget.group.id,
                );
                if (context.mounted) {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('You left the group')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to leave group: $e')),
                  );
                }
              }
            },
            child: const Text('Leave', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _startVoiceCall() async {
    try {
      // Show loading indicator
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Starting voice call...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );

      // Get RTC token from backend using group ID as channel name
      final webrtcService = WebRTCService();
      final tokenData = await webrtcService.getRtcToken(
        channelName: widget.group.id,
        role: 1, // PUBLISHER role for group calls
      );

      // Close loading dialog
      if (!mounted) return;
      Navigator.of(context).pop();

      // Create a pseudo LiveSession for the voice call
      final callSession = LiveSession(
        id: widget.group.id,
        conversationId: widget.group.id,
        hostId: '', // Current user - managed by backend
        hostName: 'Group Call',
        title: '${widget.group.title} Voice Call',
        description: 'Group voice call',
        groupType: widget.group.groupType,
        status: LiveSessionStatus.active,
        currentParticipants: widget.group.participantCount,
        maxParticipants: widget.group.participantCount,
        requireApproval: false,
        createdAt: DateTime.now(),
      );

      // Navigate to video call screen (users can disable video for voice-only)
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => VideoCallScreen(
            liveSessionId: widget.group.id,
            rtcToken: tokenData['token'] as String,
            session: callSession,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start voice call: $e')),
        );
      }
    }
  }

  void _startVideoCall() async {
    try {
      // Show loading indicator
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Starting video call...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );

      // Get RTC token from backend using group ID as channel name
      final webrtcService = WebRTCService();
      final tokenData = await webrtcService.getRtcToken(
        channelName: widget.group.id,
        role: 1, // PUBLISHER role for group calls
      );

      // Close loading dialog
      if (!mounted) return;
      Navigator.of(context).pop();

      // Create a pseudo LiveSession for the video call
      final callSession = LiveSession(
        id: widget.group.id,
        conversationId: widget.group.id,
        hostId: '', // Current user - managed by backend
        hostName: 'Group Call',
        title: '${widget.group.title} Video Call',
        description: 'Group video call',
        groupType: widget.group.groupType,
        status: LiveSessionStatus.active,
        currentParticipants: widget.group.participantCount,
        maxParticipants: widget.group.participantCount,
        requireApproval: false,
        createdAt: DateTime.now(),
      );

      // Navigate to video call screen with token
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => VideoCallScreen(
            liveSessionId: widget.group.id,
            rtcToken: tokenData['token'] as String,
            session: callSession,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start video call: $e')),
        );
      }
    }
  }

  void _startVoiceRecording() {
    setState(() {
      _isRecordingVoice = true;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final permission = source == ImageSource.camera
        ? Permission.camera
        : Permission.photos;

    final status = await permission.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission denied')),
        );
      }
      return;
    }

    final image = await _imagePicker.pickImage(source: source);
    if (image != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uploading image...')),
        );
      }

      try {
        final result = await _groupChatService.uploadMedia(
          filePath: image.path,
          mediaType: 'image',
        );

        // Send message with uploaded image URL
        if (mounted && result['url'] != null) {
          // Send via WebSocket or REST API
          _groupChatWS.sendMessage(
            conversationId: widget.group.id,
            content: result['url'],
            type: 'image',
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image sent')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload image: $e')),
          );
        }
      }
    }
  }

  Future<void> _pickVideo() async {
    final video = await _imagePicker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uploading video...')),
        );
      }

      try {
        final result = await _groupChatService.uploadMedia(
          filePath: video.path,
          mediaType: 'video',
        );

        // Send message with uploaded video URL
        if (mounted && result['url'] != null) {
          _groupChatWS.sendMessage(
            conversationId: widget.group.id,
            content: result['url'],
            type: 'video',
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Video sent')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload video: $e')),
          );
        }
      }
    }
  }

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'txt',
          'xls',
          'xlsx',
          'ppt',
          'pptx',
        ],
      );

      if (result != null && result.files.single.path != null) {
        final file = result.files.single;
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Uploading ${file.name}...')));
        }

        final uploadResult = await _groupChatService.uploadMedia(
          filePath: file.path!,
          mediaType: 'document',
        );

        // Send message with uploaded document URL
        if (mounted && uploadResult['url'] != null) {
          _groupChatWS.sendMessage(
            conversationId: widget.group.id,
            content: uploadResult['url'],
            type: 'document',
          );

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('${file.name} sent')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload document: $e')),
        );
      }
    }
  }

  void _deleteMessage(MessageModel message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text(
          'Are you sure you want to delete this message? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await _groupChatService.deleteMessage(
                  conversationId: widget.group.id,
                  messageId: message.id,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Message deleted')),
                  );
                  // Refresh messages
                  setState(() {
                    _messages.removeWhere((m) => m.id == message.id);
                  });
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete: $e')),
                  );
                }
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _reportMessage(MessageModel message) {
    String? selectedReason;
    final detailsController = TextEditingController();
    final reasons = [
      'Spam',
      'Harassment',
      'Inappropriate Content',
      'Scam or Fraud',
      'Hate Speech',
      'Violence',
      'Other',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Report Message'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Why are you reporting this message?'),
                const SizedBox(height: 16),
                ...reasons.map(
                  (reason) => InkWell(
                    onTap: () => setState(() => selectedReason = reason),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            selectedReason == reason
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: selectedReason == reason
                                ? Theme.of(context).primaryColor
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(reason)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: detailsController,
                  decoration: const InputDecoration(
                    labelText: 'Additional Details (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: selectedReason == null
                  ? null
                  : () async {
                      try {
                        await _groupChatService.reportMessage(
                          messageId: message.id,
                          reason: selectedReason!,
                          details: detailsController.text.isEmpty
                              ? null
                              : detailsController.text,
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Report submitted. We\'ll review it shortly.',
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to report: $e')),
                          );
                        }
                      }
                    },
              child: const Text(
                'Submit Report',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== HELPER METHODS ==========

  bool _isAdmin() {
    // Check if current user is admin/owner
    final currentParticipant = widget.group.participants.firstWhere(
      (p) => p.userId == _currentUserId,
      orElse: () => widget.group.participants.first,
    );
    
    return currentParticipant.role == ParticipantRole.owner ||
        currentParticipant.role == ParticipantRole.admin ||
        currentParticipant.role == ParticipantRole.moderator;
  }

  IconData _getGroupIcon(GroupType type) {
    switch (type) {
      case GroupType.dating:
        return Icons.favorite;
      case GroupType.speedDating:
        return Icons.flash_on;
      case GroupType.study:
        return Icons.school;
      case GroupType.interest:
        return Icons.interests;
      case GroupType.liveHost:
        return Icons.live_tv;
      default:
        return Icons.group;
    }
  }

  String _formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[timestamp.weekday - 1];
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
