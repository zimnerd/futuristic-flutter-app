import 'package:flutter/material.dart';

import '../../theme/theme_extensions.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';

import '../../../data/models/voice_message.dart';
import '../../theme/pulse_colors.dart';

/// Widget for playing voice messages with advanced controls
class VoiceMessagePlayerWidget extends StatefulWidget {
  final VoiceMessage message;
  final VoidCallback onClose;

  const VoiceMessagePlayerWidget({
    super.key,
    required this.message,
    required this.onClose,
  });

  @override
  State<VoiceMessagePlayerWidget> createState() => _VoiceMessagePlayerWidgetState();
}

class _VoiceMessagePlayerWidgetState extends State<VoiceMessagePlayerWidget>
    with TickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  double _playbackSpeed = 1.0;
  
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
      await _audioPlayer.setFilePath(widget.message.audioUrl);
      _totalDuration = _audioPlayer.duration ?? Duration(seconds: widget.message.duration);
      
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
      _showError('Failed to load audio: $e');
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
      _showError('Playback error: $e');
    }
  }

  Future<void> _stop() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.seek(Duration.zero);
    } catch (e) {
      _showError('Stop error: $e');
    }
  }

  Future<void> _seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      _showError('Seek error: $e');
    }
  }

  Future<void> _setSpeed(double speed) async {
    try {
      await _audioPlayer.setSpeed(speed);
      setState(() => _playbackSpeed = speed);
    } catch (e) {
      _showError('Speed change error: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: context.errorColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            PulseColors.primary.withValues(alpha: 0.1),
            PulseColors.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildWaveformVisualizer(),
          _buildProgressSlider(),
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: widget.message.senderAvatarUrl != null
                ? NetworkImage(widget.message.senderAvatarUrl!)
                : null,
            child: widget.message.senderAvatarUrl == null
                ? const Icon(Icons.person)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.message.senderName ?? 'Unknown',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _formatDate(widget.message.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.onSurfaceVariantColor,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: widget.onClose,
            icon: const Icon(Icons.close),
            color: Colors.grey[600],
          ),
        ],
      ),
    );
  }

  Widget _buildWaveformVisualizer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 60,
        child: AnimatedBuilder(
          animation: _waveController,
          builder: (context, child) {
            return Row(
              children: widget.message.waveformData.asMap().entries.map((entry) {
                final index = entry.key;
                final amplitude = entry.value;
                final progress = _currentPosition.inMilliseconds / _totalDuration.inMilliseconds;
                final isPlayed = (index / widget.message.waveformData.length) <= progress;
                
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    height: amplitude * 60,
                    decoration: BoxDecoration(
                      color: isPlayed 
                          ? context.primaryColor
                          : context.outlineColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProgressSlider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: Slider(
              value: _totalDuration.inMilliseconds > 0
                  ? _currentPosition.inMilliseconds / _totalDuration.inMilliseconds
                  : 0.0,
              onChanged: (value) {
                final position = Duration(
                  milliseconds: (value * _totalDuration.inMilliseconds).round(),
                );
                _seek(position);
              },
              activeColor: context.primaryColor,
              inactiveColor: context.outlineColor,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(_currentPosition),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  _formatDuration(_totalDuration),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Speed control
          _buildSpeedButton(),
          
          // Rewind 10s
          IconButton(
            onPressed: () {
              final newPosition = _currentPosition - const Duration(seconds: 10);
              _seek(newPosition < Duration.zero ? Duration.zero : newPosition);
            },
            icon: const Icon(Icons.replay_10),
            iconSize: 32,
            color: Colors.grey[700],
          ),
          
          // Play/Pause
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.primaryColor,
              boxShadow: [
                BoxShadow(
                  color: PulseColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: IconButton(
              onPressed: _isLoading ? null : _playPause,
              icon: _isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          context.onPrimaryColor,
                        ),
                      ),
                    )
                  : Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
              iconSize: 32,
              color: context.onPrimaryColor,
            ),
          ),
          
          // Forward 10s
          IconButton(
            onPressed: () {
              final newPosition = _currentPosition + const Duration(seconds: 10);
              _seek(newPosition > _totalDuration ? _totalDuration : newPosition);
            },
            icon: const Icon(Icons.forward_10),
            iconSize: 32,
            color: context.onSurfaceVariantColor,
          ),
          
          // Stop
          IconButton(
            onPressed: _stop,
            icon: const Icon(Icons.stop),
            iconSize: 32,
            color: context.onSurfaceVariantColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedButton() {
    return PopupMenuButton<double>(
      onSelected: _setSpeed,
      itemBuilder: (context) => [
        const PopupMenuItem(value: 0.5, child: Text('0.5x')),
        const PopupMenuItem(value: 0.75, child: Text('0.75x')),
        const PopupMenuItem(value: 1.0, child: Text('1x')),
        const PopupMenuItem(value: 1.25, child: Text('1.25x')),
        const PopupMenuItem(value: 1.5, child: Text('1.5x')),
        const PopupMenuItem(value: 2.0, child: Text('2x')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: context.outlineColor),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '${_playbackSpeed}x',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
