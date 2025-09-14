import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/call.dart';
import '../../../data/services/websocket_service.dart';
import '../auth/auth_bloc.dart';
import '../auth/auth_state.dart';

part 'call_event.dart';
part 'call_state.dart';

/// BLoC for managing call state and WebRTC operations
class CallBloc extends Bloc<CallEvent, CallState> {
  final WebSocketService _webSocketService;
  final AuthBloc _authBloc;
  Timer? _callTimer;
  Timer? _reconnectionTimer;

  CallBloc({
    required WebSocketService webSocketService,
    required AuthBloc authBloc,
  })  : _webSocketService = webSocketService,
       _authBloc = authBloc,
        super(const CallState()) {
    
    // Register event handlers
    on<InitiateCall>(_onInitiateCall);
    on<AcceptCall>(_onAcceptCall);
    on<DeclineCall>(_onDeclineCall);
    on<EndCall>(_onEndCall);
    on<ToggleVideo>(_onToggleVideo);
    on<ToggleAudio>(_onToggleAudio);
    on<ToggleSpeaker>(_onToggleSpeaker);
    on<SwitchCamera>(_onSwitchCamera);
    on<CallConnectionChanged>(_onCallConnectionChanged);
    on<CallQualityChanged>(_onCallQualityChanged);
    on<IncomingCallReceived>(_onIncomingCallReceived);
    on<UpdateCallDuration>(_onUpdateCallDuration);
    on<WebRTCConnected>(_onWebRTCConnected);
    on<WebRTCDisconnected>(_onWebRTCDisconnected);
    on<WebRTCSignalingReceived>(_onWebRTCSignalingReceived);
    on<SendWebRTCSignaling>(_onSendWebRTCSignaling);
    on<ResetCallState>(_onResetCallState);

    // Listen to WebSocket events for real-time call updates
    _setupWebSocketListeners();
  }

  /// Gets the current user ID from the AuthBloc state
  String? get _currentUserId {
    final authState = _authBloc.state;
    if (authState is AuthAuthenticated) {
      return authState.user.id;
    }
    return null;
  }

  /// Setup WebSocket listeners for real-time call events
  void _setupWebSocketListeners() {
    _webSocketService.onCallReceived = (callId) {
      // When receiving a call, we need to fetch call details
      // For now, create a mock call - in production this would fetch from API
      final call = Call(
        id: callId,
        callerId: 'unknown_caller', // This should be fetched from server
        recipientId: _currentUserId ?? 'fallback-user-id',
        type: CallType.video, // Default, should be in the event data
        status: CallStatus.incoming,
        createdAt: DateTime.now(),
      );
      add(IncomingCallReceived(call: call));
    };

    _webSocketService.onCallEnded = (callId) {
      add(const EndCall(callId: ''));
    };
  }

  /// Handle initiating an outgoing call
  Future<void> _onInitiateCall(InitiateCall event, Emitter<CallState> emit) async {
    try {
      emit(state.copyWith(
        status: CallStatus.outgoing,
        clearError: true,
      ));

      // Create new call
      final call = Call(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        callerId: _currentUserId ?? 'fallback-user-id',
        recipientId: event.recipientId,
        type: event.type,
        status: CallStatus.outgoing,
        createdAt: DateTime.now(),
      );

      emit(state.copyWith(currentCall: call));

      // Send call initiation through WebSocket
      _webSocketService.initiateCall(event.recipientId, event.type.name);

      // Start connection timeout
      _startConnectionTimeout(call.id);

    } catch (error) {
      emit(state.copyWith(
        status: CallStatus.failed,
        error: 'Failed to initiate call: $error',
      ));
    }
  }

  /// Handle accepting an incoming call
  Future<void> _onAcceptCall(AcceptCall event, Emitter<CallState> emit) async {
    try {
      if (state.incomingCall != null) {
        final updatedCall = state.incomingCall!.copyWith(
          status: CallStatus.connecting,
          startedAt: DateTime.now(),
        );

        emit(state.copyWith(
          status: CallStatus.connecting,
          currentCall: updatedCall,
          clearIncomingCall: true,
          clearError: true,
        ));

        // Send acceptance through WebSocket
        _webSocketService.acceptCall(event.callId);

        // Start call timer
        _startCallTimer();
      }
    } catch (error) {
      emit(state.copyWith(
        status: CallStatus.failed,
        error: 'Failed to accept call: $error',
      ));
    }
  }

  /// Handle declining an incoming call
  Future<void> _onDeclineCall(DeclineCall event, Emitter<CallState> emit) async {
    try {
      // Send decline through WebSocket
      _webSocketService.rejectCall(event.callId);

      emit(state.copyWith(
        status: CallStatus.idle,
        clearIncomingCall: true,
        clearCurrentCall: true,
        clearError: true,
      ));
    } catch (error) {
      emit(state.copyWith(
        error: 'Failed to decline call: $error',
      ));
    }
  }

  /// Handle ending the current call
  Future<void> _onEndCall(EndCall event, Emitter<CallState> emit) async {
    try {
      // Stop timers
      _callTimer?.cancel();
      _reconnectionTimer?.cancel();

      if (state.currentCall != null) {
        // Send end call through WebSocket
        _webSocketService.endCall(state.currentCall!.id);
      }

      emit(state.copyWith(
        status: CallStatus.idle,
        clearCurrentCall: true,
        clearIncomingCall: true,
        clearError: true,
        duration: Duration.zero,
        connectionState: CallConnectionState.disconnected,
        reconnectionAttempts: 0,
      ));
    } catch (error) {
      emit(state.copyWith(
        error: 'Failed to end call: $error',
      ));
    }
  }

  /// Handle toggling video
  Future<void> _onToggleVideo(ToggleVideo event, Emitter<CallState> emit) async {
    emit(state.copyWith(isVideoEnabled: event.enabled));
    
    // TODO: Add WebSocket video toggle support to WebSocketService
    // For now, just update local state
  }

  /// Handle toggling audio
  Future<void> _onToggleAudio(ToggleAudio event, Emitter<CallState> emit) async {
    emit(state.copyWith(isAudioEnabled: event.enabled));
    
    // TODO: Add WebSocket audio toggle support to WebSocketService
    // For now, just update local state
  }

  /// Handle toggling speaker
  Future<void> _onToggleSpeaker(ToggleSpeaker event, Emitter<CallState> emit) async {
    emit(state.copyWith(isSpeakerEnabled: event.enabled));
  }

  /// Handle switching camera
  Future<void> _onSwitchCamera(SwitchCamera event, Emitter<CallState> emit) async {
    emit(state.copyWith(isFrontCamera: !state.isFrontCamera));
    
    // TODO: Add WebSocket camera switch support to WebSocketService
    // For now, just update local state
  }

  /// Handle connection state changes
  Future<void> _onCallConnectionChanged(
    CallConnectionChanged event,
    Emitter<CallState> emit,
  ) async {
    emit(state.copyWith(connectionState: event.connectionState));

    // Handle reconnection logic
    if (event.connectionState == CallConnectionState.failed && state.canReconnect) {
      _startReconnectionAttempt(emit);
    } else if (event.connectionState == CallConnectionState.connected) {
      emit(state.copyWith(
        status: CallStatus.connected,
        reconnectionAttempts: 0,
      ));
      
      if (!_isCallTimerRunning()) {
        _startCallTimer();
      }
    }
  }

  /// Handle call quality changes
  Future<void> _onCallQualityChanged(
    CallQualityChanged event,
    Emitter<CallState> emit,
  ) async {
    emit(state.copyWith(quality: event.quality));
  }

  /// Handle incoming call received
  Future<void> _onIncomingCallReceived(
    IncomingCallReceived event,
    Emitter<CallState> emit,
  ) async {
    // Only accept incoming call if not already in a call
    if (!state.isInCall) {
      emit(state.copyWith(
        status: CallStatus.incoming,
        incomingCall: event.call,
        clearError: true,
      ));
    } else {
      // Decline the incoming call if already in a call
      _webSocketService.rejectCall(event.call.id);
    }
  }

  /// Handle call duration updates
  Future<void> _onUpdateCallDuration(
    UpdateCallDuration event,
    Emitter<CallState> emit,
  ) async {
    emit(state.copyWith(duration: event.duration));
  }

  /// Handle WebRTC connection established
  Future<void> _onWebRTCConnected(
    WebRTCConnected event,
    Emitter<CallState> emit,
  ) async {
    add(const CallConnectionChanged(connectionState: CallConnectionState.connected));
  }

  /// Handle WebRTC connection lost
  Future<void> _onWebRTCDisconnected(
    WebRTCDisconnected event,
    Emitter<CallState> emit,
  ) async {
    add(const CallConnectionChanged(connectionState: CallConnectionState.failed));
  }

  /// Handle WebRTC signaling data received
  Future<void> _onWebRTCSignalingReceived(
    WebRTCSignalingReceived event,
    Emitter<CallState> emit,
  ) async {
    // Process WebRTC signaling data
    // This would integrate with the actual WebRTC implementation
    // For now, just emit connection state change
    add(const CallConnectionChanged(connectionState: CallConnectionState.connecting));
  }

  /// Handle sending WebRTC signaling data
  Future<void> _onSendWebRTCSignaling(
    SendWebRTCSignaling event,
    Emitter<CallState> emit,
  ) async {
    // TODO: Add WebRTC signaling support to WebSocketService
    // For now, this is a placeholder for future WebRTC integration
  }

  /// Handle resetting call state
  Future<void> _onResetCallState(
    ResetCallState event,
    Emitter<CallState> emit,
  ) async {
    _callTimer?.cancel();
    _reconnectionTimer?.cancel();

    emit(const CallState());
  }

  /// Start call timer for duration tracking
  void _startCallTimer() {
    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      add(UpdateCallDuration(duration: Duration(seconds: timer.tick)));
    });
  }

  /// Check if call timer is running
  bool _isCallTimerRunning() {
    return _callTimer?.isActive ?? false;
  }

  /// Start connection timeout
  void _startConnectionTimeout(String callId) {
    Timer(const Duration(seconds: 30), () {
      if (state.status == CallStatus.outgoing) {
        add(const EndCall(callId: ''));
      }
    });
  }

  /// Start reconnection attempt
  void _startReconnectionAttempt(Emitter<CallState> emit) {
    if (!state.canReconnect) return;

    emit(state.copyWith(
      connectionState: CallConnectionState.reconnecting,
      reconnectionAttempts: state.reconnectionAttempts + 1,
    ));

    _reconnectionTimer = Timer(const Duration(seconds: 3), () {
      // Attempt to reconnect
      add(const CallConnectionChanged(connectionState: CallConnectionState.connecting));
    });
  }

  @override
  Future<void> close() {
    _callTimer?.cancel();
    _reconnectionTimer?.cancel();
    return super.close();
  }
}
