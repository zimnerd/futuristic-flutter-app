import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'dart:async';
import 'dart:io';

import '../../../data/models/voice_message.dart';
import '../../theme/pulse_colors.dart';
import '../common/pulse_toast.dart';

/// Compact voice recorder widget for chat input
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

class _CompactVoiceRecorderState extends State<CompactVoiceRecorder>
    with TickerProviderStateMixin {
  final AudioRecorder _recorder = AudioRecorder();

  bool _isRecording = false;
  bool _isPaused = false;
  Duration _recordedDuration = Duration.zero;
  Timer? _recordingTimer;

  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;

  String? _currentRecordingPath;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startRecording();
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _pulseController.dispose();
    _waveController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        final path =
            '/tmp/voice_message_${DateTime.now().millisecondsSinceEpoch}.m4a';
        _currentRecordingPath = path;

        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: path,
        );

        setState(() {
          _isRecording = true;
          _isPaused = false;
          _recordedDuration = Duration.zero;
        });

        _startTimer();
        _pulseController.repeat(reverse: true);
        _waveController.repeat();
      }
    } catch (e) {
      _showError('Failed to start recording: $e');
    }
  }

  Future<void> _pauseRecording() async {
    try {
      await _recorder.pause();
      setState(() => _isPaused = true);
      _recordingTimer?.cancel();
      _pulseController.stop();
      _waveController.stop();
    } catch (e) {
      _showError('Failed to pause recording: $e');
    }
  }

  Future<void> _resumeRecording() async {
    try {
      await _recorder.resume();
      setState(() => _isPaused = false);
      _startTimer();
      _pulseController.repeat(reverse: true);
      _waveController.repeat();
    } catch (e) {
      _showError('Failed to resume recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _recorder.stop();

      _recordingTimer?.cancel();
      _pulseController.stop();
      _waveController.stop();

      setState(() {
        _isRecording = false;
        _isPaused = false;
      });

      if (path != null && _recordedDuration.inSeconds > 0) {
        final file = File(path);
        if (await file.exists()) {
          // Generate simple waveform data
          final waveformData = List.generate(
            50,
            (index) => 0.3 + (index % 3) * 0.2 + (index % 7) * 0.1,
          );

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

  void _cancelRecording() async {
    try {
      await _recorder.stop();
      _recordingTimer?.cancel();
      _pulseController.stop();
      _waveController.stop();

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
    PulseToast.error(context, message: message);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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

          // Recording visualizer and timer
          Row(
            children: [
              // Pulsing record button
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isRecording && !_isPaused
                        ? _pulseAnimation.value
                        : 1.0,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isRecording
                            ? (_isPaused ? Colors.orange : Colors.red)
                            : PulseColors.primary,
                        boxShadow: _isRecording && !_isPaused
                            ? [
                                BoxShadow(
                                  color: Colors.red.withValues(alpha: 0.3),
                                  blurRadius: 15,
                                  spreadRadius: 3,
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        _isRecording
                            ? (_isPaused ? Icons.pause : Icons.mic)
                            : Icons.mic_none,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(width: 16),

              // Duration and waveform
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDuration(_recordedDuration),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _isRecording ? Colors.red : PulseColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Simple waveform visualization
                    AnimatedBuilder(
                      animation: _waveController,
                      builder: (context, child) {
                        return Row(
                          children: List.generate(15, (index) {
                            final height = _isRecording && !_isPaused
                                ? 2 +
                                      (index % 4) * 3 +
                                      (_waveController.value * 8)
                                : 2.0;
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              width: 3,
                              height: height,
                              decoration: BoxDecoration(
                                color: PulseColors.primary.withValues(
                                  alpha: 0.6,
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            );
                          }),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
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
          const SizedBox(height: 8),
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
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: onPressed != null ? color : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon),
            color: Colors.white,
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: onPressed != null ? color : Colors.grey[500],
            fontWeight: FontWeight.w500,
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
