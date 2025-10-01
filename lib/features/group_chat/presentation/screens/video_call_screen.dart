import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../../bloc/group_chat_bloc.dart';
import '../../data/group_chat_webrtc_service.dart';
import '../../data/models.dart';

/// Video call screen for live session group video/audio calls
/// 
/// Displays a grid layout of participants with real-time video streams,
/// provides controls for mute/video/speaker/camera/end call,
/// and manages participant state changes dynamically.
class VideoCallScreen extends StatefulWidget {
  final String liveSessionId;
  final String rtcToken;
  final LiveSession session;

  const VideoCallScreen({
    super.key,
    required this.liveSessionId,
    required this.rtcToken,
    required this.session,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final Map<int, CallParticipant> _participants = {};
  bool _isInitialized = false;
  GroupChatWebRTCService? _webrtcService;

  @override
  void initState() {
    super.initState();
    _initializeCall();
  }

  Future<void> _initializeCall() async {
    final bloc = context.read<GroupChatBloc>();
    _webrtcService = bloc.webrtcService;

    if (_webrtcService == null) {
      _showError('WebRTC service not available');
      return;
    }

    // Listen to participant events
    _webrtcService!.onUserJoined.listen((participant) {
      setState(() {
        _participants[participant.uid] = participant;
      });
    });

    _webrtcService!.onUserLeft.listen((uid) {
      setState(() {
        _participants.remove(uid);
      });
    });

    _webrtcService!.onLocalUserJoined.listen((uid) {
      setState(() {
        _isInitialized = true;
      });
    });

    _webrtcService!.onError.listen((error) {
      _showError(error);
    });

    // Start the video call
    context.read<GroupChatBloc>().add(StartVideoCall(
          liveSessionId: widget.liveSessionId,
          token: widget.rtcToken,
          enableVideo: true,
        ));
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.session.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '${_participants.length + 1} participants',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        leading: const SizedBox.shrink(), // Hide back button during call
      ),
      body: BlocListener<GroupChatBloc, GroupChatState>(
        listener: (context, state) {
          if (state is VideoCallEnded) {
            Navigator.of(context).pop();
          } else if (state is VideoCallError) {
            _showError(state.message);
          }
        },
        child: !_isInitialized
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Connecting to call...',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              )
            : Stack(
                children: [
                  // Video grid
                  _buildVideoGrid(),

                  // Control buttons at bottom
                  Positioned(
                    bottom: 40,
                    left: 0,
                    right: 0,
                    child: _buildControls(),
                  ),

                  // Session info overlay at top right
                  Positioned(
                    top: 16,
                    right: 16,
                    child: _buildSessionInfo(),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildVideoGrid() {
    final allParticipants = [
      if (_webrtcService?.localUid != null)
        CallParticipant(uid: _webrtcService!.localUid!, hasVideo: _webrtcService!.isVideoEnabled, hasAudio: !_webrtcService!.isMuted),
      ..._participants.values,
    ];

    if (allParticipants.isEmpty) {
      return const Center(
        child: Text(
          'No participants yet',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    // Calculate grid dimensions
    final int participantCount = allParticipants.length;
    final int columns = participantCount <= 2 ? 1 : 2;

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 9 / 16, // Portrait aspect ratio
      ),
      itemCount: participantCount,
      itemBuilder: (context, index) {
        final participant = allParticipants[index];
        final isLocal = participant.uid == _webrtcService?.localUid;
        return _buildParticipantView(participant, isLocal);
      },
    );
  }

  Widget _buildParticipantView(CallParticipant participant, bool isLocal) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLocal ? Colors.blue : Colors.grey[700]!,
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            // Video view
            if (participant.hasVideo && _webrtcService != null)
              isLocal
                  ? AgoraVideoView(
                      controller: VideoViewController(
                        rtcEngine: _webrtcService!.engine!,
                        canvas: const VideoCanvas(uid: 0),
                      ),
                    )
                  : AgoraVideoView(
                      controller: VideoViewController.remote(
                        rtcEngine: _webrtcService!.engine!,
                        canvas: VideoCanvas(uid: participant.uid),
                        connection: RtcConnection(channelId: widget.liveSessionId),
                      ),
                    ),

            // Placeholder when video is off
            if (!participant.hasVideo)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey[800],
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isLocal ? 'You' : 'User ${participant.uid}',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),

            // Audio/video status badges
            Positioned(
              bottom: 8,
              left: 8,
              child: Row(
                children: [
                  if (!participant.hasAudio)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.mic_off,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  const SizedBox(width: 4),
                  if (!participant.hasVideo)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.videocam_off,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),

            // "You" label for local user
            if (isLocal)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'You',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    final isMuted = _webrtcService?.isMuted ?? false;
    final isVideoEnabled = _webrtcService?.isVideoEnabled ?? true;
    final isSpeakerOn = _webrtcService?.isSpeakerOn ?? true;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mute/unmute
          _buildControlButton(
            icon: isMuted ? Icons.mic_off : Icons.mic,
            label: isMuted ? 'Unmute' : 'Mute',
            color: isMuted ? Colors.red : Colors.white,
            onPressed: () {
              context.read<GroupChatBloc>().add(ToggleMute());
              setState(() {});
            },
          ),

          // Video on/off
          _buildControlButton(
            icon: isVideoEnabled ? Icons.videocam : Icons.videocam_off,
            label: isVideoEnabled ? 'Stop Video' : 'Start Video',
            color: isVideoEnabled ? Colors.white : Colors.red,
            onPressed: () {
              context.read<GroupChatBloc>().add(ToggleVideo());
              setState(() {});
            },
          ),

          // Speaker on/off
          _buildControlButton(
            icon: isSpeakerOn ? Icons.volume_up : Icons.volume_off,
            label: isSpeakerOn ? 'Speaker' : 'Earpiece',
            color: Colors.white,
            onPressed: () {
              context.read<GroupChatBloc>().add(ToggleSpeaker());
              setState(() {});
            },
          ),

          // Switch camera
          _buildControlButton(
            icon: Icons.flip_camera_ios,
            label: 'Flip',
            color: Colors.white,
            onPressed: () {
              context.read<GroupChatBloc>().add(SwitchCamera());
            },
          ),

          // End call
          _buildControlButton(
            icon: Icons.call_end,
            label: 'End',
            color: Colors.red,
            onPressed: () {
              _showEndCallDialog();
            },
            size: 60,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    double size = 50,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onPressed,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(icon, color: color, size: size * 0.5),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildSessionInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'LIVE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showEndCallDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Call?'),
        content: const Text('Are you sure you want to end this call?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<GroupChatBloc>().add(EndVideoCall());
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('End Call'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Call will be ended when user leaves the screen
    context.read<GroupChatBloc>().add(EndVideoCall());
    super.dispose();
  }
}
