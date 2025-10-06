import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../../../data/services/audio_call_service.dart';
import '../../../data/services/conversation_service.dart';
import '../../../data/services/messaging_service.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/logger.dart';

class AudioCallScreen extends StatefulWidget {
  final String callId;
  final String recipientId;
  final String userName;
  final String? userPhotoUrl;
  final String? channelName;
  final String? token;
  final bool isOutgoing;
  final String? conversationId; // Optional, will be created if null
  final String callType; // 'audio' or 'video'

  const AudioCallScreen({
    super.key,
    required this.callId,
    required this.recipientId,
    required this.userName,
    this.userPhotoUrl,
    this.channelName,
    this.token,
    this.isOutgoing = false,
    this.conversationId,
    this.callType = 'audio', // Default to audio for backward compatibility
  });

  @override
  State<AudioCallScreen> createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen>
    with TickerProviderStateMixin {
  late AudioCallService _audioService;
  final MessagingService _messagingService = MessagingService(
    apiClient: ApiClient.instance,
  );
  final ConversationService _conversationService = ConversationService();
  
  StreamSubscription<bool>? _callStateSubscription;
  StreamSubscription<bool>? _muteStateSubscription;
  StreamSubscription<bool>? _speakerStateSubscription;
  StreamSubscription<int>? _remoteUserSubscription;
  StreamSubscription<QualityType>? _qualitySubscription;
  StreamSubscription<String>? _errorSubscription;
  StreamSubscription<Duration>? _durationSubscription;

  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _isConnected = false;
  bool _remoteUserJoined = false;
  Duration _callDuration = Duration.zero;
  QualityType _connectionQuality = QualityType.qualityUnknown;
  String? _activeConversationId; // Track conversation for call message
  DateTime? _callStartTime; // Track when call actually connected

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _audioService = AudioCallService.instance;
    _activeConversationId = widget.conversationId;
    _setupPulseAnimation();
    _setupStreamListeners();
    _initializeCall();
  }

  void _setupStreamListeners() {
    _callStateSubscription = _audioService.onCallStateChanged.listen((inCall) {
      if (mounted) {
        setState(() {
          _isConnected = inCall;
        });
      }
    });

    _muteStateSubscription = _audioService.onMuteStateChanged.listen((muted) {
      if (mounted) {
        setState(() {
          _isMuted = muted;
        });
      }
    });

    _speakerStateSubscription = _audioService.onSpeakerStateChanged.listen((speaker) {
      if (mounted) {
        setState(() {
          _isSpeakerOn = speaker;
        });
      }
    });

    _remoteUserSubscription = _audioService.onRemoteUserJoined.listen((uid) {
      if (mounted) {
        setState(() {
          _remoteUserJoined = true;
          // Track when call actually connects (remote user joins)
          _callStartTime ??= DateTime.now();
        });
      }
    });

    _qualitySubscription = _audioService.onQualityChanged.listen((quality) {
      if (mounted) {
        setState(() {
          _connectionQuality = quality;
        });
      }
    });

    _errorSubscription = _audioService.onCallError.listen((error) {
      if (mounted) {
        _showErrorDialog(error);
      }
    });

    _durationSubscription = _audioService.onCallDurationUpdate.listen((duration) {
      if (mounted) {
        setState(() {
          _callDuration = duration;
        });
      }
    });
  }

  void _setupPulseAnimation() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _initializeCall() async {
    try {
      // Initialize service if not already done
      if (!_audioService.isInCall) {
        await _audioService.initialize(
          appId: '0bb5c5b508884aa4bfc25381d51fa329',
        );
      }

      // Join the audio call
      final success = await _audioService.joinAudioCall(
        callId: widget.callId,
        recipientId: widget.recipientId,
        channelName: widget.channelName,
        token: widget.token,
      );

      if (!success) {
        _showErrorDialog('Failed to join audio call');
      }
    } catch (e) {
      _showErrorDialog('Failed to join call: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Call Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _endCall();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _endCall() async {
    // Calculate call duration
    final duration = _callDuration.inSeconds;
    final connected = _remoteUserJoined && _callStartTime != null;

    // Leave the call first
    await _audioService.leaveCall();
    
    // Create call message in conversation (WhatsApp-style)
    try {
      // Get or create conversation
      String conversationId = _activeConversationId ?? '';
      if (conversationId.isEmpty) {
        final conversation = await _conversationService.createConversation(
          participantId: widget.recipientId,
        );
        if (conversation != null) {
          conversationId = conversation.id;
        }
      }

      // Only create message if we have a valid conversation
      if (conversationId.isNotEmpty) {
        await _messagingService.createCallMessage(
          conversationId: conversationId,
          callType: widget.callType, // Dynamic call type (audio/video)
          duration: duration,
          isIncoming: !widget.isOutgoing,
          isMissed: !connected, // Missed if remote user never joined
        );
        AppLogger.info(
          'Call message created: duration=${duration}s, connected=$connected',
        );
      }
    } catch (e) {
      // Don't block navigation if call message fails
      AppLogger.error('Failed to create call message: $e');
    }
    
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _toggleMute() async {
    await _audioService.toggleMute();
  }

  Future<void> _toggleSpeaker() async {
    await _audioService.enableSpeakerphone(!_isSpeakerOn);
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Color _getQualityColor() {
    switch (_connectionQuality) {
      case QualityType.qualityExcellent:
        return Colors.green;
      case QualityType.qualityGood:
        return Colors.lightGreen;
      case QualityType.qualityPoor:
        return Colors.orange;
      case QualityType.qualityBad:
        return Colors.red;
      case QualityType.qualityVbad:
        return Colors.red.shade900;
      default:
        return Colors.grey;
    }
  }

  String _getQualityText() {
    switch (_connectionQuality) {
      case QualityType.qualityExcellent:
        return 'Excellent';
      case QualityType.qualityGood:
        return 'Good';
      case QualityType.qualityPoor:
        return 'Fair';
      case QualityType.qualityBad:
        return 'Poor';
      case QualityType.qualityVbad:
        return 'Very Poor';
      default:
        return 'Connecting...';
    }
  }

  @override
  void dispose() {
    _callStateSubscription?.cancel();
    _muteStateSubscription?.cancel();
    _speakerStateSubscription?.cancel();
    _remoteUserSubscription?.cancel();
    _qualitySubscription?.cancel();
    _errorSubscription?.cancel();
    _durationSubscription?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.primary.withValues(alpha: 0.8),
              AppColors.accent.withValues(alpha: 0.6),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildAvatar(),
                    const SizedBox(height: 32),
                    _buildUserInfo(),
                    const SizedBox(height: 16),
                    _buildCallStatus(),
                    const SizedBox(height: 8),
                    _buildConnectionQuality(),
                  ],
                ),
              ),
              _buildControls(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Encrypted',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.mic,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Audio Only',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _remoteUserJoined ? _pulseAnimation.value : 1.0,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: _remoteUserJoined ? 10 : 0,
                ),
              ],
            ),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                      width: 4,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 78,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    backgroundImage: widget.userPhotoUrl != null
                        ? CachedNetworkImageProvider(widget.userPhotoUrl!)
                        : null,
                    child: widget.userPhotoUrl == null
                        ? Text(
                            widget.userName[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 64,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                ),
                if (_remoteUserJoined && !_isMuted)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Icon(
                        Icons.mic,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserInfo() {
    return Column(
      children: [
        Text(
          widget.userName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        if (_callDuration.inSeconds > 0)
          Text(
            _formatDuration(_callDuration),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }

  Widget _buildCallStatus() {
    String statusText;
    if (!_isConnected) {
      statusText = 'Connecting...';
    } else if (!_remoteUserJoined) {
      statusText = widget.isOutgoing ? 'Calling...' : 'Waiting...';
    } else {
      statusText = 'Connected';
    }

    return Text(
      statusText,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.8),
        fontSize: 16,
      ),
    );
  }

  Widget _buildConnectionQuality() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
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
            _getQualityText(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
            label: 'Speaker',
            onTap: _toggleSpeaker,
            isActive: _isSpeakerOn,
          ),
          _buildControlButton(
            icon: _isMuted ? Icons.mic_off : Icons.mic,
            label: 'Mute',
            onTap: _toggleMute,
            isActive: _isMuted,
            activeColor: Colors.orange,
          ),
          _buildControlButton(
            icon: Icons.call_end,
            label: 'End Call',
            onTap: _endCall,
            isActive: true,
            activeColor: Colors.red,
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
    Color? activeColor,
    double size = 64,
  }) {
    final buttonColor = isActive
        ? (activeColor ?? AppColors.accent)
        : Colors.white.withValues(alpha: 0.3);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(size / 2),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: buttonColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: buttonColor.withValues(alpha: 0.4),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: size * 0.45,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
