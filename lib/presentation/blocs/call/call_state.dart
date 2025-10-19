part of 'call_bloc.dart';

/// State class for call management
class CallState extends Equatable {
  const CallState({
    this.status = CallStatus.idle,
    this.currentCall,
    this.isVideoEnabled = true,
    this.isAudioEnabled = true,
    this.isSpeakerEnabled = false,
    this.connectionState = CallConnectionState.disconnected,
    this.quality = CallQuality.good,
    this.duration = Duration.zero,
    this.error,
    this.incomingCall,
    this.isScreenSharing = false,
    this.isFrontCamera = true,
    this.reconnectionAttempts = 0,
    this.maxReconnectionAttempts = 3,
  });

  final CallStatus status;
  final Call? currentCall;
  final bool isVideoEnabled;
  final bool isAudioEnabled;
  final bool isSpeakerEnabled;
  final CallConnectionState connectionState;
  final CallQuality quality;
  final Duration duration;
  final String? error;
  final Call? incomingCall;
  final bool isScreenSharing;
  final bool isFrontCamera;
  final int reconnectionAttempts;
  final int maxReconnectionAttempts;

  /// Check if currently in a call
  bool get isInCall => [
    CallStatus.outgoing,
    CallStatus.incoming,
    CallStatus.connecting,
    CallStatus.connected,
  ].contains(status);

  /// Check if call is active (connected)
  bool get isCallActive => status == CallStatus.connected;

  /// Check if call is connecting
  bool get isConnecting => status == CallStatus.connecting;

  /// Check if there's an incoming call waiting
  bool get hasIncomingCall =>
      incomingCall != null && status == CallStatus.incoming;

  /// Check if reconnection is possible
  bool get canReconnect => reconnectionAttempts < maxReconnectionAttempts;

  /// Get formatted call duration
  String get formattedDuration {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
  }

  /// Get call quality description
  String get qualityDescription {
    switch (quality) {
      case CallQuality.poor:
        return 'Poor connection';
      case CallQuality.fair:
        return 'Fair connection';
      case CallQuality.good:
        return 'Good connection';
      case CallQuality.excellent:
        return 'Excellent connection';
    }
  }

  /// Get connection state description
  String get connectionDescription {
    switch (connectionState) {
      case CallConnectionState.disconnected:
        return 'Disconnected';
      case CallConnectionState.connecting:
        return 'Connecting...';
      case CallConnectionState.connected:
        return 'Connected';
      case CallConnectionState.reconnecting:
        return 'Reconnecting...';
      case CallConnectionState.failed:
        return 'Connection failed';
    }
  }

  @override
  List<Object?> get props => [
    status,
    currentCall,
    isVideoEnabled,
    isAudioEnabled,
    isSpeakerEnabled,
    connectionState,
    quality,
    duration,
    error,
    incomingCall,
    isScreenSharing,
    isFrontCamera,
    reconnectionAttempts,
    maxReconnectionAttempts,
  ];

  CallState copyWith({
    CallStatus? status,
    Call? currentCall,
    bool? isVideoEnabled,
    bool? isAudioEnabled,
    bool? isSpeakerEnabled,
    CallConnectionState? connectionState,
    CallQuality? quality,
    Duration? duration,
    String? error,
    Call? incomingCall,
    bool? isScreenSharing,
    bool? isFrontCamera,
    int? reconnectionAttempts,
    int? maxReconnectionAttempts,
    bool clearError = false,
    bool clearIncomingCall = false,
    bool clearCurrentCall = false,
  }) {
    return CallState(
      status: status ?? this.status,
      currentCall: clearCurrentCall ? null : (currentCall ?? this.currentCall),
      isVideoEnabled: isVideoEnabled ?? this.isVideoEnabled,
      isAudioEnabled: isAudioEnabled ?? this.isAudioEnabled,
      isSpeakerEnabled: isSpeakerEnabled ?? this.isSpeakerEnabled,
      connectionState: connectionState ?? this.connectionState,
      quality: quality ?? this.quality,
      duration: duration ?? this.duration,
      error: clearError ? null : (error ?? this.error),
      incomingCall: clearIncomingCall
          ? null
          : (incomingCall ?? this.incomingCall),
      isScreenSharing: isScreenSharing ?? this.isScreenSharing,
      isFrontCamera: isFrontCamera ?? this.isFrontCamera,
      reconnectionAttempts: reconnectionAttempts ?? this.reconnectionAttempts,
      maxReconnectionAttempts:
          maxReconnectionAttempts ?? this.maxReconnectionAttempts,
    );
  }
}
