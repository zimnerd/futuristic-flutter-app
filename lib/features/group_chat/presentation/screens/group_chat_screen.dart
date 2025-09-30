import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../bloc/group_chat_bloc.dart';
import '../../data/models.dart';

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
    // Join the group room
    context.read<GroupChatBloc>().add(
          JoinGroup(widget.group.id),
        );
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
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: _buildMessageList(),
          ),
          _buildMessageInput(),
        ],
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
    // TODO: Implement real message list with chat service
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

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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

    // TODO: Implement actual message sending
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sending: $text')),
    );

    _messageController.clear();
    setState(() {
      _isTyping = false;
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
            onPressed: () {
              Navigator.pop(context);
              // TODO: Start video call
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
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
            onPressed: () {
              Navigator.pop(context);
              // TODO: Start voice call
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
