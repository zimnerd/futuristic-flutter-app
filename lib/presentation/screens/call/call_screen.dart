import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../blocs/call_bloc.dart';
import '../../theme/pulse_colors.dart';
import '../../widgets/common/pulse_toast.dart';
import '../../../data/models/call_model.dart';

class CallScreen extends StatefulWidget {
  final CallModel? initialCall;

  const CallScreen({super.key, this.initialCall});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  int? _remoteUid;
  late RtcEngine _engine;
  bool _isCallControls = true;

  @override
  void initState() {
    super.initState();
    _hideControlsTimer();
  }

  void _hideControlsTimer() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _isCallControls = false;
        });
      }
    });
  }

  void _showControls() {
    setState(() {
      _isCallControls = true;
    });
    _hideControlsTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocConsumer<CallBloc, CallState>(
        listener: (context, state) {
          if (state is CallEnded) {
            Navigator.of(context).pop();
          } else if (state is CallError) {
            PulseToast.error(context, message: state.message,
            );
            Navigator.of(context).pop();
          }
        },
        builder: (context, state) {
          return GestureDetector(
            onTap: _showControls,
            child: Stack(
              children: [
                _buildVideoBackground(state),
                _buildCallInfo(state),
                if (_isCallControls) _buildCallControls(state),
                _buildStatusInfo(state),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildVideoBackground(CallState state) {
    if (state is CallInProgress && state.call.type == CallType.video) {
      return Stack(
        children: [
          // Remote video (full screen)
          _remoteUid != null
              ? AgoraVideoView(
                  controller: VideoViewController.remote(
                    rtcEngine: _engine,
                    canvas: VideoCanvas(uid: _remoteUid),
                    connection: const RtcConnection(channelId: ''),
                  ),
                )
              : _buildWaitingForVideo(state.call),
          
          // Local video (small window)
          if (state.isVideoEnabled)
            Positioned(
              top: 60,
              right: 20,
              child: Container(
                width: 120,
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: AgoraVideoView(
                    controller: VideoViewController(
                      rtcEngine: _engine,
                      canvas: const VideoCanvas(uid: 0),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    }

    // Audio call or waiting background
    if (state is CallInProgress) {
      return _buildAudioCallBackground(state.call);
    } else if (state is CallRinging) {
      return _buildAudioCallBackground(state.call);
    } else if (state is CallConnecting) {
      return _buildAudioCallBackground(state.call);
    }

    return Container(color: Colors.black);
  }

  Widget _buildWaitingForVideo(CallModel call) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF6E3BFF),
            Color(0xFF4CAF50),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 80,
            backgroundImage: call.receiverAvatar != null
                ? CachedNetworkImageProvider(call.receiverAvatar!)
                : null,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: call.receiverAvatar == null
                ? Text(
                    call.receiverName[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 24),
          const Text(
            'Waiting for video...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioCallBackground(CallModel call) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF6E3BFF),
            Color(0xFF4CAF50),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 100,
            backgroundImage: call.receiverAvatar != null
                ? CachedNetworkImageProvider(call.receiverAvatar!)
                : null,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: call.receiverAvatar == null
                ? Text(
                    call.receiverName[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 60,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 32),
          Text(
            call.receiverName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallInfo(CallState state) {
    String statusText = '';
    if (state is CallConnecting) {
      statusText = 'Connecting...';
    } else if (state is CallRinging) {
      statusText = 'Ringing...';
    } else if (state is CallInProgress) {
      statusText = 'Connected';
    }

    return Positioned(
      top: MediaQuery.of(context).padding.top + 20,
      left: 20,
      right: 20,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              context.read<CallBloc>().add(const EndCall());
            },
          ),
          Expanded(
            child: Text(
              statusText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 48), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildCallControls(CallState state) {
    return Positioned(
      bottom: 80,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Mute button
            if (state is CallInProgress)
              _buildControlButton(
                icon: state.isMuted ? Icons.mic_off : Icons.mic,
                backgroundColor: state.isMuted ? Colors.red : Colors.white.withValues(alpha: 0.3),
                onPressed: () {
                  context.read<CallBloc>().add(const ToggleMute());
                },
              ),

            // Speaker button (for audio calls)
            if (state is CallInProgress && state.call.type == CallType.audio)
              _buildControlButton(
                icon: state.isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                backgroundColor: state.isSpeakerOn ? PulseColors.primary : Colors.white.withValues(alpha: 0.3),
                onPressed: () {
                  context.read<CallBloc>().add(const ToggleSpeaker());
                },
              ),

            // Video controls (for video calls)
            if (state is CallInProgress && state.call.type == CallType.video) ...[
              _buildControlButton(
                icon: state.isVideoEnabled ? Icons.videocam : Icons.videocam_off,
                backgroundColor: state.isVideoEnabled ? Colors.white.withValues(alpha: 0.3) : Colors.red,
                onPressed: () {
                  context.read<CallBloc>().add(const ToggleCamera());
                },
              ),
              _buildControlButton(
                icon: Icons.flip_camera_ios,
                backgroundColor: Colors.white.withValues(alpha: 0.3),
                onPressed: () {
                  context.read<CallBloc>().add(const SwitchCamera());
                },
              ),
            ],

            // End call button
            _buildControlButton(
              icon: Icons.call_end,
              backgroundColor: Colors.red,
              onPressed: () {
                if (state is CallRinging) {
                  context.read<CallBloc>().add(const DeclineCall());
                } else {
                  context.read<CallBloc>().add(const EndCall());
                }
              },
              size: 60,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusInfo(CallState state) {
    if (state is CallRinging) {
      return Positioned(
        bottom: 180,
        left: 0,
        right: 0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Answer button
              _buildControlButton(
                icon: Icons.call,
                backgroundColor: Colors.green,
                onPressed: () {
                  context.read<CallBloc>().add(const AnswerCall());
                },
                size: 60,
              ),
              // Decline button
              _buildControlButton(
                icon: Icons.call_end,
                backgroundColor: Colors.red,
                onPressed: () {
                  context.read<CallBloc>().add(const DeclineCall());
                },
                size: 60,
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color backgroundColor,
    required VoidCallback onPressed,
    double size = 50,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: Colors.white,
          size: size * 0.4,
        ),
        onPressed: onPressed,
      ),
    );
  }
}