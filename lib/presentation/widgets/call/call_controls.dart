import 'package:flutter/material.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';

class CallControls extends StatelessWidget {
  final bool isVideoEnabled;
  final bool isAudioEnabled;
  final bool isSpeakerEnabled;
  final VoidCallback onToggleVideo;
  final VoidCallback onToggleAudio;
  final VoidCallback onToggleSpeaker;
  final VoidCallback onEndCall;
  final VoidCallback? onFlipCamera;

  const CallControls({
    super.key,
    required this.isVideoEnabled,
    required this.isAudioEnabled,
    required this.isSpeakerEnabled,
    required this.onToggleVideo,
    required this.onToggleAudio,
    required this.onToggleSpeaker,
    required this.onEndCall,
    this.onFlipCamera,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildControlButton(
          context: context,
          icon: isSpeakerEnabled ? Icons.volume_up : Icons.volume_down,
          isEnabled: isSpeakerEnabled,
          onTap: onToggleSpeaker,
        ),
        _buildControlButton(
          context: context,
          icon: isVideoEnabled ? Icons.videocam : Icons.videocam_off,
          isEnabled: isVideoEnabled,
          onTap: onToggleVideo,
        ),
        _buildEndCallButton(context),
        _buildControlButton(
          context: context,
          icon: isAudioEnabled ? Icons.mic : Icons.mic_off,
          isEnabled: isAudioEnabled,
          onTap: onToggleAudio,
        ),
        _buildControlButton(
          context: context,
          icon: Icons.flip_camera_ios,
          isEnabled: isVideoEnabled,
          onTap:
              onFlipCamera ??
              () {
                // Camera flip only available when video is enabled
              },
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required BuildContext context,
    required IconData icon,
    required bool isEnabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: isEnabled
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.red.withValues(alpha: 0.8),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Icon(icon, color: context.onSurfaceColor, size: 24),
      ),
    );
  }

  Widget _buildEndCallButton(BuildContext context) {
    return GestureDetector(
      onTap: onEndCall,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: context.errorColor,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.call_end, color: context.onSurfaceColor, size: 28),
      ),
    );
  }
}
