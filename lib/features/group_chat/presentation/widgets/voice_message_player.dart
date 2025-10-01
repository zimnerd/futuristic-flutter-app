import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class VoiceMessagePlayer extends StatefulWidget {
  final String audioUrl;
  final int duration;
  final bool isMe;

  const VoiceMessagePlayer({
    super.key,
    required this.audioUrl,
    required this.duration,
    this.isMe = false,
  });

  @override
  State<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<VoiceMessagePlayer> {
  final _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _initPlayer() async {
    try {
      // Listen to player state
      _audioPlayer.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
            if (state.processingState == ProcessingState.completed) {
              _currentPosition = Duration.zero;
              _isPlaying = false;
            }
          });
        }
      });

      // Listen to position
      _audioPlayer.positionStream.listen((position) {
        if (mounted) {
          setState(() {
            _currentPosition = position;
          });
        }
      });
    } catch (e) {
      debugPrint('Error initializing player: $e');
    }
  }

  Future<void> _togglePlayback() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        setState(() {
          _isLoading = true;
        });

        if (_audioPlayer.processingState == ProcessingState.idle) {
          await _audioPlayer.setUrl(widget.audioUrl);
        }

        await _audioPlayer.play();

        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to play audio: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalDuration = Duration(seconds: widget.duration);
    final progress = totalDuration.inMilliseconds > 0
        ? _currentPosition.inMilliseconds / totalDuration.inMilliseconds
        : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/pause button
          GestureDetector(
            onTap: _togglePlayback,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: widget.isMe
                    ? Colors.white.withOpacity(0.3)
                    : Theme.of(context).primaryColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: _isLoading
                  ? Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          widget.isMe ? Colors.white : Theme.of(context).primaryColor,
                        ),
                      ),
                    )
                  : Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: widget.isMe
                          ? Colors.white
                          : Theme.of(context).primaryColor,
                      size: 20,
                    ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Waveform and progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Waveform visualization
                SizedBox(
                  height: 30,
                  child: CustomPaint(
                    painter: WaveformPainter(
                      progress: progress,
                      color: widget.isMe ? Colors.white : Colors.black87,
                      isPlaying: _isPlaying,
                    ),
                    size: const Size(double.infinity, 30),
                  ),
                ),
                
                const SizedBox(height: 4),
                
                // Duration text
                Text(
                  _isPlaying
                      ? '${_formatDuration(_currentPosition)} / ${_formatDuration(totalDuration)}'
                      : _formatDuration(totalDuration),
                  style: TextStyle(
                    fontSize: 10,
                    color: widget.isMe ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class WaveformPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isPlaying;

  WaveformPainter({
    required this.progress,
    required this.color,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    final barCount = 30;
    final barWidth = 2.0;
    final spacing = (size.width - (barCount * barWidth)) / (barCount - 1);

    for (int i = 0; i < barCount; i++) {
      final x = i * (barWidth + spacing);
      final normalizedHeight = (i % 3 == 0) ? 0.8 : (i % 2 == 0) ? 0.6 : 0.4;
      final barHeight = size.height * normalizedHeight;
      final y = (size.height - barHeight) / 2;

      final barProgress = i / barCount;
      final isPast = barProgress <= progress;

      paint.color = isPast
          ? color
          : color.withOpacity(0.3);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, barHeight),
          const Radius.circular(1),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isPlaying != isPlaying;
  }
}
