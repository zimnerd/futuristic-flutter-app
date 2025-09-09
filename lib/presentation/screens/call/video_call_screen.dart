import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../widgets/call/call_controls.dart';
import '../../../domain/entities/user_profile.dart';

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

class _VideoCallScreenState extends State<VideoCallScreen> {
  bool _isVideoEnabled = true;
  bool _isAudioEnabled = true;
  bool _isSpeakerEnabled = false;
  bool _isCallConnected = false;
  bool _showControls = true;
  Duration _callDuration = Duration.zero;

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
            onPressed: _acceptCall,
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

  void _initiateCall() {
    // TODO: Implement WebRTC call initiation
    setState(() {
      _isCallConnected = true;
    });
    _startCallTimer();
  }

  void _acceptCall() {
    Navigator.of(context).pop(); // Close dialog
    // TODO: Implement WebRTC call acceptance
    setState(() {
      _isCallConnected = true;
    });
    _startCallTimer();
  }

  void _rejectCall() {
    Navigator.of(context).pop(); // Close dialog
    Navigator.of(context).pop(); // Exit screen
  }

  void _startCallTimer() {
    // TODO: Implement actual call timer
    Future.doWhile(() async {
      if (!mounted || !_isCallConnected) return false;
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _callDuration = Duration(seconds: _callDuration.inSeconds + 1);
        });
      }
      return true;
    });
  }

  void _toggleVideo() {
    setState(() {
      _isVideoEnabled = !_isVideoEnabled;
    });
    // TODO: Implement video toggle
  }

  void _toggleAudio() {
    setState(() {
      _isAudioEnabled = !_isAudioEnabled;
    });
    // TODO: Implement audio toggle
  }

  void _toggleSpeaker() {
    setState(() {
      _isSpeakerEnabled = !_isSpeakerEnabled;
    });
    // TODO: Implement speaker toggle
  }

  void _endCall() {
    setState(() {
      _isCallConnected = false;
    });
    // TODO: Implement call ending
    Navigator.of(context).pop();
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
          : Container(
              // TODO: Replace with actual remote video widget
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
              child: const Center(
                child: Text(
                  'Remote Video Stream',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildLocalVideo() {
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
          child: Container(
            // TODO: Replace with actual local video widget
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.withValues(alpha: 0.5),
                  Colors.blue.withValues(alpha: 0.5),
                ],
              ),
            ),
            child: const Center(
              child: Text(
                'You',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
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
