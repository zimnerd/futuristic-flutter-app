import 'package:flutter/material.dart';
import '../../../data/models/user_model.dart';

import '../../theme/pulse_colors.dart';
import '../../widgets/common/pulse_toast.dart';
import '../../widgets/call/video_effects_panel.dart';
import '../../widgets/call/group_call_widget.dart';

/// Enhanced Call Screen with Video Effects and Group Call Management
/// Integrates both Phase 3A (Virtual Backgrounds & Filters) and Phase 3B (Group Calls)
class EnhancedCallScreen extends StatefulWidget {
  final String callId;
  final List<UserModel> participants;
  final UserModel currentUser;
  final bool isGroupCall;

  const EnhancedCallScreen({
    super.key,
    required this.callId,
    required this.participants,
    required this.currentUser,
    this.isGroupCall = false,
  });

  @override
  State<EnhancedCallScreen> createState() => _EnhancedCallScreenState();
}

class _EnhancedCallScreenState extends State<EnhancedCallScreen>
    with TickerProviderStateMixin {
  bool _showVideoEffects = false;
  bool _showGroupControls = false;
  bool _isMuted = false;
  bool _isVideoEnabled = true;
  final bool _isRecording = false;
  String? _currentBackground;
  String? _currentFilter;

  // Animation controllers for smooth UI transitions
  late AnimationController _effectsPanelController;
  late AnimationController _groupControlsController;
  late Animation<Offset> _effectsPanelAnimation;
  late Animation<Offset> _groupControlsAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _effectsPanelController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _groupControlsController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Setup slide animations
    _effectsPanelAnimation =
        Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _effectsPanelController,
            curve: Curves.easeInOut,
          ),
        );

    _groupControlsAnimation =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _groupControlsController,
            curve: Curves.easeInOut,
          ),
        );
  }

  @override
  void dispose() {
    _effectsPanelController.dispose();
    _groupControlsController.dispose();
    super.dispose();
  }

  void _toggleVideoEffects() {
    setState(() {
      _showVideoEffects = !_showVideoEffects;
    });

    if (_showVideoEffects) {
      _effectsPanelController.forward();
      // Close group controls if open
      if (_showGroupControls) {
        _groupControlsController.reverse();
        _showGroupControls = false;
      }
    } else {
      _effectsPanelController.reverse();
    }
  }

  void _toggleGroupControls() {
    if (!widget.isGroupCall) return;

    setState(() {
      _showGroupControls = !_showGroupControls;
    });

    if (_showGroupControls) {
      _groupControlsController.forward();
      // Close video effects if open
      if (_showVideoEffects) {
        _effectsPanelController.reverse();
        _showVideoEffects = false;
      }
    } else {
      _groupControlsController.reverse();
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (isError) {
      PulseToast.error(context, message: message);
    } else {
      PulseToast.info(context, message: message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Main Call Video Area
            _buildMainVideoArea(),

            // Participants Grid (for group calls)
            if (widget.isGroupCall) _buildParticipantsGrid(),

            // Top Controls Bar
            _buildTopControlsBar(),

            // Bottom Controls Bar
            _buildBottomControlsBar(),

            // Group Call Management Overlay
            if (widget.isGroupCall && _showGroupControls)
              SlideTransition(
                position: _groupControlsAnimation,
                child: Positioned(
                  top: 100,
                  left: 16,
                  right: 16,
                  child: GroupCallWidget(
                    callId: widget.callId,
                    participants: widget.participants,
                    currentUser: widget.currentUser,
                    onLeave: () => Navigator.of(context).pop(),
                    onError: (error) => _showMessage(error, isError: true),
                    onSuccess: (message) => _showMessage(message),
                  ),
                ),
              ),

            // Video Effects Panel Overlay
            if (_showVideoEffects)
              SlideTransition(
                position: _effectsPanelAnimation,
                child: Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: VideoEffectsPanel(
                    callId: widget.callId,
                    onClose: _toggleVideoEffects,
                    onError: (error) => _showMessage(error, isError: true),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainVideoArea() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.3),
            Colors.black.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Placeholder for actual video stream
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: PulseColors.primary.withValues(alpha: 0.3),
                shape: BoxShape.circle,
                border: Border.all(color: PulseColors.primary, width: 3),
              ),
              child: const Icon(Icons.videocam, color: Colors.white, size: 80),
            ),

            const SizedBox(height: 20),

            // Call Status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.isGroupCall
                    ? 'Group Call - ${widget.participants.length} participants'
                    : 'Video Call',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // Active Effects Indicators
            if (_currentBackground != null || _currentFilter != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  if (_currentBackground != null)
                    _buildEffectChip('Background: $_currentBackground'),
                  if (_currentFilter != null)
                    _buildEffectChip('Filter: $_currentFilter'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEffectChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: PulseColors.primary.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildParticipantsGrid() {
    if (widget.participants.length <= 2) return const SizedBox.shrink();

    return Positioned(
      top: 100,
      right: 16,
      child: Container(
        width: 120,
        constraints: const BoxConstraints(maxHeight: 300),
        child: Column(
          children: widget.participants.take(4).map((participant) {
            return Container(
              width: 120,
              height: 80,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Stack(
                children: [
                  // Participant video placeholder
                  const Center(
                    child: Icon(Icons.person, color: Colors.white, size: 30),
                  ),

                  // Participant name
                  Positioned(
                    bottom: 4,
                    left: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        participant.firstName != null &&
                                participant.lastName != null
                            ? '${participant.firstName} ${participant.lastName}'
                            : participant.firstName ?? participant.username,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTopControlsBar() {
    return Positioned(
      top: 20,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),

          // Call Duration
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              '00:45',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Recording Indicator
          if (_isRecording)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.fiber_manual_record,
                    color: Colors.white,
                    size: 12,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'REC',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildBottomControlsBar() {
    return Positioned(
      bottom: 40,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mute Button
          _buildCallControlButton(
            icon: _isMuted ? Icons.mic_off : Icons.mic,
            isActive: !_isMuted,
            onTap: () => setState(() => _isMuted = !_isMuted),
          ),

          // Video Toggle
          _buildCallControlButton(
            icon: _isVideoEnabled ? Icons.videocam : Icons.videocam_off,
            isActive: _isVideoEnabled,
            onTap: () => setState(() => _isVideoEnabled = !_isVideoEnabled),
          ),

          // Video Effects Button
          _buildCallControlButton(
            icon: Icons.auto_fix_high,
            isActive: _showVideoEffects,
            onTap: _toggleVideoEffects,
            badge: _currentBackground != null || _currentFilter != null
                ? '●'
                : null,
          ),

          // Group Controls (only for group calls)
          if (widget.isGroupCall)
            _buildCallControlButton(
              icon: Icons.groups,
              isActive: _showGroupControls,
              onTap: _toggleGroupControls,
            ),

          // End Call Button
          _buildCallControlButton(
            icon: Icons.call_end,
            isActive: false,
            backgroundColor: Colors.red,
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildCallControlButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    Color? backgroundColor,
    String? badge,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color:
                backgroundColor ??
                (isActive
                    ? PulseColors.primary
                    : Colors.white.withValues(alpha: 0.2)),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: IconButton(
            onPressed: onTap,
            icon: Icon(
              icon,
              color: backgroundColor != null || isActive
                  ? Colors.white
                  : Colors.white70,
              size: 24,
            ),
          ),
        ),

        // Badge for active effects
        if (badge != null)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
