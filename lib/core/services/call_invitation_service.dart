import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/call_invitation.dart';
import '../../domain/services/websocket_service.dart';
import '../../data/services/websocket_service_impl.dart';

/// Service for managing call invitations between users
///
/// Handles sending/receiving call invitations via WebSocket,
/// managing call timeouts, busy states, and integration with native CallKit
/// 
/// NOTE: RTC tokens are NOT generated here - they come from backend
/// in the 'call_ready_to_connect' event after recipient accepts
class CallInvitationService {
  static final CallInvitationService _instance =
      CallInvitationService._internal();
  factory CallInvitationService() => _instance;
  CallInvitationService._internal();

  final WebSocketService _webSocketService = WebSocketServiceImpl.instance;
  final _uuid = const Uuid();

  // Stream controllers
  final _incomingCallController = StreamController<CallInvitation>.broadcast();
  final _callAcceptedController = StreamController<CallInvitation>.broadcast();
  final _callRejectedController = StreamController<CallInvitation>.broadcast();
  final _callTimeoutController = StreamController<CallInvitation>.broadcast();
  final _callCancelledController = StreamController<CallInvitation>.broadcast();
  final _callStateController = StreamController<CallState>.broadcast();
  
  // NEW: Connection status stream for Agora coordination
  final _connectionStatusController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Public streams
  Stream<CallInvitation> get onIncomingCall => _incomingCallController.stream;
  Stream<CallInvitation> get onCallAccepted => _callAcceptedController.stream;
  Stream<CallInvitation> get onCallRejected => _callRejectedController.stream;
  Stream<CallInvitation> get onCallTimeout => _callTimeoutController.stream;
  Stream<CallInvitation> get onCallCancelled => _callCancelledController.stream;
  Stream<CallState> get onCallStateChanged => _callStateController.stream;
  
  /// Stream for call connection status changes
  /// Emits events: call_ready_to_connect, call_connected, call_failed
  Stream<Map<String, dynamic>> get onConnectionStatusChanged =>
      _connectionStatusController.stream;

  // Current state
  CallState _currentState = const CallState();
  final Map<String, Timer> _callTimeouts = {};

  /// Initialize the service and listen to WebSocket events
  Future<void> initialize() async {
    debugPrint('🎬 CallInvitationService.initialize() called');

    // Listen to WebSocket connection status to set up listeners after connection
    _webSocketService.connectionStatus.listen((isConnected) {
      debugPrint('🔌 WebSocket connection status changed: $isConnected');
      if (isConnected) {
        _registerEventListeners();
      }
    });

    // If already connected, register listeners immediately
    if (_webSocketService.isConnected) {
      debugPrint(
        '✅ WebSocket already connected, registering listeners immediately',
      );
      _registerEventListeners();
    } else {
      debugPrint(
        '⏳ WebSocket not yet connected, listeners will be registered on connection',
      );
    }

    debugPrint('✅ CallInvitationService initialized');
  }

  /// Register event listeners on WebSocket
  /// Called when WebSocket connects or reconnects
  void _registerEventListeners() {
    debugPrint('📋 Registering call event listeners on WebSocket...');

    // Note: Socket.IO allows registering the same listener multiple times
    // but will only fire once per event. We re-register on every connect
    // to ensure listeners persist after reconnections.

    // Listen to WebSocket events using the service interface
    _webSocketService.on('call_invitation', _handleIncomingCall);
    _webSocketService.on('call_accepted', _handleCallAccepted);
    _webSocketService.on('call_rejected', _handleCallRejected);
    _webSocketService.on('call_timeout', _handleCallTimeout);
    _webSocketService.on('call_cancelled', _handleCallCancelled);
    
    // NEW: Listen for connection status events
    _webSocketService.on('call_ready_to_connect', _handleReadyToConnect);
    _webSocketService.on('call_connected', _handleCallConnected);
    _webSocketService.on('call_failed', _handleCallFailed);

    debugPrint('✅ All call event listeners registered (total: 8 events)');
  }

  /// Send a call invitation to another user
  /// 
  /// NOTE: Does NOT generate RTC token here!
  /// Token will be received in 'call_ready_to_connect' event after recipient accepts.
  /// This prevents Agora resource usage if call is declined/timeout.
  Future<CallInvitation> sendCallInvitation({
    required String recipientId,
    required String recipientName,
    required CallType callType,
    String? recipientPhoto,
    String? conversationId,
    String? groupId,
    Map<String, dynamic>? metadata,
  }) async {
    // Check if user can make calls
    if (!_currentState.canReceiveCalls) {
      throw CallException('Cannot make calls while in another call');
    }

    // Generate call ID and channel name
    final callId = _uuid.v4();
    final channelName = groupId ?? callId;

    // ❌ DO NOT generate RTC token here!
    // Token will be sent by backend in 'call_ready_to_connect' event
    // after recipient accepts the call
    // This optimization prevents Agora charges for declined/timeout calls

    // Create invitation WITHOUT token
    final invitation = CallInvitation(
      callId: callId,
      callerId: '', // Will be set by backend from JWT
      callerName: '', // Will be set by backend from user data
      recipientId: recipientId,
      callType: callType,
      status: CallInvitationStatus.pending,
      conversationId: conversationId,
      groupId: groupId,
      // rtcToken: null, // Will be received in ready_to_connect event
      channelName: channelName,
      metadata: metadata,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(seconds: 30)),
    );

    // Send via WebSocket using the service interface
    _webSocketService.emit('send_call_invitation', invitation.toJson());

    // Update state
    _currentState = _currentState.copyWith(outgoingInvitation: invitation);
    _callStateController.add(_currentState);

    // Set timeout (30 seconds)
    _setCallTimeout(callId);

    debugPrint('Sent call invitation: $callId to $recipientId');
    return invitation;
  }

  /// Accept an incoming call
  Future<void> acceptCall(String callId) async {
    final invitation = _currentState.currentInvitation;
    if (invitation == null || invitation.callId != callId) {
      throw CallException('No active invitation to accept');
    }

    // Send acceptance via WebSocket using the service interface
    _webSocketService.emit('accept_call', {'callId': callId});

    // Update state
    _currentState = _currentState.copyWith(
      isInCall: true,
      currentInvitation: invitation.copyWith(
        status: CallInvitationStatus.accepted,
      ),
    );
    _callStateController.add(_currentState);

    // Cancel timeout
    _cancelCallTimeout(callId);

    debugPrint('Accepted call: $callId');
  }

  /// Reject an incoming call
  Future<void> rejectCall(String callId, {CallRejectionReason? reason}) async {
    final invitation = _currentState.currentInvitation;
    if (invitation == null || invitation.callId != callId) {
      throw CallException('No active invitation to reject');
    }

    // Send rejection via WebSocket using the service interface
    _webSocketService.emit('reject_call', {
      'callId': callId,
      'reason': reason?.toString() ?? 'user_declined',
    });

    // Update state
    _currentState = _currentState.copyWith(currentInvitation: null);
    _callStateController.add(_currentState);

    // Cancel timeout
    _cancelCallTimeout(callId);

    debugPrint('Rejected call: $callId, reason: $reason');
  }

  /// Cancel an outgoing call
  Future<void> cancelCall(String callId) async {
    final invitation = _currentState.outgoingInvitation;
    if (invitation == null || invitation.callId != callId) {
      throw CallException('No active outgoing call to cancel');
    }

    // Send cancellation via WebSocket using the service interface
    _webSocketService.emit('cancel_call', {'callId': callId});

    // Update state
    _currentState = _currentState.copyWith(outgoingInvitation: null);
    _callStateController.add(_currentState);

    // Cancel timeout
    _cancelCallTimeout(callId);

    debugPrint('Cancelled call: $callId');
  }

  /// Mark call as ended (user hung up)
  Future<void> endCall(String callId) async {
    // Update state
    _currentState = _currentState.copyWith(
      isInCall: false,
      currentInvitation: null,
      outgoingInvitation: null,
    );
    _callStateController.add(_currentState);

    debugPrint('Ended call: $callId');
  }

  /// Set user availability for receiving calls
  void setAvailability(bool isAvailable) {
    _currentState = _currentState.copyWith(isAvailable: isAvailable);
    _callStateController.add(_currentState);
    debugPrint('User availability set to: $isAvailable');
  }

  /// Get current call state
  CallState get currentState => _currentState;

  /// Handle incoming call from WebSocket
  void _handleIncomingCall(dynamic data) {
    try {
      final invitation = CallInvitation.fromJson(data as Map<String, dynamic>);

      // Prevent duplicate call handling
      // If we already have this call invitation active, skip it
      // This prevents duplicate call screens when both WebSocket and FCM deliver the same call
      if (_currentState.currentInvitation?.callId == invitation.callId) {
        debugPrint(
          '⏭️ Call ${invitation.callId} already active, skipping duplicate WebSocket event',
        );
        return;
      }

      // Check if user can receive calls
      if (!_currentState.canReceiveCalls) {
        // Auto-reject with busy status
        rejectCall(invitation.callId, reason: CallRejectionReason.busy);
        return;
      }

      // Update state
      _currentState = _currentState.copyWith(currentInvitation: invitation);
      _callStateController.add(_currentState);

      // Emit to listeners
      _incomingCallController.add(invitation);

      // Set timeout
      _setCallTimeout(invitation.callId);

      debugPrint(
        'Received incoming call: ${invitation.callId} from ${invitation.callerName}',
      );
    } catch (e) {
      debugPrint('Error handling incoming call: $e');
    }
  }

  /// Handle call accepted from WebSocket
  void _handleCallAccepted(dynamic data) {
    try {
      final callId = data['callId'] as String;
      final invitation = _currentState.outgoingInvitation;

      if (invitation != null && invitation.callId == callId) {
        final acceptedInvitation = invitation.copyWith(
          status: CallInvitationStatus.accepted,
        );

        _currentState = _currentState.copyWith(
          isInCall: true,
          outgoingInvitation: acceptedInvitation,
        );
        _callStateController.add(_currentState);

        _callAcceptedController.add(acceptedInvitation);
        _cancelCallTimeout(callId);

        debugPrint('Call accepted: $callId');
      }
    } catch (e) {
      debugPrint('Error handling call accepted: $e');
    }
  }

  /// Handle call rejected from WebSocket
  void _handleCallRejected(dynamic data) {
    try {
      final callId = data['callId'] as String;
      final reason = data['reason'] as String?;
      final invitation = _currentState.outgoingInvitation;

      if (invitation != null && invitation.callId == callId) {
        final rejectedInvitation = invitation.copyWith(
          status: CallInvitationStatus.rejected,
        );

        _currentState = _currentState.copyWith(outgoingInvitation: null);
        _callStateController.add(_currentState);

        _callRejectedController.add(rejectedInvitation);
        _cancelCallTimeout(callId);

        debugPrint('Call rejected: $callId, reason: $reason');
      }
    } catch (e) {
      debugPrint('Error handling call rejected: $e');
    }
  }

  /// Handle call timeout from WebSocket or local timeout
  void _handleCallTimeout(dynamic data) {
    try {
      final callId = data is String ? data : data['callId'] as String;
      final invitation =
          _currentState.currentInvitation ?? _currentState.outgoingInvitation;

      if (invitation != null && invitation.callId == callId) {
        final timeoutInvitation = invitation.copyWith(
          status: CallInvitationStatus.timeout,
        );

        // Add to missed calls if it was incoming
        final missedCalls = _currentState.currentInvitation != null
            ? [..._currentState.missedCalls, timeoutInvitation]
            : _currentState.missedCalls;

        _currentState = _currentState.copyWith(
          currentInvitation: null,
          outgoingInvitation: null,
          missedCalls: missedCalls,
        );
        _callStateController.add(_currentState);

        _callTimeoutController.add(timeoutInvitation);
        _cancelCallTimeout(callId);

        debugPrint('Call timeout: $callId');
      }
    } catch (e) {
      debugPrint('Error handling call timeout: $e');
    }
  }

  /// Handle call cancelled from WebSocket
  void _handleCallCancelled(dynamic data) {
    try {
      final callId = data['callId'] as String;
      final invitation = _currentState.currentInvitation;

      if (invitation != null && invitation.callId == callId) {
        _currentState = _currentState.copyWith(currentInvitation: null);
        _callStateController.add(_currentState);

        _callCancelledController.add(invitation);
        _cancelCallTimeout(callId);

        debugPrint('Call cancelled: $callId');
      }
    } catch (e) {
      debugPrint('Error handling call cancelled: $e');
    }
  }

  /// Set timeout for a call invitation
  void _setCallTimeout(String callId) {
    _callTimeouts[callId] = Timer(const Duration(seconds: 30), () {
      _handleCallTimeout(callId);
    });
  }

  /// Cancel timeout for a call invitation
  void _cancelCallTimeout(String callId) {
    _callTimeouts[callId]?.cancel();
    _callTimeouts.remove(callId);
  }

  /// NEW: Handle call ready to connect event from backend
  /// This means both users have accepted and should now join Agora
  void _handleReadyToConnect(dynamic data) {
    try {
      final callId = data['callId'] as String;
      final channelName = data['channelName'] as String?;
      final token = data['token'] as String?;
      final uid = data['uid'] as int?; // ✅ Extract UID from backend event

      debugPrint('Call ready to connect: $callId (UID: $uid)');

      // Emit connection status event
      _connectionStatusController.add({
        'event': 'ready_to_connect',
        'callId': callId,
        'channelName': channelName,
        'token': token,
        'uid': uid, // ✅ Pass UID to AudioCallScreen
        'status': CallConnectionStatus.connecting,
      });
    } catch (e) {
      debugPrint('Error handling call ready to connect: $e');
    }
  }

  /// NEW: Handle call connected event from backend
  /// This means both users are in the Agora channel
  void _handleCallConnected(dynamic data) {
    try {
      final callId = data['callId'] as String;

      debugPrint('Call connected: $callId');

      // Emit connection status event
      _connectionStatusController.add({
        'event': 'connected',
        'callId': callId,
        'status': CallConnectionStatus.connected,
      });
    } catch (e) {
      debugPrint('Error handling call connected: $e');
    }
  }

  /// NEW: Handle call failed event from backend
  /// User is offline, unreachable, or network error
  void _handleCallFailed(dynamic data) {
    try {
      final callId = data['callId'] as String;
      final reason = data['reason'] as String?;

      debugPrint('Call failed: $callId, reason: $reason');

      // Emit connection status event
      _connectionStatusController.add({
        'event': 'failed',
        'callId': callId,
        'reason': reason,
        'status': CallConnectionStatus.failed,
      });

      // Update state to clear invitation
      _currentState = _currentState.copyWith(
        currentInvitation: null,
        outgoingInvitation: null,
      );
      _callStateController.add(_currentState);
    } catch (e) {
      debugPrint('Error handling call failed: $e');
    }
  }

  /// Clear missed calls
  void clearMissedCalls() {
    _currentState = _currentState.copyWith(missedCalls: []);
    _callStateController.add(_currentState);
  }

  /// Dispose the service
  void dispose() {
    _incomingCallController.close();
    _callAcceptedController.close();
    _callRejectedController.close();
    _callTimeoutController.close();
    _callCancelledController.close();
    _callStateController.close();
    _connectionStatusController.close(); // NEW: Close connection status stream

    for (final timer in _callTimeouts.values) {
      timer.cancel();
    }
    _callTimeouts.clear();
  }
}

/// Exception thrown by call invitation operations
class CallException implements Exception {
  final String message;
  CallException(this.message);

  @override
  String toString() => 'CallException: $message';
}
