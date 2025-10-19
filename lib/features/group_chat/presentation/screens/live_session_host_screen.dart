import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../presentation/blocs/group_chat/group_chat_bloc.dart';
import '../../../../presentation/widgets/common/pulse_toast.dart';
import '../../data/models.dart';

class LiveSessionHostScreen extends StatefulWidget {
  final LiveSession session;

  const LiveSessionHostScreen({super.key, required this.session});

  @override
  State<LiveSessionHostScreen> createState() => _LiveSessionHostScreenState();
}

class _LiveSessionHostScreenState extends State<LiveSessionHostScreen> {
  @override
  void initState() {
    super.initState();
    // Join the live session room for real-time updates
    context.read<GroupChatBloc>().add(JoinLiveSessionRoom(widget.session.id));
    // Load pending join requests
    _loadJoinRequests();
  }

  void _loadJoinRequests() {
    context.read<GroupChatBloc>().add(
      LoadPendingJoinRequests(widget.session.id),
    );
  }

  @override
  void dispose() {
    // Leave the live session room
    context.read<GroupChatBloc>().add(LeaveLiveSessionRoom(widget.session.id));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.session.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSessionSettings,
          ),
          IconButton(
            icon: const Icon(Icons.stop_circle),
            onPressed: _showEndSessionDialog,
          ),
        ],
      ),
      body: BlocConsumer<GroupChatBloc, GroupChatState>(
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
            final requests = state.pendingRequests;

            return Column(
              children: [
                _buildSessionInfo(),
                const Divider(height: 1),
                Expanded(
                  child: requests.isEmpty
                      ? _buildEmptyState()
                      : _buildRequestsList(requests),
                ),
              ],
            );
          }

          return _buildEmptyState();
        },
      ),
    );
  }

  Widget _buildSessionInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.greenAccent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'LIVE',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.people,
                size: 20,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 4),
              Text(
                '${widget.session.currentParticipants}/${widget.session.maxParticipants}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.session.description ?? 'No description',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
          Icon(Icons.pending_actions, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No pending join requests',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Waiting for people to request joining...',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsList(List<JoinRequest> requests) {
    return RefreshIndicator(
      onRefresh: () async {
        _loadJoinRequests();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          return _JoinRequestCard(
            request: requests[index],
            onApprove: () => _approveRequest(requests[index]),
            onReject: () => _rejectRequest(requests[index]),
          );
        },
      ),
    );
  }

  void _approveRequest(JoinRequest request) {
    context.read<GroupChatBloc>().add(ApproveJoinRequest(request.id));
    PulseToast.success(context, message: 'Approved ${request.requesterName}');
  }

  void _rejectRequest(JoinRequest request) {
    context.read<GroupChatBloc>().add(RejectJoinRequest(request.id));
    PulseToast.info(context, message: 'Rejected ${request.requesterName}');
  }

  void _showSessionSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Session Settings'),
              subtitle: Text(widget.session.title),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text('Current Participants'),
              trailing: Text('${widget.session.currentParticipants}'),
            ),
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text(
                'Require Approval',
                style: TextStyle(
                  color: Color(0xFF202124),
                ), // PulseColors.onSurface
              ),
              trailing: Switch(
                value: widget.session.requireApproval,
                onChanged: null, // Read-only for now
              ),
            ),
            ListTile(
              leading: const Icon(Icons.people_alt),
              title: const Text('Max Participants'),
              trailing: Text(widget.session.maxParticipants.toString()),
            ),
          ],
        ),
      ),
    );
  }

  void _showEndSessionDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('End Live Session'),
        content: const Text(
          'Are you sure you want to end this live session? All participants will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop(); // Go back to previous screen
              PulseToast.success(context, message: 'Live session ended');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('End Session'),
          ),
        ],
      ),
    );
  }
}

class _JoinRequestCard extends StatelessWidget {
  final JoinRequest request;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _JoinRequestCard({
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: request.requesterPhoto != null
                      ? CachedNetworkImageProvider(request.requesterPhoto!)
                      : null,
                  child: request.requesterPhoto == null
                      ? Text(
                          request.requesterName[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.requesterName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (request.requesterAge != null)
                        Text(
                          '${request.requesterAge} years old',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      Text(
                        _formatTime(request.requestedAt),
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (request.message != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  request.message!,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final duration = DateTime.now().difference(time);
    if (duration.inMinutes < 1) {
      return 'Just now';
    } else if (duration.inHours < 1) {
      return '${duration.inMinutes}m ago';
    } else if (duration.inDays < 1) {
      return '${duration.inHours}h ago';
    } else {
      return '${duration.inDays}d ago';
    }
  }
}
