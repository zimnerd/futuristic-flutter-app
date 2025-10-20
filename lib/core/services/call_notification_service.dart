import 'dart:async';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:uuid/uuid.dart';
import '../models/call_invitation.dart';
import '../utils/logger.dart';
import 'call_invitation_service.dart';
import '../../presentation/navigation/app_router.dart';

/// Service for handling call notifications with native platform UI
///
/// Integrates with CallInvitationService (WebSocket) and provides:
/// - Android: Full-screen intent with native call UI
/// - iOS: CallKit integration with native call screen
/// - Background/foreground/terminated app state handling
/// - Accept/decline actions from notification
class CallNotificationService {
  static final CallNotificationService _instance =
      CallNotificationService._internal();
  factory CallNotificationService() => _instance;
  static CallNotificationService get instance => _instance;
  CallNotificationService._internal();

  final CallInvitationService _callInvitationService = CallInvitationService();
  final _uuid = const Uuid();

  /// Map of callId → flutter_callkit_incoming UUID for tracking
  final Map<String, String> _activeCallNotifications = {};

  /// Initialize service and set up event listeners
  Future<void> initialize() async {
    try {
      AppLogger.info('📞 Initializing CallNotificationService...');

      // Listen to flutter_callkit_incoming events
      await _setupCallKitListeners();

      AppLogger.info('✅ CallNotificationService initialized successfully');
    } catch (e) {
      AppLogger.error('❌ Failed to initialize CallNotificationService: $e');
    }
  }

  /// Set up flutter_callkit_incoming event listeners
  Future<void> _setupCallKitListeners() async {
    // Listen for call accepted event
    FlutterCallkitIncoming.onEvent.listen((CallEvent? event) {
      if (event == null) return;

      AppLogger.info(
        '📞 CallKit event received: ${event.event} - ${event.body}',
      );

      switch (event.event) {
        case Event.actionCallAccept:
          _handleAcceptFromNotification(event.body);
          break;
        case Event.actionCallDecline:
          _handleDeclineFromNotification(event.body);
          break;
        case Event.actionCallEnded:
          _handleCallEndedFromNotification(event.body);
          break;
        case Event.actionCallTimeout:
          _handleCallTimeoutFromNotification(event.body);
          break;
        default:
          AppLogger.info('📞 Unhandled CallKit event: ${event.event}');
      }
    });
  }

  /// Handle incoming call push notification from FCM
  ///
  /// This is called by FirebaseNotificationService when an incoming_call
  /// type notification is received
  Future<void> handleIncomingCallPush(Map<String, dynamic> data) async {
    try {
      AppLogger.info('📞 Handling incoming call push: $data');

      // Extract call data
      final callId = data['callId'] as String?;
      final callerId = data['callerId'] as String?;
      final callerName = data['callerName'] as String? ?? 'Unknown';
      final callerPhoto = data['callerPhoto'] as String?;
      final callType = data['callType'] as String? ?? 'AUDIO';
      final recipientId = data['recipientId'] as String?;
      final conversationId = data['conversationId'] as String?;
      final groupId = data['groupId'] as String?;

      if (callId == null || callerId == null || recipientId == null) {
        AppLogger.error('❌ Invalid call data: missing required fields');
        return;
      }

      // Prevent duplicate call notifications
      // This handles cases where both WebSocket and FCM deliver the same call
      if (_activeCallNotifications.containsKey(callId)) {
        AppLogger.info(
          '⏭️ Call $callId already being shown, skipping duplicate',
        );
        return;
      }

      // Create CallInvitation object for consistency with existing model
      final invitation = CallInvitation(
        callId: callId,
        callerId: callerId,
        callerName: callerName,
        callerPhoto: callerPhoto,
        recipientId: recipientId,
        callType: callType == 'VIDEO' ? CallType.video : CallType.audio,
        status: CallInvitationStatus.pending,
        conversationId: conversationId,
        groupId: groupId,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(seconds: 30)),
      );

      // Show native call UI
      await _showNativeCallUI(invitation);

      AppLogger.info('✅ Native call UI displayed for call: $callId');
    } catch (e) {
      AppLogger.error('❌ Error handling incoming call push: $e');
    }
  }

  /// Show native platform call UI
  ///
  /// Android: Full-screen intent with custom layout
  /// iOS: CallKit native call screen
  Future<void> _showNativeCallUI(CallInvitation invitation) async {
    try {
      // Generate unique UUID for flutter_callkit_incoming
      final callKitUuid = _uuid.v4();
      _activeCallNotifications[invitation.callId] = callKitUuid;

      // Prepare call data
      final params = CallKitParams(
        id: callKitUuid,
        nameCaller: invitation.callerName,
        appName: 'PulseLink',
        avatar: invitation.callerPhoto,
        handle: invitation.callerId,
        type: invitation.callType == CallType.video ? 1 : 0,
        duration: 30000, // 30 seconds timeout
        textAccept: 'Accept',
        textDecline: 'Decline',
        missedCallNotification: const NotificationParams(
          showNotification: true,
          isShowCallback: true,
          subtitle: 'Missed call',
          callbackText: 'Call back',
        ),
        extra: <String, dynamic>{
          'callId': invitation.callId,
          'callerId': invitation.callerId,
          'callerName': invitation.callerName,
          'callerPhoto': invitation.callerPhoto,
          'callType': invitation.callType.toString(),
          'conversationId': invitation.conversationId,
          'groupId': invitation.groupId,
        },
        headers: <String, dynamic>{'platform': 'flutter'},
        android: const AndroidParams(
          isCustomNotification: true,
          isShowLogo: false,
          ringtonePath: 'system_ringtone_default',
          backgroundColor: '#6E3BFF', // Pulse primary color
          backgroundUrl: '',
          actionColor: '#00C2FF', // Pulse accent color
          incomingCallNotificationChannelName: 'Incoming Calls',
          missedCallNotificationChannelName: 'Missed Calls',
        ),
        ios: const IOSParams(
          iconName: 'CallKitLogo',
          handleType: 'generic',
          supportsVideo: true,
          maximumCallGroups: 2,
          maximumCallsPerCallGroup: 1,
          audioSessionMode: 'default',
          audioSessionActive: true,
          audioSessionPreferredSampleRate: 44100.0,
          audioSessionPreferredIOBufferDuration: 0.005,
          supportsDTMF: true,
          supportsHolding: true,
          supportsGrouping: false,
          supportsUngrouping: false,
          ringtonePath: 'system_ringtone_default',
        ),
      );

      await FlutterCallkitIncoming.showCallkitIncoming(params);

      AppLogger.info('✅ Native call UI shown with CallKit UUID: $callKitUuid');
    } catch (e) {
      AppLogger.error('❌ Error showing native call UI: $e');
    }
  }

  /// Handle accept action from notification
  void _handleAcceptFromNotification(Map<String, dynamic>? body) {
    try {
      if (body == null) return;

      final extra = body['extra'] as Map<String, dynamic>?;
      if (extra == null) return;

      final callId = extra['callId'] as String?;
      if (callId == null) return;

      AppLogger.info('✅ User accepted call from notification: $callId');

      // Accept call via CallInvitationService
      _callInvitationService.acceptCall(callId);

      // Navigate to IncomingCallScreen
      _navigateToIncomingCallScreen(extra);

      // Clean up
      _cleanupCallNotification(callId);
    } catch (e) {
      AppLogger.error('❌ Error handling accept action: $e');
    }
  }

  /// Handle decline action from notification
  void _handleDeclineFromNotification(Map<String, dynamic>? body) {
    try {
      if (body == null) return;

      final extra = body['extra'] as Map<String, dynamic>?;
      if (extra == null) return;

      final callId = extra['callId'] as String?;
      if (callId == null) return;

      AppLogger.info('❌ User declined call from notification: $callId');

      // Decline call via CallInvitationService
      _callInvitationService.rejectCall(
        callId,
        reason: CallRejectionReason.userDeclined,
      );

      // Clean up
      _cleanupCallNotification(callId);
    } catch (e) {
      AppLogger.error('❌ Error handling decline action: $e');
    }
  }

  /// Handle call ended from notification
  void _handleCallEndedFromNotification(Map<String, dynamic>? body) {
    try {
      if (body == null) return;

      final extra = body['extra'] as Map<String, dynamic>?;
      if (extra == null) return;

      final callId = extra['callId'] as String?;
      if (callId == null) return;

      AppLogger.info('📞 Call ended from notification: $callId');

      // Clean up
      _cleanupCallNotification(callId);
    } catch (e) {
      AppLogger.error('❌ Error handling call ended: $e');
    }
  }

  /// Handle call timeout from notification
  void _handleCallTimeoutFromNotification(Map<String, dynamic>? body) {
    try {
      if (body == null) return;

      final extra = body['extra'] as Map<String, dynamic>?;
      if (extra == null) return;

      final callId = extra['callId'] as String?;
      if (callId == null) return;

      AppLogger.info('⏱️ Call timed out from notification: $callId');

      // Reject with timeout reason
      _callInvitationService.rejectCall(
        callId,
        reason: CallRejectionReason.timeout,
      );

      // Clean up
      _cleanupCallNotification(callId);
    } catch (e) {
      AppLogger.error('❌ Error handling call timeout: $e');
    }
  }

  /// Navigate to IncomingCallScreen with call data
  void _navigateToIncomingCallScreen(Map<String, dynamic> callData) {
    try {
      final navigator = AppRouter.navigatorKey.currentState;
      if (navigator == null) {
        AppLogger.error('❌ Navigator not available');
        return;
      }

      // Navigate to IncomingCallScreen (Sprint 1 UI)
      navigator.pushNamed(
        '/incoming-call',
        arguments: {
          'callId': callData['callId'],
          'callerId': callData['callerId'],
          'callerName': callData['callerName'],
          'callerPhoto': callData['callerPhoto'],
          'callType': callData['callType'],
          'conversationId': callData['conversationId'],
          'groupId': callData['groupId'],
        },
      );

      AppLogger.info('✅ Navigated to IncomingCallScreen');
    } catch (e) {
      AppLogger.error('❌ Error navigating to incoming call screen: $e');
    }
  }

  /// Dismiss call notification programmatically
  Future<void> dismissCallNotification(String callId) async {
    try {
      final callKitUuid = _activeCallNotifications[callId];
      if (callKitUuid != null) {
        await FlutterCallkitIncoming.endCall(callKitUuid);
        AppLogger.info('✅ Call notification dismissed: $callId');
      }

      _cleanupCallNotification(callId);
    } catch (e) {
      AppLogger.error('❌ Error dismissing call notification: $e');
    }
  }

  /// Clean up call notification tracking
  void _cleanupCallNotification(String callId) {
    _activeCallNotifications.remove(callId);
    AppLogger.info('🧹 Cleaned up call notification: $callId');
  }

  /// Get active call notifications (for debugging)
  Map<String, String> get activeCallNotifications =>
      Map.unmodifiable(_activeCallNotifications);

  /// Dispose resources
  void dispose() {
    _activeCallNotifications.clear();
  }
}
