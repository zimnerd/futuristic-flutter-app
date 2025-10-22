import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';

import '../../theme/pulse_colors.dart';

/// Compact voice message bubble for chat with enhanced playback controls
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
  double _playbackSpeed = 1.0;

  late AnimationController _waveController;
  late AnimationController _speedChangeController;
  late Animation<double> _speedChangeAnimation;
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

    _speedChangeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _speedChangeAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _speedChangeController, curve: Curves.easeOut),
    );
  }

  Future<void> _initializePlayer() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Check if audioUrl is a network URL or local file path
      if (widget.audioUrl.startsWith('http://') ||
          widget.audioUrl.startsWith('https://')) {
        // Network audio
        await _audioPlayer.setUrl(widget.audioUrl);
      } else {
        // Local file
        await _audioPlayer.setFilePath(widget.audioUrl);
      }

      _totalDuration =
          _audioPlayer.duration ?? Duration(seconds: widget.duration);

      _positionSubscription = _audioPlayer.positionStream.listen((position) {
        if (mounted) {
          setState(() => _currentPosition = position);
        }
      });

      _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
            _isLoading = state.processingState == ProcessingState.loading;
          });

          if (state.playing) {
            _waveController.repeat();
          } else {
            _waveController.stop();
          }
        }
      });
    } catch (e) {
      // Handle error silently for better UX
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    // Cancel subscriptions first to stop incoming events
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _playerStateSubscription?.cancel();
    _playerStateSubscription = null;

    // Stop and dispose audio player
    _audioPlayer.stop();
    _audioPlayer.dispose();
    
    // Dispose animation controllers
    _waveController.dispose();
    _speedChangeController.dispose();
    
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

  Future<void> _cyclePlaybackSpeed() async {
    try {
      // Cycle through speeds: 1.0x → 1.5x → 2.0x → 1.0x
      double newSpeed;
      if (_playbackSpeed == 1.0) {
        newSpeed = 1.5;
      } else if (_playbackSpeed == 1.5) {
        newSpeed = 2.0;
      } else {
        newSpeed = 1.0;
      }

      await _audioPlayer.setSpeed(newSpeed);
      if (mounted) {
        setState(() => _playbackSpeed = newSpeed);
      }

      // Haptic feedback
      HapticFeedback.selectionClick();

      // Animate speed change
      _speedChangeController.forward(from: 0);
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _seekToPosition(double position) async {
    try {
      final seekPosition = Duration(
        milliseconds: (position * _totalDuration.inMilliseconds).toInt(),
      );
      await _audioPlayer.seek(seekPosition);

      // Haptic feedback
      HapticFeedback.lightImpact();
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _totalDuration.inMilliseconds > 0
        ? _currentPosition.inMilliseconds / _totalDuration.inMilliseconds
        : 0.0;

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
                // Interactive Waveform visualization with progress
                GestureDetector(
                  onTapDown: (details) {
                    final RenderBox box =
                        context.findRenderObject() as RenderBox;
                    final localPosition = box.globalToLocal(
                      details.globalPosition,
                    );
                    final waveformWidth =
                        box.size.width - 60; // Subtract button + spacing
                    final relativePosition =
                        (localPosition.dx - 44) / waveformWidth;
                    _seekToPosition(relativePosition.clamp(0.0, 1.0));
                  },
                  child: SizedBox(
                    height: 28,
                    child: AnimatedBuilder(
                      animation: _waveController,
                      builder: (context, child) {
                        return Row(
                          children: List.generate(
                            widget.waveformData.length.clamp(0, 40),
                            (index) {
                              final amplitude =
                                  index < widget.waveformData.length
                                  ? widget.waveformData[index]
                                  : 0.2;
                              final height = 4 + (amplitude * 20);
                              final barProgress =
                                  index / widget.waveformData.length;
                              final isPlayed = barProgress <= progress;

                              return Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 0.5,
                                ),
                                width: 2,
                                height:
                                    height *
                                    (_isPlaying
                                        ? (0.7 + _waveController.value * 0.3)
                                        : 1.0),
                                decoration: BoxDecoration(
                                  color: isPlayed
                                      ? (widget.isCurrentUser
                                            ? Colors.white
                                            : PulseColors.primary)
                                      : (widget.isCurrentUser
                                            ? Colors.white.withValues(
                                                alpha: 0.4,
                                              )
                                            : PulseColors.primary.withValues(
                                                alpha: 0.3,
                                              )),
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                // Duration and playback speed
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(
                        _isPlaying ? _currentPosition : _totalDuration,
                      ),
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
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Playback speed button
          GestureDetector(
            onTap: _cyclePlaybackSpeed,
            child: AnimatedBuilder(
              animation: _speedChangeAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _speedChangeAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: widget.isCurrentUser
                          ? Colors.white.withValues(alpha: 0.2)
                          : PulseColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_playbackSpeed}x',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: widget.isCurrentUser
                            ? Colors.white
                            : PulseColors.primary,
                      ),
                    ),
                  ),
                );
              },
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
