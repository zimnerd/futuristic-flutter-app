import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/call_invitation.dart';
import '../../../core/services/call_invitation_service.dart';
import '../../../core/utils/logger.dart';
import '../../../domain/entities/user_profile.dart';
import '../../screens/calls/audio_call_screen.dart';
import '../../screens/call/video_call_screen.dart';
import '../../../features/calls/presentation/screens/incoming_call_screen.dart';

/// Global overlay handler for incoming calls
///
/// This widget wraps the entire app and listens for incoming call invitations.
/// When a call arrives while app is in foreground, it shows a full-screen
/// incoming call UI with accept/decline options.
///
/// Features:
/// - Foreground call handling (WebSocket)
/// - Full-screen overlay with ringtone + vibration
/// - Auto-navigation to call screen on accept
/// - Handles call cancellation/timeout
/// - Works with CallNotificationService for background calls
class CallOverlayHandler extends StatefulWidget {
  final Widget child;

  const CallOverlayHandler({super.key, required this.child});

  @override
  State<CallOverlayHandler> createState() => _CallOverlayHandlerState();
}

class _CallOverlayHandlerState extends State<CallOverlayHandler> {
  final CallInvitationService _callService = CallInvitationService();
  StreamSubscription<CallInvitation>? _incomingCallSubscription;
  StreamSubscription<CallInvitation>? _callCancelledSubscription;
  StreamSubscription<CallInvitation>? _callTimeoutSubscription;
  OverlayEntry? _callOverlay;

  @override
  void initState() {
    super.initState();
    _setupCallListeners();
  }

  void _setupCallListeners() {
    // Listen for incoming calls (WebSocket)
    _incomingCallSubscription = _callService.onIncomingCall.listen((invitation) {
      AppLogger.info('📞 Incoming call received in CallOverlayHandler: ${invitation.callId}');
      _showIncomingCallOverlay(invitation);
    });

    // Listen for call cancellation
    _callCancelledSubscription = _callService.onCallCancelled.listen((invitation) {
      AppLogger.info('📞 Call cancelled: ${invitation.callId}');
      _removeCallOverlay();
    });

    // Listen for call timeout
    _callTimeoutSubscription = _callService.onCallTimeout.listen((invitation) {
      AppLogger.info('📞 Call timeout: ${invitation.callId}');
      _removeCallOverlay();
    });
  }

  void _showIncomingCallOverlay(CallInvitation invitation) {
    // Remove any existing overlay first
    _removeCallOverlay();

    // Vibrate to alert user
    HapticFeedback.heavyImpact();

    // Navigate to IncomingCallScreen and await result
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => IncomingCallScreen(invitation: invitation),
        fullscreenDialog: true,
      ),
    ).then((accepted) {
      if (accepted == true) {
        _handleCallAccepted(invitation);
      } else if (accepted == false) {
        _handleCallDeclined(invitation);
      }
      // If null, call was cancelled/timed out - handled by service streams
    });

    AppLogger.info('📞 Incoming call screen displayed');
  }

  void _removeCallOverlay() {
    if (_callOverlay != null) {
      _callOverlay!.remove();
      _callOverlay = null;
      AppLogger.info('📞 Incoming call overlay removed');
    }
  }

  Future<void> _handleCallAccepted(CallInvitation invitation) async {
    AppLogger.info('✅ Call accepted: ${invitation.callId}');
    
    // Remove overlay
    _removeCallOverlay();

    // Accept call via service
    await _callService.acceptCall(invitation.callId);

    // Navigate to appropriate call screen
    if (!mounted) return;

    if (invitation.callType == CallType.video) {
      // Navigate to video call screen
      // Create minimal UserProfile for video call (only required fields)
      final remoteUser = UserProfile(
        id: invitation.callerId,
        name: invitation.callerName,
        age: 25, // Placeholder - not critical for call UI
        bio: '',
        photos: invitation.callerPhoto != null 
            ? [ProfilePhoto(
                id: 'temp',
                url: invitation.callerPhoto!,
                order: 0,
                isMain: true,
              )]
            : [],
        location: UserLocation(
          latitude: 0,
          longitude: 0,
          city: '',
          country: '',
        ),
      );

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => VideoCallScreen(
            remoteUser: remoteUser,
            callId: invitation.callId,
            isIncoming: true,
          ),
          fullscreenDialog: true,
        ),
      );
    } else {
      // Navigate to audio call screen
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AudioCallScreen(
            callId: invitation.callId,
            recipientId: invitation.callerId,
            userName: invitation.callerName,
            userPhotoUrl: invitation.callerPhoto,
            channelName: invitation.channelName,
            token: invitation.rtcToken,
            isOutgoing: false, // isIncoming would be true, but param is isOutgoing
            conversationId: invitation.conversationId,
          ),
          fullscreenDialog: true,
        ),
      );
    }
  }

  Future<void> _handleCallDeclined(CallInvitation invitation) async {
    AppLogger.info('❌ Call declined: ${invitation.callId}');
    
    // Remove overlay
    _removeCallOverlay();

    // Reject call via service
    await _callService.rejectCall(
      invitation.callId,
      reason: CallRejectionReason.userDeclined,
    );
  }

  @override
  void dispose() {
    _incomingCallSubscription?.cancel();
    _callCancelledSubscription?.cancel();
    _callTimeoutSubscription?.cancel();
    _removeCallOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Just pass through the child - incoming calls handled via Navigator
    return widget.child;
  }
}

