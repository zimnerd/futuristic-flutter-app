import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../navigation/app_router.dart';
import '../../../core/di/service_locator.dart';
import '../../../features/group_chat/data/models.dart';
import '../../../data/services/webrtc_service.dart';
import '../../blocs/group_chat/group_chat_barrel.dart';
import '../../theme/pulse_colors.dart';
import '../../widgets/common/keyboard_dismissible_scaffold.dart';

/// Screen for browsing and managing group chats
/// Features: My Groups, Live Sessions, Create Group/Session
class GroupChatListScreen extends StatefulWidget {
  const GroupChatListScreen({super.key});

  @override
  State<GroupChatListScreen> createState() => _GroupChatListScreenState();
}

class _GroupChatListScreenState extends State<GroupChatListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isGridView = false;
  String _searchQuery = '';
  GroupType? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<GroupChatBloc>()
        ..add(const LoadActiveLiveSessions())
        ..add(const InitializeGroupChatWebSocket()),
      child: KeyboardDismissibleScaffold(
        backgroundColor: Colors.grey[50],
        appBar: _buildAppBar(),
        body: Column(
          children: [
            _buildSearchBar(),
            _buildFilterChips(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMyGroupsTab(),
                  _buildLiveSessionsTab(),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: _buildFAB(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Group Chats',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
      bottom: TabBar(
        controller: _tabController,
        labelColor: PulseColors.primary,
        unselectedLabelColor: Colors.grey,
        indicatorColor: PulseColors.primary,
        tabs: const [
          Tab(
            icon: Icon(Icons.group),
            text: 'My Groups',
          ),
          Tab(
            icon: Icon(Icons.live_tv),
            text: 'Live Sessions',
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
          onPressed: () {
            setState(() {
              _isGridView = !_isGridView;
            });
          },
          tooltip: _isGridView ? 'List View' : 'Grid View',
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search groups or sessions...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 50,
      color: Colors.white,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildFilterChip('All', null),
          _buildFilterChip('Dating', GroupType.dating),
          _buildFilterChip('Interest', GroupType.interest),
          _buildFilterChip('Study', GroupType.study),
          _buildFilterChip('Live Host', GroupType.liveHost),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, GroupType? type) {
    final isSelected = _selectedFilter == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = selected ? type : null;
          });
        },
        selectedColor: PulseColors.primary.withValues(alpha: 0.2),
        checkmarkColor: PulseColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? PulseColors.primary : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildMyGroupsTab() {
    return BlocBuilder<GroupChatBloc, GroupChatState>(
      builder: (context, state) {
        if (state is GroupChatCreatingGroup) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (state is GroupChatError) {
          return _buildErrorView(state.message);
        }

        // For now, show empty state - will be populated by GroupChatDetailsLoaded
        // In production, you'd have a GroupsLoaded state that lists all groups
        if (state is GroupChatDetailsLoaded) {
          final filteredGroups = _filterGroups([state.group]);

          if (filteredGroups.isEmpty) {
            return _buildEmptyView(
              icon: Icons.group_add,
              title: 'No Groups Yet',
              subtitle: 'Create your first group to start connecting!',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<GroupChatBloc>().add(const RefreshGroupChatData());
              await Future.delayed(const Duration(seconds: 1));
            },
            child: _isGridView
                ? _buildGroupsGrid(filteredGroups)
                : _buildGroupsList(filteredGroups),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildLiveSessionsTab() {
    return BlocBuilder<GroupChatBloc, GroupChatState>(
      builder: (context, state) {
        if (state is GroupChatLoadingSessions) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (state is GroupChatError) {
          return _buildErrorView(state.message);
        }

        if (state is GroupChatSessionsLoaded) {
          final filteredSessions = _filterSessions(state.sessions);

          if (filteredSessions.isEmpty) {
            return _buildEmptyView(
              icon: Icons.live_tv,
              title: 'No Live Sessions',
              subtitle: 'Start a live session or join one below!',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<GroupChatBloc>().add(const LoadActiveLiveSessions());
              await Future.delayed(const Duration(seconds: 1));
            },
            child: _isGridView
                ? _buildSessionsGrid(filteredSessions)
                : _buildSessionsList(filteredSessions),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildGroupsGrid(List<GroupConversation> groups) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        return _buildGroupCard(groups[index]);
      },
    );
  }

  Widget _buildGroupsList(List<GroupConversation> groups) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        return _buildGroupListTile(groups[index]);
      },
    );
  }

  Widget _buildSessionsGrid(List<LiveSession> sessions) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        return _buildSessionCard(sessions[index]);
      },
    );
  }

  Widget _buildSessionsList(List<LiveSession> sessions) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        return _buildSessionListTile(sessions[index]);
      },
    );
  }

  Widget _buildGroupCard(GroupConversation group) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _navigateToGroupDetails(context, group),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group Image/Icon
            Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    PulseColors.primary.withValues(alpha: 0.7),
                    PulseColors.secondary.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Center(
                child: Icon(
                  _getGroupIcon(group.groupType),
                  size: 48,
                  color: Colors.white,
                ),
              ),
            ),
            // Group Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${group.participantCount} members',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupListTile(GroupConversation group) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: () => _navigateToGroupDetails(context, group),
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: PulseColors.primary.withValues(alpha: 0.1),
          child: Icon(
            _getGroupIcon(group.groupType),
            color: PulseColors.primary,
          ),
        ),
        title: Text(
          group.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              _getGroupTypeLabel(group.groupType),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  Icons.people,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  '${group.participantCount} members',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  Widget _buildSessionCard(LiveSession session) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _navigateToSessionDetails(session),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Live Badge
            Stack(
              children: [
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.red.withValues(alpha: 0.7),
                        Colors.orange.withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.live_tv,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Session Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            session.hostName,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionListTile(LiveSession session) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: () => _navigateToSessionDetails(session),
        contentPadding: const EdgeInsets.all(12),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.red.withValues(alpha: 0.1),
              child: const Icon(
                Icons.live_tv,
                color: Colors.red,
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
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
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Hosted by ${session.hostName}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  Icons.people,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  '${session.currentParticipants} watching',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  Widget _buildEmptyView({
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
            Icon(
              icon,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
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

  Widget _buildErrorView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Oops!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<GroupChatBloc>().add(const RefreshGroupChatData());
                context.read<GroupChatBloc>().add(const LoadActiveLiveSessions());
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: PulseColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: _showCreateOptions,
      backgroundColor: PulseColors.primary,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: const Text('Create'),
    );
  }

  void _showCreateOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: PulseColors.primary.withValues(alpha: 0.1),
                  child: const Icon(Icons.group_add, color: PulseColors.primary),
                ),
                title: const Text(
                  'Create Group',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Start a new group chat'),
                onTap: () {
                  Navigator.pop(context);
                  _showCreateGroupDialog();
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.red.withValues(alpha: 0.1),
                  child: const Icon(Icons.live_tv, color: Colors.red),
                ),
                title: const Text(
                  'Start Live Session',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Go live and connect with others'),
                onTap: () {
                  Navigator.pop(context);
                  _showCreateLiveSessionDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCreateGroupDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    GroupType selectedType = GroupType.standard;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Create Group'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Group Name',
                        hintText: 'Enter group name',
                        border: OutlineInputBorder(),
                      ),
                      maxLength: 50,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'What is this group about?',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      maxLength: 200,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Group Type',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<GroupType>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: GroupType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(_getGroupTypeLabel(type)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedType = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.trim().isNotEmpty) {
                      context.read<GroupChatBloc>().add(
                            CreateGroupConversation(
                              title: nameController.text.trim(),
                              groupType: selectedType,
                              participantUserIds: const [],
                              maxParticipants: 50,
                              allowParticipantInvite: true,
                              requireApproval: false,
                              enableVoiceChat: true,
                              enableVideoChat: false,
                            ),
                          );
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Creating group...'),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PulseColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCreateLiveSessionDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Start Live Session'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Session Title',
                    hintText: 'What are you streaming?',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 50,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    hintText: 'Tell viewers what to expect',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  maxLength: 200,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isNotEmpty) {
                  context.read<GroupChatBloc>().add(
                        CreateLiveSession(
                          title: titleController.text.trim(),
                          description: descriptionController.text.trim().isEmpty
                              ? null
                              : descriptionController.text.trim(),
                        ),
                      );
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Starting live session...'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Go Live'),
            ),
          ],
        );
      },
    );
  }

  List<GroupConversation> _filterGroups(List<GroupConversation> groups) {
    var filtered = groups;

    // Filter by type
    if (_selectedFilter != null) {
      filtered = filtered
          .where((group) => group.groupType == _selectedFilter)
          .toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((group) =>
              group.title.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return filtered;
  }

  List<LiveSession> _filterSessions(List<LiveSession> sessions) {
    var filtered = sessions;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((session) =>
              session.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              session.hostName.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return filtered;
  }

  IconData _getGroupIcon(GroupType type) {
    switch (type) {
      case GroupType.dating:
        return Icons.favorite;
      case GroupType.interest:
        return Icons.interests;
      case GroupType.study:
        return Icons.school;
      case GroupType.liveHost:
        return Icons.live_tv;
      case GroupType.speedDating:
        return Icons.speed;
      default:
        return Icons.group;
    }
  }

  String _getGroupTypeLabel(GroupType type) {
    switch (type) {
      case GroupType.dating:
        return 'Dating';
      case GroupType.interest:
        return 'Interest';
      case GroupType.study:
        return 'Study';
      case GroupType.liveHost:
        return 'Live Host';
      case GroupType.speedDating:
        return 'Speed Dating';
      default:
        return 'Standard';
    }
  }

  void _navigateToGroupDetails(BuildContext context, dynamic group) {
    // Navigate to group chat screen (GroupChatDetailScreen is for settings/info)
    // Using the main group chat screen from features/group_chat
    context.push(AppRoutes.groupChat, extra: group);
  }

  void _navigateToSessionDetails(LiveSession session) async {
    // Navigate to video call screen with WebRTC session
    try {
      final webrtcService = WebRTCService();
      final tokenData = await webrtcService.getRtcToken(
        channelName: session.id,
        role: 1, // PUBLISHER role
      );
      
      if (!mounted) return;
      context.push(
        AppRoutes.videoCall,
        extra: {
          'liveSessionId': session.id,
          'rtcToken': tokenData['token'] as String,
          'session': session,
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to join live session: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
