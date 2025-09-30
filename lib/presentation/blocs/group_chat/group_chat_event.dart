import 'package:equatable/equatable.dart';
import '../../../features/group_chat/data/models.dart';

/// Base event for Group Chat BLoC
abstract class GroupChatEvent extends Equatable {
  const GroupChatEvent();

  @override
  List<Object?> get props => [];
}

// ==================== LIVE SESSION EVENTS ====================

/// Load active live sessions
class LoadActiveLiveSessions extends GroupChatEvent {
  final GroupType? filterType;

  const LoadActiveLiveSessions({this.filterType});

  @override
  List<Object?> get props => [filterType];
}

/// Create a new live session
class CreateLiveSession extends GroupChatEvent {
  final String title;
  final String? description;
  final int? maxParticipants;
  final bool requireApproval;

  const CreateLiveSession({
    required this.title,
    this.description,
    this.maxParticipants,
    this.requireApproval = true,
  });

  @override
  List<Object?> get props => [title, description, maxParticipants, requireApproval];
}

/// Request to join a live session
class RequestToJoinLiveSession extends GroupChatEvent {
  final String liveSessionId;
  final String? message;

  const RequestToJoinLiveSession({
    required this.liveSessionId,
    this.message,
  });

  @override
  List<Object?> get props => [liveSessionId, message];
}

/// Load pending join requests (for host)
class LoadPendingJoinRequests extends GroupChatEvent {
  final String liveSessionId;

  const LoadPendingJoinRequests(this.liveSessionId);

  @override
  List<Object?> get props => [liveSessionId];
}

/// Approve a join request (host only)
class ApproveJoinRequest extends GroupChatEvent {
  final String requestId;

  const ApproveJoinRequest(this.requestId);

  @override
  List<Object?> get props => [requestId];
}

/// Reject a join request (host only)
class RejectJoinRequest extends GroupChatEvent {
  final String requestId;

  const RejectJoinRequest(this.requestId);

  @override
  List<Object?> get props => [requestId];
}

// ==================== GROUP MANAGEMENT EVENTS ====================

/// Create a new group conversation
class CreateGroupConversation extends GroupChatEvent {
  final String title;
  final GroupType groupType;
  final List<String> participantUserIds;
  final int maxParticipants;
  final bool allowParticipantInvite;
  final bool requireApproval;
  final bool enableVoiceChat;
  final bool enableVideoChat;

  const CreateGroupConversation({
    required this.title,
    required this.groupType,
    required this.participantUserIds,
    this.maxParticipants = 50,
    this.allowParticipantInvite = true,
    this.requireApproval = false,
    this.enableVoiceChat = true,
    this.enableVideoChat = false,
  });

  @override
  List<Object?> get props => [
        title,
        groupType,
        participantUserIds,
        maxParticipants,
        allowParticipantInvite,
        requireApproval,
        enableVoiceChat,
        enableVideoChat,
      ];
}

/// Load group details
class LoadGroupDetails extends GroupChatEvent {
  final String conversationId;

  const LoadGroupDetails(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

/// Add participant to group (admin only)
class AddParticipantToGroup extends GroupChatEvent {
  final String conversationId;
  final String userId;
  final ParticipantRole role;

  const AddParticipantToGroup({
    required this.conversationId,
    required this.userId,
    this.role = ParticipantRole.member,
  });

  @override
  List<Object?> get props => [conversationId, userId, role];
}

/// Remove participant from group (admin only)
class RemoveParticipantFromGroup extends GroupChatEvent {
  final String conversationId;
  final String userId;
  final String? reason;

  const RemoveParticipantFromGroup({
    required this.conversationId,
    required this.userId,
    this.reason,
  });

  @override
  List<Object?> get props => [conversationId, userId, reason];
}

// ==================== MODERATION EVENTS ====================

/// Report a user in group chat
class ReportGroupUser extends GroupChatEvent {
  final String conversationId;
  final String reportedUserId;
  final String reason;
  final String? description;

  const ReportGroupUser({
    required this.conversationId,
    required this.reportedUserId,
    required this.reason,
    this.description,
  });

  @override
  List<Object?> get props => [conversationId, reportedUserId, reason, description];
}

// ==================== REAL-TIME EVENTS ====================

/// Join request received (WebSocket event)
class JoinRequestReceived extends GroupChatEvent {
  final JoinRequest request;

  const JoinRequestReceived(this.request);

  @override
  List<Object?> get props => [request];
}

/// Join request approved (WebSocket event)
class JoinRequestApproved extends GroupChatEvent {
  final JoinRequest request;

  const JoinRequestApproved(this.request);

  @override
  List<Object?> get props => [request];
}

/// Join request rejected (WebSocket event)
class JoinRequestRejected extends GroupChatEvent {
  final JoinRequest request;

  const JoinRequestRejected(this.request);

  @override
  List<Object?> get props => [request];
}

/// Participant joined (WebSocket event)
class ParticipantJoined extends GroupChatEvent {
  final GroupParticipant participant;

  const ParticipantJoined(this.participant);

  @override
  List<Object?> get props => [participant];
}

/// Participant left (WebSocket event)
class ParticipantLeft extends GroupChatEvent {
  final GroupParticipant participant;

  const ParticipantLeft(this.participant);

  @override
  List<Object?> get props => [participant];
}

/// Live session started (WebSocket event)
class LiveSessionStarted extends GroupChatEvent {
  final LiveSession session;

  const LiveSessionStarted(this.session);

  @override
  List<Object?> get props => [session];
}

/// Live session ended (WebSocket event)
class LiveSessionEnded extends GroupChatEvent {
  final LiveSession session;

  const LiveSessionEnded(this.session);

  @override
  List<Object?> get props => [session];
}

// ==================== UTILITY EVENTS ====================

/// Refresh group chat data
class RefreshGroupChatData extends GroupChatEvent {
  const RefreshGroupChatData();
}

/// Clear error state
class ClearGroupChatError extends GroupChatEvent {
  const ClearGroupChatError();
}

/// Initialize WebSocket connection
class InitializeGroupChatWebSocket extends GroupChatEvent {
  const InitializeGroupChatWebSocket();
}

/// Disconnect WebSocket
class DisconnectGroupChatWebSocket extends GroupChatEvent {
  const DisconnectGroupChatWebSocket();
}
