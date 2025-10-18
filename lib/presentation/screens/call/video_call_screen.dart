import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart'; // ✅ ADDED: For video rendering

import '../../widgets/call/call_controls.dart';
import '../../widgets/common/pulse_toast.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../data/services/webrtc_service.dart';
import '../../../data/services/messaging_service.dart';
import '../../../data/services/conversation_service.dart';
import '../../../data/models/call_model.dart' as model;
import '../../../core/mixins/permission_required_mixin.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/logger.dart';

class VideoCallScreen extends StatefulWidget {
  final UserProfile remoteUser;
  final String callId;
  final bool isIncoming;

  const VideoCallScreen({
    super.key,
    required this.remoteUser,
    required this.callId,
    this.isIncoming = false,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen>
    with PermissionRequiredMixin {
  final WebRTCService _webRTCService = WebRTCService();
  final MessagingService _messagingService = MessagingService(
    apiClient: ApiClient.instance,
  );
  
  bool _isVideoEnabled = true;
  bool _isAudioEnabled = true;
  bool _isSpeakerEnabled = false;
  bool _isCallConnected = false;
  bool _showControls = true;
  Duration _callDuration = Duration.zero;
  Timer? _callDurationTimer;
  DateTime? _callStartTime;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    if (widget.isIncoming) {
      _showIncomingCallDialog();
    } else {
      _initiateCall();
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  void _showIncomingCallDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Incoming Call'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: widget.remoteUser.photos.isNotEmpty
                  ? NetworkImage(widget.remoteUser.photos.first.url)
                  : null,
              child: widget.remoteUser.photos.isEmpty
                  ? Text(
                      widget.remoteUser.name[0].toUpperCase(),
                      style: const TextStyle(fontSize: 24),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              widget.remoteUser.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Video call'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _rejectCall,
            child: const Text(
              'Decline',
              style: TextStyle(color: Colors.red),
            ),
          ),
          ElevatedButton(
            onPressed: _answerCall,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  void _initiateCall() async {
    try {
      // Request permissions first
      final hasPermissions = await ensureVideoCallPermissions();
      if (!hasPermissions) {
        if (mounted) {
          PulseToast.error(
            context,
            message:
                'Camera and microphone permissions are required for video calls',
          );
          Navigator.of(context).pop();
        }
        return;
      }

      // Get call token from backend
      final tokenResponse = await ApiClient.instance.post(
        '/webrtc/calls/${widget.callId}/token',
      );
      
      if (tokenResponse.data == null) {
        throw Exception('Failed to get call token');
      }
      
      final String token = tokenResponse.data['token'] as String;
      final String channelName = tokenResponse.data['channelName'] as String;

      // Start WebRTC call with real token from backend
      await _webRTCService.startCall(
        receiverId: widget.remoteUser.id,
        receiverName: widget.remoteUser.name,
        receiverAvatar: widget.remoteUser.photos.isNotEmpty ? widget.remoteUser.photos.first.url : null,
        callType: model.CallType.video,
        channelName: channelName,
        token: token,
      );
      
      setState(() {
        _isCallConnected = true;
        _callStartTime = DateTime.now(); // Start tracking call duration
      });
      _startCallTimer();
    } catch (e) {
      debugPrint('Failed to initiate call: $e');
      if (mounted) {
        PulseToast.error(
          context,
          message: 'Failed to start call: ${e.toString()}',
        );
        Navigator.of(context).pop();
      }
    }
  }

  void _answerCall() async {
    if (mounted) {
      Navigator.of(context).pop(); // Close dialog
    }
    
    try {
      // Request permissions first
      final hasPermissions = await ensureVideoCallPermissions();
      if (!hasPermissions) {
        if (mounted) {
          PulseToast.error(
            context,
            message:
                'Camera and microphone permissions are required for video calls',
          );
          Navigator.of(context).pop();
        }
        return;
      }

      // Get call token from backend
      final tokenResponse = await ApiClient.instance.post(
        '/webrtc/calls/${widget.callId}/token',
      );
      
      if (tokenResponse.data == null) {
        throw Exception('Failed to get call token');
      }
      
      final String token = tokenResponse.data['token'] as String;
      final String channelName = tokenResponse.data['channelName'] as String;

      // Answer WebRTC call with real token from backend
      await _webRTCService.answerCall(
        channelName: channelName,
        token: token,
      );
      
      if (mounted) {
        setState(() {
          _isCallConnected = true;
          _callStartTime = DateTime.now(); // Start tracking call duration
        });
      }
      _startCallTimer();
    } catch (e) {
      debugPrint('Failed to accept call: $e');
      if (mounted) {
        PulseToast.error(
          context,
          message: 'Failed to accept call: ${e.toString()}',
        );
        Navigator.of(context).pop();
      }
    }
  }

  void _rejectCall() {
    if (mounted) {
      Navigator.of(context).pop(); // Close dialog
      Navigator.of(context).pop(); // Exit screen
    }
  }

  void _startCallTimer() {
    // Start timer for call duration tracking
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_isCallConnected) {
        timer.cancel();
        return;
      }

      setState(() {
        _callDuration = Duration(seconds: _callDuration.inSeconds + 1);
      });
    });
  }

  void _toggleVideo() async {
    try {
      await _webRTCService.toggleCamera();
      setState(() {
        _isVideoEnabled = !_isVideoEnabled;
      });
    } catch (e) {
      debugPrint('Failed to toggle video: $e');
    }
  }

  void _toggleAudio() async {
    try {
      await _webRTCService.toggleMute();
      setState(() {
        _isAudioEnabled = !_isAudioEnabled;
      });
    } catch (e) {
      debugPrint('Failed to toggle audio: $e');
    }
  }

  void _toggleSpeaker() async {
    try {
      await _webRTCService.toggleSpeaker();
      setState(() {
        _isSpeakerEnabled = !_isSpeakerEnabled;
      });
    } catch (e) {
      debugPrint('Failed to toggle speaker: $e');
    }
  }

  void _endCall() async {
    try {
      // Calculate call duration
      final duration = _callStartTime != null
          ? DateTime.now().difference(_callStartTime!).inSeconds
          : 0;

      // End the WebRTC call first
      await _webRTCService.endCall();
      
      // Stop call duration timer
      _callDurationTimer?.cancel();

      // Try to create call message (don't block navigation if it fails)
      _createCallMessageAsync(duration);
      
      if (mounted) {
        setState(() {
          _isCallConnected = false;
        });
        Navigator.of(context).pop();
      }
    } catch (e) {
      AppLogger.error('Failed to end call: $e');
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  // Create call message asynchronously (don't wait for it)
  Future<void> _createCallMessageAsync(int duration) async {
    try {
      // Get or create conversation directly
      final conversationService = ConversationService();
      final conversation = await conversationService.createConversation(
        participantId: widget.remoteUser.id,
      );

      if (conversation != null) {
        await _messagingService.createCallMessage(
          conversationId: conversation.id,
          callType: 'video',
          duration: duration,
          isIncoming: widget.isIncoming,
          isMissed: !_isCallConnected,
        );
        AppLogger.info(
          'Video call message created: duration=${duration}s, connected=$_isCallConnected',
        );
      }
    } catch (e) {
      AppLogger.error('Failed to create video call message: $e');
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            // Remote video (full screen)
            _buildRemoteVideo(),
            
            // Local video (picture-in-picture)
            if (_isVideoEnabled) _buildLocalVideo(),
            
            // Call info overlay
            if (_showControls) _buildCallInfo(),
            
            // Call controls
            if (_showControls) _buildCallControls(),
          ],
        ),
      ),
    );
  }

  // ✅ FIXED: Build remote video with actual Agora video view
  Widget _buildRemoteVideo() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black87,
      child: !_isCallConnected
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 80,
                    backgroundImage: widget.remoteUser.photos.isNotEmpty
                        ? NetworkImage(widget.remoteUser.photos.first.url)
                        : null,
                    child: widget.remoteUser.photos.isEmpty
                        ? Text(
                            widget.remoteUser.name[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 48,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.remoteUser.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Calling...',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : StreamBuilder<List<int>>(
              stream: _webRTCService.remoteUsersStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty || _webRTCService.engine == null) {
                  // Waiting for remote user to join
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.blue.withValues(alpha: 0.3),
                          Colors.purple.withValues(alpha: 0.3),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(color: Colors.white),
                          const SizedBox(height: 16),
                          Text(
                            'Waiting for ${widget.remoteUser.name.split(' ').first} to join...',
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final remoteUid = snapshot.data!.first;
                
                // ✅ RENDER ACTUAL REMOTE VIDEO
                return AgoraVideoView(
                  controller: VideoViewController.remote(
                    rtcEngine: _webRTCService.engine!,
                    canvas: VideoCanvas(uid: remoteUid),
                    connection: RtcConnection(channelId: widget.callId),
                  ),
                );
              },
            ),
    );
  }

  // ✅ FIXED: Build local video with actual Agora video view
  Widget _buildLocalVideo() {
    if (_webRTCService.engine == null) {
      return const SizedBox.shrink(); // Don't show anything if engine not ready
    }

    return Positioned(
      top: 60,
      right: 16,
      child: Container(
        width: 120,
        height: 160,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24, width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: AgoraVideoView(
            controller: VideoViewController(
              rtcEngine: _webRTCService.engine!,
              canvas: const VideoCanvas(uid: 0), // uid 0 = local user
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCallInfo() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          right: 16,
          bottom: 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            const Spacer(),
            Column(
              children: [
                Text(
                  widget.remoteUser.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_isCallConnected) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatDuration(_callDuration),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
          top: 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: CallControls(
          isVideoEnabled: _isVideoEnabled,
          isAudioEnabled: _isAudioEnabled,
          isSpeakerEnabled: _isSpeakerEnabled,
          onToggleVideo: _toggleVideo,
          onToggleAudio: _toggleAudio,
          onToggleSpeaker: _toggleSpeaker,
          onEndCall: _endCall,
        ),
      ),
    );
  }
}
