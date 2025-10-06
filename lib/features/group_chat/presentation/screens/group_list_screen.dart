import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get_it/get_it.dart';
import '../../bloc/group_chat_bloc.dart';
import '../../data/models.dart';
import '../../data/group_chat_service.dart';
import '../../../../presentation/navigation/app_router.dart';
import '../../../../data/services/webrtc_service.dart';

class GroupListScreen extends StatefulWidget {
  final GroupChatBloc bloc;

  const GroupListScreen({super.key, required this.bloc});

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
    // Load groups after the first frame when context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadGroups();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadGroups() {
    widget.bloc.add(LoadUserGroups());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF6E3BFF),
        foregroundColor: Colors.white,
        title: const Text(
          'My Groups',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              text: 'Groups',
              icon: Icon(Icons.group),
              iconMargin: EdgeInsets.only(bottom: 4),
            ),
            Tab(
              text: 'Live Sessions',
              icon: Icon(Icons.live_tv),
              iconMargin: EdgeInsets.only(bottom: 4),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.add),
            tooltip: 'Create new',
            offset: const Offset(0, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 8,
            color: Theme.of(context).cardColor,
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'group',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.group_add, color: Colors.blue),
                  ),
                  title: const Text(
                    'Create Group',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Start a new group conversation',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
              PopupMenuItem<String>(
                value: 'live',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.live_tv, color: Colors.purple),
                  ),
                  title: const Text(
                    'Start Live Session',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Host a live session',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'group') {
                _navigateToCreateGroup();
              } else if (value == 'live') {
                _createLiveSession();
              }
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildGroupsTab(), _buildLiveSessionsTab()],
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
            color: const Color(0xFF6E3BFF),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              widget.bloc.add(LoadActiveLiveSessions());
            },
            color: const Color(0xFF6E3BFF),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF6E3BFF).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: const Color(0xFF6E3BFF),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF202124),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF5F6368),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCreateGroup() async {
    final result = await context.push(AppRoutes.createGroup);
    if (result != null && mounted) {
      _loadGroups();
    }
  }

  void _createLiveSession() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final maxParticipantsController = TextEditingController(text: '10');
    bool requireApproval = true;

    // Read the bloc before showing the dialog to avoid provider scope issues
    final bloc = context.read<GroupChatBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
              return AlertDialog(
                title: const Text('Create Live Session'),
                contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                content: SizedBox(
                  width: double.maxFinite,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

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
                      if (titleController.text.trim().isEmpty) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
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
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Max participants must be between 2 and 100',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                  // Close dialog first
                      Navigator.pop(dialogContext);
                      
                  // Show loading
                  if (!mounted) return;
                      showDialog(
                    context: context,
                        barrierDismissible: false,
                    builder: (loadingContext) =>
                        const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );

                      try {
                    // Create live session via service (no conversation required)
                        final service = GetIt.instance<GroupChatService>();
                    final session = await service.createLiveSession(
                          title: titleController.text.trim(),
                          description: descriptionController.text.trim().isEmpty
                              ? null
                              : descriptionController.text.trim(),
                          maxParticipants: maxParticipants,
                          requireApproval: requireApproval,
                        );

                    // Dispose controllers
                    titleController.dispose();
                    descriptionController.dispose();
                    maxParticipantsController.dispose();

                        // Close loading
                    if (!mounted) return;
                        Navigator.of(context).pop();

                        // Show success
                    if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Live session created successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );

                        // Reload sessions
                    bloc.add(LoadActiveLiveSessions());

                        // Auto-join the created session
                    if (!mounted) return;
                        _joinLiveSession(session);
                      } catch (e) {
                    // Dispose controllers on error
                    titleController.dispose();
                    descriptionController.dispose();
                    maxParticipantsController.dispose();
                        
                        // Close loading
                    if (!mounted) return;
                        Navigator.of(context).pop();

                    if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('Failed to create session: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                    );
                      }
                    },
                    child: const Text('Create'),
                  ),
                ],
          );
        },
      ),
    );
  }

  void _openGroupChat(GroupConversation group) {
    context.push(AppRoutes.groupChat, extra: group);
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
      context.push(
        AppRoutes.videoCall,
        extra: {
          'liveSessionId': session.id,
          'rtcToken': tokenData['token'] as String,
          'session': session,
        },
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getGroupColor(group.groupType).withValues(alpha: 0.05),
            _getGroupColor(group.groupType).withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getGroupColor(group.groupType).withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _getGroupColor(group.groupType).withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon with gradient background
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getGroupColor(group.groupType),
                        _getGroupColor(group.groupType).withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: _getGroupColor(group.groupType).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getGroupIcon(group.groupType),
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF202124),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (group.description != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          group.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF5F6368),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getGroupColor(group.groupType).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.people,
                                  size: 14,
                                  color: _getGroupColor(group.groupType),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${group.participants.length} members',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _getGroupColor(group.groupType),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (group.settings?.enableVideoChat == true)
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.videocam,
                                size: 14,
                                color: Colors.green,
                              ),
                            ),
                          const SizedBox(width: 4),
                          if (group.settings?.enableVoiceChat == true)
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.mic,
                                size: 14,
                                color: Colors.blue,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Chevron
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getGroupColor(group.groupType).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chevron_right,
                    color: _getGroupColor(group.groupType),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
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
