import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../domain/entities/call.dart';
import '../models/call_model.dart' as model;
import 'websocket_service.dart';
import 'webrtc_service.dart';

/// Service for managing WebRTC calls and real-time communication
class CallService {
  static CallService? _instance;
  static CallService get instance => _instance ??= CallService._();
  
  CallService._();

  final WebSocketService _webSocketService = WebSocketService.instance;
  final WebRTCService _webRTCService = WebRTCService();
  
  // Stream controllers for call events
  final StreamController<Call> _incomingCallController = StreamController.broadcast();
  final StreamController<String> _callEndedController = StreamController.broadcast();
  final StreamController<CallConnectionState> _connectionStateController = StreamController.broadcast();
  final StreamController<CallQuality> _callQualityController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _signalingController = StreamController.broadcast();

  // Public streams
  Stream<Call> get onIncomingCall => _incomingCallController.stream;
  Stream<String> get onCallEnded => _callEndedController.stream;
  Stream<CallConnectionState> get onConnectionStateChanged => _connectionStateController.stream;
  Stream<CallQuality> get onCallQualityChanged => _callQualityController.stream;
  Stream<Map<String, dynamic>> get onSignalingReceived => _signalingController.stream;

  bool _isInitialized = false;

  /// Initialize the call service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Setup WebSocket listeners for call events
    _setupWebSocketListeners();
    _isInitialized = true;
  }

  /// Setup WebSocket event listeners
  void _setupWebSocketListeners() {
    // Incoming call listener
    _webSocketService.onCallReceived = (callId) {
      // Create a mock call for now - in production this would fetch from API
      final call = Call(
        id: callId,
        callerId: 'unknown_caller',
        recipientId: 'current_user_id',
        type: CallType.video,
        status: CallStatus.incoming,
        createdAt: DateTime.now(),
      );
      _incomingCallController.add(call);
    };

    // Call ended listener
    _webSocketService.onCallEnded = (callId) {
      _callEndedController.add(callId);
    };
  }

  /// Initiate a new call
  Future<String> initiateCall({
    required String recipientId,
    required CallType type,
  }) async {
    try {
      // Generate call ID and channel name
      final callId = DateTime.now().millisecondsSinceEpoch.toString();
      final channelName = 'call_$callId';
      
      // Send call initiation through WebSocket
      _webSocketService.initiateCall(recipientId, type.name);
      
      // Start WebRTC call (token should come from backend)
      // For now using a placeholder token - in production get from API
      await _webRTCService.startCall(
        receiverId: recipientId,
        receiverName: 'User $recipientId', // Should come from user data
        callType: type == CallType.video ? model.CallType.video : model.CallType.audio,
        channelName: channelName,
        token: 'placeholder_token', // Get from backend API
      );
      
      return callId;
    } catch (e) {
      throw CallException('Failed to initiate call: $e');
    }
  }

  /// Accept an incoming call
  Future<void> acceptCall(String callId) async {
    try {
      _webSocketService.acceptCall(callId);
      _connectionStateController.add(CallConnectionState.connecting);
      
      // Answer WebRTC call with channel name and token from incoming call
      // In production, these should be provided by the incoming call data
      await _webRTCService.answerCall(
        channelName: 'call_$callId',
        token: 'placeholder_token', // Get from backend API
      );
    } catch (e) {
      throw CallException('Failed to accept call: $e');
    }
  }

  /// Decline an incoming call
  Future<void> declineCall(String callId) async {
    try {
      _webSocketService.rejectCall(callId);
    } catch (e) {
      throw CallException('Failed to decline call: $e');
    }
  }

  /// End the current call
  Future<void> endCall(String callId) async {
    try {
      _webSocketService.endCall(callId);
      
      // End WebRTC call
      await _webRTCService.endCall();
    } catch (e) {
      throw CallException('Failed to end call: $e');
    }
  }

  /// Toggle video during call
  Future<void> toggleVideo(String callId, bool enabled) async {
    try {
      // Use WebRTCService to toggle camera
      if (enabled) {
        await _webRTCService.toggleCamera();
      } else {
        await _webRTCService.toggleCamera();
      }
      debugPrint('Video ${enabled ? 'enabled' : 'disabled'} for call $callId');
    } catch (e) {
      throw CallException('Failed to toggle video: $e');
    }
  }

  /// Toggle audio during call
  Future<void> toggleAudio(String callId, bool enabled) async {
    try {
      // Use WebRTCService to toggle microphone
      await _webRTCService.toggleMute();
      debugPrint('Audio ${enabled ? 'enabled' : 'disabled'} for call $callId');
    } catch (e) {
      throw CallException('Failed to toggle audio: $e');
    }
  }

  /// Switch camera (front/back)
  Future<void> switchCamera(String callId) async {
    try {
      // Use WebRTCService to switch camera
      await _webRTCService.switchCamera();
      debugPrint('Camera switched for call $callId');
    } catch (e) {
      throw CallException('Failed to switch camera: $e');
    }
  }

  /// Send WebRTC signaling data
  Future<void> sendSignaling({
    required String callId,
    required Map<String, dynamic> signalingData,
  }) async {
    try {
      // Use WebRTCService for signaling
      if (signalingData['type'] != null) {
        // Handle different signaling types
        final signalType = signalingData['type'] as String;
        switch (signalType) {
          case 'offer':
            // Handled by WebRTCService internally
            break;
          case 'answer':
            // Handled by WebRTCService internally
            break;
          case 'ice-candidate':
            // ICE candidates handled by Agora SDK
            break;
          default:
            debugPrint('Unknown signaling type: $signalType');
        }
      }
      _signalingController.add(signalingData);
    } catch (e) {
      throw CallException('Failed to send signaling data: $e');
    }
  }

  /// Get call history for current user
  Future<List<Call>> getCallHistory({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      // TODO: Implement API call to fetch call history
      // For now, return empty list
      return [];
    } catch (e) {
      throw CallException('Failed to get call history: $e');
    }
  }

  /// Update call quality metrics
  void updateCallQuality(CallQuality quality) {
    _callQualityController.add(quality);
  }

  /// Update connection state
  void updateConnectionState(CallConnectionState state) {
    _connectionStateController.add(state);
  }

  /// Check if WebSocket is connected
  bool get isConnected => _webSocketService.isConnected;

  /// Connect WebSocket if not already connected
  Future<void> ensureConnection(String userId, String token) async {
    if (!_webSocketService.isConnected) {
      await _webSocketService.connect(userId, token);
    }
  }

  /// Dispose resources
  void dispose() {
    _incomingCallController.close();
    _callEndedController.close();
    _connectionStateController.close();
    _callQualityController.close();
    _signalingController.close();
    _isInitialized = false;
  }
}

/// Exception class for call-related errors
class CallException implements Exception {
  final String message;
  
  const CallException(this.message);
  
  @override
  String toString() => 'CallException: $message';
}

/// Extension methods for call quality
extension CallQualityExtension on CallQuality {
  /// Get quality score (0-100)
  int get score {
    switch (this) {
      case CallQuality.poor:
        return 25;
      case CallQuality.fair:
        return 50;
      case CallQuality.good:
        return 75;
      case CallQuality.excellent:
        return 100;
    }
  }

  /// Get quality color for UI
  String get colorHex {
    switch (this) {
      case CallQuality.poor:
        return '#FF4444'; // Red
      case CallQuality.fair:
        return '#FF8800'; // Orange
      case CallQuality.good:
        return '#44AA44'; // Green
      case CallQuality.excellent:
        return '#00AA44'; // Dark Green
    }
  }

  /// Check if quality is acceptable
  bool get isAcceptable => [CallQuality.good, CallQuality.excellent].contains(this);
}
