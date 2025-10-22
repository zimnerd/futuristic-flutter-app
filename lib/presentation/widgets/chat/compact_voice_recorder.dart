import 'package:flutter/material.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../../../data/models/voice_message.dart';
import '../../theme/pulse_colors.dart';
import '../common/pulse_toast.dart';

/// Compact voice recorder widget for chat input with live waveform
class CompactVoiceRecorder extends StatefulWidget {
  final Function(VoiceMessage) onMessageRecorded;
  final VoidCallback onCancel;
  final Duration maxDuration;

  const CompactVoiceRecorder({
    super.key,
    required this.onMessageRecorded,
    required this.onCancel,
    this.maxDuration = const Duration(minutes: 2),
  });

  @override
  State<CompactVoiceRecorder> createState() => _CompactVoiceRecorderState();
}

class _CompactVoiceRecorderState extends State<CompactVoiceRecorder> {
  late RecorderController _recorderController;

  bool _isRecording = false;
  bool _isPaused = false;
  Duration _recordedDuration = Duration.zero;
  Timer? _recordingTimer;

  String? _currentRecordingPath;

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    // Initialize recorder controller
    _recorderController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate = 44100;

    await _startRecording();
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _recorderController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      // Get temporary directory for recording
      final directory = await getTemporaryDirectory();
      final path =
          '${directory.path}/voice_message_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _currentRecordingPath = path;

      // Check permissions and start recording
      await _recorderController.record(path: path);

      setState(() {
        _isRecording = true;
        _isPaused = false;
        _recordedDuration = Duration.zero;
      });

      _startTimer();
    } catch (e) {
      _showError('Failed to start recording: $e');
      widget.onCancel();
    }
  }

  Future<void> _pauseRecording() async {
    try {
      await _recorderController.pause();
      setState(() => _isPaused = true);
      _recordingTimer?.cancel();
    } catch (e) {
      _showError('Failed to pause recording: $e');
    }
  }

  Future<void> _resumeRecording() async {
    try {
      await _recorderController.record();
      setState(() => _isPaused = false);
      _startTimer();
    } catch (e) {
      _showError('Failed to resume recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _recorderController.stop();

      _recordingTimer?.cancel();

      setState(() {
        _isRecording = false;
        _isPaused = false;
      });

      if (path != null && _recordedDuration.inSeconds > 0) {
        final file = File(path);
        if (await file.exists()) {
          // Extract real waveform data from the recorded audio
          final waveformData = await _extractWaveformData(path);

          final message = VoiceMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            conversationId: 'temp_conversation',
            senderId: 'current_user',
            audioUrl: path,
            duration: _recordedDuration.inSeconds,
            waveformData: waveformData,
            createdAt: DateTime.now(),
          );

          widget.onMessageRecorded(message);
        }
      } else {
        widget.onCancel();
      }
    } catch (e) {
      _showError('Failed to stop recording: $e');
      widget.onCancel();
    }
  }

  /// Extract waveform data from recorded audio
  Future<List<double>> _extractWaveformData(String audioPath) async {
    try {
      // Initialize a player controller to extract waveform
      final playerController = PlayerController();
      await playerController.preparePlayer(
        path: audioPath,
        shouldExtractWaveform: true,
      );

      // Get waveform data (normalized to 0.0-1.0 range)
      final waveform = playerController.waveformData;
      playerController.dispose();

      if (waveform.isNotEmpty) {
        return waveform;
      }
    } catch (e) {
      // If waveform extraction fails, generate placeholder
      debugPrint('Failed to extract waveform: $e');
    }

    // Fallback: generate simple waveform data
    return List.generate(
      50,
      (index) => 0.3 + (index % 3) * 0.2 + (index % 7) * 0.1,
    );
  }

  void _cancelRecording() async {
    try {
      await _recorderController.stop();
      _recordingTimer?.cancel();

      // Delete the recording file
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      // Ignore cleanup errors
    }

    widget.onCancel();
  }

  void _startTimer() {
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordedDuration = Duration(seconds: _recordedDuration.inSeconds + 1);
      });

      if (_recordedDuration >= widget.maxDuration) {
        _stopRecording();
      }
    });
  }

  void _showError(String message) {
    if (mounted) {
      PulseToast.error(context, message: message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.mic, color: PulseColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Recording Voice Message',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: PulseColors.primary,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: _cancelRecording,
                color: Colors.grey[600],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Live Waveform Visualization
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AudioWaveforms(
              recorderController: _recorderController,
              size: Size(MediaQuery.of(context).size.width - 80, 80),
              waveStyle: WaveStyle(
                waveColor: _isRecording
                    ? (_isPaused ? Colors.orange : PulseColors.primary)
                    : Colors.grey,
                showDurationLabel: false,
                spacing: 4,
                extendWaveform: true,
                showMiddleLine: false,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Duration Display
          Text(
            _formatDuration(_recordedDuration),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _isRecording
                  ? (_isPaused ? Colors.orange : PulseColors.primary)
                  : Colors.grey,
            ),
          ),

          const SizedBox(height: 20),

          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Delete/Cancel
              _buildControlButton(
                icon: Icons.delete,
                label: 'Cancel',
                color: Colors.red,
                onPressed: _cancelRecording,
              ),

              // Pause/Resume
              if (_isRecording)
                _buildControlButton(
                  icon: _isPaused ? Icons.play_arrow : Icons.pause,
                  label: _isPaused ? 'Resume' : 'Pause',
                  color: Colors.orange,
                  onPressed: _isPaused ? _resumeRecording : _pauseRecording,
                ),

              // Send
              _buildControlButton(
                icon: Icons.send,
                label: 'Send',
                color: PulseColors.primary,
                onPressed: _recordedDuration.inSeconds > 0
                    ? _stopRecording
                    : null,
              ),
            ],
          ),

          // Max duration indicator
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value:
                _recordedDuration.inMilliseconds /
                widget.maxDuration.inMilliseconds,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              _recordedDuration.inSeconds > (widget.maxDuration.inSeconds * 0.8)
                  ? Colors.red
                  : PulseColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Max: ${_formatDuration(widget.maxDuration)}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onPressed,
  }) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: onPressed != null ? color : Colors.grey[300],
            shape: BoxShape.circle,
            boxShadow: onPressed != null
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: IconButton(
            icon: Icon(icon, size: 24),
            color: Colors.white,
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: onPressed != null ? color : Colors.grey[500],
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
