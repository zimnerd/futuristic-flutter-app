import 'dart:async';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

import '../../../data/services/audio_call_service.dart';
import '../../../data/models/user_model.dart';
import '../../theme/pulse_colors.dart';
import '../../widgets/common/pulse_toast.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';

/// Audio Call Screen with elegant UI for voice-only communication
/// Features: Pulsing avatar animation, call duration, mute, speaker controls
class AudioCallScreen extends StatefulWidget {
  final String callId;
  final UserModel remoteUser;
  final bool isIncoming;

  const AudioCallScreen({
    super.key,
    required this.callId,
    required this.remoteUser,
    this.isIncoming = false,
  });

  @override
  State<AudioCallScreen> createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen>
    with TickerProviderStateMixin {
  final AudioCallService _audioService = AudioCallService.instance;

  bool _isConnected = false;
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  Duration _callDuration = Duration.zero;
  QualityType _connectionQuality = QualityType.qualityUnknown;
  String _statusMessage = 'Calling...';

  // Animation controllers
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Stream subscriptions
  StreamSubscription<bool>? _callStateSubscription;
  StreamSubscription<bool>? _muteSubscription;
  StreamSubscription<bool>? _speakerSubscription;
  StreamSubscription<int>? _remoteUserSubscription;
  StreamSubscription<QualityType>? _qualitySubscription;
  StreamSubscription<String>? _errorSubscription;
  StreamSubscription<Duration>? _durationSubscription;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupAudioCallListeners();
    _initializeCall();
  }

  void _setupAnimations() {
    // Pulsing animation for avatar
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _setupAudioCallListeners() {
    _callStateSubscription = _audioService.onCallStateChanged.listen((
      isConnected,
    ) {
      setState(() {
        _isConnected = isConnected;
        _statusMessage = isConnected ? 'Connected' : 'Call ended';
      });

      if (!isConnected && mounted) {
        // Call ended, navigate back after delay
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.of(context).pop();
        });
      }
    });

    _muteSubscription = _audioService.onMuteStateChanged.listen((isMuted) {
      setState(() => _isMuted = isMuted);
    });

    _speakerSubscription = _audioService.onSpeakerStateChanged.listen((
      isSpeakerOn,
    ) {
      setState(() => _isSpeakerOn = isSpeakerOn);
    });

    _remoteUserSubscription = _audioService.onRemoteUserJoined.listen((
      remoteUid,
    ) {
      setState(() {
        _statusMessage = 'Connected';
        _isConnected = true;
      });
    });

    _qualitySubscription = _audioService.onQualityChanged.listen((quality) {
      setState(() => _connectionQuality = quality);
    });

    _errorSubscription = _audioService.onCallError.listen((error) {
      _showErrorSnackBar(error);
    });

    _durationSubscription = _audioService.onCallDurationUpdate.listen((
      duration,
    ) {
      setState(() => _callDuration = duration);
    });
  }

  Future<void> _initializeCall() async {
    if (widget.isIncoming) {
      // Accept incoming call
      final success = await _audioService.acceptIncomingCall(
        callId: widget.callId,
        callerId: widget.remoteUser.id,
      );

      if (!success && mounted) {
        _showErrorSnackBar('Failed to join call');
        Navigator.of(context).pop();
      }
    } else {
      // Join outgoing call (already initiated)
      final success = await _audioService.joinAudioCall(
        callId: widget.callId,
        recipientId: widget.remoteUser.id,
      );

      if (!success && mounted) {
        _showErrorSnackBar('Failed to start call');
        Navigator.of(context).pop();
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    PulseToast.error(context, message: message);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _callStateSubscription?.cancel();
    _muteSubscription?.cancel();
    _speakerSubscription?.cancel();
    _remoteUserSubscription?.cancel();
    _qualitySubscription?.cancel();
    _errorSubscription?.cancel();
    _durationSubscription?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Color _getQualityColor() {
    switch (_connectionQuality) {
      case QualityType.qualityExcellent:
      case QualityType.qualityGood:
        return Colors.green;
      case QualityType.qualityPoor:
        return Colors.orange;
      case QualityType.qualityBad:
      case QualityType.qualityVbad:
        return Colors.red;
      default:
        return context.outlineColor;
    }
  }

  String _getQualityLabel() {
    switch (_connectionQuality) {
      case QualityType.qualityExcellent:
        return 'Excellent';
      case QualityType.qualityGood:
        return 'Good';
      case QualityType.qualityPoor:
        return 'Poor';
      case QualityType.qualityBad:
      case QualityType.qualityVbad:
        return 'Bad';
      default:
        return 'Connecting...';
    }
  }

  Future<void> _endCall() async {
    await _audioService.leaveCall();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              PulseColors.primary.withValues(alpha: 0.8),
              const Color(0xFF0F0F1E),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(child: _buildCallContent()),
              _buildControlButtons(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Connection quality indicator
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getQualityColor(),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getQualityLabel(),
                    style: TextStyle(
                      color: context.onSurfaceColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Call duration
          if (_isConnected)
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time,
                      color: context.onSurfaceColor,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatDuration(_callDuration),
                      style: TextStyle(
                        color: context.onSurfaceColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCallContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Pulsing avatar
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _isConnected ? _pulseAnimation.value : 1.0,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [PulseColors.primary, PulseColors.secondary],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: PulseColors.primary.withValues(alpha: 0.4),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: widget.remoteUser.photos.isNotEmpty
                      ? Image.network(
                          widget.remoteUser.photos.first,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildAvatarFallback();
                          },
                        )
                      : _buildAvatarFallback(),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 32),

        // User name
        Text(
          widget.remoteUser.firstName != null &&
                  widget.remoteUser.lastName != null
              ? '${widget.remoteUser.firstName} ${widget.remoteUser.lastName}'
              : widget.remoteUser.firstName ?? widget.remoteUser.username,
          style: TextStyle(
            color: context.onSurfaceColor,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        // Call status
        Text(
          _statusMessage,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 16,
          ),
        ),

        if (_isConnected && widget.remoteUser.age != null) ...[
          const SizedBox(height: 4),
          Text(
            '${widget.remoteUser.age} years old',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAvatarFallback() {
    final displayName =
        widget.remoteUser.firstName != null &&
            widget.remoteUser.lastName != null
        ? '${widget.remoteUser.firstName} ${widget.remoteUser.lastName}'
        : widget.remoteUser.firstName ?? widget.remoteUser.username;
    return Container(
      color: PulseColors.primary,
      child: Center(
        child: Text(
          displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
          style: TextStyle(
            color: context.onSurfaceColor,
            fontSize: 64,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mute/Unmute button
          _buildControlButton(
            icon: _isMuted ? Icons.mic_off : Icons.mic,
            label: _isMuted ? 'Unmute' : 'Mute',
            onTap: () => _audioService.toggleMute(),
            isActive: _isMuted,
          ),

          // Speaker button
          _buildControlButton(
            icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
            label: _isSpeakerOn ? 'Speaker' : 'Earpiece',
            onTap: () => _audioService.enableSpeakerphone(!_isSpeakerOn),
            isActive: _isSpeakerOn,
          ),

          // End call button
          _buildControlButton(
            icon: Icons.call_end,
            label: 'End',
            onTap: _endCall,
            isActive: true,
            color: context.errorColor,
            size: 72,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
    Color? color,
    double size = 64,
  }) {
    final buttonColor =
        color ??
        (isActive ? PulseColors.primary : Colors.white.withValues(alpha: 0.2));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: buttonColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: buttonColor.withValues(alpha: 0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(icon, color: context.onSurfaceColor, size: size * 0.4),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: context.onSurfaceColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
