import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/services/speed_dating_service.dart';
import '../../../data/services/audio_call_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
// TODO: Uncomment when round_transition_screen.dart is created (Task 5)
// import 'round_transition_screen.dart';

/// Active Round Screen for Speed Dating
/// Shows partner profile, countdown timer, and audio call controls
class ActiveRoundScreen extends StatefulWidget {
  final String eventId;
  final String sessionId;

  const ActiveRoundScreen({
    Key? key,
    required this.eventId,
    required this.sessionId,
  }) : super(key: key);

  @override
  State<ActiveRoundScreen> createState() => _ActiveRoundScreenState();
}

class _ActiveRoundScreenState extends State<ActiveRoundScreen>
    with TickerProviderStateMixin {
  final SpeedDatingService _speedDatingService = SpeedDatingService();
  final AudioCallService _audioCallService = AudioCallService.instance;

  Map<String, dynamic>? _currentSession;
  Map<String, dynamic>? _nextSession;
  Map<String, dynamic>? _partnerProfile;
  int _remainingSeconds = 180; // 3 minutes default
  bool _isLoading = true;
  bool _isCallActive = false;
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  String? _error;

  late AnimationController _progressController;
  late AnimationController _pulseController;
  StreamSubscription? _timerSubscription;
  StreamSubscription? _sessionSubscription;
  StreamSubscription? _callStateSubscription;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadSessionData();
    _listenToTimer();
    _listenToSession();
    _listenToCallState();
  }

  void _initAnimations() {
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  Future<void> _loadSessionData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = _getCurrentUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Load current session
      final session = await _speedDatingService.getCurrentSession(
        widget.eventId,
        userId,
      );

      if (session != null && mounted) {
        setState(() {
          _currentSession = session;
          _remainingSeconds = _speedDatingService.remainingSeconds;
          _isLoading = false;
        });

        // Extract partner profile
        _extractPartnerProfile(session, userId);

        // Load next session
        _loadNextSession(userId);

        // Start audio call automatically
        await _startAudioCall();
      } else if (mounted) {
        setState(() {
          _error = 'No active session found';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load session: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadNextSession(String userId) async {
    try {
      final nextSession = await _speedDatingService.getNextSession(
        widget.eventId,
        userId,
      );

      if (nextSession != null && mounted) {
        setState(() {
          _nextSession = nextSession;
        });
      }
    } catch (e) {
      // Next session is optional, don't show error
      debugPrint('No next session available: $e');
    }
  }

  void _extractPartnerProfile(Map<String, dynamic> session, String userId) {
    final participant1 = session['participant1'] as Map<String, dynamic>?;
    final participant2 = session['participant2'] as Map<String, dynamic>?;

    // Determine which participant is the partner
    Map<String, dynamic>? partner;
    if (participant1?['userId'] == userId) {
      partner = participant2;
    } else if (participant2?['userId'] == userId) {
      partner = participant1;
    }

    if (partner != null && partner['user'] != null) {
      final userMap = partner['user'];
      if (userMap is Map<String, dynamic>) {
        setState(() {
          _partnerProfile = userMap;
        });
      }
    }
  }

  String? _getCurrentUserId() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      return authState.user.id;
    }
    return null;
  }

  void _listenToTimer() {
    _timerSubscription = _speedDatingService.onTimerTick.listen((seconds) {
      if (mounted) {
        setState(() {
          _remainingSeconds = seconds;
        });

        // Update progress animation
        final progress = seconds / 180.0; // 3 minutes
        _progressController.animateTo(
          1.0 - progress,
          duration: const Duration(milliseconds: 500),
        );

        // Auto-transition when time runs out
        if (seconds <= 0) {
          _handleRoundComplete();
        }
      }
    });
  }

  void _listenToSession() {
    _sessionSubscription = _speedDatingService.onCurrentSessionChanged.listen(
      (session) {
        if (session == null && mounted) {
          // Session ended, navigate away
          _handleRoundComplete();
        }
      },
    );
  }

  void _listenToCallState() {
    _callStateSubscription = _audioCallService.onCallStateChanged.listen(
      (isInCall) {
        if (mounted) {
          setState(() {
            _isCallActive = isInCall;
          });
        }
      },
    );
  }

  Future<void> _startAudioCall() async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null || _partnerProfile == null) return;

      final channelName = 'speed_dating_${widget.sessionId}';
      final partnerId = _partnerProfile!['id'] as String;
      
      final success = await _audioCallService.joinAudioCall(
        callId: widget.sessionId,
        recipientId: partnerId,
        channelName: channelName,
      );

      if (success && mounted) {
        setState(() {
          _isCallActive = true;
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to start audio call')),
        );
      }
    } catch (e) {
      debugPrint('Failed to start audio call: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start call: $e')),
        );
      }
    }
  }

  Future<void> _toggleMute() async {
    try {
      await _audioCallService.toggleMute();
      setState(() {
        _isMuted = !_isMuted;
      });
    } catch (e) {
      debugPrint('Failed to toggle mute: $e');
    }
  }

  Future<void> _toggleSpeaker() async {
    try {
      final newState = !_isSpeakerOn;
      await _audioCallService.enableSpeakerphone(newState);
      setState(() {
        _isSpeakerOn = newState;
      });
    } catch (e) {
      debugPrint('Failed to toggle speaker: $e');
    }
  }

  Future<void> _endRoundEarly() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Round Early?'),
        content: const Text(
          'Are you sure you want to end this round early? '
          'You can still rate your partner.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('End Round'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _audioCallService.leaveCall();
      _handleRoundComplete();
    }
  }

  void _handleRoundComplete() {
    // End audio call
    _audioCallService.leaveCall();

    // TODO: Navigate to transition screen for rating (Task 5)
    // For now, just go back to lobby
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Round complete! Rating screen coming in Task 5.'),
          duration: Duration(seconds: 3),
        ),
      );
      Navigator.of(context).pop();
    }
    
    // TODO: Uncomment when RoundTransitionScreen is created
    // if (mounted && _currentSession != null) {
    //   Navigator.of(context).pushReplacement(
    //     MaterialPageRoute(
    //       builder: (_) => RoundTransitionScreen(
    //         eventId: widget.eventId,
    //         sessionId: widget.sessionId,
    //         partnerProfile: _partnerProfile,
    //         nextSession: _nextSession,
    //       ),
    //     ),
    //   );
    // }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Leave Round?'),
            content: const Text(
              'Are you sure you want to leave this speed dating round?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Stay'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Leave'),
              ),
            ],
          ),
        );
        
        if (confirmed == true) {
          await _audioCallService.leaveCall();
        }
        
        return confirmed ?? false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back to Lobby'),
            ),
          ],
        ),
      );
    }

    if (_partnerProfile == null || _currentSession == null) {
      return const Center(
        child: Text(
          'No partner profile available',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      );
    }

    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildPartnerProfile()),
          _buildCallControls(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Timer with progress ring
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Progress ring
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: _remainingSeconds / 180.0,
                    strokeWidth: 4,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation(
                      _remainingSeconds < 30
                          ? Colors.red
                          : _remainingSeconds < 60
                              ? Colors.orange
                              : AppColors.primary,
                    ),
                  ),
                ),
                // Timer text
                Text(
                  _formatTime(_remainingSeconds),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Status text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Speed Dating',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (_isCallActive) ...[
                      FadeTransition(
                        opacity: _pulseController,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Connected',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ] else ...[
                      const Text(
                        'Connecting...',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // End round button
          IconButton(
            onPressed: _endRoundEarly,
            icon: const Icon(Icons.close, color: Colors.white),
            iconSize: 28,
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerProfile() {
    final name = _partnerProfile!['name'] as String? ?? 'Unknown';
    final age = _partnerProfile!['age'] as int?;
    final bio = _partnerProfile!['bio'] as String?;
    final photoUrl = _partnerProfile!['photoUrl'] as String?;
    final location = _partnerProfile!['location'] as String?;
    final interests = _partnerProfile!['interests'] as List<dynamic>?;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Profile photo
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary,
                width: 4,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: ClipOval(
              child: photoUrl != null
                  ? CachedNetworkImage(
                      imageUrl: photoUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: Colors.grey[800],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.grey[800],
                        child: const Icon(
                          Icons.person,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.grey[800],
                      child: Center(
                        child: Text(
                          name[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 64,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),
          // Name and age
          Text(
            age != null ? '$name, $age' : name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          if (location != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.location_on,
                  color: Colors.white70,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  location,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          // Bio
          if (bio != null && bio.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                bio,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          // Interests
          if (interests != null && interests.isNotEmpty) ...[
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: interests.map((interest) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    interest.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          // Next partner preview
          if (_nextSession != null) ...[
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'Next Partner',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildNextPartnerPreview(),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildNextPartnerPreview() {
    if (_nextSession == null) return const SizedBox.shrink();

    final userId = _getCurrentUserId();
    final participant1 = _nextSession!['participant1'] as Map<String, dynamic>?;
    final participant2 = _nextSession!['participant2'] as Map<String, dynamic>?;

    Map<String, dynamic>? nextPartner;
    if (participant1?['userId'] == userId) {
      nextPartner = participant2?['user'] as Map<String, dynamic>?;
    } else if (participant2?['userId'] == userId) {
      nextPartner = participant1?['user'] as Map<String, dynamic>?;
    }

    if (nextPartner == null) return const SizedBox.shrink();

    final name = nextPartner['name'] as String? ?? 'Unknown';
    final photoUrl = nextPartner['photoUrl'] as String?;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 24,
          backgroundImage: photoUrl != null
              ? CachedNetworkImageProvider(photoUrl)
              : null,
          child: photoUrl == null
              ? Text(
                  name[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 12),
        Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCallControls() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mute button
          _buildControlButton(
            icon: _isMuted ? Icons.mic_off : Icons.mic,
            label: _isMuted ? 'Unmute' : 'Mute',
            color: _isMuted ? Colors.red : Colors.white,
            backgroundColor: _isMuted
                ? Colors.red.withOpacity(0.2)
                : Colors.white.withOpacity(0.2),
            onPressed: _toggleMute,
          ),
          // Speaker button
          _buildControlButton(
            icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
            label: _isSpeakerOn ? 'Speaker On' : 'Speaker Off',
            color: _isSpeakerOn ? AppColors.primary : Colors.white,
            backgroundColor: _isSpeakerOn
                ? AppColors.primary.withOpacity(0.2)
                : Colors.white.withOpacity(0.2),
            onPressed: _toggleSpeaker,
          ),
          // End call button
          _buildControlButton(
            icon: Icons.call_end,
            label: 'End',
            color: Colors.white,
            backgroundColor: Colors.red,
            onPressed: _endRoundEarly,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color backgroundColor,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: backgroundColor,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Icon(icon, color: color, size: 28),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    _timerSubscription?.cancel();
    _sessionSubscription?.cancel();
    _callStateSubscription?.cancel();
    _audioCallService.leaveCall();
    super.dispose();
  }
}
