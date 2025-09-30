import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../bloc/group_chat_bloc.dart';
import '../../data/models.dart';
import 'create_group_screen.dart';
import 'group_chat_screen.dart';

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
    // TODO: Show live session creation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Live Session'),
        content: const Text('Live session creation dialog will be implemented'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Create session
            },
            child: const Text('Create'),
          ),
        ],
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

  void _joinLiveSession(LiveSession session) {
    // TODO: Implement join logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Joining ${session.title}...'),
      ),
    );
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
