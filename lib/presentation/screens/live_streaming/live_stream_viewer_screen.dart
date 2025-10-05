import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'dart:async';

import '../../../data/services/video_streaming_service.dart';
import '../../../data/services/live_streaming_service.dart';
import '../../../data/services/service_locator.dart';
import '../../theme/pulse_colors.dart';
import '../../widgets/common/keyboard_dismissible_scaffold.dart';

/// Screen for viewing a live stream (audience view)
class LiveStreamViewerScreen extends StatefulWidget {
  final Map<String, dynamic> stream;

  const LiveStreamViewerScreen({
    super.key,
    required this.stream,
  });

  @override
  State<LiveStreamViewerScreen> createState() => _LiveStreamViewerScreenState();
}

class _LiveStreamViewerScreenState extends State<LiveStreamViewerScreen> {
  final VideoStreamingService _streamingService =
      VideoStreamingService.instance;
  final LiveStreamingService _apiService =
      ServiceLocator().liveStreamingService;
  final _messageController = TextEditingController();

  bool _isInitialized = false;
  int? _broadcasterUid;
  String _connectionQuality = 'Excellent';
  String? _errorMessage;

  StreamSubscription? _remoteUsersSubscription;
  StreamSubscription? _remoteVideoSubscription;
  StreamSubscription? _qualitySubscription;
  StreamSubscription? _errorSubscription;

  @override
  void initState() {
    super.initState();
    _initializeAndJoinStream();
  }

  Future<void> _initializeAndJoinStream() async {
    try {
      setState(() {
        _errorMessage = null;
      });

      // Step 1: Initialize Agora engine
      const agoraAppId = '0bb5c5b508884aa4bfc25381d51fa329';
      await _streamingService.initialize(agoraAppId);

      // Step 2: Setup stream listeners
      _setupStreamListeners();

      // Step 3: Get stream ID
      final streamId = widget.stream['id']?.toString() ?? '';
      if (streamId.isEmpty) {
        throw Exception('Invalid stream ID');
      }

      // Step 4: Join stream on backend
      // (This would typically send a request to join the stream)
      // For now, we'll just get the RTC token

      // Step 5: Get RTC token from backend
      final tokenData = await _apiService.generateStreamRtcToken(
        streamId: streamId,
        role: 'audience',
      );

      if (tokenData == null) {
        throw Exception('Failed to get RTC token');
      }

      // Step 6: Join as audience
      await _streamingService.joinAsAudience(
        streamId: streamId,
        channelName: tokenData['channelName'] as String,
        token: tokenData['token'] as String,
        uid: tokenData['uid'] as int,
      );

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to join stream: $e';
      });
    }
  }

  void _setupStreamListeners() {
    _remoteUsersSubscription = _streamingService.onRemoteUsersChanged.listen((
      users,
    ) {
      if (users.isNotEmpty && _broadcasterUid == null) {
        setState(() {
          _broadcasterUid = users.first;
        });
      }
    });

    _remoteVideoSubscription = _streamingService.onRemoteVideoStateChanged
        .listen((videoStates) {
          // Just log video state changes
          debugPrint('Remote video states updated: $videoStates');
        });

    _qualitySubscription = _streamingService.onConnectionQualityChanged.listen((
      quality,
    ) {
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

  Future<void> _leaveStream() async {
    try {
      await _streamingService.leaveStream();

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error leaving stream: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      try {
        final streamId = widget.stream['id']?.toString() ?? '';
        final success = await _apiService.sendChatMessage(
          streamId: streamId,
          message: message,
        );

        if (success) {
          _messageController.clear();
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to send message'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _remoteUsersSubscription?.cancel();
    _remoteVideoSubscription?.cancel();
    _qualitySubscription?.cancel();
    _errorSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.stream['title']?.toString() ?? 'Live Stream';
    final String streamerName =
        widget.stream['streamerName']?.toString() ?? 'Unknown';

    return KeyboardDismissibleScaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video area
          if (_isInitialized &&
              _streamingService.engine != null &&
              _broadcasterUid != null)
            Center(
              child: AgoraVideoView(
                controller: VideoViewController.remote(
                  rtcEngine: _streamingService.engine!,
                  canvas: VideoCanvas(uid: _broadcasterUid),
                  connection: RtcConnection(
                    channelId: _streamingService.currentChannelName,
                  ),
                ),
              ),
            )
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: PulseColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    _broadcasterUid == null
                        ? 'Waiting for broadcaster...'
                        : 'Connecting...',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
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
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _leaveStream,
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            streamerName,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Connection quality indicator
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
                  ],
                ),
              ),
            ),
          ),

          // Chat overlay (right side)
          Positioned(
            bottom: 100,
            right: 16,
            child: Container(
              width: 200,
              height: 300,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.chat, color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Live Chat',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Chat messages\nwill appear here',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
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
                padding: const EdgeInsets.all(16),
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
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: const TextStyle(color: Colors.white54),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: const BorderSide(color: Colors.white54),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: const BorderSide(color: Colors.white54),
                          ),
                          filled: true,
                          fillColor: Colors.black.withValues(alpha: 0.5),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FloatingActionButton(
                      mini: true,
                      onPressed: _sendMessage,
                      backgroundColor: PulseColors.primary,
                      child: const Icon(Icons.send, color: Colors.white),
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
}
