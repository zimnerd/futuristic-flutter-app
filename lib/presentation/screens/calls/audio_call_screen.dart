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
import '../../../core/services/call_invitation_service.dart';
import '../../../core/models/call_invitation.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';

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
  final CallInvitationService _callInvitationService = CallInvitationService();
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
  StreamSubscription<Map<String, dynamic>>? _connectionStatusSubscription;

  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _remoteUserJoined = false;
  Duration _callDuration = Duration.zero;
  QualityType _connectionQuality = QualityType.qualityUnknown;
  String? _activeConversationId; // Track conversation for call message
  DateTime? _callStartTime; // Track when call actually connected
  
  // NEW: Track connection status
  CallConnectionStatus _connectionStatus = CallConnectionStatus.ringing;
  bool _isJoiningAgora = false; // Prevent duplicate joins

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    AppLogger.info(
      '🎬 AudioCallScreen.initState - callId: ${widget.callId}, isOutgoing: ${widget.isOutgoing}',
    );
    _audioService = AudioCallService.instance;
    _activeConversationId = widget.conversationId;
    _setupPulseAnimation();
    _setupStreamListeners();
    // NEW: Initialize Agora service but don't join channel yet
    _initializeAgoraService();
    // NEW: Listen for ready_to_connect event before joining
    _setupConnectionStatusListener();
    AppLogger.info(
      '✅ AudioCallScreen setup complete - waiting for ready_to_connect event',
    );
  }

  void _setupStreamListeners() {
    _callStateSubscription = _audioService.onCallStateChanged.listen((inCall) {
      // Connection status is now tracked via _connectionStatus from WebSocket events
      // This listener is kept for backward compatibility but not used for UI state
    });

    _muteStateSubscription = _audioService.onMuteStateChanged.listen((muted) {
      if (mounted) {
        setState(() {
          _isMuted = muted;
        });
      }
    });

    _speakerStateSubscription = _audioService.onSpeakerStateChanged.listen((
      speaker,
    ) {
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

    _durationSubscription = _audioService.onCallDurationUpdate.listen((
      duration,
    ) {
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

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  /// NEW: Initialize Agora service but don't join channel yet
  Future<void> _initializeAgoraService() async {
    try {
      if (!_audioService.isInCall) {
        await _audioService.initialize(
          appId: '0bb5c5b508884aa4bfc25381d51fa329',
        );
        AppLogger.info(
          'Agora service initialized, waiting for ready_to_connect event',
        );
      }
    } catch (e) {
      AppLogger.error('Failed to initialize Agora service: $e');
      _showErrorDialog('Failed to initialize call: $e');
    }
  }

  /// NEW: Listen for connection status events from backend
  void _setupConnectionStatusListener() {
    AppLogger.info(
      '🎧 Setting up connection status listener for call ${widget.callId}',
    );
    _connectionStatusSubscription = _callInvitationService
        .onConnectionStatusChanged
        .listen((statusData) {
          final event = statusData['event'] as String;
          final callId = statusData['callId'] as String;

          // Only process events for this call
          if (callId != widget.callId) {
            AppLogger.info(
              '⏭️ Ignoring event $event for different call $callId (expected: ${widget.callId})',
            );
            return;
          }

          AppLogger.info('✅ Connection status event: $event for call $callId');

          switch (event) {
            case 'ready_to_connect':
              // Both users accepted, now join Agora
              _handleReadyToConnect(statusData);
              break;
            case 'connected':
              // Both users in Agora channel, start timer
              _handleCallConnected();
              break;
            case 'failed':
              // Call failed (offline, network error, etc.)
              _handleCallFailed(statusData['reason'] as String?);
              break;
          }
        });
  }

  /// NEW: Handle ready to connect - Join Agora channel now
  Future<void> _handleReadyToConnect(Map<String, dynamic> data) async {
    if (_isJoiningAgora) {
      AppLogger.warning('Already joining Agora, skipping duplicate join');
      return;
    }

    setState(() {
      _isJoiningAgora = true;
      _connectionStatus = CallConnectionStatus.connecting;
    });

    try {
      AppLogger.info('🎉 ===== READY TO CONNECT EVENT RECEIVED =====');
      AppLogger.info('📦 Event data: $data');

      // ✅ Extract token, channelName, and UID from WebSocket event
      final token = data['token'] as String?;
      final channelName = data['channelName'] as String?;
      final uid = data['uid'] as int?;

      AppLogger.info(
        '🔍 Extracted: token=${token != null ? "PRESENT" : "NULL"}, channel=$channelName, uid=$uid',
      );

      if (token == null || channelName == null || uid == null) {
        AppLogger.error(
          '❌ Missing required data in ready_to_connect event: '
          'token=${token != null}, channelName=${channelName != null}, uid=${uid != null}',
        );
        _showErrorDialog('Invalid call data received from server');
        return;
      }

      AppLogger.info('✅ All data present - proceeding to join Agora');

      AppLogger.info(
        '🎧 Joining with WebSocket token - Channel: $channelName, UID: $uid',
      );
      
      final success = await _audioService.joinAudioCall(
        callId: widget.callId,
        recipientId: widget.recipientId,
        channelName: channelName,
        token: token,
        uid: uid, // ✅ Pass UID from event
      );

      if (!success) {
        _showErrorDialog('Failed to join audio call');
      }
    } catch (e) {
      AppLogger.error('Failed to join Agora: $e');
      _showErrorDialog('Failed to join call: $e');
    }
  }

  /// NEW: Handle call connected - Start timer NOW
  void _handleCallConnected() {
    setState(() {
      _connectionStatus = CallConnectionStatus.connected;
      _callStartTime = DateTime.now();
    });
    AppLogger.info('Call connected - timer started');
  }

  /// NEW: Handle call failed
  void _handleCallFailed(String? reason) {
    setState(() {
      _connectionStatus = CallConnectionStatus.failed;
    });
    AppLogger.error('Call failed: ${reason ?? "Unknown reason"}');
    _showErrorDialog(
      'Call failed: ${reason ?? "User is offline or unreachable"}',
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Call Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _endCall();
            },
            child: Text('OK'),
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
        return context.outlineColor;
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
    _connectionStatusSubscription
        ?.cancel(); // NEW: Cancel connection status subscription
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
                    backgroundColor: context.surfaceColor.withValues(
                      alpha: 0.2,
                    ),
                    backgroundImage: widget.userPhotoUrl != null
                        ? CachedNetworkImageProvider(widget.userPhotoUrl!)
                        : null,
                    child: widget.userPhotoUrl == null
                        ? Text(
                            widget.userName[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 64,
                              fontWeight: FontWeight.bold,
                              color: context.onSurfaceColor,
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
                        border: Border.all(color: context.onSurfaceColor, width: 3),
                      ),
                      child: Icon(
                        Icons.mic,
                        color: context.onSurfaceColor,
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
          style: TextStyle(
            color: context.onSurfaceColor,
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
    
    // NEW: Use connection status for more accurate state display
    switch (_connectionStatus) {
      case CallConnectionStatus.ringing:
        statusText = widget.isOutgoing ? 'Ringing...' : 'Incoming call...';
        break;
      case CallConnectionStatus.connecting:
        statusText = 'Connecting...';
        break;
      case CallConnectionStatus.connected:
        statusText = _remoteUserJoined ? 'Connected' : 'Joining...';
        break;
      case CallConnectionStatus.failed:
        statusText = 'Call failed';
        break;
      case CallConnectionStatus.noAnswer:
        statusText = 'No answer';
        break;
      case CallConnectionStatus.declined:
        statusText = 'Declined';
        break;
      case CallConnectionStatus.ended:
        statusText = 'Ended';
        break;
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
                color: context.onSurfaceColor,
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
