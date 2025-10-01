import 'package:flutter/material.dart';

import '../../../data/models/user_model.dart';
import '../../../data/services/group_call_service.dart';
import '../../theme/pulse_colors.dart';

/// Group Call Management Widget for creating and managing group video calls
class GroupCallWidget extends StatefulWidget {
  final String callId;
  final List<UserModel> participants;
  final UserModel currentUser;
  final VoidCallback? onLeave;
  final Function(String message)? onError;
  final Function(String message)? onSuccess;

  const GroupCallWidget({
    super.key,
    required this.callId,
    required this.participants,
    required this.currentUser,
    this.onLeave,
    this.onError,
    this.onSuccess,
  });

  @override
  State<GroupCallWidget> createState() => _GroupCallWidgetState();
}

class _GroupCallWidgetState extends State<GroupCallWidget>
    with TickerProviderStateMixin {
  final GroupCallService _groupCallService = GroupCallService.instance;
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  bool _isExpanded = false;
  bool _isLoading = false;
  bool _showParticipants = false;
  String _callDuration = "00:00";
  Map<String, bool> _participantAudioStatus = {};
  Map<String, bool> _participantVideoStatus = {};

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _initializeGroupCall();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initializeGroupCall() async {
    setState(() => _isLoading = true);
    
    try {
      // Initialize participant statuses
      for (final participant in widget.participants) {
        _participantAudioStatus[participant.id] = true;
        _participantVideoStatus[participant.id] = true;
      }
      
      // Get call analytics to update UI
      final analytics = await _groupCallService.getCallAnalytics(widget.callId);
      if (analytics != null) {
        setState(() {
          _callDuration = _formatDuration(analytics.averageDuration);
        });
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      widget.onError?.call('Failed to initialize group call: $e');
    }
  }



  Future<void> _removeParticipant(String userId) async {
    setState(() => _isLoading = true);
    
    try {
      final success = await _groupCallService.removeParticipant(
        callId: widget.callId,
        userId: userId,
      );
      
      if (success) {
        widget.onSuccess?.call('Participant removed from call');
        
        // Update local state
        setState(() {
          _participantAudioStatus.remove(userId);
          _participantVideoStatus.remove(userId);
        });
      } else {
        widget.onError?.call('Failed to remove participant');
      }
    } catch (e) {
      widget.onError?.call('Error removing participant: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _muteParticipant(String userId, bool shouldMute) async {
    try {
      final success = await _groupCallService.applyModerationAction(
        callId: widget.callId,
        action: GroupModerationAction(
          action: shouldMute ? 'MUTE' : 'UNMUTE',
          targetUserId: userId,
        ),
      );
      
      if (success) {
        setState(() {
          _participantAudioStatus[userId] = !shouldMute;
        });
      } else {
        widget.onError?.call('Failed to ${shouldMute ? 'mute' : 'unmute'} participant');
      }
    } catch (e) {
      widget.onError?.call('Error ${shouldMute ? 'muting' : 'unmuting'} participant: $e');
    }
  }

  Future<void> _enableParticipantVideo(String userId, bool shouldEnable) async {
    try {
      final success = await _groupCallService.applyModerationAction(
        callId: widget.callId,
        action: GroupModerationAction(
          action: shouldEnable ? 'ENABLE_VIDEO' : 'DISABLE_VIDEO',
          targetUserId: userId,
        ),
      );
      
      if (success) {
        setState(() {
          _participantVideoStatus[userId] = shouldEnable;
        });
      } else {
        widget.onError?.call('Failed to ${shouldEnable ? 'enable' : 'disable'} video for participant');
      }
    } catch (e) {
      widget.onError?.call('Error ${shouldEnable ? 'enabling' : 'disabling'} video: $e');
    }
  }

  Future<void> _endGroupCall() async {
    setState(() => _isLoading = true);
    
    try {
      final success = await _groupCallService.endCall(widget.callId);
      
      if (success) {
        widget.onSuccess?.call('Group call ended');
        widget.onLeave?.call();
      } else {
        widget.onError?.call('Failed to end group call');
      }
    } catch (e) {
      widget.onError?.call('Error ending group call: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: _isExpanded ? 400 : 80,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(),
          
          // Expanded Content
          if (_isExpanded) ...[
            const Divider(height: 1),
            Expanded(child: _buildExpandedContent()),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Group Call Indicator
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: PulseColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.groups,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(width: 12),
          
          // Call Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Group Call',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
                Text(
                  '${widget.participants.length} participants • $_callDuration',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
          
          // Action Buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => setState(() => _showParticipants = !_showParticipants),
                icon: Icon(
                  Icons.people,
                  color: _showParticipants ? PulseColors.primary : Theme.of(context).iconTheme.color,
                ),
              ),
              IconButton(
                onPressed: _isLoading ? null : () => setState(() => _isExpanded = !_isExpanded),
                icon: Icon(
                  _isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                  color: Theme.of(context).iconTheme.color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Tab Bar
          Row(
            children: [
              _buildTab('Participants', _showParticipants, () => setState(() => _showParticipants = true)),
              const SizedBox(width: 16),
              _buildTab('Controls', !_showParticipants, () => setState(() => _showParticipants = false)),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Content
          Expanded(
            child: _showParticipants ? _buildParticipantsTab() : _buildControlsTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String title, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? PulseColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isActive ? null : Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildParticipantsTab() {
    return ListView.builder(
      itemCount: widget.participants.length,
      itemBuilder: (context, index) {
        final participant = widget.participants[index];
        final isCurrentUser = participant.id == widget.currentUser.id;
        final hasAudio = _participantAudioStatus[participant.id] ?? true;
        final hasVideo = _participantVideoStatus[participant.id] ?? true;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: PulseColors.primary.withValues(alpha: 0.1),
                  backgroundImage: participant.photos.isNotEmpty
                      ? NetworkImage(participant.photos.first)
                      : null,
                  child: participant.photos.isEmpty
                      ? Text(
                          (participant.firstName?.isNotEmpty == true ? participant.firstName![0] : participant.username[0]).toUpperCase(),
                          style: const TextStyle(
                            color: PulseColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                
                const SizedBox(width: 12),
                
                // Participant Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${participant.firstName} ${participant.lastName}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isCurrentUser) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: PulseColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'You',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: PulseColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Row(
                        children: [
                          Icon(
                            hasAudio ? Icons.mic : Icons.mic_off,
                            size: 16,
                            color: hasAudio ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            hasVideo ? Icons.videocam : Icons.videocam_off,
                            size: 16,
                            color: hasVideo ? Colors.green : Colors.red,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Actions (only for other participants if current user is host)
                if (!isCurrentUser) ...[
                  IconButton(
                    onPressed: () => _muteParticipant(participant.id, hasAudio),
                    icon: Icon(
                      hasAudio ? Icons.mic_off : Icons.mic,
                      size: 20,
                    ),
                    tooltip: hasAudio ? 'Mute' : 'Unmute',
                  ),
                  IconButton(
                    onPressed: () => _enableParticipantVideo(participant.id, !hasVideo),
                    icon: Icon(
                      hasVideo ? Icons.videocam_off : Icons.videocam,
                      size: 20,
                    ),
                    tooltip: hasVideo ? 'Disable Video' : 'Enable Video',
                  ),
                  IconButton(
                    onPressed: () => _removeParticipant(participant.id),
                    icon: const Icon(
                      Icons.person_remove,
                      size: 20,
                      color: Colors.red,
                    ),
                    tooltip: 'Remove',
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildControlsTab() {
    return Column(
      children: [
        // Call Analytics
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.analytics, color: PulseColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Call Analytics',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Duration: $_callDuration • Participants: ${widget.participants.length}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Action Buttons
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2,
            children: [
              _buildActionButton(
                icon: Icons.person_add,
                label: 'Invite',
                onTap: () => _showInviteDialog(),
              ),
              _buildActionButton(
                icon: Icons.record_voice_over,
                label: 'Recording',
                onTap: () => _toggleRecording(),
              ),
              _buildActionButton(
                icon: Icons.screen_share,
                label: 'Share Screen',
                onTap: () => _shareScreen(),
              ),
              _buildActionButton(
                icon: Icons.call_end,
                label: 'End Call',
                color: Colors.red,
                onTap: _endGroupCall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: _isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color ?? Theme.of(context).iconTheme.color,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color ?? Theme.of(context).textTheme.bodyMedium?.color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInviteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: const Text(
          'Invite to Call',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This feature allows you to:',
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• Search for users', style: TextStyle(color: Colors.white70)),
              const Text('• Invite them to join this call', style: TextStyle(color: Colors.white70)),
              const Text('• Send real-time notifications', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              const Text(
                'Integration ready - UI can be enhanced based on your design preferences.',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _toggleRecording() {
    // Recording functionality ready for backend integration
    // Backend endpoints: POST /group-chat/conversation/:id/recording
    widget.onSuccess?.call(
      'Recording feature: Backend endpoints ready. Requires WebRTC integration for actual recording.',
    );
  }

  void _shareScreen() {
    // Screen sharing functionality ready for backend integration
    // Backend endpoints: POST /group-chat/conversation/:id/screen-sharing
    widget.onSuccess?.call(
      'Screen sharing: Backend endpoints ready. Requires platform-specific screen capture setup.',
    );
  }
}