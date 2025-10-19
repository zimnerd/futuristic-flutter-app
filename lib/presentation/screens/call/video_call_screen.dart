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
import '../../../core/services/call_invitation_service.dart';
import '../../../core/models/call_invitation.dart';

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
  final CallInvitationService _callInvitationService = CallInvitationService();
  final MessagingService _messagingService = MessagingService(
    apiClient: ApiClient.instance,
  );

  StreamSubscription<Map<String, dynamic>>? _connectionStatusSubscription;

  bool _isVideoEnabled = true;
  bool _isAudioEnabled = true;
  bool _isSpeakerEnabled = false;
  bool _isCallConnected = false;
  bool _showControls = true;
  Duration _callDuration = Duration.zero;
  Timer? _callDurationTimer;
  DateTime? _callStartTime;
  
  // NEW: Track connection status
  CallConnectionStatus _connectionStatus = CallConnectionStatus.ringing;
  bool _isJoiningCall = false; // Prevent duplicate joins
  String? _pendingChannelName;
  String? _pendingToken;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // NEW: Setup connection status listener first
    _setupConnectionStatusListener();

    if (widget.isIncoming) {
      _showIncomingCallDialog();
    } else {
      // NEW: Don't initiate call immediately, wait for ready_to_connect event
      _prepareForCall();
    }
  }

  /// NEW: Prepare for call but don't join yet
  Future<void> _prepareForCall() async {
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

      setState(() {
        _connectionStatus = CallConnectionStatus.ringing;
      });

      AppLogger.info('Video call prepared, waiting for ready_to_connect event');
    } catch (e) {
      AppLogger.error('Failed to prepare call: $e');
      if (mounted) {
        PulseToast.error(
          context,
          message: 'Failed to prepare call: ${e.toString()}',
        );
        Navigator.of(context).pop();
      }
    }
  }

  /// NEW: Listen for connection status events from backend
  void _setupConnectionStatusListener() {
    _connectionStatusSubscription = _callInvitationService
        .onConnectionStatusChanged
        .listen((statusData) {
          final event = statusData['event'] as String;
          final callId = statusData['callId'] as String;

          // Only process events for this call
          if (callId != widget.callId) return;

          AppLogger.info(
            'Video call connection status event: $event for call $callId',
          );

          switch (event) {
            case 'ready_to_connect':
              // Both users accepted, now join WebRTC
              _handleReadyToConnect(statusData);
              break;
            case 'connected':
              // Both users in WebRTC channel, start timer
              _handleCallConnected();
              break;
            case 'failed':
              // Call failed (offline, network error, etc.)
              _handleCallFailed(statusData['reason'] as String?);
              break;
          }
        });
  }

  /// NEW: Handle ready to connect - Join WebRTC channel now
  void _handleReadyToConnect(Map<String, dynamic> data) {
    if (_isJoiningCall) {
      AppLogger.warning('Already joining WebRTC, skipping duplicate join');
      return;
    }

    setState(() {
      _isJoiningCall = true;
      _connectionStatus = CallConnectionStatus.connecting;
      _pendingChannelName = data['channelName'] as String?;
      _pendingToken = data['token'] as String?;
    });

    _initiateCall();
  }

  /// NEW: Handle call connected - Start timer NOW
  void _handleCallConnected() {
    setState(() {
      _connectionStatus = CallConnectionStatus.connected;
      _callStartTime = DateTime.now();
      _isCallConnected = true;
    });
    _startCallTimer();
    AppLogger.info('Video call connected - timer started');
  }

  /// NEW: Handle call failed
  void _handleCallFailed(String? reason) {
    setState(() {
      _connectionStatus = CallConnectionStatus.failed;
    });
    AppLogger.error('Video call failed: ${reason ?? "Unknown reason"}');
    if (mounted) {
      PulseToast.error(
        context,
        message: 'Call failed: ${reason ?? "User is offline or unreachable"}',
      );
      Navigator.of(context).pop();
    }
  }

  /// NEW: Get call status text based on connection status
  String _getCallStatusText() {
    switch (_connectionStatus) {
      case CallConnectionStatus.ringing:
        return 'Ringing...';
      case CallConnectionStatus.connecting:
        return 'Connecting...';
      case CallConnectionStatus.connected:
        return 'Connected';
      case CallConnectionStatus.ended:
        return 'Call ended';
      case CallConnectionStatus.failed:
        return 'Connection failed';
      case CallConnectionStatus.noAnswer:
        return 'No answer';
      case CallConnectionStatus.declined:
        return 'Call declined';
    }
  }

  @override
  void dispose() {
    _connectionStatusSubscription?.cancel();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
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
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text('Video call'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _rejectCall,
            child: const Text('Decline', style: TextStyle(color: Colors.red)),
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
      // UPDATED: Use pending token from ready_to_connect event if available
      String token;
      String channelName;

      if (_pendingToken != null && _pendingChannelName != null) {
        // Use token from ready_to_connect event (both users accepted)
        token = _pendingToken!;
        channelName = _pendingChannelName!;
        AppLogger.info('Using token from ready_to_connect event');
      } else {
        // Fallback: Get fresh token (shouldn't happen in normal flow)
        AppLogger.warning(
          'No pending token, requesting fresh token from backend',
        );
        final tokenResponse = await ApiClient.instance.post(
          '/webrtc/calls/${widget.callId}/token',
        );

        if (tokenResponse.data == null) {
          throw Exception('Failed to get call token');
        }

        token = tokenResponse.data['token'] as String;
        channelName = tokenResponse.data['channelName'] as String;
      }

      // Start WebRTC call with token from backend
      await _webRTCService.startCall(
        receiverId: widget.remoteUser.id,
        receiverName: widget.remoteUser.name,
        receiverAvatar: widget.remoteUser.photos.isNotEmpty
            ? widget.remoteUser.photos.first.url
            : null,
        callType: model.CallType.video,
        channelName: channelName,
        token: token,
      );

      // REMOVED: Don't set _isCallConnected or start timer here
      // Wait for call_connected event from backend instead
      AppLogger.info('Joined WebRTC channel, waiting for call_connected event');
    } catch (e) {
      AppLogger.error('Failed to initiate call: $e');
      setState(() {
        _connectionStatus = CallConnectionStatus.failed;
      });
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
      await _webRTCService.answerCall(channelName: channelName, token: token);

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
                  // NEW: Show connection status based on enum
                  Text(
                    _getCallStatusText(),
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            )
          : StreamBuilder<List<int>>(
              stream: _webRTCService.remoteUsersStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData ||
                    snapshot.data!.isEmpty ||
                    _webRTCService.engine == null) {
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
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
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
            colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
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
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
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
            colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
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
