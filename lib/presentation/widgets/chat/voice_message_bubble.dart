import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';

import '../../theme/pulse_colors.dart';

/// Compact voice message bubble for chat
class VoiceMessageBubble extends StatefulWidget {
  final String audioUrl;
  final int duration;
  final List<double> waveformData;
  final bool isCurrentUser;

  const VoiceMessageBubble({
    super.key,
    required this.audioUrl,
    required this.duration,
    required this.waveformData,
    required this.isCurrentUser,
  });

  @override
  State<VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble>
    with TickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  
  late AnimationController _waveController;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerStateSubscription;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    _initAnimations();
  }

  void _initAnimations() {
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
  }

  Future<void> _initializePlayer() async {
    setState(() => _isLoading = true);
    
    try {
      await _audioPlayer.setFilePath(widget.audioUrl);
      _totalDuration = _audioPlayer.duration ?? Duration(seconds: widget.duration);
      
      _positionSubscription = _audioPlayer.positionStream.listen((position) {
        setState(() => _currentPosition = position);
      });

      _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
        setState(() {
          _isPlaying = state.playing;
          _isLoading = state.processingState == ProcessingState.loading;
        });

        if (state.playing) {
          _waveController.repeat();
        } else {
          _waveController.stop();
        }
      });
      
    } catch (e) {
      // Handle error silently for better UX
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _waveController.dispose();
    _positionSubscription?.cancel();
    _playerStateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _playPause() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play();
      }
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/pause button
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: widget.isCurrentUser 
                  ? Colors.white.withValues(alpha: 0.2)
                  : PulseColors.primary,
              shape: BoxShape.circle,
            ),
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.isCurrentUser ? Colors.white : Colors.white,
                      ),
                    ),
                  )
                : IconButton(
                    icon: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      size: 20,
                    ),
                    color: widget.isCurrentUser ? Colors.white : Colors.white,
                    onPressed: _playPause,
                    padding: EdgeInsets.zero,
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
                  height: 24,
                  child: AnimatedBuilder(
                    animation: _waveController,
                    builder: (context, child) {
                      return Row(
                        children: widget.waveformData.take(20).map((amplitude) {
                          final height = 4 + (amplitude * 16);
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            width: 2,
                            height: height * (_isPlaying ? (0.7 + _waveController.value * 0.3) : 1.0),
                            decoration: BoxDecoration(
                              color: widget.isCurrentUser 
                                  ? Colors.white.withValues(alpha: 0.8)
                                  : PulseColors.primary.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 4),
                
                // Duration
                Text(
                  _formatDuration(_isPlaying ? _currentPosition : _totalDuration),
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.isCurrentUser 
                        ? Colors.white.withValues(alpha: 0.8)
                        : Colors.grey[600],
                    fontWeight: FontWeight.w500,
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
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}