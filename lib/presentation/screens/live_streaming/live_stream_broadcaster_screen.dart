import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'dart:async';

import '../../../data/services/video_streaming_service.dart';
import '../../../data/services/live_streaming_service.dart';
import '../../../data/services/service_locator.dart';
import '../../theme/pulse_colors.dart';

/// Screen for broadcasting a live stream (host view)
class LiveStreamBroadcasterScreen extends StatefulWidget {
  final String streamId;
  final String title;
  final String description;

  const LiveStreamBroadcasterScreen({
    super.key,
    required this.streamId,
    required this.title,
    required this.description,
  });

  @override
  State<LiveStreamBroadcasterScreen> createState() =>
      _LiveStreamBroadcasterScreenState();
}

class _LiveStreamBroadcasterScreenState
    extends State<LiveStreamBroadcasterScreen> {
  final VideoStreamingService _streamingService = VideoStreamingService.instance;
  final LiveStreamingService _apiService = ServiceLocator().liveStreamingService;

  bool _isInitialized = false;
  bool _isCameraOn = true;
  bool _isMicOn = true;
  int _viewerCount = 0;
  String _connectionQuality = 'Excellent';
  String? _errorMessage;

  StreamSubscription? _stateSubscription;
  StreamSubscription? _videoSubscription;
  StreamSubscription? _audioSubscription;
  StreamSubscription? _viewerSubscription;
  StreamSubscription? _qualitySubscription;
  StreamSubscription? _errorSubscription;

  @override
  void initState() {
    super.initState();
    _initializeAndStartStream();
  }

  Future<void> _initializeAndStartStream() async {
    try {
      setState(() {
        _errorMessage = null;
      });

      // Step 1: Initialize Agora engine
      const agoraAppId = '0bb5c5b508884aa4bfc25381d51fa329';
      await _streamingService.initialize(agoraAppId);

      // Step 2: Setup stream listeners
      _setupStreamListeners();

      // Step 3: Get RTC token from backend
      final tokenData = await _apiService.generateStreamRtcToken(
        streamId: widget.streamId,
        role: 'broadcaster',
      );

      if (tokenData == null) {
        throw Exception('Failed to get RTC token');
      }

      // Step 4: Start broadcasting
      await _streamingService.startBroadcasting(
        streamId: widget.streamId,
        channelName: tokenData['channelName'] as String,
        token: tokenData['token'] as String,
        uid: tokenData['uid'] as int,
      );

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to start stream: $e';
      });
    }
  }

  void _setupStreamListeners() {
    _stateSubscription = _streamingService.onStreamStateChanged.listen((state) {
      // Just log state changes, no need to update UI state
      debugPrint('Stream state changed to: $state');
    });

    _videoSubscription =
        _streamingService.onLocalVideoEnabledChanged.listen((enabled) {
      setState(() {
        _isCameraOn = enabled;
      });
    });

    _audioSubscription =
        _streamingService.onLocalAudioEnabledChanged.listen((enabled) {
      setState(() {
        _isMicOn = enabled;
      });
    });

    _viewerSubscription =
        _streamingService.onViewerCountChanged.listen((count) {
      setState(() {
        _viewerCount = count;
      });
    });

    _qualitySubscription =
        _streamingService.onConnectionQualityChanged.listen((quality) {
      setState(() {
        _connectionQuality = _getQualityText(quality);
      });
    });

    _errorSubscription = _streamingService.onStreamError.listen((error) {
      setState(() {
        _errorMessage = error;
      });
    });
  }

  String _getQualityText(QualityType quality) {
    switch (quality) {
      case QualityType.qualityExcellent:
        return 'Excellent';
      case QualityType.qualityGood:
        return 'Good';
      case QualityType.qualityPoor:
        return 'Poor';
      case QualityType.qualityBad:
        return 'Bad';
      case QualityType.qualityVbad:
        return 'Very Bad';
      case QualityType.qualityDown:
        return 'Disconnected';
      default:
        return 'Unknown';
    }
  }

  Future<void> _toggleCamera() async {
    await _streamingService.toggleCamera();
  }

  Future<void> _toggleMicrophone() async {
    await _streamingService.toggleMicrophone();
  }

  Future<void> _switchCamera() async {
    await _streamingService.switchCamera();
  }

  Future<void> _endStream() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Stream'),
        content: const Text('Are you sure you want to end this live stream?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('End Stream'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Leave Agora channel
        await _streamingService.leaveStream();

        // End stream on backend
        await _apiService.endLiveStream(widget.streamId);

        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error ending stream: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _videoSubscription?.cancel();
    _audioSubscription?.cancel();
    _viewerSubscription?.cancel();
    _qualitySubscription?.cancel();
    _errorSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          if (_isInitialized && _streamingService.engine != null)
            Center(
              child: AgoraVideoView(
                controller: VideoViewController(
                  rtcEngine: _streamingService.engine!,
                  canvas: const VideoCanvas(uid: 0),
                ),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(
                color: PulseColors.primary,
              ),
            ),

          // Error message overlay
          if (_errorMessage != null)
            Positioned(
              top: 100,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          // Top info bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Live indicator
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Viewer count
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.remove_red_eye,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _viewerCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Connection quality
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _connectionQuality,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Close button
                        IconButton(
                          onPressed: _endStream,
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Stream title
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Switch camera
                    _buildControlButton(
                      icon: Icons.flip_camera_ios,
                      label: 'Flip',
                      onPressed: _switchCamera,
                    ),
                    // Toggle camera
                    _buildControlButton(
                      icon: _isCameraOn ? Icons.videocam : Icons.videocam_off,
                      label: _isCameraOn ? 'Camera' : 'Camera Off',
                      onPressed: _toggleCamera,
                      isActive: _isCameraOn,
                    ),
                    // Toggle microphone
                    _buildControlButton(
                      icon: _isMicOn ? Icons.mic : Icons.mic_off,
                      label: _isMicOn ? 'Mic' : 'Mic Off',
                      onPressed: _toggleMicrophone,
                      isActive: _isMicOn,
                    ),
                    // End stream
                    _buildControlButton(
                      icon: Icons.call_end,
                      label: 'End',
                      onPressed: _endStream,
                      color: Colors.red,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isActive = true,
    Color? color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: color ??
                (isActive
                    ? PulseColors.primary.withValues(alpha: 0.2)
                    : Colors.grey.withValues(alpha: 0.2)),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(
              icon,
              color: color ?? (isActive ? Colors.white : Colors.grey),
              size: 28,
            ),
            padding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: color ?? (isActive ? Colors.white : Colors.grey),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
