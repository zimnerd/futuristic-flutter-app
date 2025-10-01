import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get_it/get_it.dart';
import '../../bloc/group_chat_bloc.dart';
import '../../data/models.dart';
import '../../data/group_chat_service.dart';
import 'create_group_screen.dart';
import 'group_chat_screen.dart';
import 'video_call_screen.dart';
import '../../../../data/services/webrtc_service.dart';

class GroupListScreen extends StatefulWidget {
  const GroupListScreen({super.key});

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadGroups();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadGroups() {
    context.read<GroupChatBloc>().add(LoadUserGroups());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Groups'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Groups', icon: Icon(Icons.group)),
            Tab(text: 'Live Sessions', icon: Icon(Icons.live_tv)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateOptions,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGroupsTab(),
          _buildLiveSessionsTab(),
        ],
      ),
    );
  }

  Widget _buildGroupsTab() {
    return BlocConsumer<GroupChatBloc, GroupChatState>(
      listener: (context, state) {
        if (state is GroupChatError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is GroupChatLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is GroupChatLoaded) {
          final groups = state.userGroups;

          if (groups.isEmpty) {
            return _buildEmptyState(
              icon: Icons.group_outlined,
              title: 'No Groups Yet',
              subtitle: 'Create or join a group to get started',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _loadGroups();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                return _GroupCard(
                  group: groups[index],
                  onTap: () => _openGroupChat(groups[index]),
                );
              },
            ),
          );
        }

        return _buildEmptyState(
          icon: Icons.group_outlined,
          title: 'No Groups',
          subtitle: 'Start by creating a new group',
        );
      },
    );
  }

  Widget _buildLiveSessionsTab() {
    return BlocBuilder<GroupChatBloc, GroupChatState>(
      builder: (context, state) {
        if (state is GroupChatLoaded) {
          final liveSessions = state.activeLiveSessions;

          if (liveSessions.isEmpty) {
            return _buildEmptyState(
              icon: Icons.live_tv_outlined,
              title: 'No Active Sessions',
              subtitle: 'Browse or create a live session',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<GroupChatBloc>().add(LoadActiveLiveSessions());
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: liveSessions.length,
              itemBuilder: (context, index) {
                return _LiveSessionCard(
                  session: liveSessions[index],
                  onTap: () => _joinLiveSession(liveSessions[index]),
                );
              },
            ),
          );
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.group_add),
              title: const Text('Create Group'),
              subtitle: const Text('Start a new group conversation'),
              onTap: () {
                Navigator.pop(context);
                _navigateToCreateGroup();
              },
            ),
            ListTile(
              leading: const Icon(Icons.live_tv),
              title: const Text('Start Live Session'),
              subtitle: const Text('Host a live session'),
              onTap: () {
                Navigator.pop(context);
                _createLiveSession();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCreateGroup() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateGroupScreen(),
      ),
    ).then((result) {
      if (result != null) {
        _loadGroups();
      }
    });
  }

  void _createLiveSession() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final maxParticipantsController = TextEditingController(text: '10');
    GroupConversation? selectedGroup;
    bool requireApproval = true;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return BlocBuilder<GroupChatBloc, GroupChatState>(
            builder: (context, state) {
              final groups = state is GroupChatLoaded
                  ? state.userGroups
                      .where((g) => g.groupType == GroupType.liveHost)
                      .toList()
                  : <GroupConversation>[];

              return AlertDialog(
                title: const Text('Create Live Session'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Group Selection
                      const Text(
                        'Select Group',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<GroupConversation>(
                        value: selectedGroup,
                        decoration: const InputDecoration(
                          hintText: 'Choose a live host group',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: groups.map((group) {
                          return DropdownMenuItem(
                            value: group,
                            child: Text(group.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedGroup = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Title
                      const Text(
                        'Session Title',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          hintText: 'Enter session title',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        maxLength: 100,
                      ),
                      const SizedBox(height: 8),

                      // Description
                      const Text(
                        'Description (Optional)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          hintText: 'Enter session description',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        maxLines: 3,
                        maxLength: 500,
                      ),
                      const SizedBox(height: 8),

                      // Max Participants
                      const Text(
                        'Max Participants',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: maxParticipantsController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),

                      // Require Approval
                      SwitchListTile(
                        title: const Text(
                          'Require Approval',
                          style: TextStyle(fontSize: 14),
                        ),
                        subtitle: const Text(
                          'Approve participants before they join',
                          style: TextStyle(fontSize: 12),
                        ),
                        value: requireApproval,
                        onChanged: (value) {
                          setState(() {
                            requireApproval = value;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      titleController.dispose();
                      descriptionController.dispose();
                      maxParticipantsController.dispose();
                      Navigator.pop(dialogContext);
                    },
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      // Validation
                      if (selectedGroup == null) {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select a group'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      if (titleController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a title'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      final maxParticipants =
                          int.tryParse(maxParticipantsController.text) ?? 10;

                      if (maxParticipants < 2 || maxParticipants > 100) {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Max participants must be between 2 and 100',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      // Show loading
                      Navigator.pop(dialogContext);
                      showDialog(
                        context: this.context,
                        barrierDismissible: false,
                        builder: (context) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );

                      try {
                        // Create live session via service
                        final service = GetIt.instance<GroupChatService>();
                        final session = await service.createLiveSession(
                          conversationId: selectedGroup!.id,
                          title: titleController.text.trim(),
                          description: descriptionController.text.trim().isEmpty
                              ? null
                              : descriptionController.text.trim(),
                          maxParticipants: maxParticipants,
                          requireApproval: requireApproval,
                        );

                        // Close loading
                        if (!this.mounted) return;
                        Navigator.of(this.context).pop();

                        // Show success
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(
                            content: Text('Live session created successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );

                        // Reload sessions
                        this.context.read<GroupChatBloc>().add(
                              LoadActiveLiveSessions(),
                            );

                        // Auto-join the created session
                        _joinLiveSession(session);
                      } catch (e) {
                        // Close loading
                        if (!this.mounted) return;
                        Navigator.of(this.context).pop();

                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content:
                                Text('Failed to create session: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } finally {
                        titleController.dispose();
                        descriptionController.dispose();
                        maxParticipantsController.dispose();
                      }
                    },
                    child: const Text('Create'),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _openGroupChat(GroupConversation group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupChatScreen(group: group),
      ),
    );
  }

  void _joinLiveSession(LiveSession session) async {
    try {
      // Show loading
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
                'Joining session...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );

      // Get RTC token for the live session
      final webrtcService = WebRTCService();
      final tokenData = await webrtcService.getRtcToken(
        channelName: session.id,
        role: 1, // PUBLISHER role
      );

      // Close loading
      if (!mounted) return;
      Navigator.of(context).pop();

      // Navigate to video call screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => VideoCallScreen(
            liveSessionId: session.id,
            rtcToken: tokenData['token'] as String,
            session: session,
          ),
        ),
      );

      // Show success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Joined ${session.title}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // Close loading if still showing
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to join session: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

class _GroupCard extends StatelessWidget {
  final GroupConversation group;
  final VoidCallback onTap;

  const _GroupCard({
    required this.group,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getGroupColor(group.groupType),
          child: Icon(
            _getGroupIcon(group.groupType),
            color: Colors.white,
          ),
        ),
        title: Text(
          group.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (group.description != null) ...[
              const SizedBox(height: 4),
              Text(
                group.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.people, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${group.participants.length} members',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                if (group.settings?.enableVideoChat == true)
                  Icon(Icons.videocam, size: 14, color: Colors.grey[600]),
                if (group.settings?.enableVoiceChat == true)
                  Icon(Icons.mic, size: 14, color: Colors.grey[600]),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Color _getGroupColor(GroupType type) {
    switch (type) {
      case GroupType.standard:
        return Colors.blue;
      case GroupType.study:
        return Colors.green;
      case GroupType.interest:
        return Colors.orange;
      case GroupType.dating:
        return Colors.pink;
      case GroupType.liveHost:
        return Colors.purple;
      case GroupType.speedDating:
        return Colors.red;
    }
  }

  IconData _getGroupIcon(GroupType type) {
    switch (type) {
      case GroupType.standard:
        return Icons.group;
      case GroupType.study:
        return Icons.school;
      case GroupType.interest:
        return Icons.interests;
      case GroupType.dating:
        return Icons.favorite;
      case GroupType.liveHost:
        return Icons.live_tv;
      case GroupType.speedDating:
        return Icons.flash_on;
    }
  }
}

class _LiveSessionCard extends StatelessWidget {
  final LiveSession session;
  final VoidCallback onTap;

  const _LiveSessionCard({
    required this.session,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundImage: session.hostAvatarUrl != null
                  ? CachedNetworkImageProvider(session.hostAvatarUrl!)
                  : null,
              child: session.hostAvatarUrl == null
                  ? const Icon(Icons.person)
                  : null,
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
        title: Text(
          session.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Hosted by ${session.hostFirstName}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.people, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${session.currentParticipants}/${session.maxParticipants}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                if (session.isFull) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'FULL',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: session.isFull ? null : onTap,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: const Text('Join'),
        ),
      ),
    );
  }
}
