import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/models/call_invitation.dart';
import '../../../../core/services/call_invitation_service.dart';

/// Outgoing call screen shown when user initiates a call
/// 
/// Features:
/// - "Calling..." state with animated rings
/// - Recipient photo/name display
/// - Cancel button
/// - Listen for acceptance/rejection/timeout
/// - Pulse brand colors
class OutgoingCallScreen extends StatefulWidget {
  final CallInvitation invitation;
  final String recipientName;
  final String? recipientPhoto;

  const OutgoingCallScreen({
    super.key,
    required this.invitation,
    required this.recipientName,
    this.recipientPhoto,
  });

  @override
  State<OutgoingCallScreen> createState() => _OutgoingCallScreenState();
}

class _OutgoingCallScreenState extends State<OutgoingCallScreen>
    with TickerProviderStateMixin {
  final CallInvitationService _callService = CallInvitationService();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  StreamSubscription? _acceptedSubscription;
  StreamSubscription? _rejectedSubscription;
  StreamSubscription? _timeoutSubscription;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _listenToCallEvents();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
  }

  void _listenToCallEvents() {
    // Listen for call accepted
    _acceptedSubscription = _callService.onCallAccepted.listen((invitation) {
      if (invitation.callId == widget.invitation.callId) {
        _onCallAccepted(invitation);
      }
    });

    // Listen for call rejected
    _rejectedSubscription = _callService.onCallRejected.listen((invitation) {
      if (invitation.callId == widget.invitation.callId) {
        _onCallRejected();
      }
    });

    // Listen for call timeout
    _timeoutSubscription = _callService.onCallTimeout.listen((invitation) {
      if (invitation.callId == widget.invitation.callId) {
        _onCallTimeout();
      }
    });
  }

  void _onCallAccepted(CallInvitation invitation) {
    if (mounted) {
      Navigator.of(context).pop({
        'accepted': true,
        'invitation': invitation,
      });
    }
  }

  void _onCallRejected() {
    if (mounted) {
      _showSnackBar('Call declined', Colors.orange);
      Navigator.of(context).pop({'accepted': false});
    }
  }

  void _onCallTimeout() {
    if (mounted) {
      _showSnackBar('No answer', Colors.grey);
      Navigator.of(context).pop({'accepted': false});
    }
  }

  Future<void> _onCancel() async {
    HapticFeedback.mediumImpact();
    await _callService.cancelCall(widget.invitation.callId);
    if (mounted) {
      Navigator.of(context).pop({'accepted': false});
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _acceptedSubscription?.cancel();
    _rejectedSubscription?.cancel();
    _timeoutSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Stack(
        children: [
          // Gradient background
          _buildGradientBackground(),

          // Content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 60),

                // Call type badge
                _buildCallTypeBadge(),

                const SizedBox(height: 80),

                // Recipient photo with pulsing rings
                _buildRecipientPhoto(),

                const SizedBox(height: 32),

                // Recipient name
                _buildRecipientName(),

                const SizedBox(height: 8),

                // Calling status
                _buildCallingStatus(),

                const Spacer(),

                // Cancel button
                _buildCancelButton(),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF6E3BFF).withOpacity(0.3), // Pulse primary
            const Color(0xFF00C2FF).withOpacity(0.2), // Pulse accent
            Colors.black87,
          ],
          stops: const [0.0, 0.4, 1.0],
        ),
      ),
    );
  }

  Widget _buildCallTypeBadge() {
    final isVideo = widget.invitation.callType == CallType.video;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVideo ? Icons.videocam : Icons.phone,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            widget.invitation.callTypeDisplay,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipientPhoto() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Animated pulsing rings
        ..._buildPulsingRings(),

        // Recipient photo
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 4,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6E3BFF).withOpacity(0.5),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ClipOval(
            child: widget.recipientPhoto != null
                ? CachedNetworkImage(
                    imageUrl: widget.recipientPhoto!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => _buildPhotoPlaceholder(),
                    errorWidget: (context, url, error) =>
                        _buildPhotoPlaceholder(),
                  )
                : _buildPhotoPlaceholder(),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildPulsingRings() {
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
                color: const Color(0xFF00C2FF).withOpacity(0.5 - value * 0.5),
                width: 2,
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildPhotoPlaceholder() {
    return Container(
      color: const Color(0xFF6E3BFF),
      child: Center(
        child: Text(
          widget.recipientName.isNotEmpty
              ? widget.recipientName[0].toUpperCase()
              : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildRecipientName() {
    return Text(
      widget.recipientName,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 32,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildCallingStatus() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Animated dots
        ...List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final delay = index * 0.3;
              final value =
                  ((_pulseController.value - delay) % 1.0).clamp(0.0, 1.0);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.3 + value * 0.7),
                  ),
                ),
              );
            },
          );
        }),

        const SizedBox(width: 12),

        // Status text
        Text(
          'Calling',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCancelButton() {
    return GestureDetector(
      onTap: _onCancel,
      child: Column(
        children: [
          // Button circle
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.call_end,
              color: Colors.white,
              size: 32,
            ),
          ),

          const SizedBox(height: 12),

          // Label
          const Text(
            'Cancel',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
