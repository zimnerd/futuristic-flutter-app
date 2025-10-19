import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import '../models/voice_message.dart';
import '../../core/network/api_client.dart';

/// Service for handling voice message recording, playback, and management
class VoiceMessageService {
  final ApiClient _apiClient;
  final Logger _logger = Logger();

  // Current recording session
  VoiceRecordingSession? _currentSession;
  String? _currentPlayingMessageId;

  VoiceMessageService(this._apiClient);

  /// Check and request microphone permission
  Future<bool> checkMicrophonePermission() async {
    try {
      final status = await Permission.microphone.status;
      if (status.isGranted) {
        return true;
      } else if (status.isDenied) {
        final result = await Permission.microphone.request();
        return result.isGranted;
      }
      return false;
    } catch (e) {
      _logger.e('Error checking microphone permission: $e');
      return false;
    }
  }

  /// Start recording a voice message
  Future<VoiceRecordingSession?> startRecording() async {
    try {
      // Check permission first
      final hasPermission = await checkMicrophonePermission();
      if (!hasPermission) {
        _logger.w('Microphone permission denied');
        return null;
      }

      // Stop any current recording
      if (_currentSession?.state == VoiceRecordingState.recording) {
        await stopRecording();
      }

      // Create session
      final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      _currentSession = VoiceRecordingSession(
        sessionId: sessionId,
        state: VoiceRecordingState.recording,
      );

      // Get temporary file path
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/voice_recording_$sessionId.aac';

      _currentSession = _currentSession!.copyWith(
        filePath: filePath,
        state: VoiceRecordingState.recording,
      );

      _logger.d('Voice recording started: $sessionId');
      return _currentSession;
    } catch (e) {
      _logger.e('Error starting voice recording: $e');
      _currentSession = null;
      return null;
    }
  }

  /// Stop recording and return the session
  Future<VoiceRecordingSession?> stopRecording() async {
    try {
      if (_currentSession?.state != VoiceRecordingState.recording) {
        _logger.w('No active recording to stop');
        return _currentSession;
      }

      if (_currentSession != null) {
        final path = _currentSession!.filePath;

        if (path != null) {
          final file = File(path);
          if (await file.exists()) {
            // Get file duration (simplified - would need actual audio analysis)
            final fileStat = await file.stat();
            final estimatedDuration = (fileStat.size / 16000)
                .ceil(); // Rough estimate

            _currentSession = _currentSession!.copyWith(
              state: VoiceRecordingState.finished,
              duration: estimatedDuration,
              filePath: path,
            );

            _logger.d('Voice recording stopped: ${_currentSession!.sessionId}');
            return _currentSession;
          }
        }
      }

      _logger.e('Failed to stop recording - no file created');
      return null;
    } catch (e) {
      _logger.e('Error stopping voice recording: $e');
      return null;
    }
  }

  /// Cancel current recording
  Future<void> cancelRecording() async {
    try {
      if (_currentSession?.state == VoiceRecordingState.recording) {
        // Delete the file if it exists
        if (_currentSession?.filePath != null) {
          final file = File(_currentSession!.filePath!);
          if (await file.exists()) {
            await file.delete();
          }
        }
      }

      _currentSession = null;
      _logger.d('Voice recording cancelled');
    } catch (e) {
      _logger.e('Error cancelling voice recording: $e');
    }
  }

  /// Send a voice message
  Future<VoiceMessage?> sendVoiceMessage({
    required String conversationId,
    required String filePath,
    int? duration,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        _logger.e('Voice message file does not exist: $filePath');
        return null;
      }

      // Upload the voice message file
      final response = await _apiClient.post(
        '/api/v1/voice-messages',
        data: FormData.fromMap({
          'audio': await MultipartFile.fromFile(filePath),
          'conversationId': conversationId,
          'duration': duration?.toString() ?? '0',
        }),
      );

      if (response.statusCode == 200 && response.data != null) {
        final voiceMessage = VoiceMessage.fromJson(response.data!);

        // Clean up temporary file
        await file.delete();

        _logger.d('Voice message sent successfully: ${voiceMessage.id}');
        return voiceMessage;
      } else {
        _logger.e('Failed to send voice message: ${response.statusMessage}');
        return null;
      }
    } catch (e) {
      _logger.e('Error sending voice message: $e');
      return null;
    }
  }

  /// Play a voice message - simplified implementation
  Future<bool> playVoiceMessage(VoiceMessage message) async {
    try {
      // Stop any currently playing message
      await stopPlayback();

      _currentPlayingMessageId = message.id;

      // In a real implementation, you would use just_audio or similar
      // For now, we'll just mark it as playing
      _logger.d('Playing voice message: ${message.id}');
      return true;
    } catch (e) {
      _logger.e('Error playing voice message: $e');
      _currentPlayingMessageId = null;
      return false;
    }
  }

  /// Pause voice message playback
  Future<void> pausePlayback() async {
    try {
      _logger.d('Voice message playback paused');
    } catch (e) {
      _logger.e('Error pausing voice message: $e');
    }
  }

  /// Resume voice message playback
  Future<void> resumePlayback() async {
    try {
      _logger.d('Voice message playback resumed');
    } catch (e) {
      _logger.e('Error resuming voice message: $e');
    }
  }

  /// Stop voice message playback
  Future<void> stopPlayback() async {
    try {
      _currentPlayingMessageId = null;
      _logger.d('Voice message playback stopped');
    } catch (e) {
      _logger.e('Error stopping voice message: $e');
    }
  }

  /// Mark voice message as played
  Future<bool> markAsPlayed(String messageId) async {
    try {
      final response = await _apiClient.put(
        '/api/v1/voice-messages/$messageId/play',
        data: {'isPlayed': true},
      );

      if (response.statusCode == 200) {
        _logger.d('Voice message marked as played: $messageId');
        return true;
      } else {
        _logger.e(
          'Failed to mark voice message as played: ${response.statusMessage}',
        );
        return false;
      }
    } catch (e) {
      _logger.e('Error marking voice message as played: $e');
      return false;
    }
  }

  /// Get voice messages for a conversation
  Future<List<VoiceMessage>> getVoiceMessages(String conversationId) async {
    try {
      final response = await _apiClient.get(
        '/api/v1/voice-messages/conversation/$conversationId',
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['messages'] ?? [];
        final messages = data
            .map((json) => VoiceMessage.fromJson(json))
            .toList();

        _logger.d(
          'Retrieved ${messages.length} voice messages for conversation: $conversationId',
        );
        return messages;
      } else {
        _logger.e('Failed to get voice messages: ${response.statusMessage}');
        return [];
      }
    } catch (e) {
      _logger.e('Error getting voice messages: $e');
      return [];
    }
  }

  /// Get current recording session
  VoiceRecordingSession? get currentSession => _currentSession;

  /// Get current playing message ID
  String? get currentPlayingMessageId => _currentPlayingMessageId;

  /// Check if currently recording
  bool get isRecording =>
      _currentSession?.state == VoiceRecordingState.recording;

  /// Dispose of resources
  void dispose() {
    _currentSession = null;
    _currentPlayingMessageId = null;
  }
}
