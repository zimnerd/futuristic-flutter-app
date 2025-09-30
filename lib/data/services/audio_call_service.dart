import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';

import 'api_service_impl.dart';
import '../../core/constants/api_constants.dart';
import '../../domain/services/websocket_service.dart';

/// Service for managing audio-only calls
/// Uses Agora RTC SDK in Communication Mode with video disabled
class AudioCallService {
  static AudioCallService? _instance;
  static AudioCallService get instance => _instance ??= AudioCallService._();
  
  AudioCallService._();

  final Logger _logger = Logger();
  final ApiServiceImpl _apiService = ApiServiceImpl();
  
  RtcEngine? _engine;
  WebSocketService? _webSocketService;
  
  // Call state
  String? _currentCallId;
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
      
      // Create Agora RTC engine
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
        audioScenario: AudioScenarioType.audioScenarioChatroom,
      ));

      // Configure for audio-only mode
      await _engine!.disableVideo();
      
      // Set audio profile for high quality voice
      await _engine!.setAudioProfile(
        profile: AudioProfileType.audioProfileMusicStandard,
        scenario: AudioScenarioType.audioScenarioChatroom,
      );

      // Set event handlers
      _engine!.registerEventHandler(RtcEngineEventHandler(
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
        onUserOffline: (
          RtcConnection connection, 
          int remoteUid, 
          UserOfflineReasonType reason,
        ) {
          _logger.i('👋 Remote user left audio call: $remoteUid, reason: $reason');
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
        onNetworkQuality: (
          RtcConnection connection,
          int remoteUid,
          QualityType txQuality,
          QualityType rxQuality,
        ) {
          _connectionQuality = rxQuality;
          _qualityController.add(rxQuality);
        },
        onAudioVolumeIndication: (
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
        onConnectionStateChanged: (
          RtcConnection connection,
          ConnectionStateType state,
          ConnectionChangedReasonType reason,
        ) {
          _logger.i('📡 Connection state: $state, reason: $reason');
          if (state == ConnectionStateType.connectionStateFailed) {
            _handleCallEnded('Connection failed');
          }
        },
      ));

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
  }) async {
    try {
      // Check microphone permission
      final hasPermission = await requestMicrophonePermission();
      if (!hasPermission) {
        _callErrorController.add('Microphone permission required');
        return false;
      }

      // Get RTC token from backend if not provided
      String agoraToken = token ?? '';
      String agoraChannel = channelName ?? '';
      
      if (token == null || channelName == null) {
        _logger.i('🔑 Requesting audio call token for call: $callId');
        final response = await _apiService.post(
          '${ApiConstants.webrtc}/calls/$callId/token',
          queryParameters: {'audioOnly': 'true'},
        );

        if (response.data['success'] != true) {
          _callErrorController.add('Failed to get audio token');
          return false;
        }

        final tokenData = response.data['data'];
        agoraToken = tokenData['token'] as String;
        agoraChannel = tokenData['channelName'] as String;
      }

      _currentCallId = callId;

      // Join Agora channel
      _logger.i('🎤 Joining audio channel: $agoraChannel');
      await _engine!.joinChannel(
        token: agoraToken,
        channelId: agoraChannel,
        uid: 0, // Agora assigns UID automatically
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileCommunication,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishMicrophoneTrack: true,
          autoSubscribeAudio: true,
          publishCameraTrack: false, // Audio-only
          autoSubscribeVideo: false, // Audio-only
        ),
      );

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

  /// Initiate an audio call to another user
  Future<String?> initiateAudioCall({
    required String recipientId,
    required String recipientName,
  }) async {
    try {
      _logger.i('📞 Initiating audio call to: $recipientId');
      
      // Create call through backend API
      final response = await _apiService.post(
        '${ApiConstants.webrtc}/calls',
        data: {
          'participantIds': [recipientId],
          'type': 'audio',
        },
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
        'type': 'audio',
      });

      // Join the audio call
      final success = await joinAudioCall(
        callId: callId,
        recipientId: recipientId,
      );

      return success ? callId : null;
    } catch (e) {
      _logger.e('❌ Failed to initiate audio call: $e');
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
      await _apiService.post(
        '${ApiConstants.webrtc}/calls/$callId/accept',
      );

      // Send acceptance through WebSocket
      _webSocketService?.emit('call:accept', {
        'callId': callId,
      });

      // Join the audio call
      return await joinAudioCall(
        callId: callId,
        recipientId: callerId,
      );
    } catch (e) {
      _logger.e('❌ Failed to accept call: $e');
      _callErrorController.add('Failed to accept call: $e');
      return false;
    }
  }

  /// Reject an incoming audio call
  Future<void> rejectCall({
    required String callId,
    String? reason,
  }) async {
    try {
      _logger.i('❌ Rejecting call: $callId');
      
      // Notify backend
      await _apiService.post(
        '${ApiConstants.webrtc}/calls/$callId/reject',
        data: {'reason': reason ?? 'User declined'},
      );

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

  /// Handle call ended event
  void _handleCallEnded(String reason) {
    _logger.i('📞 Call ended: $reason');
    leaveCall();
  }

  /// Reset call state
  void _resetCallState() {
    _currentCallId = null;
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
