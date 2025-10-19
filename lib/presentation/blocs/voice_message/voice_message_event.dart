import 'package:equatable/equatable.dart';

abstract class VoiceMessageEvent extends Equatable {
  const VoiceMessageEvent();

  @override
  List<Object?> get props => [];
}

class RecordVoiceMessage extends VoiceMessageEvent {
  const RecordVoiceMessage();
}

class StopRecording extends VoiceMessageEvent {
  const StopRecording();
}

class SendVoiceMessage extends VoiceMessageEvent {
  final String chatId;
  final String audioPath;
  final int durationMs;

  const SendVoiceMessage({
    required this.chatId,
    required this.audioPath,
    required this.durationMs,
  });

  @override
  List<Object?> get props => [chatId, audioPath, durationMs];
}

class PlayVoiceMessage extends VoiceMessageEvent {
  final String messageId;
  final String audioPath;

  const PlayVoiceMessage({required this.messageId, required this.audioPath});

  @override
  List<Object?> get props => [messageId, audioPath];
}

class PauseVoiceMessage extends VoiceMessageEvent {
  const PauseVoiceMessage();
}

class StopPlayback extends VoiceMessageEvent {
  const StopPlayback();
}

class LoadVoiceMessages extends VoiceMessageEvent {
  final String chatId;

  const LoadVoiceMessages({required this.chatId});

  @override
  List<Object?> get props => [chatId];
}

class DeleteVoiceMessage extends VoiceMessageEvent {
  final String messageId;

  const DeleteVoiceMessage({required this.messageId});

  @override
  List<Object?> get props => [messageId];
}

class CancelRecording extends VoiceMessageEvent {
  const CancelRecording();
}

class SeekToPosition extends VoiceMessageEvent {
  final double position;

  const SeekToPosition({required this.position});

  @override
  List<Object?> get props => [position];
}
