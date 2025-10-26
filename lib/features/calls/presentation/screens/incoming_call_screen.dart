import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/models/call_invitation.dart';
import '../../../../core/services/call_invitation_service.dart';
import '../../../../core/theme/theme_extensions.dart';

/// Full-screen incoming call UI with glassmorphism design
///
/// Features:
/// - Full-screen overlay that works on locked screen
/// - Caller photo, name, call type display
/// - Animated pulsing rings
/// - Accept/Decline gesture buttons
/// - Vibration + ringtone
/// - 30-second timeout countdown
/// - Pulse brand colors (#6E3BFF primary, #00C2FF accent)
class IncomingCallScreen extends StatefulWidget {
  final CallInvitation invitation;

  const IncomingCallScreen({super.key, required this.invitation});

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with TickerProviderStateMixin {
  final CallInvitationService _callService = CallInvitationService();

  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late Animation<double> _pulseAnimation;
  Timer? _timeoutTimer;
  int _remainingSeconds = 30;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startTimeout();
    _startVibration();

    // Listen for call cancellation
    _callService.onCallCancelled.listen((invitation) {
      if (invitation.callId == widget.invitation.callId) {
        _onCallCancelled();
      }
    });
  }

  void _setupAnimations() {
    // Pulsing rings animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));

    // Shimmer animation for buttons
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
  }

  void _startTimeout() {
    _timeoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
      });

      if (_remainingSeconds <= 0) {
        timer.cancel();
        _onTimeout();
      }
    });
  }

  void _startVibration() {
    // Vibrate in pattern: [wait, vibrate, wait, vibrate]
    HapticFeedback.heavyImpact();
    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      HapticFeedback.heavyImpact();
    });
  }

  Future<void> _onAccept() async {
    HapticFeedback.mediumImpact();
    await _callService.acceptCall(widget.invitation.callId);
    if (mounted) {
      Navigator.of(context).pop(true); // Return true = accepted
    }
  }

  Future<void> _onDecline() async {
    HapticFeedback.mediumImpact();
    await _callService.rejectCall(
      widget.invitation.callId,
      reason: CallRejectionReason.userDeclined,
    );
    if (mounted) {
      Navigator.of(context).pop(false); // Return false = declined
    }
  }

  void _onTimeout() {
    if (mounted) {
      Navigator.of(context).pop(false); // Return false = timeout
    }
  }

  void _onCallCancelled() {
    if (mounted) {
      Navigator.of(context).pop(false); // Return false = cancelled
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shimmerController.dispose();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Stack(
        children: [
          // Gradient background
          _buildGradientBackground(context),

          // Content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 60),

                // Call type badge
                _buildCallTypeBadge(context),

                const SizedBox(height: 40),

                // Caller photo with pulsing rings
                _buildCallerPhoto(context),

                const SizedBox(height: 32),

                // Caller name
                _buildCallerName(context),

                const SizedBox(height: 8),

                // Call status
                _buildCallStatus(context),

                const Spacer(),

                // Timeout countdown
                _buildTimeoutCountdown(context),

                const SizedBox(height: 40),

                // Action buttons
                _buildActionButtons(context),

                const SizedBox(height: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientBackground(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            context.primaryColor.withValues(alpha: 0.3),
            context.accentColor.withValues(alpha: 0.2),
            Colors.black87,
          ],
          stops: const [0.0, 0.4, 1.0],
        ),
      ),
    );
  }

  Widget _buildCallTypeBadge(BuildContext context) {
    final isVideo = widget.invitation.callType == CallType.video;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: context.glassSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: context.glassBorder,
          width: 1,
        ),
        // Glassmorphism
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      // Apply backdrop filter
      child: BackdropFilter(
        filter: const ColorFilter.mode(Colors.transparent, BlendMode.src),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isVideo ? Icons.videocam : Icons.phone,
              color: context.callOverlayText,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              widget.invitation.callTypeDisplay,
              style: TextStyle(
                color: context.callOverlayText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallerPhoto(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Animated pulsing rings
        ..._buildPulsingRings(context),

        // Caller photo
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: context.callOverlayText, width: 4),
            boxShadow: [
              BoxShadow(
                color: context.primaryColor.withValues(alpha: 0.5),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ClipOval(
            child: widget.invitation.callerPhoto != null
                ? CachedNetworkImage(
                    imageUrl: widget.invitation.callerPhoto!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => _buildPhotoPlaceholder(context),
                    errorWidget: (context, url, error) =>
                        _buildPhotoPlaceholder(context),
                  )
                : _buildPhotoPlaceholder(context),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildPulsingRings(BuildContext context) {
    return List.generate(3, (index) {
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          final delay = index * 0.2;
          final value = (_pulseAnimation.value - delay).clamp(0.0, 1.0);

          return Container(
            width: 140 + (value * 100),
            height: 140 + (value * 100),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: context.primaryColor.withValues(alpha: 0.5 - value * 0.5),
                width: 2,
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildPhotoPlaceholder(BuildContext context) {
    return Container(
      color: context.primaryColor,
      child: Center(
        child: Text(
          widget.invitation.callerName.isNotEmpty
              ? widget.invitation.callerName[0].toUpperCase()
              : '?',
          style: TextStyle(
            color: context.callOverlayText,
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCallerName(BuildContext context) {
    return Text(
      widget.invitation.callerName,
      style: TextStyle(
        color: context.callOverlayText,
        fontSize: 32,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildCallStatus(BuildContext context) {
    return Text(
      'Incoming ${widget.invitation.callTypeEmoji}',
      style: TextStyle(
        color: context.callOverlayTextSecondary,
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildTimeoutCountdown(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: _remainingSeconds <= 10
            ? context.callDecline.withValues(alpha: 0.2)
            : context.glassSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _remainingSeconds <= 10
              ? context.callDecline.withValues(alpha: 0.5)
              : context.glassBorder,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            color: _remainingSeconds <= 10 ? context.callDecline : context.callOverlayTextSecondary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '${_remainingSeconds}s',
            style: TextStyle(
              color: _remainingSeconds <= 10 ? context.callDecline : context.callOverlayTextSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Decline button
          _buildActionButton(
            context: context,
            icon: Icons.call_end,
            label: 'Decline',
            color: context.callDecline,
            onTap: _onDecline,
          ),

          // Accept button
          _buildActionButton(
            context: context,
            icon: widget.invitation.callType == CallType.video
                ? Icons.videocam
                : Icons.phone,
            label: 'Accept',
            color: context.callAccept,
            onTap: _onAccept,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          // Button circle
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(icon, color: context.callOverlayText, size: 32),
          ),

          const SizedBox(height: 12),

          // Label
          Text(
            label,
            style: TextStyle(
              color: context.callOverlayText,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
