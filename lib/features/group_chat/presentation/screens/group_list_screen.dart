import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';
import '../../../../presentation/blocs/group_chat/group_chat_bloc.dart';
import '../../data/models.dart';
import '../../data/group_chat_service.dart';
import '../../../../presentation/navigation/app_router.dart';
import '../../../../data/services/webrtc_service.dart';
import '../../../../presentation/widgets/common/initials_avatar.dart';
import '../../../../presentation/widgets/common/pulse_toast.dart';

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
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: context.primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          'My Groups',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(color: Colors.white),
          unselectedLabelStyle: const TextStyle(color: Colors.white70),
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
            icon: Icon(Icons.add),
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
                      color: context.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.group_add, color: context.primaryColor),
                  ),
                  title: Text(
                    'Create Group',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
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
                      color: context.accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.live_tv, color: context.accentColor),
                  ),
                  title: Text(
                    'Start Live Session',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
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
          PulseToast.error(context, message: state.message);
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
              child: Icon(icon, size: 64, color: const Color(0xFF6E3BFF)),
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
    final durationController = TextEditingController(text: '30');
    String sessionType = 'CASUAL_CHAT';
    bool requireApproval = true;
    bool allowVideo = true;
    bool allowAudio = true;
    bool controllersDisposed = false;

    // Read the bloc before showing the dialog to avoid provider scope issues
    final bloc = context.read<GroupChatBloc>();

    // Helper function to safely dispose controllers once
    void disposeControllers() {
      if (!controllersDisposed) {
        titleController.dispose();
        descriptionController.dispose();
        maxParticipantsController.dispose();
        durationController.dispose();
        controllersDisposed = true;
      }
    }

    // Helper to build labels with icons
    Widget buildLabel(String text, IconData icon) {
      return Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF6E3BFF)),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF202124),
            ),
          ),
        ],
      );
    }

    // Helper to build modern input decoration
    InputDecoration buildInputDecoration(String hint, IconData icon) {
      return InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF6E3BFF)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: const Color(0xFF6E3BFF).withAlpha(77), // 0.3 * 255 ≈ 77
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: const Color(0xFF6E3BFF).withAlpha(77), // 0.3 * 255 ≈ 77
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF6E3BFF), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      );
    }

    // Helper to build toggle options
    Widget buildToggleOption({
      required IconData icon,
      required String title,
      required String subtitle,
      required bool value,
      required ValueChanged<bool> onChanged,
    }) {
      return Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6E3BFF).withAlpha(26), // 0.1 * 255 ≈ 26
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF6E3BFF), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF202124),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(
                      0xFF202124,
                    ).withAlpha(153), // 0.6 * 255 ≈ 153
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF6E3BFF),
          ),
        ],
      );
    }

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            backgroundColor: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF5F3FF), Color(0xFFFFFFFF)],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(
                      0xFF6E3BFF,
                    ).withAlpha(77), // 0.3 * 255 ≈ 77
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with gradient
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF6E3BFF), Color(0xFF9D5CFF)],
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(28),
                          topRight: Radius.circular(28),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(
                                51,
                              ), // 0.2 * 255 ≈ 51
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.video_call_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Create Live Session',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Start a real-time group experience',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Form content
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          buildLabel('Session Title', Icons.title),
                          const SizedBox(height: 8),
                          TextField(
                            controller: titleController,
                            decoration: buildInputDecoration(
                              'Enter session title',
                              Icons.edit_outlined,
                            ),
                            maxLength: 100,
                          ),
                          const SizedBox(height: 16),

                          // Description
                          buildLabel('Description', Icons.description_outlined),
                          const SizedBox(height: 8),
                          TextField(
                            controller: descriptionController,
                            decoration: buildInputDecoration(
                              'Enter description',
                              Icons.notes,
                            ),
                            maxLines: 3,
                            maxLength: 500,
                          ),
                          const SizedBox(height: 16),

                          // Session Type
                          buildLabel('Session Type', Icons.category_outlined),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(
                                  0xFF6E3BFF,
                                ).withAlpha(77), // 0.3 * 255 ≈ 77
                              ),
                            ),
                            child: DropdownButtonFormField<String>(
                              initialValue: sessionType,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                prefixIcon: Icon(
                                  Icons.category_outlined,
                                  color: Color(0xFF6E3BFF),
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'SPEED_DATING',
                                  child: Text('⚡ Speed Dating'),
                                ),
                                DropdownMenuItem(
                                  value: 'CASUAL_CHAT',
                                  child: Text('💬 Casual Chat'),
                                ),
                                DropdownMenuItem(
                                  value: 'GROUP_HANGOUT',
                                  child: Text('👥 Group Hangout'),
                                ),
                                DropdownMenuItem(
                                  value: 'DATING_GAME',
                                  child: Text('🎮 Dating Game'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => sessionType = value);
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Duration and Max Participants in a row
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    buildLabel(
                                      'Duration (min)',
                                      Icons.timer_outlined,
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: durationController,
                                      decoration: buildInputDecoration(
                                        '5-180',
                                        Icons.timer,
                                      ),
                                      keyboardType: TextInputType.number,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    buildLabel(
                                      'Max People',
                                      Icons.people_outline,
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: maxParticipantsController,
                                      decoration: buildInputDecoration(
                                        '2-100',
                                        Icons.people,
                                      ),
                                      keyboardType: TextInputType.number,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Settings section
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF6E3BFF,
                              ).withAlpha(13), // 0.05 * 255 ≈ 13
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(
                                  0xFF6E3BFF,
                                ).withAlpha(26), // 0.1 * 255 ≈ 26
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.settings_outlined,
                                      color: Color(0xFF6E3BFF),
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Session Settings',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF202124),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                buildToggleOption(
                                  icon: Icons.verified_user_outlined,
                                  title: 'Require Approval',
                                  subtitle:
                                      'Approve participants before joining',
                                  value: requireApproval,
                                  onChanged: (v) =>
                                      setState(() => requireApproval = v),
                                ),
                                const Divider(height: 24),
                                buildToggleOption(
                                  icon: Icons.videocam_outlined,
                                  title: 'Allow Video',
                                  subtitle: 'Enable video streaming',
                                  value: allowVideo,
                                  onChanged: (v) =>
                                      setState(() => allowVideo = v),
                                ),
                                const Divider(height: 24),
                                buildToggleOption(
                                  icon: Icons.mic_outlined,
                                  title: 'Allow Audio',
                                  subtitle: 'Enable voice communication',
                                  value: allowAudio,
                                  onChanged: (v) =>
                                      setState(() => allowAudio = v),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Action buttons
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                Navigator.pop(dialogContext);
                                // Delay disposal until after dialog closes
                                Future.delayed(
                                  const Duration(milliseconds: 300),
                                  disposeControllers,
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF6E3BFF),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                // Validation
                                if (titleController.text.trim().isEmpty) {
                                  PulseToast.error(
                                    context,
                                    message: 'Please enter a title',
                                  );
                                  return;
                                }

                                final maxPart =
                                    int.tryParse(
                                      maxParticipantsController.text,
                                    ) ??
                                    10;
                                final duration =
                                    int.tryParse(durationController.text) ?? 30;

                                if (maxPart < 2 || maxPart > 100) {
                                  PulseToast.error(
                                    context,
                                    message: 'Max participants: 2-100',
                                  );
                                  return;
                                }

                                if (duration < 5 || duration > 180) {
                                  PulseToast.error(
                                    context,
                                    message: 'Duration: 5-180 minutes',
                                  );
                                  return;
                                }

                                // Capture values before async
                                final title = titleController.text.trim();
                                final description =
                                    descriptionController.text.trim().isEmpty
                                    ? null
                                    : descriptionController.text.trim();

                                // Show loading
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (c) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );

                                try {
                                  final service = GroupChatService();
                                  final session = await service
                                      .createLiveSession(
                                        title: title,
                                        description: description,
                                        maxParticipants: maxPart,
                                        requireApproval: requireApproval,
                                        sessionType: sessionType,
                                        durationMinutes: duration,
                                        allowVideo: allowVideo,
                                        allowAudio: allowAudio,
                                      );

                                  if (mounted) {
                                    Navigator.of(
                                      context,
                                    ).pop(); // ignore: use_build_context_synchronously
                                  }
                                  if (mounted) {
                                    Navigator.pop(dialogContext); // Close form
                                  }

                                  // Delay disposal until after dialog closes
                                  Future.delayed(
                                    const Duration(milliseconds: 300),
                                    disposeControllers,
                                  );

                                  if (mounted) {
                                    PulseToast.success(
                                      context,
                                      message: 'Live session created!',
                                    );
                                  }

                                  bloc.add(LoadActiveLiveSessions());
                                  if (!mounted) return;
                                  _joinLiveSession(session);
                                } catch (e) {
                                  if (mounted) {
                                    Navigator.of(
                                      context,
                                    ).pop(); // ignore: use_build_context_synchronously
                                  }
                                  if (mounted) {
                                    PulseToast.error(
                                      context,
                                      message: 'Failed: ${e.toString()}',
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6E3BFF),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 2,
                              ),
                              child: Text(
                                'Create',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
              Text('Joining session...', style: TextStyle(color: Colors.white)),
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
      PulseToast.success(context, message: 'Joined ${session.title}');
    } catch (e) {
      // Close loading if still showing
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (!mounted) return;
      PulseToast.error(
        context,
        message: 'Failed to join session: ${e.toString()}',
      );
    }
  }
}

class _GroupCard extends StatelessWidget {
  final GroupConversation group;
  final VoidCallback onTap;

  const _GroupCard({required this.group, required this.onTap});

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
                // Group avatar with initials
                InitialsAvatar(
                  name: group.title,
                  imageUrl: null, // Groups use initials based on name
                  radius: 28,
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
                              color: _getGroupColor(
                                group.groupType,
                              ).withValues(alpha: 0.15),
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
                              child: Icon(
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
                              child: Icon(
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
                    color: _getGroupColor(
                      group.groupType,
                    ).withValues(alpha: 0.1),
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
}

class _LiveSessionCard extends StatelessWidget {
  final LiveSession session;
  final VoidCallback onTap;

  const _LiveSessionCard({required this.session, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Stack(
          children: [
            InitialsAvatar(
              name: session.hostFirstName,
              imageUrl: session.hostAvatarUrl,
              radius: 20,
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
                Icon(
                  Icons.people,
                  size: 14,
                  color: context.onSurfaceVariantColor,
                ),
                const SizedBox(width: 4),
                Text(
                  '${session.currentParticipants}/${session.maxParticipants}',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.onSurfaceVariantColor,
                  ),
                ),
                if (session.isFull) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
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
          child: Text('Join'),
        ),
      ),
    );
  }
}
