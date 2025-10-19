import 'package:equatable/equatable.dart';
import '../../../data/models/voice_message.dart';

enum VoiceMessageStatus {
  initial,
  recording,
  recordingPaused,
  recorded,
  sending,
  sent,
  playing,
  paused,
  stopped,
  loading,
  loaded,
  error,
}

enum PlaybackState { idle, playing, paused, loading, buffering }

class VoiceMessageState extends Equatable {
  final VoiceMessageStatus status;
  final List<VoiceMessage> messages;
  final VoiceMessage? currentMessage;
  final PlaybackState playbackState;
  final String? currentlyPlayingId;
  final double playbackPosition;
  final double recordingDuration;
  final String? recordingPath;
  final String? errorMessage;
  final bool isRecording;
  final bool hasPermission;
  final double? currentVolume;

  const VoiceMessageState({
    this.status = VoiceMessageStatus.initial,
    this.messages = const [],
    this.currentMessage,
    this.playbackState = PlaybackState.idle,
    this.currentlyPlayingId,
    this.playbackPosition = 0.0,
    this.recordingDuration = 0.0,
    this.recordingPath,
    this.errorMessage,
    this.isRecording = false,
    this.hasPermission = false,
    this.currentVolume,
  });

  VoiceMessageState copyWith({
    VoiceMessageStatus? status,
    List<VoiceMessage>? messages,
    VoiceMessage? currentMessage,
    PlaybackState? playbackState,
    String? currentlyPlayingId,
    double? playbackPosition,
    double? recordingDuration,
    String? recordingPath,
    String? errorMessage,
    bool? isRecording,
    bool? hasPermission,
    double? currentVolume,
  }) {
    return VoiceMessageState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      currentMessage: currentMessage ?? this.currentMessage,
      playbackState: playbackState ?? this.playbackState,
      currentlyPlayingId: currentlyPlayingId ?? this.currentlyPlayingId,
      playbackPosition: playbackPosition ?? this.playbackPosition,
      recordingDuration: recordingDuration ?? this.recordingDuration,
      recordingPath: recordingPath ?? this.recordingPath,
      errorMessage: errorMessage ?? this.errorMessage,
      isRecording: isRecording ?? this.isRecording,
      hasPermission: hasPermission ?? this.hasPermission,
      currentVolume: currentVolume ?? this.currentVolume,
    );
  }

  @override
  List<Object?> get props => [
    status,
    messages,
    currentMessage,
    playbackState,
    currentlyPlayingId,
    playbackPosition,
    recordingDuration,
    recordingPath,
    errorMessage,
    isRecording,
    hasPermission,
    currentVolume,
  ];
}
