import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';

import '../../core/network/api_client.dart';
import '../../domain/services/websocket_service.dart';

/// Service for managing audio-only calls
/// Uses Agora RTC SDK in Communication Mode with video disabled
class AudioCallService {
  static AudioCallService? _instance;
  static AudioCallService get instance => _instance ??= AudioCallService._();

  AudioCallService._();

  final Logger _logger = Logger();
  final ApiClient _apiClient = ApiClient.instance;

  RtcEngine? _engine;
  WebSocketService? _webSocketService;

  // Call state
  String? _currentCallId;
  String? _currentChannelName;
  int? _currentRemoteUid;
  bool _isInCall = false;
  bool _isMuted = false;
  bool _isSpeakerOn = false;

  // Connection quality tracking
  QualityType _connectionQuality = QualityType.qualityUnknown;

  // Stream controllers for UI updates
  final StreamController<bool> _callStateController =
      StreamController<bool>.broadcast();
  final StreamController<bool> _muteStateController =
      StreamController<bool>.broadcast();
  final StreamController<bool> _speakerStateController =
      StreamController<bool>.broadcast();
  final StreamController<int> _remoteUserController =
      StreamController<int>.broadcast();
  final StreamController<QualityType> _qualityController =
      StreamController<QualityType>.broadcast();
  final StreamController<String> _callErrorController =
      StreamController<String>.broadcast();
  final StreamController<Duration> _callDurationController =
      StreamController<Duration>.broadcast();

  // Getters for streams
  Stream<bool> get onCallStateChanged => _callStateController.stream;
  Stream<bool> get onMuteStateChanged => _muteStateController.stream;
  Stream<bool> get onSpeakerStateChanged => _speakerStateController.stream;
  Stream<int> get onRemoteUserJoined => _remoteUserController.stream;
  Stream<QualityType> get onQualityChanged => _qualityController.stream;
  Stream<String> get onCallError => _callErrorController.stream;
  Stream<Duration> get onCallDurationUpdate => _callDurationController.stream;

  // Getters for current state
  bool get isInCall => _isInCall;
  bool get isMuted => _isMuted;
  bool get isSpeakerOn => _isSpeakerOn;
  QualityType get connectionQuality => _connectionQuality;
  String? get currentCallId => _currentCallId;

  // Call duration tracking
  Timer? _durationTimer;
  DateTime? _callStartTime;
  Duration _callDuration = Duration.zero;

  /// Initialize audio call service with Agora App ID
  Future<void> initialize({
    required String appId,
    WebSocketService? webSocketService,
  }) async {
    try {
      _webSocketService = webSocketService;

      _logger.i('🔧 Creating Agora RTC engine...');

      // Create Agora RTC engine
      _engine = createAgoraRtcEngine();

      _logger.i(
        '🔧 Initializing Agora engine with appId: ${appId.substring(0, 8)}...',
      );
      await _engine!.initialize(
        RtcEngineContext(
          appId: appId,
          channelProfile: ChannelProfileType.channelProfileCommunication,
          audioScenario: AudioScenarioType.audioScenarioChatroom,
        ),
      );

      _logger.i('🔧 Enabling audio module...');
      // Enable audio explicitly (don't disable video, just don't enable it)
      await _engine!.enableAudio();

      _logger.i('🔧 Enabling local audio capture...');
      // Enable local audio capture (microphone)
      await _engine!.enableLocalAudio(true);

      _logger.i('🔧 Setting audio profile...');
      // Set audio profile for high quality voice
      await _engine!.setAudioProfile(
        profile: AudioProfileType.audioProfileMusicStandard,
        scenario: AudioScenarioType.audioScenarioChatroom,
      );

      _logger.i('🔧 Registering event handlers...');
      // Set event handlers
      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            _logger.i('✅ Joined audio channel: ${connection.channelId}');
            _isInCall = true;
            _callStateController.add(true);
            _startCallDurationTimer();
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            _logger.i('🎤 Remote user joined audio call: $remoteUid');
            _currentRemoteUid = remoteUid;
            _remoteUserController.add(remoteUid);
          },
          onUserOffline:
              (
                RtcConnection connection,
                int remoteUid,
                UserOfflineReasonType reason,
              ) {
                _logger.i(
                  '👋 Remote user left audio call: $remoteUid, reason: $reason',
                );
                if (_currentRemoteUid == remoteUid) {
                  _currentRemoteUid = null;
                  _handleCallEnded('Remote user left');
                }
              },
          onLeaveChannel: (RtcConnection connection, RtcStats stats) {
            _logger.i('📞 Left audio channel');
            _isInCall = false;
            _callStateController.add(false);
            _stopCallDurationTimer();
          },
          onNetworkQuality:
              (
                RtcConnection connection,
                int remoteUid,
                QualityType txQuality,
                QualityType rxQuality,
              ) {
                _connectionQuality = rxQuality;
                _qualityController.add(rxQuality);
              },
          onAudioVolumeIndication:
              (
                RtcConnection connection,
                List<AudioVolumeInfo> speakers,
                int speakerNumber,
                int totalVolume,
              ) {
                // Can be used for audio level indicators
                // _logger.d('Audio volume: $totalVolume');
              },
          onError: (ErrorCodeType err, String msg) {
            _logger.e('❌ Agora audio error: $err - $msg');
            _callErrorController.add('Call error: $msg');
          },
          onConnectionStateChanged:
              (
                RtcConnection connection,
                ConnectionStateType state,
                ConnectionChangedReasonType reason,
              ) {
                _logger.i('📡 Connection state: $state, reason: $reason');
                if (state == ConnectionStateType.connectionStateFailed) {
                  _handleCallEnded('Connection failed');
                }
              },
          onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
            _logger.w('⚠️ Token will expire in 30 seconds, refreshing...');
            _refreshToken();
          },
          onRequestToken: (RtcConnection connection) {
            _logger.e('❌ Token expired! Requesting new token...');
            _refreshToken();
          },
          onConnectionLost: (RtcConnection connection) {
            _logger.w('⚠️ Connection lost, will attempt auto-reconnect');
            _callErrorController.add('Connection lost, reconnecting...');
          },
          onRejoinChannelSuccess: (RtcConnection connection, int elapsed) {
            _logger.i(
              '✅ Rejoined channel after connection loss: ${connection.channelId}',
            );
            _callErrorController.add('Reconnected successfully');
          },
          onLocalAudioStateChanged:
              (
                RtcConnection connection,
                LocalAudioStreamState state,
                LocalAudioStreamReason reason,
              ) {
                _logger.i('🎤 Local audio state: $state, reason: $reason');
                if (reason ==
                    LocalAudioStreamReason
                        .localAudioStreamReasonRecordFailure) {
                  _logger.e('❌ Microphone recording failed');
                  _callErrorController.add('Microphone error');
                }
              },
          onRemoteAudioStateChanged:
              (
                RtcConnection connection,
                int remoteUid,
                RemoteAudioState state,
                RemoteAudioStateReason reason,
                int elapsed,
              ) {
                _logger.i(
                  '🔊 Remote audio state for $remoteUid: $state, reason: $reason',
                );
                if (state == RemoteAudioState.remoteAudioStateFailed) {
                  _logger.w('⚠️ Remote user $remoteUid audio failed');
                }
              },
        ),
      );

      _logger.i('✅ Audio call service initialized successfully');
    } catch (e) {
      _logger.e('❌ Failed to initialize audio call service: $e');
      throw Exception('Failed to initialize audio call service: $e');
    }
  }

  /// Request microphone permission
  Future<bool> requestMicrophonePermission() async {
    try {
      final status = await Permission.microphone.request();

      if (status != PermissionStatus.granted) {
        _logger.w('⚠️ Microphone permission denied');
        return false;
      }

      return true;
    } catch (e) {
      _logger.e('❌ Error requesting microphone permission: $e');
      return false;
    }
  }

  /// Join an audio call with token from backend
  Future<bool> joinAudioCall({
    required String callId,
    required String recipientId,
    String? channelName,
    String? token,
    int? uid, // ✅ NEW: Accept UID from WebSocket event
  }) async {
    try {
      // Get app ID from environment or config
      const appId = String.fromEnvironment(
        'AGORA_APP_ID',
        defaultValue:
            '0bb5c5b508884aa4bfc25381d51fa329', // Correct from Agora Console
      );

      // Force re-initialization to ensure clean state
      if (_engine != null) {
        _logger.w(
          '⚠️ Agora engine exists but may be in invalid state, releasing...',
        );
        try {
          await _engine!.release();
        } catch (e) {
          _logger.w('⚠️ Error releasing engine (may already be released): $e');
        }
        _engine = null;
      }

      // Always initialize fresh for each call
      _logger.i('🔧 Initializing Agora engine for call...');
      await initialize(appId: appId);

      // Wait a moment for engine to fully initialize
      await Future.delayed(const Duration(milliseconds: 500));

      // Verify engine is ready
      if (_engine == null) {
        throw Exception('Failed to initialize Agora engine');
      }

      // Check microphone permission
      final hasPermission = await requestMicrophonePermission();
      if (!hasPermission) {
        _callErrorController.add('Microphone permission required');
        return false;
      }

      // Get RTC token from backend if not provided
      String agoraToken = token ?? '';
      String agoraChannel = channelName ?? '';
      int tokenUid = uid ?? 0; // ✅ Use provided UID or default to 0

      if (token == null || channelName == null) {
        // ⚠️ DEPRECATED PATH: This should only be used for incoming calls
        // For outgoing calls, token/channel/uid should come from WebSocket event
        _logger.w(
          '⚠️ DEPRECATED: Requesting token via REST API. '
          'New flows should receive token via WebSocket call_ready_to_connect event.',
        );
        _logger.i('🔑 Requesting audio call token for call: $callId');
        final response = await _apiClient.getCallToken(
          callId: callId,
          audioOnly: true,
        );

        if (response.data['success'] != true) {
          _callErrorController.add('Failed to get audio token');
          return false;
        }

        final tokenData = response.data['data'];
        agoraToken = tokenData['token'] as String;
        agoraChannel = tokenData['channelName'] as String;
        tokenUid = tokenData['uid'] as int; // ✅ Extract UID from token response

        _logger.i('🔑 Token received - Channel: $agoraChannel, UID: $tokenUid');
      } else {
        // ✅ NEW PATH: Using token from WebSocket event
        _logger.i(
          '✅ Using token from WebSocket event - Channel: $agoraChannel, UID: $tokenUid',
        );
      }

      _currentCallId = callId;
      _currentChannelName = agoraChannel; // ✅ Store for token refresh

      // Join Agora channel
      _logger.i(
        '🎤 Joining audio channel: $agoraChannel with token: ${agoraToken.substring(0, 20)}... (UID: $tokenUid)',
      );
      await _engine!.joinChannel(
        token: agoraToken, // Use token from backend
        channelId: agoraChannel,
        uid:
            tokenUid, // ✅ CRITICAL: Use UID from token - must match for validation
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileCommunication,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishMicrophoneTrack: true,
          autoSubscribeAudio: true,
          publishCameraTrack: false, // Audio-only
          autoSubscribeVideo: false, // Audio-only
        ),
      );

      _logger.i('✅ Join channel request sent successfully');

      return true;
    } catch (e) {
      _logger.e('❌ Failed to join audio call: $e');
      _callErrorController.add('Failed to join call: $e');
      return false;
    }
  }

  /// Leave the current audio call
  Future<void> leaveCall() async {
    try {
      if (_engine != null && _isInCall) {
        await _engine!.leaveChannel();
      }

      _resetCallState();
      _logger.i('✅ Left audio call successfully');
    } catch (e) {
      _logger.e('❌ Error leaving audio call: $e');
      _resetCallState();
    }
  }

  /// Toggle microphone mute
  Future<void> toggleMute() async {
    try {
      _isMuted = !_isMuted;
      await _engine!.muteLocalAudioStream(_isMuted);
      _muteStateController.add(_isMuted);
      _logger.i('🔇 Microphone ${_isMuted ? "muted" : "unmuted"}');
    } catch (e) {
      _logger.e('❌ Error toggling mute: $e');
    }
  }

  /// Enable/disable speakerphone
  Future<void> enableSpeakerphone(bool enable) async {
    try {
      _isSpeakerOn = enable;
      await _engine!.setEnableSpeakerphone(enable);
      _speakerStateController.add(_isSpeakerOn);
      _logger.i('🔊 Speakerphone ${enable ? "enabled" : "disabled"}');
    } catch (e) {
      _logger.e('❌ Error toggling speakerphone: $e');
    }
  }

  /// ⚠️ DEPRECATED: Use CallInvitationService.sendCallInvitation() instead
  ///
  /// This method uses the old REST API flow which generates Agora tokens
  /// immediately and causes premature "Connected" status before the other
  /// user accepts. The new WebSocket-based CallInvitationService implements
  /// proper event-driven call flow.
  ///
  /// See: CALL_SYSTEM_COMPLETE_MIGRATION.md for migration guide
  @Deprecated(
    'Use CallInvitationService.sendCallInvitation() instead. '
    'This REST API flow will be removed in a future version.',
  )
  Future<String?> initiateAudioCall({
    required String recipientId,
    required String recipientName,
    bool isVideo = false,
  }) async {
    try {
      final callType = isVideo ? 'VIDEO' : 'AUDIO';
      _logger.w(
        '⚠️ DEPRECATED: initiateAudioCall() called for $callType call\n'
        'Please migrate to CallInvitationService.sendCallInvitation()\n'
        'See: CALL_SYSTEM_COMPLETE_MIGRATION.md',
      );

      // Create call through backend API
      final response = await _apiClient.initiateCall(
        participantIds: [recipientId],
        type: callType,
      );

      if (response.data['success'] != true) {
        _callErrorController.add('Failed to initiate call');
        return null;
      }

      final callData = response.data['data'];
      final callId = callData['id'] as String;

      // Send call notification through WebSocket
      _webSocketService?.emit('call:initiate', {
        'callId': callId,
        'recipientId': recipientId,
        'type': isVideo ? 'video' : 'audio',
      });

      // Join the call
      final success = await joinAudioCall(
        callId: callId,
        recipientId: recipientId,
      );

      return success ? callId : null;
    } catch (e) {
      _logger.e('❌ Failed to initiate call: $e');
      _callErrorController.add('Failed to initiate call: $e');
      return null;
    }
  }

  /// Accept an incoming audio call
  Future<bool> acceptIncomingCall({
    required String callId,
    required String callerId,
  }) async {
    try {
      _logger.i('✅ Accepting incoming audio call: $callId');

      // Notify backend of call acceptance
      await _apiClient.acceptCall(callId);

      // Send acceptance through WebSocket
      _webSocketService?.emit('call:accept', {'callId': callId});

      // Join the audio call
      return await joinAudioCall(callId: callId, recipientId: callerId);
    } catch (e) {
      _logger.e('❌ Failed to accept call: $e');
      _callErrorController.add('Failed to accept call: $e');
      return false;
    }
  }

  /// Reject an incoming audio call
  Future<void> rejectCall({required String callId, String? reason}) async {
    try {
      _logger.i('❌ Rejecting call: $callId');

      // Notify backend
      await _apiClient.rejectCall(callId, reason: reason ?? 'User declined');

      // Send rejection through WebSocket
      _webSocketService?.emit('call:reject', {
        'callId': callId,
        'reason': reason,
      });
    } catch (e) {
      _logger.e('❌ Error rejecting call: $e');
    }
  }

  /// Start call duration timer
  void _startCallDurationTimer() {
    _callStartTime = DateTime.now();
    _callDuration = Duration.zero;

    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_callStartTime != null) {
        _callDuration = DateTime.now().difference(_callStartTime!);
        _callDurationController.add(_callDuration);
      }
    });
  }

  /// Stop call duration timer
  void _stopCallDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
    _callStartTime = null;
    _callDuration = Duration.zero;
  }

  /// Refresh Agora token when it's about to expire
  Future<void> _refreshToken() async {
    if (_currentCallId == null || _currentChannelName == null) {
      _logger.w('⚠️ Cannot refresh token: missing call ID or channel name');
      return;
    }

    try {
      _logger.i('🔄 Refreshing token for call: $_currentCallId');

      final response = await _apiClient.getCallToken(
        callId: _currentCallId!,
        audioOnly: true,
      );

      if (response.data['success'] != true) {
        _logger.e('❌ Failed to refresh token');
        return;
      }

      final tokenData = response.data['data'];
      final newToken = tokenData['token'] as String;

      _logger.i('✅ Token refreshed, updating RTC engine...');

      // Update token without rejoining channel
      await _engine?.renewToken(newToken);

      _logger.i('✅ Token updated successfully');
    } catch (e) {
      _logger.e('❌ Error refreshing token: $e');
      // Don't end call, let Agora handle reconnection
    }
  }

  /// Handle call ended event
  void _handleCallEnded(String reason) {
    _logger.i('📞 Call ended: $reason');
    leaveCall();
  }

  /// Reset call state
  void _resetCallState() {
    _currentCallId = null;
    _currentChannelName = null;
    _currentRemoteUid = null;
    _isInCall = false;
    _isMuted = false;
    _isSpeakerOn = false;
    _connectionQuality = QualityType.qualityUnknown;
    _callStateController.add(false);
    _stopCallDurationTimer();
  }

  /// Get call statistics
  Future<RtcStats?> getCallStats() async {
    try {
      // Note: This would require storing stats from onRtcStats callback
      // For now, return null - implement if needed
      return null;
    } catch (e) {
      _logger.e('❌ Error getting call stats: $e');
      return null;
    }
  }

  /// Dispose the service
  Future<void> dispose() async {
    try {
      await leaveCall();
      await _engine?.release();
      _engine = null;

      await _callStateController.close();
      await _muteStateController.close();
      await _speakerStateController.close();
      await _remoteUserController.close();
      await _qualityController.close();
      await _callErrorController.close();
      await _callDurationController.close();

      _durationTimer?.cancel();

      _logger.i('✅ Audio call service disposed');
    } catch (e) {
      _logger.e('❌ Error disposing audio call service: $e');
    }
  }
}
