import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../blocs/call/call_bloc.dart';
import '../../widgets/call/enhanced_call_controls.dart';
import '../../theme/pulse_colors.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../domain/entities/call.dart';

/// Enhanced video call screen with BLoC integration
class EnhancedVideoCallScreen extends StatefulWidget {
  final UserProfile remoteUser;
  final String callId;
  final bool isIncoming;

  const EnhancedVideoCallScreen({
    super.key,
    required this.remoteUser,
    required this.callId,
    this.isIncoming = false,
  });

  @override
  State<EnhancedVideoCallScreen> createState() => _EnhancedVideoCallScreenState();
}

class _EnhancedVideoCallScreenState extends State<EnhancedVideoCallScreen> {
  bool _showControls = true;
  
  @override
  void initState() {
    super.initState();
    
    // Set landscape orientation for video calls
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    // Auto-hide controls after 5 seconds
    _startControlsTimer();
  }

  @override
  void dispose() {
    // Reset orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  void _startControlsTimer() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    
    if (_showControls) {
      _startControlsTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CallBloc, CallState>(
      listener: (context, state) {
        // Handle call state changes
        if (state.status == CallStatus.ended || 
            state.status == CallStatus.failed ||
            state.status == CallStatus.declined) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: BlocBuilder<CallBloc, CallState>(
          builder: (context, state) {
            return Stack(
              children: [
                // Main video area
                _buildVideoArea(state),
                
                // Controls overlay
                if (_showControls) _buildControlsOverlay(state),
                
                // Connection status overlay
                if (state.connectionState != CallConnectionState.connected)
                  _buildConnectionStatusOverlay(state),
                
                // Tap detector to show/hide controls
                GestureDetector(
                  onTap: _toggleControls,
                  behavior: HitTestBehavior.translucent,
                  child: Container(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildVideoArea(CallState state) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Stack(
        children: [
          // Remote video (main area)
          _buildRemoteVideo(state),
          
          // Local video (small overlay)
          if (state.isVideoEnabled)
            _buildLocalVideoOverlay(state),
        ],
      ),
    );
  }

  Widget _buildRemoteVideo(CallState state) {
    if (state.status == CallStatus.connecting || 
        state.connectionState == CallConnectionState.connecting) {
      return _buildConnectingView();
    }
    
    if (!state.isVideoEnabled || 
        state.connectionState != CallConnectionState.connected) {
      return _buildAudioOnlyView();
    }
    
    // TODO: Integrate with actual WebRTC video renderer
    // For now, show a placeholder
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            PulseColors.primary,
            PulseColors.secondary,
          ],
        ),
      ),
      child: const Center(
        child: Text(
          'WebRTC Video\n(Integration Required)',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildLocalVideoOverlay(CallState state) {
    return Positioned(
      top: 60,
      right: 20,
      child: Container(
        width: 120,
        height: 160,
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              // TODO: Integrate with actual WebRTC local video renderer
              Container(
                color: Colors.grey[800],
                child: const Center(
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
              
              // Camera switch button
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () {
                      context.read<CallBloc>().add(const SwitchCamera());
                    },
                    icon: const Icon(
                      Icons.flip_camera_ios,
                      color: Colors.white,
                      size: 16,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectingView() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            PulseColors.primary,
            PulseColors.secondary,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // User avatar
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 3,
                ),
              ),
              child: ClipOval(
                child: widget.remoteUser.photos.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: widget.remoteUser.photos.first.url,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[700],
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 60,
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[700],
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 60,
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey[700],
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 60,
                        ),
                      ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // User name
            Text(
              widget.remoteUser.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Connection status
            const Text(
              'Connecting...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioOnlyView() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            PulseColors.primary,
            PulseColors.secondary,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // User avatar (larger for audio-only)
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 4,
                ),
              ),
              child: ClipOval(
                child: widget.remoteUser.photos.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: widget.remoteUser.photos.first.url,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[700],
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 75,
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[700],
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 75,
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey[700],
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 75,
                        ),
                      ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // User name
            Text(
              widget.remoteUser.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w600,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Audio indicator
            const Text(
              'Audio Call',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsOverlay(CallState state) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
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
        child: SafeArea(
          top: false,
          child: EnhancedCallControls(
            callId: widget.callId,
            showCameraSwitch: true,
            showScreenShare: false,
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionStatusOverlay(CallState state) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.8),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (state.connectionState == CallConnectionState.reconnecting) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Reconnecting... (${state.reconnectionAttempts}/${state.maxReconnectionAttempts})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ] else if (state.connectionState == CallConnectionState.failed) ...[
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Connection failed',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
