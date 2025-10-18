import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/call/call_bloc.dart';
import '../../theme/pulse_colors.dart';
import '../../../domain/entities/call.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../data/services/messaging_service.dart';
import '../../../core/network/api_client.dart';
import '../common/robust_network_image.dart';
import '../common/pulse_toast.dart';

/// Widget for displaying incoming call UI
class IncomingCallWidget extends StatefulWidget {
  final Call call;

  const IncomingCallWidget({
    super.key,
    required this.call,
  });

  @override
  State<IncomingCallWidget> createState() => _IncomingCallWidgetState();
}

class _IncomingCallWidgetState extends State<IncomingCallWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Setup animations
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    // Start slide-in animation
    _slideController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SlideTransition(
        position: _slideAnimation,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                PulseColors.primary,
                PulseColors.secondary,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header with call type and status
                _buildHeader(),
                
                // Caller info section
                Expanded(
                  flex: 2,
                  child: _buildCallerInfo(),
                ),
                
                // Action buttons
                _buildActionButtons(),
                
                // Bottom spacing
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            'Incoming ${widget.call.type.name.toUpperCase()} call',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.greenAccent,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Ringing...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
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

  Widget _buildCallerInfo() {
    final callerProfile = widget.call.getOtherParticipant('current_user_id');
    
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Profile picture with pulse animation
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: _buildProfileImage(callerProfile),
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 24),
          
          // Caller name
          Text(
            callerProfile?.name ?? 'Unknown Caller',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          // Caller status or additional info
          if (callerProfile?.bio.isNotEmpty == true) ...[
            Text(
              callerProfile!.bio,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ] else ...[
            Text(
              'PulseLink User',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileImage(UserProfile? profile) {
    if (profile?.photos.isNotEmpty == true) {
      return ProfileNetworkImage(
        imageUrl: profile!.photos.first.url,
        size: 150, // Set appropriate size for call widget
        userGender: profile.gender,
      );
    }
    
    return _buildDefaultAvatar();
  }

  Widget _buildDefaultAvatar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
      ),
      child: const Icon(
        Icons.person,
        size: 80,
        color: Colors.white,
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Decline button
          _buildActionButton(
            icon: Icons.call_end,
            color: Colors.red,
            onTap: () => _declineCall(),
            label: 'Decline',
          ),
          
          // Quick message button (optional)
          if (widget.call.type == CallType.video) ...[
            _buildActionButton(
              icon: Icons.message,
              color: Colors.white.withValues(alpha: 0.3),
              onTap: () => _sendQuickMessage(),
              label: 'Message',
              iconColor: Colors.white,
            ),
          ],
          
          // Accept button
          _buildActionButton(
            icon: widget.call.type == CallType.video 
                ? Icons.videocam 
                : Icons.call,
            color: Colors.green,
            onTap: () => _acceptCall(),
            label: 'Accept',
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String label,
    Color iconColor = Colors.white,
  }) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(32),
              onTap: onTap,
              child: Icon(
                icon,
                color: iconColor,
                size: 28,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _acceptCall() {
    context.read<CallBloc>().add(AcceptCall(callId: widget.call.id));
    Navigator.of(context).pop();
  }

  void _declineCall() {
    context.read<CallBloc>().add(DeclineCall(callId: widget.call.id));
    Navigator.of(context).pop();
  }

  void _sendQuickMessage() {
    final quickMessages = [
      "I'm busy right now, can I call you back?",
      "I'm in a meeting, text me instead",
      "Can't talk now, everything okay?",
      "I'll call you back in a few minutes",
      "What's up? Send me a message",
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Quick Message'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: quickMessages
              .map(
                (message) => ListTile(
                  title: Text(message),
                  onTap: () {
                    Navigator.pop(context);
                    // Send the message and decline the call
                    _sendMessageAndDecline(message);
                  },
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _sendMessageAndDecline(String message) async {
    try {
      // Send quick message via messaging service
      final messagingService = MessagingService(apiClient: ApiClient.instance);
      await messagingService.sendMessage(
        conversationId: widget.call.recipientId,
        content: message,
        type: 'text',
      );

      // Show feedback
      if (mounted) {
        PulseToast.info(context, message: 'Message sent: "$message"');
      }
    } catch (e) {
      if (mounted) {
        PulseToast.error(
          context,
          message: 'Failed to send message: ${e.toString()}',
        );
      }
    } finally {
      // Always decline the call
      _declineCall();
    }
  }
}
