import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:logger/logger.dart';
import '../../theme/pulse_colors.dart';
import '../../../data/services/audio_call_service.dart';

/// Speed dating room screen for audio chat
/// Integrates Agora RTC Engine for real-time audio communication
class SpeedDatingRoomScreen extends StatefulWidget {
  final Map<String, dynamic> session;
  final String eventId;

  const SpeedDatingRoomScreen({
    super.key,
    required this.session,
    required this.eventId,
  });

  @override
  State<SpeedDatingRoomScreen> createState() => _SpeedDatingRoomScreenState();
}

class _SpeedDatingRoomScreenState extends State<SpeedDatingRoomScreen> {
  final Logger _logger = Logger();
  final AudioCallService _audioService = AudioCallService.instance;
  
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isAudioInitialized = false;
  bool _isConnected = false;
  QualityType _connectionQuality = QualityType.qualityUnknown;

  @override
  void initState() {
    super.initState();
    _initializeAudio();
    _setupAudioListeners();
  }

  @override
  void dispose() {
    _audioService.leaveCall();
    super.dispose();
  }

  /// Initialize Agora audio engine and join channel
  Future<void> _initializeAudio() async {
    try {
      // Agora App ID (same as used in other features)
      const agoraAppId = '0bb5c5b508884aa4bfc25381d51fa329';

      // Initialize audio service if not already initialized
      if (!_audioService.isInCall) {
        await _audioService.initialize(appId: agoraAppId);
      }

      // Get session details
      final sessionId = widget.session['id'] as String?;
      final partnerId = widget.session['partnerId'] as String?;

      if (sessionId == null || partnerId == null) {
        _logger.e('❌ Missing session details for audio initialization');
        return;
      }

      // Join audio call with speed dating channel
      final success = await _audioService.joinAudioCall(
        callId: sessionId,
        recipientId: partnerId,
        channelName: 'speed_date_${widget.eventId}_$sessionId',
      );

      if (success) {
        setState(() {
          _isAudioInitialized = true;
        });
        _logger.i('✅ Speed dating audio initialized');
      } else {
        _logger.e('❌ Failed to join speed dating audio channel');
        _showError('Failed to connect audio');
      }
    } catch (e) {
      _logger.e('❌ Error initializing speed dating audio: $e');
      _showError('Audio initialization failed');
    }
  }

  /// Setup audio event listeners
  void _setupAudioListeners() {
    // Listen for remote user joining
    _audioService.onRemoteUserJoined.listen((uid) {
      setState(() {
        _isConnected = true;
      });
      _logger.i('🎤 Partner connected to audio call (UID: $uid)');
    });

    // Listen for connection quality changes
    _audioService.onQualityChanged.listen((quality) {
      setState(() {
        _connectionQuality = quality;
      });
    });

    // Listen for audio errors
    _audioService.onCallError.listen((error) {
      _showError(error);
    });

    // Listen for call state changes
    _audioService.onCallStateChanged.listen((isInCall) {
      if (!isInCall && mounted) {
        // Call ended, return to previous screen
        Navigator.pop(context);
      }
    });
  }

  /// Toggle microphone mute
  Future<void> _toggleMute() async {
    await _audioService.toggleMute();
    setState(() {
      _isMuted = _audioService.isMuted;
    });
  }

  /// Show error message
  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Get connection quality icon
  Widget _getQualityIcon() {
    switch (_connectionQuality) {
      case QualityType.qualityExcellent:
      case QualityType.qualityGood:
        return const Icon(
          Icons.signal_cellular_alt,
          color: Colors.green,
          size: 20,
        );
      case QualityType.qualityPoor:
        return const Icon(
          Icons.signal_cellular_alt_2_bar,
          color: Colors.orange,
          size: 20,
        );
      case QualityType.qualityBad:
      case QualityType.qualityVbad:
        return const Icon(
          Icons.signal_cellular_alt_1_bar,
          color: Colors.red,
          size: 20,
        );
      default:
        return const Icon(
          Icons.signal_cellular_null,
          color: Colors.grey,
          size: 20,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String partnerName = widget.session['currentPartner'] ?? 'Unknown';
    final String timeRemaining = widget.session['timeRemaining'] ?? '3:00';

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Video area
            Column(
              children: [
                // Partner video (top half)
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: PulseColors.primary.withValues(
                              alpha: 0.3,
                            ),
                            child: const Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            partnerName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Audio connection status
                          if (!_isConnected && _isAudioInitialized)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      PulseColors.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Connecting audio...',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            )
                          else if (_isConnected)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.mic,
                                  size: 16,
                                  color: PulseColors.primary,
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'Audio connected',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // User video (bottom half)
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Center(
                      child: _isCameraOff
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 40,
                                  backgroundColor: PulseColors.secondary
                                      .withValues(alpha: 0.3),
                                child: const Icon(
                                  Icons.videocam_off,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Camera Off',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          )
                        : Container(
                            decoration: BoxDecoration(
                                color: PulseColors.secondary.withValues(
                                  alpha: 0.2,
                                ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text(
                                'Your Video',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Top overlay - timer and info
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: PulseColors.primary,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        timeRemaining,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Speed Dating with $partnerName',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Connection quality indicator
                    if (_isConnected) ...[
                      const SizedBox(width: 8),
                      _getQualityIcon(),
                    ],
                  ],
                ),
              ),
            ),
            
            // Bottom controls
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Mute button
                  GestureDetector(
                    onTap: _toggleMute,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _isMuted ? Colors.red : Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isMuted ? Icons.mic_off : Icons.mic,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  
                  // End call button
                  GestureDetector(
                    onTap: () async {
                      await _audioService.leaveCall();
                      if (mounted && context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.call_end,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                  
                  // Camera button
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isCameraOff = !_isCameraOff;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _isCameraOff ? Colors.red : Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isCameraOff ? Icons.videocam_off : Icons.videocam,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Match/Pass buttons
            Positioned(
              right: 20,
              top: MediaQuery.of(context).size.height * 0.4,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => _showMatchDialog(true),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => _showMatchDialog(false),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMatchDialog(bool isMatch) {
    final String partnerName = widget.session['currentPartner'] ?? 'this person';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isMatch ? 'Match!' : 'Pass'),
        content: Text(
          isMatch 
            ? 'You liked $partnerName! We\'ll let you know if it\'s a mutual match.'
            : 'You passed on $partnerName. No worries, there are more great people to meet!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}
