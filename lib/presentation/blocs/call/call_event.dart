part of 'call_bloc.dart';

/// Events for call management
abstract class CallEvent extends Equatable {
  const CallEvent();

  @override
  List<Object?> get props => [];
}

/// Event to initiate an outgoing call
class InitiateCall extends CallEvent {
  final String recipientId;
  final CallType type;

  const InitiateCall({
    required this.recipientId,
    required this.type,
  });

  @override
  List<Object> get props => [recipientId, type];
}

/// Event to accept an incoming call
class AcceptCall extends CallEvent {
  final String callId;

  const AcceptCall({required this.callId});

  @override
  List<Object> get props => [callId];
}

/// Event to decline an incoming call
class DeclineCall extends CallEvent {
  final String callId;

  const DeclineCall({required this.callId});

  @override
  List<Object> get props => [callId];
}

/// Event to end the current call
class EndCall extends CallEvent {
  final String callId;

  const EndCall({required this.callId});

  @override
  List<Object> get props => [callId];
}

/// Event to toggle video on/off
class ToggleVideo extends CallEvent {
  final bool enabled;

  const ToggleVideo({required this.enabled});

  @override
  List<Object> get props => [enabled];
}

/// Event to toggle audio on/off
class ToggleAudio extends CallEvent {
  final bool enabled;

  const ToggleAudio({required this.enabled});

  @override
  List<Object> get props => [enabled];
}

/// Event to toggle speaker on/off
class ToggleSpeaker extends CallEvent {
  final bool enabled;

  const ToggleSpeaker({required this.enabled});

  @override
  List<Object> get props => [enabled];
}

/// Event to switch camera (front/back)
class SwitchCamera extends CallEvent {
  const SwitchCamera();
}

/// Event when call connection state changes
class CallConnectionChanged extends CallEvent {
  final CallConnectionState connectionState;

  const CallConnectionChanged({required this.connectionState});

  @override
  List<Object> get props => [connectionState];
}

/// Event when call quality changes
class CallQualityChanged extends CallEvent {
  final CallQuality quality;

  const CallQualityChanged({required this.quality});

  @override
  List<Object> get props => [quality];
}

/// Event when receiving an incoming call
class IncomingCallReceived extends CallEvent {
  final Call call;

  const IncomingCallReceived({required this.call});

  @override
  List<Object> get props => [call];
}

/// Event to update call duration
class UpdateCallDuration extends CallEvent {
  final Duration duration;

  const UpdateCallDuration({required this.duration});

  @override
  List<Object> get props => [duration];
}

/// Event when WebRTC peer connection is established
class WebRTCConnected extends CallEvent {
  final String callId;

  const WebRTCConnected({required this.callId});

  @override
  List<Object> get props => [callId];
}

/// Event when WebRTC peer connection is lost
class WebRTCDisconnected extends CallEvent {
  final String callId;

  const WebRTCDisconnected({required this.callId});

  @override
  List<Object> get props => [callId];
}

/// Event when WebRTC signaling data is received
class WebRTCSignalingReceived extends CallEvent {
  final Map<String, dynamic> signalingData;

  const WebRTCSignalingReceived({required this.signalingData});

  @override
  List<Object> get props => [signalingData];
}

/// Event to send WebRTC signaling data
class SendWebRTCSignaling extends CallEvent {
  final String callId;
  final Map<String, dynamic> signalingData;

  const SendWebRTCSignaling({
    required this.callId,
    required this.signalingData,
  });

  @override
  List<Object> get props => [callId, signalingData];
}

/// Event to reset call state
class ResetCallState extends CallEvent {
  const ResetCallState();
}
