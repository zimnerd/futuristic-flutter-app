import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/network/api_client.dart';
import 'live_streaming_service.dart';

/// Streaming state enum
enum StreamState {
  idle,
  connecting,
  connected,
  disconnected,
  error,
}

/// Video streaming service for live broadcasts using Agora SDK
/// Handles broadcaster (host) and audience (viewer) roles
class VideoStreamingService {
  static final VideoStreamingService _instance = VideoStreamingService._internal();
  static VideoStreamingService get instance => _instance;

  VideoStreamingService._internal();

  RtcEngine? _engine;
  final Logger _logger = Logger();

  // Stream controllers for state management
  final _streamStateController = StreamController<StreamState>.broadcast();
  final _remoteUsersController = StreamController<List<int>>.broadcast();
  final _localVideoEnabledController = StreamController<bool>.broadcast();
  final _localAudioEnabledController = StreamController<bool>.broadcast();
  final _remoteVideoStateController = StreamController<Map<int, bool>>.broadcast();
  final _connectionQualityController = StreamController<QualityType>.broadcast();
  final _streamErrorController = StreamController<String>.broadcast();
  final _viewerCountController = StreamController<int>.broadcast();

  // Stream getters
  Stream<StreamState> get onStreamStateChanged => _streamStateController.stream;
  Stream<List<int>> get onRemoteUsersChanged => _remoteUsersController.stream;
  Stream<bool> get onLocalVideoEnabledChanged => _localVideoEnabledController.stream;
  Stream<bool> get onLocalAudioEnabledChanged => _localAudioEnabledController.stream;
  Stream<Map<int, bool>> get onRemoteVideoStateChanged => _remoteVideoStateController.stream;
  Stream<QualityType> get onConnectionQualityChanged => _connectionQualityController.stream;
  Stream<String> get onStreamError => _streamErrorController.stream;
  Stream<int> get onViewerCountChanged => _viewerCountController.stream;

  // State variables
  StreamState _currentState = StreamState.idle;
  String? _currentStreamId;
  String? _currentChannelName;
  bool _isBroadcaster = false;
  bool _isLocalVideoEnabled = true;
  bool _isLocalAudioEnabled = true;
  final List<int> _remoteUsers = [];
  final Map<int, bool> _remoteVideoStates = {};

  // Getters
  StreamState get currentState => _currentState;
  String? get currentStreamId => _currentStreamId;
  String? get currentChannelName => _currentChannelName;
  bool get isBroadcaster => _isBroadcaster;
  bool get isLocalVideoEnabled => _isLocalVideoEnabled;
  bool get isLocalAudioEnabled => _isLocalAudioEnabled;
  List<int> get remoteUsers => List.unmodifiable(_remoteUsers);
  RtcEngine? get engine => _engine;

  /// Initialize the Agora RTC engine
  Future<void> initialize(String appId) async {
    if (_engine != null) {
      _logger.w('Engine already initialized');
      return;
    }

    try {
      _logger.d('Initializing Agora RTC Engine with App ID: $appId');
      
      // Request permissions first
      await _requestPermissions();

      // Create engine
      _engine = createAgoraRtcEngine();
      
      await _engine!.initialize(RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));

      // Register event handlers
      _registerEventHandlers();

      _logger.d('Agora RTC Engine initialized successfully');
    } catch (e) {
      _logger.e('Error initializing Agora engine: $e');
      _streamErrorController.add('Failed to initialize: $e');
      rethrow;
    }
  }

  /// Request camera and microphone permissions
  Future<void> _requestPermissions() async {
    await [
      Permission.camera,
      Permission.microphone,
    ].request();
  }

  /// Register event handlers for Agora events
  void _registerEventHandlers() {
    if (_engine == null) return;

    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          _logger.d('Successfully joined channel: ${connection.channelId}');
          _updateState(StreamState.connected);
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          _logger.d('Remote user joined: $remoteUid');
          if (!_remoteUsers.contains(remoteUid)) {
            _remoteUsers.add(remoteUid);
            _remoteUsersController.add(List.from(_remoteUsers));
            
            // Update viewer count if we're the broadcaster
            if (_isBroadcaster) {
              _viewerCountController.add(_remoteUsers.length);
            }
          }
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          _logger.d('Remote user offline: $remoteUid, reason: $reason');
          _remoteUsers.remove(remoteUid);
          _remoteVideoStates.remove(remoteUid);
          _remoteUsersController.add(List.from(_remoteUsers));
          _remoteVideoStateController.add(Map.from(_remoteVideoStates));
          
          // Update viewer count if we're the broadcaster
          if (_isBroadcaster) {
            _viewerCountController.add(_remoteUsers.length);
          }
        },
        onRemoteVideoStateChanged: (RtcConnection connection, int remoteUid, 
            RemoteVideoState state, RemoteVideoStateReason reason, int elapsed) {
          _logger.d('Remote video state changed: uid=$remoteUid, state=$state');
          
          final isVideoEnabled = state == RemoteVideoState.remoteVideoStateDecoding ||
                                 state == RemoteVideoState.remoteVideoStateStarting;
          
          _remoteVideoStates[remoteUid] = isVideoEnabled;
          _remoteVideoStateController.add(Map.from(_remoteVideoStates));
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          _logger.d('Left channel: ${connection.channelId}');
          _cleanup();
        },
        onError: (ErrorCodeType err, String msg) {
          _logger.e('Agora error: $err - $msg');
          _streamErrorController.add('Error: $msg');
          _updateState(StreamState.error);
        },
        onConnectionStateChanged: (RtcConnection connection, 
            ConnectionStateType state, ConnectionChangedReasonType reason) {
          _logger.d('Connection state changed: $state, reason: $reason');
          
          if (state == ConnectionStateType.connectionStateConnected) {
            _updateState(StreamState.connected);
          } else if (state == ConnectionStateType.connectionStateDisconnected ||
                     state == ConnectionStateType.connectionStateFailed) {
            _updateState(StreamState.disconnected);
          }
        },
        onNetworkQuality: (RtcConnection connection, int remoteUid, 
            QualityType txQuality, QualityType rxQuality) {
          // Report the worse of the two qualities
          final quality = txQuality.index > rxQuality.index ? txQuality : rxQuality;
          _connectionQualityController.add(quality);
        },
        // ✅ NEW - Token expiry handling (production-critical)
        onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
          _logger.w('⚠️ Token expiring in 30 seconds, refreshing...');
          _refreshToken();
        },
        onRequestToken: (RtcConnection connection) {
          _logger.e('❌ Token expired, must refresh immediately');
          _refreshToken();
        },
        // ✅ NEW - Connection recovery
        onConnectionLost: (RtcConnection connection) {
          _logger.w('⚠️ Connection lost, attempting to reconnect...');
          _streamErrorController.add('Connection lost, reconnecting...');
        },
        onRejoinChannelSuccess: (RtcConnection connection, int elapsed) {
          _logger.i('✅ Successfully rejoined channel after disconnection');
        },
        // ✅ NEW - Local video state monitoring
        onLocalVideoStateChanged:
            (
              VideoSourceType source,
              LocalVideoStreamState state,
              LocalVideoStreamReason reason,
            ) {
              _logger.i('📹 Local video state: $state, reason: $reason');
            },
        // ✅ NEW - Local audio state monitoring
        onLocalAudioStateChanged:
            (
              RtcConnection connection,
              LocalAudioStreamState state,
              LocalAudioStreamReason reason,
            ) {
              _logger.i('🎤 Local audio state: $state, reason: $reason');
            },
        // ✅ NEW - Remote audio state monitoring
        onRemoteAudioStateChanged:
            (
              RtcConnection connection,
              int remoteUid,
              RemoteAudioState state,
              RemoteAudioStateReason reason,
              int elapsed,
            ) {
              _logger.i(
                '🔊 Remote audio state (uid: $remoteUid): $state, reason: $reason',
              );
            },
      ),
    );
  }

  /// Start streaming as broadcaster (host)
  Future<void> startBroadcasting({
    required String streamId,
    required String channelName,
    required String token,
    required int uid,
  }) async {
    try {
      if (_engine == null) {
        throw Exception('Engine not initialized. Call initialize() first.');
      }

      _logger.d('Starting broadcast - Stream: $streamId, Channel: $channelName, UID: $uid');
      
      _currentStreamId = streamId;
      _currentChannelName = channelName;
      _isBroadcaster = true;
      
      _updateState(StreamState.connecting);

      // Set client role as broadcaster
      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

      // Enable video
      await _engine!.enableVideo();
      await _engine!.enableLocalVideo(true);
      
      // Enable audio
      await _engine!.enableAudio();
      await _engine!.enableLocalAudio(true);

      // Start camera preview
      await _engine!.startPreview();

      // Set video configuration
      await _engine!.setVideoEncoderConfiguration(
        const VideoEncoderConfiguration(
          dimensions: VideoDimensions(width: 1280, height: 720),
          frameRate: 30,
          bitrate: 0, // Let Agora determine optimal bitrate
          orientationMode: OrientationMode.orientationModeFixedPortrait,
        ),
      );

      // Join channel
      await _engine!.joinChannel(
        token: token,
        channelId: channelName,
        uid: uid,
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishCameraTrack: true,
          publishMicrophoneTrack: true,
        ),
      );

      _logger.d('Successfully started broadcasting');
    } catch (e) {
      _logger.e('Error starting broadcast: $e');
      _streamErrorController.add('Failed to start broadcast: $e');
      _updateState(StreamState.error);
      rethrow;
    }
  }

  /// Join stream as audience (viewer)
  Future<void> joinAsAudience({
    required String streamId,
    required String channelName,
    required String token,
    required int uid,
  }) async {
    try {
      if (_engine == null) {
        throw Exception('Engine not initialized. Call initialize() first.');
      }

      _logger.d('Joining as audience - Stream: $streamId, Channel: $channelName, UID: $uid');
      
      _currentStreamId = streamId;
      _currentChannelName = channelName;
      _isBroadcaster = false;
      
      _updateState(StreamState.connecting);

      // Set client role as audience
      await _engine!.setClientRole(role: ClientRoleType.clientRoleAudience);

      // Enable video playback (but not publishing)
      await _engine!.enableVideo();
      await _engine!.enableLocalVideo(false);

      // Join channel
      await _engine!.joinChannel(
        token: token,
        channelId: channelName,
        uid: uid,
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
          clientRoleType: ClientRoleType.clientRoleAudience,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
        ),
      );

      _logger.d('Successfully joined as audience');
    } catch (e) {
      _logger.e('Error joining as audience: $e');
      _streamErrorController.add('Failed to join stream: $e');
      _updateState(StreamState.error);
      rethrow;
    }
  }

  /// Toggle camera on/off (broadcaster only)
  Future<void> toggleCamera() async {
    if (!_isBroadcaster || _engine == null) return;

    try {
      _isLocalVideoEnabled = !_isLocalVideoEnabled;
      await _engine!.enableLocalVideo(_isLocalVideoEnabled);
      _localVideoEnabledController.add(_isLocalVideoEnabled);
      _logger.d('Camera ${_isLocalVideoEnabled ? "enabled" : "disabled"}');
    } catch (e) {
      _logger.e('Error toggling camera: $e');
      _streamErrorController.add('Failed to toggle camera: $e');
    }
  }

  /// Toggle microphone on/off
  Future<void> toggleMicrophone() async {
    if (_engine == null) return;

    try {
      _isLocalAudioEnabled = !_isLocalAudioEnabled;
      await _engine!.enableLocalAudio(_isLocalAudioEnabled);
      _localAudioEnabledController.add(_isLocalAudioEnabled);
      _logger.d('Microphone ${_isLocalAudioEnabled ? "enabled" : "disabled"}');
    } catch (e) {
      _logger.e('Error toggling microphone: $e');
      _streamErrorController.add('Failed to toggle microphone: $e');
    }
  }

  /// Switch camera (front/back) - broadcaster only
  Future<void> switchCamera() async {
    if (!_isBroadcaster || _engine == null) return;

    try {
      await _engine!.switchCamera();
      _logger.d('Camera switched');
    } catch (e) {
      _logger.e('Error switching camera: $e');
      _streamErrorController.add('Failed to switch camera: $e');
    }
  }

  /// Refresh token when expiring or expired
  Future<void> _refreshToken() async {
    if (_currentStreamId == null || _currentChannelName == null) {
      _logger.w('⚠️ Cannot refresh token: missing stream context');
      return;
    }

    try {
      _logger.i('🔄 Refreshing Agora token for stream: $_currentStreamId');

      final liveStreamingService = LiveStreamingService(ApiClient.instance);
      final role = _isBroadcaster ? 'broadcaster' : 'audience';

      final tokenData = await liveStreamingService.generateStreamRtcToken(
        streamId: _currentStreamId!,
        role: role,
      );

      if (tokenData == null) {
        _logger.e('❌ Failed to refresh token');
        _streamErrorController.add('Failed to refresh authentication');
        return;
      }

      final newToken = tokenData['token'] as String;

      _logger.i('✅ Token refreshed successfully');

      // Update token without rejoining channel
      await _engine?.renewToken(newToken);

      _logger.i('✅ Token renewed in Agora engine');
    } catch (e) {
      _logger.e('❌ Error refreshing token: $e');
      _streamErrorController.add('Authentication refresh failed');
    }
  }

  /// Leave the current stream
  Future<void> leaveStream() async {
    if (_engine == null) return;

    try {
      _logger.d('Leaving stream: $_currentStreamId');
      
      await _engine!.leaveChannel();
      
      if (_isBroadcaster) {
        await _engine!.stopPreview();
      }

      _cleanup();
      _logger.d('Successfully left stream');
    } catch (e) {
      _logger.e('Error leaving stream: $e');
      _streamErrorController.add('Failed to leave stream: $e');
    }
  }

  /// Clean up resources
  void _cleanup() {
    _currentStreamId = null;
    _currentChannelName = null;
    _isBroadcaster = false;
    _isLocalVideoEnabled = true;
    _isLocalAudioEnabled = true;
    _remoteUsers.clear();
    _remoteVideoStates.clear();
    
    _remoteUsersController.add([]);
    _remoteVideoStateController.add({});
    _viewerCountController.add(0);
    _updateState(StreamState.idle);
  }

  /// Update stream state
  void _updateState(StreamState newState) {
    if (_currentState != newState) {
      _currentState = newState;
      _streamStateController.add(newState);
      _logger.d('Stream state changed to: $newState');
    }
  }

  /// Dispose the service and release resources
  Future<void> dispose() async {
    try {
      await leaveStream();
      await _engine?.release();
      _engine = null;

      await _streamStateController.close();
      await _remoteUsersController.close();
      await _localVideoEnabledController.close();
      await _localAudioEnabledController.close();
      await _remoteVideoStateController.close();
      await _connectionQualityController.close();
      await _streamErrorController.close();
      await _viewerCountController.close();

      _logger.d('VideoStreamingService disposed');
    } catch (e) {
      _logger.e('Error disposing VideoStreamingService: $e');
    }
  }
}
