import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'dart:async';
import 'dart:io';

import '../../../data/models/voice_message.dart';
import '../../theme/pulse_colors.dart';

/// Widget for recording voice messages
class VoiceRecorderWidget extends StatefulWidget {
  final Function(VoiceMessage) onMessageRecorded;
  final Duration maxDuration;

  const VoiceRecorderWidget({
    super.key,
    required this.onMessageRecorded,
    this.maxDuration = const Duration(minutes: 2),
  });

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget>
    with TickerProviderStateMixin {
  final AudioRecorder _recorder = AudioRecorder();
  
  bool _isRecording = false;
  bool _isPaused = false;
  Duration _recordedDuration = Duration.zero;
  Timer? _recordingTimer;
  
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
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

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ),
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
        final path = '/tmp/voice_message_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
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
            // Generate simple waveform data (in a real app, you'd analyze the audio)
            final waveformData = List.generate(50, (index) => 
              0.3 + (index % 3) * 0.2 + (index % 7) * 0.1);
              
            final message = VoiceMessage(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              conversationId: 'temp_conversation', // Will be set when sending
              senderId: 'current_user', // Replace with actual user ID
              audioUrl: path, // Local file path for now
              duration: _recordedDuration.inSeconds,
              waveformData: waveformData,
              createdAt: DateTime.now(),
            );
            
            widget.onMessageRecorded(message);
          }
      }

      setState(() {
        _recordedDuration = Duration.zero;
      });
    } catch (e) {
      _showError('Failed to stop recording: $e');
    }
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildRecordingVisualizer(),
            const SizedBox(height: 24),
            _buildDurationDisplay(),
            const SizedBox(height: 24),
            _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingVisualizer() {
    return SizedBox(
      height: 120,
      child: Center(
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _isRecording && !_isPaused ? _pulseAnimation.value : 1.0,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isRecording 
                      ? (_isPaused ? Colors.orange : Colors.red)
                      : PulseColors.primary,
                  boxShadow: _isRecording && !_isPaused
                      ? [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  _isRecording 
                      ? (_isPaused ? Icons.pause : Icons.mic)
                      : Icons.mic_none,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDurationDisplay() {
    return Column(
      children: [
        Text(
          _formatDuration(_recordedDuration),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: _isRecording ? Colors.red : null,
          ),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: _recordedDuration.inMilliseconds / widget.maxDuration.inMilliseconds,
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
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildControls() {
    if (!_isRecording) {
      return ElevatedButton.icon(
        onPressed: _startRecording,
        icon: const Icon(Icons.mic),
        label: const Text('Start Recording'),
        style: ElevatedButton.styleFrom(
          backgroundColor: PulseColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Pause/Resume Button
        ElevatedButton.icon(
          onPressed: _isPaused ? _resumeRecording : _pauseRecording,
          icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
          label: Text(_isPaused ? 'Resume' : 'Pause'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        
        // Stop Button
        ElevatedButton.icon(
          onPressed: _stopRecording,
          icon: const Icon(Icons.stop),
          label: const Text('Finish'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
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
