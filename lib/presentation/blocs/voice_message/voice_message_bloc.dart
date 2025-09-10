import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import '../../../data/models/voice_message.dart';
import '../../../data/services/voice_message_service.dart';
import 'voice_message_event.dart';
import 'voice_message_state.dart';

class VoiceMessageBloc extends Bloc<VoiceMessageEvent, VoiceMessageState> {
  final VoiceMessageService _voiceMessageService;
  final Logger _logger = Logger();
  Timer? _recordingTimer;
  Timer? _playbackTimer;

  VoiceMessageBloc(this._voiceMessageService) : super(const VoiceMessageState()) {
    on<RecordVoiceMessage>(_onRecordVoiceMessage);
    on<StopRecording>(_onStopRecording);
    on<SendVoiceMessage>(_onSendVoiceMessage);
    on<PlayVoiceMessage>(_onPlayVoiceMessage);
    on<PauseVoiceMessage>(_onPauseVoiceMessage);
    on<StopPlayback>(_onStopPlayback);
    on<LoadVoiceMessages>(_onLoadVoiceMessages);
    on<DeleteVoiceMessage>(_onDeleteVoiceMessage);
    on<CancelRecording>(_onCancelRecording);
    on<SeekToPosition>(_onSeekToPosition);
  }

  Future<void> _onRecordVoiceMessage(
    RecordVoiceMessage event,
    Emitter<VoiceMessageState> emit,
  ) async {
    try {
      emit(state.copyWith(status: VoiceMessageStatus.loading));

      // Check and request microphone permission
      final hasPermission = await _voiceMessageService.checkMicrophonePermission();
      if (!hasPermission) {
        emit(state.copyWith(
          status: VoiceMessageStatus.error,
          errorMessage: 'Microphone permission is required to record voice messages',
          hasPermission: false,
        ));
        return;
      }

      // Start recording
      final recordingSession = await _voiceMessageService.startRecording();
      if (recordingSession != null) {
        emit(state.copyWith(
          status: VoiceMessageStatus.recording,
          isRecording: true,
          recordingPath: recordingSession.filePath,
          recordingDuration: 0.0,
          hasPermission: true,
        ));

        // Start timer to update recording duration
        _recordingTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
          if (state.isRecording) {
            emit(state.copyWith(
              recordingDuration: state.recordingDuration + 0.1,
            ));
          }
        });
      } else {
        emit(state.copyWith(
          status: VoiceMessageStatus.error,
          errorMessage: 'Failed to start recording',
        ));
      }
    } catch (e) {
      _logger.e('Error starting voice recording: $e');
      emit(state.copyWith(
        status: VoiceMessageStatus.error,
        errorMessage: 'Failed to start recording: $e',
      ));
    }
  }

  Future<void> _onStopRecording(
    StopRecording event,
    Emitter<VoiceMessageState> emit,
  ) async {
    try {
      if (!state.isRecording) return;

      _recordingTimer?.cancel();
      
      final recordingSession = await _voiceMessageService.stopRecording();
      if (recordingSession != null) {
        emit(state.copyWith(
          status: VoiceMessageStatus.recorded,
          isRecording: false,
          recordingPath: recordingSession.filePath,
          recordingDuration: recordingSession.duration.toDouble(),
        ));
      } else {
        emit(state.copyWith(
          status: VoiceMessageStatus.error,
          errorMessage: 'Failed to stop recording',
          isRecording: false,
        ));
      }
    } catch (e) {
      _logger.e('Error stopping voice recording: $e');
      emit(state.copyWith(
        status: VoiceMessageStatus.error,
        errorMessage: 'Failed to stop recording: $e',
        isRecording: false,
      ));
    }
  }

  Future<void> _onSendVoiceMessage(
    SendVoiceMessage event,
    Emitter<VoiceMessageState> emit,
  ) async {
    try {
      emit(state.copyWith(status: VoiceMessageStatus.sending));

      final voiceMessage = await _voiceMessageService.sendVoiceMessage(
        conversationId: event.chatId,
        filePath: event.audioPath,
        duration: event.durationMs,
      );

      if (voiceMessage != null) {
        emit(state.copyWith(
          status: VoiceMessageStatus.sent,
          recordingPath: null,
          recordingDuration: 0.0,
        ));
        
        // Reload messages to show the new voice message
        add(LoadVoiceMessages(chatId: event.chatId));
      } else {
        emit(state.copyWith(
          status: VoiceMessageStatus.error,
          errorMessage: 'Failed to send voice message',
        ));
      }
    } catch (e) {
      _logger.e('Error sending voice message: $e');
      emit(state.copyWith(
        status: VoiceMessageStatus.error,
        errorMessage: 'Failed to send voice message: $e',
      ));
    }
  }

  Future<void> _onPlayVoiceMessage(
    PlayVoiceMessage event,
    Emitter<VoiceMessageState> emit,
  ) async {
    try {
      // Stop any current playback
      if (state.playbackState == PlaybackState.playing) {
        await _voiceMessageService.stopPlayback();
        _playbackTimer?.cancel();
      }

      emit(state.copyWith(
        playbackState: PlaybackState.loading,
        currentlyPlayingId: event.messageId,
        playbackPosition: 0.0,
      ));

      // Find the voice message from the current messages
      VoiceMessage? voiceMessage;
      try {
        voiceMessage = state.messages.firstWhere(
          (msg) => msg.id == event.messageId,
        );
      } catch (e) {
        voiceMessage = VoiceMessage(
          id: event.messageId,
          conversationId: '',
          senderId: '',
          audioUrl: event.audioPath,
          duration: 0,
          waveformData: const [],
          createdAt: DateTime.now(),
          isPlayed: false,
        );
      }

      final success = await _voiceMessageService.playVoiceMessage(voiceMessage);
      if (success) {
        emit(state.copyWith(
          playbackState: PlaybackState.playing,
        ));

        // Start timer to update playback position
        _playbackTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
          if (state.playbackState == PlaybackState.playing) {
            // Note: In a real implementation, you'd get the actual position from the audio player
            emit(state.copyWith(
              playbackPosition: state.playbackPosition + 0.1,
            ));
          }
        });
      } else {
        emit(state.copyWith(
          playbackState: PlaybackState.idle,
          currentlyPlayingId: null,
          errorMessage: 'Failed to play voice message',
        ));
      }
    } catch (e) {
      _logger.e('Error playing voice message: $e');
      emit(state.copyWith(
        playbackState: PlaybackState.idle,
        currentlyPlayingId: null,
        errorMessage: 'Failed to play voice message: $e',
      ));
    }
  }

  Future<void> _onPauseVoiceMessage(
    PauseVoiceMessage event,
    Emitter<VoiceMessageState> emit,
  ) async {
    try {
      await _voiceMessageService.pausePlayback();
      _playbackTimer?.cancel();
      
      emit(state.copyWith(
        playbackState: PlaybackState.paused,
      ));
    } catch (e) {
      _logger.e('Error pausing voice message: $e');
      emit(state.copyWith(
        errorMessage: 'Failed to pause voice message: $e',
      ));
    }
  }

  Future<void> _onStopPlayback(
    StopPlayback event,
    Emitter<VoiceMessageState> emit,
  ) async {
    try {
      await _voiceMessageService.stopPlayback();
      _playbackTimer?.cancel();
      
      emit(state.copyWith(
        playbackState: PlaybackState.idle,
        currentlyPlayingId: null,
        playbackPosition: 0.0,
      ));
    } catch (e) {
      _logger.e('Error stopping voice message playback: $e');
      emit(state.copyWith(
        errorMessage: 'Failed to stop playback: $e',
      ));
    }
  }

  Future<void> _onLoadVoiceMessages(
    LoadVoiceMessages event,
    Emitter<VoiceMessageState> emit,
  ) async {
    try {
      emit(state.copyWith(status: VoiceMessageStatus.loading));

      final messages = await _voiceMessageService.getVoiceMessages(event.chatId);
      
      emit(state.copyWith(
        status: VoiceMessageStatus.loaded,
        messages: messages,
      ));
    } catch (e) {
      _logger.e('Error loading voice messages: $e');
      emit(state.copyWith(
        status: VoiceMessageStatus.error,
        errorMessage: 'Failed to load voice messages: $e',
      ));
    }
  }

  Future<void> _onDeleteVoiceMessage(
    DeleteVoiceMessage event,
    Emitter<VoiceMessageState> emit,
  ) async {
    try {
      // For now, just remove from local state as the service doesn't have delete method
      final updatedMessages = state.messages
          .where((message) => message.id != event.messageId)
          .toList();
      
      emit(state.copyWith(
        messages: updatedMessages,
      ));
      
      _logger.d('Voice message removed from local state: ${event.messageId}');
    } catch (e) {
      _logger.e('Error deleting voice message: $e');
      emit(state.copyWith(
        errorMessage: 'Failed to delete voice message: $e',
      ));
    }
  }

  Future<void> _onCancelRecording(
    CancelRecording event,
    Emitter<VoiceMessageState> emit,
  ) async {
    try {
      _recordingTimer?.cancel();
      await _voiceMessageService.cancelRecording();
      
      emit(state.copyWith(
        status: VoiceMessageStatus.initial,
        isRecording: false,
        recordingPath: null,
        recordingDuration: 0.0,
      ));
    } catch (e) {
      _logger.e('Error cancelling recording: $e');
      emit(state.copyWith(
        status: VoiceMessageStatus.error,
        errorMessage: 'Failed to cancel recording: $e',
        isRecording: false,
      ));
    }
  }

  Future<void> _onSeekToPosition(
    SeekToPosition event,
    Emitter<VoiceMessageState> emit,
  ) async {
    try {
      if (state.currentlyPlayingId != null) {
        // For now, just update the position in state since service doesn't have seekTo
        emit(state.copyWith(
          playbackPosition: event.position,
        ));
        
        _logger.d('Seeked to position: ${event.position}');
      }
    } catch (e) {
      _logger.e('Error seeking to position: $e');
      emit(state.copyWith(
        errorMessage: 'Failed to seek to position: $e',
      ));
    }
  }

  @override
  Future<void> close() {
    _recordingTimer?.cancel();
    _playbackTimer?.cancel();
    return super.close();
  }
}
