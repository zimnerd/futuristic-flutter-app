import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:uuid/uuid.dart';
import '../../bloc/group_chat_bloc.dart';
import '../../data/models.dart';
import 'video_call_screen.dart';
import '../../../../data/services/webrtc_service.dart';

class GroupChatScreen extends StatefulWidget {
  final GroupConversation group;

  const GroupChatScreen({
    super.key,
    required this.group,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<GroupChatBloc>();
    // Join the group room
    bloc.add(JoinGroup(widget.group.id));
    // Load message history
    bloc.add(LoadMessages(widget.group.id));
  }

  @override
  void dispose() {
    // Leave the group room
    context.read<GroupChatBloc>().add(
          LeaveGroup(widget.group.id),
        );
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<GroupChatBloc, GroupChatState>(
      listener: (context, state) {
        if (state is GroupChatError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
        appBar: _buildAppBar(),
        body: Column(
          children: [
            Expanded(child: _buildMessageList()),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.group.name),
          Text(
            '${widget.group.participants.length} members',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
      actions: [
        if (widget.group.settings?.enableVideoChat == true)
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: _startVideoCall,
            tooltip: 'Start video call',
          ),
        if (widget.group.settings?.enableVoiceChat == true)
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: _startVoiceCall,
            tooltip: 'Start voice call',
          ),
        PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'participants',
              child: Row(
                children: [
                  Icon(Icons.people),
                  SizedBox(width: 8),
                  Text('View Participants'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings),
                  SizedBox(width: 8),
                  Text('Group Settings'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'leave',
              child: Row(
                children: [
                  Icon(Icons.exit_to_app, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Leave Group', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: _handleMenuAction,
        ),
      ],
    );
  }

  Widget _buildMessageList() {
    return BlocBuilder<GroupChatBloc, GroupChatState>(
      builder: (context, state) {
        if (state is GroupChatLoading ||
            (state is GroupChatLoaded && state.isLoadingMessages)) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is GroupChatLoaded) {
          if (state.messages.isEmpty) {
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Be the first to say something!',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            controller: _scrollController,
            reverse: true,
            padding: const EdgeInsets.all(8),
            itemCount: state.messages.length,
            itemBuilder: (context, index) {
              final message = state.messages[state.messages.length - 1 - index];
              return _buildMessageBubble(message);
            },
          );
        }

        return const Center(child: Text('Something went wrong'));
      },
    );
  }

  Widget _buildMessageBubble(GroupMessage message) {
    // TODO: Pass current user ID from parent widget or get from auth BLoC
    // For now, compare with sender ID - you'll need to inject this
    final currentUserId = ''; // Will be injected via context or constructor
    final isMe = message.senderId == currentUserId;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Theme.of(context).primaryColor : Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(
                message.senderFirstName ?? message.senderUsername,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isMe ? Colors.white : Colors.black87,
                  fontSize: 12,
                ),
              ),
            if (!isMe) const SizedBox(height: 4),
            Text(
              message.content,
              style: TextStyle(color: isMe ? Colors.white : Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(message.timestamp),
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8),
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
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: _showAttachmentOptions,
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.newline,
                onChanged: _handleTyping,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                _messageController.text.trim().isEmpty
                    ? Icons.mic
                    : Icons.send,
                color: Theme.of(context).primaryColor,
              ),
              onPressed: _messageController.text.trim().isEmpty
                  ? _recordVoiceMessage
                  : _sendMessage,
            ),
          ],
        ),
      ),
    );
  }

  void _handleTyping(String text) {
    final isNowTyping = text.trim().isNotEmpty;
    if (_isTyping != isNowTyping) {
      setState(() {
        _isTyping = isNowTyping;
      });
      // Send typing indicator
      context.read<GroupChatBloc>().add(
            SendTypingIndicator(
              conversationId: widget.group.id,
              isTyping: isNowTyping,
            ),
          );
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Generate temporary ID for optimistic UI
    final tempId = const Uuid().v4();

    // Send message via BLoC
    context.read<GroupChatBloc>().add(
      SendMessage(
        conversationId: widget.group.id,
        content: text,
        tempId: tempId,
      ),
    );

    _messageController.clear();
    setState(() {
      _isTyping = false;
    });

    // Scroll to bottom to show new message
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _recordVoiceMessage() {
    // TODO: Implement voice recording
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Voice recording will be implemented')),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo, color: Colors.blue),
              title: const Text('Photo'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Pick photo
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_library, color: Colors.red),
              title: const Text('Video'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Pick video
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file, color: Colors.orange),
              title: const Text('File'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Pick file
              },
            ),
          ],
        ),
      ),
    );
  }

  void _startVideoCall() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Video Call'),
        content: const Text(
          'Video calling will be implemented with WebRTC integration.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _initiateCall(isVideoCall: true);
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  Future<void> _initiateCall({required bool isVideoCall}) async {
    try {
      // Show loading indicator
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Starting ${isVideoCall ? 'video' : 'voice'} call...',
                style: const TextStyle(color: Colors.white),
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

      // Create a pseudo LiveSession for the group call
      final callSession = LiveSession(
        id: widget.group.id,
        conversationId: widget.group.id,
        hostId: '', // Current user - will be managed by backend
        hostName: 'Group Call',
        title: '${widget.group.title} ${isVideoCall ? 'Video' : 'Voice'} Call',
        description: 'Group ${isVideoCall ? 'video' : 'voice'} call',
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
      // Close loading dialog if still showing
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start call: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _startVoiceCall() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Voice Call'),
        content: const Text(
          'Voice calling will be implemented with WebRTC integration.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _initiateCall(isVideoCall: false);
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'participants':
        _showParticipants();
        break;
      case 'settings':
        _showGroupSettings();
        break;
      case 'leave':
        _confirmLeaveGroup();
        break;
    }
  }

  void _showParticipants() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Column(
            children: [
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
                      '${widget.group.participants.length} members',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: widget.group.participants.length,
                  itemBuilder: (context, index) {
                    final participant = widget.group.participants[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: participant.profilePhoto != null
                            ? CachedNetworkImageProvider(
                                participant.profilePhoto!)
                            : null,
                        child: participant.profilePhoto == null
                            ? Text(participant.firstName[0])
                            : null,
                      ),
                      title: Text(participant.fullName),
                      subtitle: Text(_getRoleLabel(participant.role)),
                      trailing: participant.isOnline
                          ? Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            )
                          : null,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getRoleLabel(ParticipantRole role) {
    switch (role) {
      case ParticipantRole.owner:
        return 'Owner';
      case ParticipantRole.admin:
        return 'Admin';
      case ParticipantRole.moderator:
        return 'Moderator';
      case ParticipantRole.guest:
        return 'Guest';
      case ParticipantRole.member:
        return 'Member';
    }
  }

  void _showGroupSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Group Settings',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (widget.group.settings != null) ...[
                _buildSettingItem(
                  'Group Type',
                  _getGroupTypeLabel(widget.group.settings!.groupType),
                ),
                _buildSettingItem(
                  'Max Participants',
                  '${widget.group.settings!.maxParticipants}',
                ),
                _buildSettingItem(
                  'Require Approval',
                  widget.group.settings!.requireApproval ? 'Yes' : 'No',
                ),
                _buildSettingItem(
                  'Voice Chat',
                  widget.group.settings!.enableVoiceChat ? 'Enabled' : 'Disabled',
                ),
                _buildSettingItem(
                  'Video Chat',
                  widget.group.settings!.enableVideoChat ? 'Enabled' : 'Disabled',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(color: Colors.grey[700])),
        ],
      ),
    );
  }

  String _getGroupTypeLabel(GroupType type) {
    switch (type) {
      case GroupType.standard:
        return 'Standard';
      case GroupType.study:
        return 'Study';
      case GroupType.interest:
        return 'Interest';
      case GroupType.dating:
        return 'Dating';
      case GroupType.liveHost:
        return 'Live Host';
      case GroupType.speedDating:
        return 'Speed Dating';
    }
  }

  void _confirmLeaveGroup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: Text('Are you sure you want to leave ${widget.group.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Exit chat screen
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Left ${widget.group.name}')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }
}
