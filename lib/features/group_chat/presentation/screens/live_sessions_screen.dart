import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../presentation/blocs/group_chat/group_chat_bloc.dart';
import '../../data/models.dart';
import 'video_call_screen.dart';
import '../../../../data/services/webrtc_service.dart';
import '../../../../presentation/widgets/common/pulse_toast.dart';

class LiveSessionsScreen extends StatefulWidget {
  const LiveSessionsScreen({super.key});

  @override
  State<LiveSessionsScreen> createState() => _LiveSessionsScreenState();
}

class _LiveSessionsScreenState extends State<LiveSessionsScreen> {
  GroupType? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  void _loadSessions() {
    context.read<GroupChatBloc>().add(
          LoadActiveLiveSessions(filterByType: _selectedFilter),
        );
  }

  void _onFilterChanged(GroupType? type) {
    setState(() {
      _selectedFilter = type;
    });
    _loadSessions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Sessions'),
        actions: [
          PopupMenuButton<GroupType?>(
            icon: const Icon(Icons.filter_list),
            onSelected: _onFilterChanged,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('All'),
              ),
              const PopupMenuItem(
                value: GroupType.dating,
                child: Text('Dating'),
              ),
              const PopupMenuItem(
                value: GroupType.speedDating,
                child: Text('Speed Dating'),
              ),
              const PopupMenuItem(
                value: GroupType.study,
                child: Text('Study'),
              ),
              const PopupMenuItem(
                value: GroupType.interest,
                child: Text('Interest'),
              ),
            ],
          ),
        ],
      ),
      body: BlocConsumer<GroupChatBloc, GroupChatState>(
        listener: (context, state) {
          if (state is GroupChatError) {
            PulseToast.error(context, message: state.message);
          } else if (state is JoinRequestSent) {
            PulseToast.success(context, message: 'Join request sent! Waiting for approval...');
            _loadSessions(); // Reload to show updated state
          }
        },
        builder: (context, state) {
          if (state is GroupChatLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is GroupChatLoaded) {
            final sessions = state.liveSessions;

            if (sessions.isEmpty) {
              return _buildEmptyState();
            }

            return RefreshIndicator(
              onRefresh: () async {
                _loadSessions();
              },
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: sessions.length,
                itemBuilder: (context, index) {
                  return _LiveSessionCard(
                    session: sessions[index],
                    onTap: () => _onSessionTap(sessions[index]),
                  );
                },
              ),
            );
          }

          return _buildEmptyState();
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_call_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No active live sessions',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later or create your own!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  void _onSessionTap(LiveSession session) {
    if (session.requireApproval) {
      _showJoinRequestDialog(session);
    } else {
      _joinSessionDirectly(session);
    }
  }

  void _showJoinRequestDialog(LiveSession session) {
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Join ${session.title}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hosted by ${session.hostName}'),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Message (optional)',
                hintText: 'Introduce yourself...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 200,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<GroupChatBloc>().add(
                    RequestToJoinSession(
                      liveSessionId: session.id,
                      message: messageController.text.trim().isEmpty
                          ? null
                          : messageController.text.trim(),
                    ),
                  );
            },
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
  }

  void _joinSessionDirectly(LiveSession session) {
    // Join WebSocket room
    context.read<GroupChatBloc>().add(JoinLiveSessionRoom(session.id));

    // Show video call option
    _showVideoCallDialog(session);
  }

  void _showVideoCallDialog(LiveSession session) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Join ${session.title}'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Would you like to join with video/audio?'),
            SizedBox(height: 8),
            Text(
              'You can chat without video or join the video call.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              // Navigate to chat screen (to be implemented)
              PulseToast.success(context, message: 'Joined ${session.title} chat');
            },
            child: const Text('Chat Only'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _navigateToVideoCall(session);
            },
            icon: const Icon(Icons.videocam),
            label: const Text('Join Video Call'),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToVideoCall(LiveSession session) async {
    try {
      // Show loading indicator
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Get RTC token from backend using session ID as channel name
      final webrtcService = WebRTCService();
      final tokenData = await webrtcService.getRtcToken(
        channelName: session.id,
        role: 1, // PUBLISHER role for live sessions
      );

      // Close loading dialog
      if (!mounted) return;
      Navigator.of(context).pop();

      // Navigate to video call screen with token
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => BlocProvider.value(
            value: context.read<GroupChatBloc>(),
            child: VideoCallScreen(
              liveSessionId: session.id,
              rtcToken: tokenData['token'] as String,
              session: session,
            ),
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
      PulseToast.error(context, message: 'Failed to join session: ${e.toString()}');
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
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: session.isFull ? null : onTap,
        child: Stack(
          children: [
            // Background gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _getGradientColors(session.groupType),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Host avatar and status
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: session.hostPhoto != null
                            ? CachedNetworkImageProvider(session.hostPhoto!)
                            : null,
                        child: session.hostPhoto == null
                            ? Text(
                                session.hostName[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          session.hostName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildStatusBadge(),
                    ],
                  ),

                  const Spacer(),

                  // Session title
                  Text(
                    session.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // Participant count and type
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: Colors.white.a * 0.2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.people,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${session.currentParticipants}/${session.maxParticipants}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: Colors.white.a * 0.2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getGroupTypeLabel(session.groupType),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Time elapsed
                  if (session.startedAt != null)
                    Text(
                      _getTimeElapsed(session.startedAt!),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),

            // Full badge overlay
            if (session.isFull)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5),
                  child: const Center(
                    child: Chip(
                      label: Text(
                        'FULL',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: Colors.red,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    if (session.status == LiveSessionStatus.active) {
      return Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.greenAccent,
          shape: BoxShape.circle,
        ),
      );
    }
    return const SizedBox.shrink();
  }

  List<Color> _getGradientColors(GroupType type) {
    switch (type) {
      case GroupType.dating:
        return [Colors.pink.shade400, Colors.purple.shade600];
      case GroupType.speedDating:
        return [Colors.red.shade400, Colors.orange.shade600];
      case GroupType.study:
        return [Colors.blue.shade400, Colors.cyan.shade600];
      case GroupType.interest:
        return [Colors.green.shade400, Colors.teal.shade600];
      case GroupType.liveHost:
        return [Colors.deepPurple.shade400, Colors.indigo.shade600];
      default:
        return [Colors.grey.shade500, Colors.blueGrey.shade700];
    }
  }

  String _getGroupTypeLabel(GroupType type) {
    switch (type) {
      case GroupType.dating:
        return '💕 Dating';
      case GroupType.speedDating:
        return '⚡ Speed Date';
      case GroupType.study:
        return '📚 Study';
      case GroupType.interest:
        return '🎯 Interest';
      case GroupType.liveHost:
        return '🎥 Live';
      default:
        return 'Chat';
    }
  }

  String _getTimeElapsed(DateTime startedAt) {
    final duration = DateTime.now().difference(startedAt);
    if (duration.inHours > 0) {
      return '${duration.inHours}h ago';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
