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

/// Load user's groups
class LoadUserGroups extends GroupChatEvent {
  const LoadUserGroups();
}

/// Create a new group conversation
class CreateGroupConversation extends GroupChatEvent {
  final String title;
  final String? description;
  final GroupType groupType;
  final List<String> participantUserIds;
  final bool requireApproval;

  const CreateGroupConversation({
    required this.title,
    this.description,
    required this.groupType,
    required this.participantUserIds,
    this.requireApproval = false,
  });

  @override
  List<Object?> get props => [
        title,
    description,
        groupType,
        participantUserIds,
    requireApproval,
      ];
}

/// Join a group/conversation WebSocket room
class JoinGroup extends GroupChatEvent {
  final String conversationId;

  const JoinGroup(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

/// Leave a group/conversation WebSocket room
class LeaveGroup extends GroupChatEvent {
  final String conversationId;

  const LeaveGroup(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
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

// ==================== MESSAGING EVENTS ====================

/// Load messages for a conversation
class LoadMessages extends GroupChatEvent {
  final String conversationId;

  const LoadMessages(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

/// Send a message
class SendMessage extends GroupChatEvent {
  final String conversationId;
  final String content;
  final String type;
  final String? replyToMessageId;
  final String? tempId;

  const SendMessage({
    required this.conversationId,
    required this.content,
    this.type = 'text',
    this.replyToMessageId,
    this.tempId,
  });

  @override
  List<Object?> get props => [
    conversationId,
    content,
    type,
    replyToMessageId,
    tempId,
  ];
}

/// Message received (WebSocket event)
class MessageReceived extends GroupChatEvent {
  final GroupMessage message;

  const MessageReceived(this.message);

  @override
  List<Object?> get props => [message];
}

/// Message confirmed by server (WebSocket event)
class MessageConfirmed extends GroupChatEvent {
  final GroupMessage message;

  const MessageConfirmed(this.message);

  @override
  List<Object?> get props => [message];
}

/// Delete a message
class DeleteMessage extends GroupChatEvent {
  final String messageId;
  final String conversationId;

  const DeleteMessage({
    required this.messageId,
    required this.conversationId,
  });

  @override
  List<Object?> get props => [messageId, conversationId];
}

/// Add reaction to message
class AddReaction extends GroupChatEvent {
  final String messageId;
  final String conversationId;
  final String emoji;

  const AddReaction({
    required this.messageId,
    required this.conversationId,
    required this.emoji,
  });

  @override
  List<Object?> get props => [messageId, conversationId, emoji];
}

/// Remove reaction from message
class RemoveReaction extends GroupChatEvent {
  final String messageId;
  final String conversationId;
  final String emoji;

  const RemoveReaction({
    required this.messageId,
    required this.conversationId,
    required this.emoji,
  });

  @override
  List<Object?> get props => [messageId, conversationId, emoji];
}

/// Mark message as read
class MarkMessageAsRead extends GroupChatEvent {
  final String messageId;
  final String conversationId;

  const MarkMessageAsRead({
    required this.messageId,
    required this.conversationId,
  });

  @override
  List<Object?> get props => [messageId, conversationId];
}

/// Search messages in conversation
class SearchMessages extends GroupChatEvent {
  final String conversationId;
  final String query;

  const SearchMessages({
    required this.conversationId,
    required this.query,
  });

  @override
  List<Object?> get props => [conversationId, query];
}

/// Clear message search results
class ClearMessageSearch extends GroupChatEvent {
  const ClearMessageSearch();
}

/// Send typing indicator
class SendTypingIndicator extends GroupChatEvent {
  final String conversationId;
  final bool isTyping;

  const SendTypingIndicator({
    required this.conversationId,
    required this.isTyping,
  });

  @override
  List<Object?> get props => [conversationId, isTyping];
}

/// Typing indicator received (WebSocket event)
class TypingIndicatorReceived extends GroupChatEvent {
  final String userId;
  final String username;
  final bool isTyping;

  const TypingIndicatorReceived({
    required this.userId,
    required this.username,
    required this.isTyping,
  });

  @override
  List<Object?> get props => [userId, username, isTyping];
}

// ==================== WEBRTC/VIDEO CALL EVENTS ====================

/// Start video call
class StartVideoCall extends GroupChatEvent {
  final String liveSessionId;
  final String token;
  final bool enableVideo;

  const StartVideoCall({
    required this.liveSessionId,
    required this.token,
    this.enableVideo = true,
  });

  @override
  List<Object?> get props => [liveSessionId, token, enableVideo];
}

/// End video call
class EndVideoCall extends GroupChatEvent {
  const EndVideoCall();
}

/// Toggle microphone mute
class ToggleMute extends GroupChatEvent {
  const ToggleMute();
}

/// Toggle video on/off
class ToggleVideo extends GroupChatEvent {
  const ToggleVideo();
}

/// Toggle speaker on/off
class ToggleSpeaker extends GroupChatEvent {
  const ToggleSpeaker();
}

/// Switch camera (front/back)
class SwitchCamera extends GroupChatEvent {
  const SwitchCamera();
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
