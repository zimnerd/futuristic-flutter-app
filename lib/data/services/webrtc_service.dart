import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';

import '../models/call_model.dart';
import '../../domain/services/websocket_service.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';

class WebRTCService {
  static final WebRTCService _instance = WebRTCService._internal();
  factory WebRTCService() => _instance;
  WebRTCService._internal();

  final Logger _logger = Logger();
  RtcEngine? _engine;
  WebSocketService? _webSocketService;
  
  // Call state
  CallModel? _currentCall;
  bool _isInCall = false;
  bool _isMuted = false;
  bool _isVideoEnabled = true;
  bool _isSpeakerOn = false;
  
  // Stream controllers for UI updates
  final StreamController<CallModel?> _callStateController = StreamController<CallModel?>.broadcast();
  final StreamController<bool> _muteStateController = StreamController<bool>.broadcast();
  final StreamController<bool> _videoStateController = StreamController<bool>.broadcast();
  final StreamController<bool> _speakerStateController = StreamController<bool>.broadcast();
  final StreamController<List<int>> _remoteUsersController = StreamController<List<int>>.broadcast();

  // Getters for streams
  Stream<CallModel?> get callStateStream => _callStateController.stream;
  Stream<bool> get muteStateStream => _muteStateController.stream;
  Stream<bool> get videoStateStream => _videoStateController.stream;
  Stream<bool> get speakerStateStream => _speakerStateController.stream;
  Stream<List<int>> get remoteUsersStream => _remoteUsersController.stream;

  // Getters for current state
  CallModel? get currentCall => _currentCall;
  bool get isInCall => _isInCall;
  bool get isMuted => _isMuted;
  bool get isVideoEnabled => _isVideoEnabled;
  bool get isSpeakerOn => _isSpeakerOn;
  
  // ✅ ADDED: Getter for Agora engine (needed for video rendering)
  RtcEngine? get engine => _engine;

  // ✅ ADDED: Track remote users
  List<int> _remoteUsers = [];
  List<int> get remoteUsers => _remoteUsers;

  /// Initialize WebRTC service with Agora App ID
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
      ));

      // Set event handlers
      _engine!.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          _logger.i('Joined channel: ${connection.channelId}');
          _isInCall = true;
          _updateCallStatus(CallStatus.connected);
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          _logger.i('User joined: $remoteUid');
            _remoteUsers = [remoteUid]; // ✅ ADDED: Update remote users list
          _remoteUsersController.add([remoteUid]);
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          _logger.i('User offline: $remoteUid, reason: $reason');
                _remoteUsers = []; // ✅ ADDED: Clear remote users list
          _remoteUsersController.add([]);
          if (reason == UserOfflineReasonType.userOfflineDropped ||
              reason == UserOfflineReasonType.userOfflineQuit) {
            _handleCallEnded();
          }
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          _logger.i('Left channel');
          _isInCall = false;
          _updateCallStatus(CallStatus.ended);
        },
        onError: (ErrorCodeType err, String msg) {
          _logger.e('Agora error: $err - $msg');
          _updateCallStatus(CallStatus.failed);
        },
      ));

      _logger.i('WebRTC service initialized successfully');
    } catch (e) {
      _logger.e('Failed to initialize WebRTC service: $e');
      throw Exception('Failed to initialize WebRTC service: $e');
    }
  }

  /// Check if necessary permissions are granted (does not request)
  /// This should be called AFTER permissions have been requested by the UI layer
  Future<bool> checkPermissions({bool isVideoCall = true}) async {
    try {
      final micStatus = await Permission.microphone.status;
      if (!micStatus.isGranted) {
        _logger.w('Microphone permission not granted');
        return false;
      }

      if (isVideoCall) {
        final cameraStatus = await Permission.camera.status;
        if (!cameraStatus.isGranted) {
          _logger.w('Camera permission not granted');
          return false;
        }
      }

      return true;
    } catch (e) {
      _logger.e('Error checking permissions: $e');
      return false;
    }
  }

  /// Start an outgoing call
  Future<void> startCall({
    required String receiverId,
    required String receiverName,
    String? receiverAvatar,
    required CallType callType,
    required String channelName,
    required String token,
  }) async {
    try {
      if (_isInCall) {
        throw Exception('Already in a call');
      }

      // Check permissions (should already be granted by UI layer)
      final hasPermissions = await checkPermissions(
        isVideoCall: callType == CallType.video,
      );
      if (!hasPermissions) {
        throw Exception('Required permissions not granted');
      }

      // Create call model
      _currentCall = CallModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        callerId: 'current_user_id',
        callerName: 'Current User',
        receiverId: receiverId,
        receiverName: receiverName,
        receiverAvatar: receiverAvatar,
        type: callType,
        status: CallStatus.initiating,
        channelName: channelName,
        token: token,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      _callStateController.add(_currentCall);

      // Configure engine for call type
      await _configureEngineForCall(callType);

      // Join channel
      await _engine!.joinChannel(
        token: token,
        channelId: channelName,
        uid: 0, // Let Agora assign UID
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );

      // Send call signal through WebSocket
      _sendCallSignal(CallSignalType.offer);

      _logger.i('Started call to $receiverName');
    } catch (e) {
      _logger.e('Failed to start call: $e');
      _updateCallStatus(CallStatus.failed);
      throw Exception('Failed to start call: $e');
    }
  }

  /// Answer an incoming call
  Future<void> answerCall({
    required String channelName,
    required String token,
  }) async {
    try {
      if (_currentCall == null) {
        throw Exception('No incoming call to answer');
      }

      // Check permissions (should already be granted by UI layer)
      final hasPermissions = await checkPermissions(
        isVideoCall: _currentCall!.type == CallType.video,
      );
      if (!hasPermissions) {
        throw Exception('Required permissions not granted');
      }

      // Configure engine
      await _configureEngineForCall(_currentCall!.type);

      // Join channel
      await _engine!.joinChannel(
        token: token,
        channelId: channelName,
        uid: 0,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );

      // Send answer signal
      _sendCallSignal(CallSignalType.answer);

      _logger.i('Answered call');
    } catch (e) {
      _logger.e('Failed to answer call: $e');
      _updateCallStatus(CallStatus.failed);
      throw Exception('Failed to answer call: $e');
    }
  }

  /// End the current call
  Future<void> endCall() async {
    try {
      if (_currentCall == null) return;

      // Send hangup signal
      _sendCallSignal(CallSignalType.hangup);

      // Leave channel
      await _engine?.leaveChannel();

      _handleCallEnded();
      
      _logger.i('Call ended');
    } catch (e) {
      _logger.e('Error ending call: $e');
    }
  }

  /// Decline an incoming call
  Future<void> declineCall() async {
    try {
      if (_currentCall == null) return;

      // Send reject signal
      _sendCallSignal(CallSignalType.reject);

      _updateCallStatus(CallStatus.declined);
      _currentCall = null;
      _callStateController.add(null);

      _logger.i('Call declined');
    } catch (e) {
      _logger.e('Error declining call: $e');
    }
  }

  /// Toggle microphone mute
  Future<void> toggleMute() async {
    try {
      _isMuted = !_isMuted;
      await _engine?.muteLocalAudioStream(_isMuted);
      _muteStateController.add(_isMuted);

      // Send mute signal
      _sendCallSignal(_isMuted ? CallSignalType.mute : CallSignalType.unmute);

      _logger.i('Microphone ${_isMuted ? 'muted' : 'unmuted'}');
    } catch (e) {
      _logger.e('Error toggling mute: $e');
    }
  }

  /// Toggle camera on/off
  Future<void> toggleCamera() async {
    try {
      if (_currentCall?.type != CallType.video) return;

      _isVideoEnabled = !_isVideoEnabled;
      
      // ✅ FIXED: Use enableLocalVideo instead of muteLocalVideoStream
      // enableLocalVideo actually stops the camera, muteLocalVideoStream just stops sending
      await _engine?.enableLocalVideo(_isVideoEnabled);
      _videoStateController.add(_isVideoEnabled);

      // Send camera signal
      _sendCallSignal(_isVideoEnabled ? CallSignalType.cameraOn : CallSignalType.cameraOff);

      _logger.i('Camera ${_isVideoEnabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      _logger.e('Error toggling camera: $e');
    }
  }

  /// Switch camera (front/back)
  Future<void> switchCamera() async {
    try {
      if (_currentCall?.type != CallType.video) return;
      await _engine?.switchCamera();
      _logger.i('Camera switched');
    } catch (e) {
      _logger.e('Error switching camera: $e');
    }
  }

  /// Toggle speaker on/off
  Future<void> toggleSpeaker() async {
    try {
      _isSpeakerOn = !_isSpeakerOn;
      await _engine?.setEnableSpeakerphone(_isSpeakerOn);
      _speakerStateController.add(_isSpeakerOn);
      _logger.i('Speaker ${_isSpeakerOn ? 'enabled' : 'disabled'}');
    } catch (e) {
      _logger.e('Error toggling speaker: $e');
    }
  }

  /// Handle incoming call signal
  void handleIncomingCallSignal(CallSignalModel signal) {
    switch (signal.type) {
      case CallSignalType.offer:
        _handleIncomingCall(signal);
        break;
      case CallSignalType.answer:
        _updateCallStatus(CallStatus.connected);
        break;
      case CallSignalType.hangup:
      case CallSignalType.reject:
        _handleCallEnded();
        break;
      default:
        break;
    }
  }

  /// Configure engine settings for call type
  Future<void> _configureEngineForCall(CallType callType) async {
    // Enable audio
    await _engine!.enableAudio();
    
    if (callType == CallType.video) {
      // Enable video for video calls
      await _engine!.enableVideo();
      await _engine!.enableLocalVideo(
        true,
      ); // ✅ ADDED: Enable local video capture
      await _engine!.startPreview();
    } else {
      // Disable video for audio calls
      await _engine!.disableVideo();
      await _engine!.enableLocalVideo(
        false,
      ); // ✅ ADDED: Ensure video is disabled
    }

    // Set default states
    _isMuted = false;
    _isVideoEnabled = callType == CallType.video;
    _isSpeakerOn = callType == CallType.video; // Default to speaker for video calls

    await _engine!.muteLocalAudioStream(_isMuted);
    await _engine!.setEnableSpeakerphone(_isSpeakerOn);

    // Emit initial states
    _muteStateController.add(_isMuted);
    _videoStateController.add(_isVideoEnabled);
    _speakerStateController.add(_isSpeakerOn);
  }

  /// Handle incoming call
  void _handleIncomingCall(CallSignalModel signal) {
    // Create call model from signal data
    _currentCall = CallModel(
      id: signal.callId,
      callerId: signal.fromUserId,
      callerName: signal.data?['callerName'] ?? 'Unknown',
      callerAvatar: signal.data?['callerAvatar'],
      receiverId: signal.toUserId,
      receiverName: 'You',
      type: CallType.values.byName(signal.data?['callType'] ?? 'audio'),
      status: CallStatus.ringing,
      channelName: signal.data?['channelName'],
      token: signal.data?['token'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _callStateController.add(_currentCall);
  }

  /// Handle call ended
  void _handleCallEnded() {
    _isInCall = false;
    _updateCallStatus(CallStatus.ended);
    _currentCall = null;
    _callStateController.add(null);
    _remoteUsersController.add([]);
  }

  /// Update call status
  void _updateCallStatus(CallStatus status) {
    if (_currentCall != null) {
      _currentCall = _currentCall!.copyWith(
        status: status,
        updatedAt: DateTime.now(),
        startedAt: status == CallStatus.connected ? DateTime.now() : _currentCall!.startedAt,
        endedAt: status == CallStatus.ended ? DateTime.now() : _currentCall!.endedAt,
      );
      _callStateController.add(_currentCall);
    }
  }

  /// Send call signal through WebSocket
  void _sendCallSignal(CallSignalType signalType) {
    if (_currentCall == null || _webSocketService == null) return;

    final signal = CallSignalModel(
      callId: _currentCall!.id,
      type: signalType,
      fromUserId: _currentCall!.callerId,
      toUserId: _currentCall!.receiverId,
      data: {
        'channelName': _currentCall!.channelName,
        'token': _currentCall!.token,
        'callType': _currentCall!.type.name,
        'callerName': _currentCall!.callerName,
        'callerAvatar': _currentCall!.callerAvatar,
      },
    );

    _webSocketService!.sendWebRTCSignaling(_currentCall!.id, signal.toJson());
  }

  /// Get RTC token from backend for a specific channel
  /// 
  /// This calls the POST /api/v1/webrtc/rtc-token endpoint
  /// 
  /// Parameters:
  /// - [channelName]: The name of the channel to join
  /// - [role]: 1 = PUBLISHER/Host (default), 2 = SUBSCRIBER/Audience
  /// 
  /// Returns a Map with:
  /// - token: The Agora RTC token
  /// - channelName: The channel name
  /// - uid: The user ID for this session
  /// - appId: The Agora app ID
  /// - expiresIn: Token expiration time in seconds
  /// - role: The role string (PUBLISHER or SUBSCRIBER)
  Future<Map<String, dynamic>> getRtcToken({
    required String channelName,
    int role = 1,
  }) async {
    try {
      final apiClient = ApiClient.instance;
      
      final response = await apiClient.post(
        ApiConstants.webrtcRtcToken,
        data: {
          'channelName': channelName,
          'role': role,
        },
      );

      final data = response.data as Map<String, dynamic>;
      
      // Backend returns { data: { token, channelName, uid, appId, expiresIn, role } }
      if (data.containsKey('data')) {
        return data['data'] as Map<String, dynamic>;
      }
      
      // Fallback if response structure is different
      return data;
    } catch (e) {
      _logger.e('Failed to get RTC token: $e');
      throw Exception('Failed to get RTC token: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _engine?.leaveChannel();
    _engine?.release();
    _callStateController.close();
    _muteStateController.close();
    _videoStateController.close();
    _speakerStateController.close();
    _remoteUsersController.close();
  }
}