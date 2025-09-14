import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:logger/logger.dart';

import '../data/models/call_model.dart';
import '../data/services/webrtc_service.dart';
import '../data/services/websocket_service.dart';
import '../presentation/blocs/auth/auth_bloc.dart';
import '../presentation/blocs/auth/auth_state.dart';

// Events
abstract class CallEvent extends Equatable {
  const CallEvent();

  @override
  List<Object?> get props => [];
}

class InitiateCall extends CallEvent {
  final String receiverId;
  final String receiverName;
  final String? receiverAvatar;
  final CallType callType;

  const InitiateCall({
    required this.receiverId,
    required this.receiverName,
    this.receiverAvatar,
    required this.callType,
  });

  @override
  List<Object?> get props => [receiverId, receiverName, receiverAvatar, callType];
}

class AnswerCall extends CallEvent {
  const AnswerCall();
}

class EndCall extends CallEvent {
  const EndCall();
}

class DeclineCall extends CallEvent {
  const DeclineCall();
}

class ToggleMute extends CallEvent {
  const ToggleMute();
}

class ToggleCamera extends CallEvent {
  const ToggleCamera();
}

class SwitchCamera extends CallEvent {
  const SwitchCamera();
}

class ToggleSpeaker extends CallEvent {
  const ToggleSpeaker();
}

class CallSignalReceived extends CallEvent {
  final CallSignalModel signal;

  const CallSignalReceived({required this.signal});

  @override
  List<Object?> get props => [signal];
}

// States
abstract class CallState extends Equatable {
  const CallState();

  @override
  List<Object?> get props => [];
}

class CallInitial extends CallState {
  const CallInitial();
}

class CallConnecting extends CallState {
  final CallModel call;

  const CallConnecting({required this.call});

  @override
  List<Object?> get props => [call];
}

class CallRinging extends CallState {
  final CallModel call;

  const CallRinging({required this.call});

  @override
  List<Object?> get props => [call];
}

class CallInProgress extends CallState {
  final CallModel call;
  final bool isMuted;
  final bool isVideoEnabled;
  final bool isSpeakerOn;
  final List<int> remoteUsers;

  const CallInProgress({
    required this.call,
    required this.isMuted,
    required this.isVideoEnabled,
    required this.isSpeakerOn,
    required this.remoteUsers,
  });

  @override
  List<Object?> get props => [call, isMuted, isVideoEnabled, isSpeakerOn, remoteUsers];

  CallInProgress copyWith({
    CallModel? call,
    bool? isMuted,
    bool? isVideoEnabled,
    bool? isSpeakerOn,
    List<int>? remoteUsers,
  }) {
    return CallInProgress(
      call: call ?? this.call,
      isMuted: isMuted ?? this.isMuted,
      isVideoEnabled: isVideoEnabled ?? this.isVideoEnabled,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
      remoteUsers: remoteUsers ?? this.remoteUsers,
    );
  }
}

class CallEnded extends CallState {
  final CallModel? call;
  final String? reason;

  const CallEnded({this.call, this.reason});

  @override
  List<Object?> get props => [call, reason];
}

class CallError extends CallState {
  final String message;

  const CallError({required this.message});

  @override
  List<Object?> get props => [message];
}

// BLoC
class CallBloc extends Bloc<CallEvent, CallState> {
  final WebRTCService _webRTCService;
  final WebSocketService _webSocketService;
  final Logger _logger = Logger();

  CallBloc({
    required WebRTCService webRTCService,
    required WebSocketService webSocketService,
  })  : _webRTCService = webRTCService,
        _webSocketService = webSocketService,
        super(const CallInitial()) {
    on<InitiateCall>(_onInitiateCall);
    on<AnswerCall>(_onAnswerCall);
    on<EndCall>(_onEndCall);
    on<DeclineCall>(_onDeclineCall);
    on<ToggleMute>(_onToggleMute);
    on<ToggleCamera>(_onToggleCamera);
    on<SwitchCamera>(_onSwitchCamera);
    on<ToggleSpeaker>(_onToggleSpeaker);
    on<CallSignalReceived>(_onCallSignalReceived);

    // Listen to WebSocket call signals
    _webSocketService.onCallSignalReceived = (signal) {
      add(CallSignalReceived(signal: signal));
    };
  }

  Future<void> _onInitiateCall(
    InitiateCall event,
    Emitter<CallState> emit,
  ) async {
    try {
      // Generate unique channel name for this call
      final channelName = 'call_${DateTime.now().millisecondsSinceEpoch}';
      final token = ''; // Token will be provided by Agora when needed
      final currentUserId = 'user_${DateTime.now().millisecondsSinceEpoch}'; // Generate unique ID
      final currentUserName = 'Current User'; // Default name for now

      emit(CallConnecting(
        call: CallModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          callerId: currentUserId,
          callerName: currentUserName,
          receiverId: event.receiverId,
          receiverName: event.receiverName,
          receiverAvatar: event.receiverAvatar,
          type: event.callType,
          status: CallStatus.initiating,
          channelName: channelName,
          token: token,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ));

      await _webRTCService.startCall(
        receiverId: event.receiverId,
        receiverName: event.receiverName,
        receiverAvatar: event.receiverAvatar,
        callType: event.callType,
        channelName: channelName,
        token: token,
      );

      _logger.i('Call initiated to ${event.receiverName}');
    } catch (e) {
      _logger.e('Failed to initiate call: $e');
      emit(CallError(message: 'Failed to start call: $e'));
    }
  }

  Future<void> _onAnswerCall(
    AnswerCall event,
    Emitter<CallState> emit,
  ) async {
    try {
      if (state is! CallRinging) return;

      final call = (state as CallRinging).call;
      
      // Use the token provided in the call model
      await _webRTCService.answerCall(
        channelName: call.channelName!,
        token: call.token!,
      );

      _logger.i('Call answered');
    } catch (e) {
      _logger.e('Failed to answer call: $e');
      emit(CallError(message: 'Failed to answer call: $e'));
    }
  }

  Future<void> _onEndCall(
    EndCall event,
    Emitter<CallState> emit,
  ) async {
    try {
      await _webRTCService.endCall();
      emit(const CallEnded());
      _logger.i('Call ended');
    } catch (e) {
      _logger.e('Error ending call: $e');
      emit(CallError(message: 'Error ending call: $e'));
    }
  }

  Future<void> _onDeclineCall(
    DeclineCall event,
    Emitter<CallState> emit,
  ) async {
    try {
      await _webRTCService.declineCall();
      emit(const CallEnded(reason: 'declined'));
      _logger.i('Call declined');
    } catch (e) {
      _logger.e('Error declining call: $e');
      emit(CallError(message: 'Error declining call: $e'));
    }
  }

  Future<void> _onToggleMute(
    ToggleMute event,
    Emitter<CallState> emit,
  ) async {
    try {
      await _webRTCService.toggleMute();
      _logger.i('Toggled mute');
    } catch (e) {
      _logger.e('Error toggling mute: $e');
    }
  }

  Future<void> _onToggleCamera(
    ToggleCamera event,
    Emitter<CallState> emit,
  ) async {
    try {
      await _webRTCService.toggleCamera();
      _logger.i('Toggled camera');
    } catch (e) {
      _logger.e('Error toggling camera: $e');
    }
  }

  Future<void> _onSwitchCamera(
    SwitchCamera event,
    Emitter<CallState> emit,
  ) async {
    try {
      await _webRTCService.switchCamera();
      _logger.i('Switched camera');
    } catch (e) {
      _logger.e('Error switching camera: $e');
    }
  }

  Future<void> _onToggleSpeaker(
    ToggleSpeaker event,
    Emitter<CallState> emit,
  ) async {
    try {
      await _webRTCService.toggleSpeaker();
      _logger.i('Toggled speaker');
    } catch (e) {
      _logger.e('Error toggling speaker: $e');
    }
  }

  Future<void> _onCallSignalReceived(
    CallSignalReceived event,
    Emitter<CallState> emit,
  ) async {
    try {
      _webRTCService.handleIncomingCallSignal(event.signal);
      _logger.i('Call signal received: ${event.signal.type}');
    } catch (e) {
      _logger.e('Error handling call signal: $e');
    }
  }
}