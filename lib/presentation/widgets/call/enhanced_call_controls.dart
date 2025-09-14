import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/call/call_bloc.dart';
import '../../theme/pulse_colors.dart';
import '../../../domain/entities/call.dart';

/// Enhanced call controls widget that integrates with CallBloc
class EnhancedCallControls extends StatelessWidget {
  final String? callId;
  final bool showCameraSwitch;
  final bool showScreenShare;

  const EnhancedCallControls({
    super.key,
    this.callId,
    this.showCameraSwitch = true,
    this.showScreenShare = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CallBloc, CallState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.7),
              ],
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Call status and duration
                if (state.isCallActive) ...[
                  _buildCallStatus(state),
                  const SizedBox(height: 16),
                ],
                
                // Main control buttons
                _buildMainControls(context, state),
                
                // Additional controls
                if (showCameraSwitch || showScreenShare) ...[
                  const SizedBox(height: 16),
                  _buildSecondaryControls(context, state),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCallStatus(CallState state) {
    return Column(
      children: [
        // Connection status indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getConnectionColor(state.connectionState),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              state.connectionDescription,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 4),
        
        // Call duration
        Text(
          state.formattedDuration,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        
        // Call quality indicator
        if (state.quality != CallQuality.excellent) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getQualityIcon(state.quality),
                color: _getQualityColor(state.quality),
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                state.qualityDescription,
                style: TextStyle(
                  color: _getQualityColor(state.quality),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildMainControls(BuildContext context, CallState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Speaker toggle
        _buildControlButton(
          icon: state.isSpeakerEnabled ? Icons.volume_up : Icons.volume_down,
          isEnabled: state.isSpeakerEnabled,
          onTap: () => context.read<CallBloc>().add(
            ToggleSpeaker(enabled: !state.isSpeakerEnabled),
          ),
          tooltip: state.isSpeakerEnabled ? 'Turn off speaker' : 'Turn on speaker',
        ),
        
        // Video toggle
        _buildControlButton(
          icon: state.isVideoEnabled ? Icons.videocam : Icons.videocam_off,
          isEnabled: state.isVideoEnabled,
          onTap: () => context.read<CallBloc>().add(
            ToggleVideo(enabled: !state.isVideoEnabled),
          ),
          tooltip: state.isVideoEnabled ? 'Turn off camera' : 'Turn on camera',
        ),
        
        // End call
        _buildEndCallButton(context, state),
        
        // Audio toggle
        _buildControlButton(
          icon: state.isAudioEnabled ? Icons.mic : Icons.mic_off,
          isEnabled: state.isAudioEnabled,
          onTap: () => context.read<CallBloc>().add(
            ToggleAudio(enabled: !state.isAudioEnabled),
          ),
          tooltip: state.isAudioEnabled ? 'Mute microphone' : 'Unmute microphone',
        ),
      ],
    );
  }

  Widget _buildSecondaryControls(BuildContext context, CallState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (showCameraSwitch && state.isVideoEnabled)
          _buildControlButton(
            icon: Icons.flip_camera_ios,
            isEnabled: true,
            onTap: () => context.read<CallBloc>().add(const SwitchCamera()),
            tooltip: 'Switch camera',
          ),
        
        if (showScreenShare)
          _buildControlButton(
            icon: state.isScreenSharing 
                ? Icons.stop_screen_share 
                : Icons.screen_share,
            isEnabled: state.isScreenSharing,
            onTap: () {
              context.read<CallBloc>().add(
                ToggleScreenShare(enabled: !state.isScreenSharing),
              );
            },
            tooltip: state.isScreenSharing 
                ? 'Stop sharing screen' 
                : 'Share screen',
          ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required bool isEnabled,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isEnabled 
              ? PulseColors.primary.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.2),
          border: Border.all(
            color: isEnabled 
                ? PulseColors.primary
                : Colors.white.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: onTap,
            child: Icon(
              icon,
              color: isEnabled ? PulseColors.primary : Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEndCallButton(BuildContext context, CallState state) {
    return Tooltip(
      message: 'End call',
      child: Container(
        width: 64,
        height: 64,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.red,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(32),
            onTap: () {
              if (state.currentCall != null) {
                context.read<CallBloc>().add(
                  EndCall(callId: state.currentCall!.id),
                );
              }
            },
            child: const Icon(
              Icons.call_end,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  Color _getConnectionColor(CallConnectionState state) {
    switch (state) {
      case CallConnectionState.connected:
        return Colors.green;
      case CallConnectionState.connecting:
      case CallConnectionState.reconnecting:
        return Colors.orange;
      case CallConnectionState.failed:
      case CallConnectionState.disconnected:
        return Colors.red;
    }
  }

  IconData _getQualityIcon(CallQuality quality) {
    switch (quality) {
      case CallQuality.poor:
        return Icons.network_check;
      case CallQuality.fair:
        return Icons.network_check;
      case CallQuality.good:
        return Icons.network_check;
      case CallQuality.excellent:
        return Icons.network_check;
    }
  }

  Color _getQualityColor(CallQuality quality) {
    switch (quality) {
      case CallQuality.poor:
        return Colors.red;
      case CallQuality.fair:
        return Colors.orange;
      case CallQuality.good:
        return Colors.green;
      case CallQuality.excellent:
        return Colors.green;
    }
  }
}
