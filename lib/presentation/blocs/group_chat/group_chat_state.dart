import 'package:equatable/equatable.dart';
import '../../../features/group_chat/data/models.dart';

/// Base state for Group Chat BLoC
abstract class GroupChatState extends Equatable {
  const GroupChatState();

  @override
  List<Object?> get props => [];
}

// ==================== INITIAL & LOADING STATES ====================

/// Initial state
class GroupChatInitial extends GroupChatState {
  const GroupChatInitial();
}

/// Loading active sessions
class GroupChatLoadingSessions extends GroupChatState {
  const GroupChatLoadingSessions();
}

/// Loading group details
class GroupChatLoadingDetails extends GroupChatState {
  const GroupChatLoadingDetails();
}

/// Creating live session
class GroupChatCreatingSession extends GroupChatState {
  const GroupChatCreatingSession();
}

/// Creating group
class GroupChatCreatingGroup extends GroupChatState {
  const GroupChatCreatingGroup();
}

/// Requesting to join
class GroupChatRequestingJoin extends GroupChatState {
  const GroupChatRequestingJoin();
}

/// Processing join request (approve/reject)
class GroupChatProcessingRequest extends GroupChatState {
  const GroupChatProcessingRequest();
}

/// Adding participant
class GroupChatAddingParticipant extends GroupChatState {
  const GroupChatAddingParticipant();
}

/// Removing participant
class GroupChatRemovingParticipant extends GroupChatState {
  const GroupChatRemovingParticipant();
}

/// Reporting user
class GroupChatReportingUser extends GroupChatState {
  const GroupChatReportingUser();
}

// ==================== SUCCESS STATES ====================

/// Active sessions loaded
class GroupChatSessionsLoaded extends GroupChatState {
  final List<LiveSession> sessions;
  final GroupType? filterType;

  const GroupChatSessionsLoaded({
    required this.sessions,
    this.filterType,
  });

  @override
  List<Object?> get props => [sessions, filterType];
}

/// Group details loaded
class GroupChatDetailsLoaded extends GroupChatState {
  final GroupConversation group;

  const GroupChatDetailsLoaded(this.group);

  @override
  List<Object?> get props => [group];
}

/// Live session created successfully
class GroupChatSessionCreated extends GroupChatState {
  final LiveSession session;

  const GroupChatSessionCreated(this.session);

  @override
  List<Object?> get props => [session];
}

/// Group created successfully
class GroupChatGroupCreated extends GroupChatState {
  final GroupConversation group;

  const GroupChatGroupCreated(this.group);

  @override
  List<Object?> get props => [group];
}

/// Join request sent successfully
class GroupChatJoinRequested extends GroupChatState {
  final JoinRequest request;

  const GroupChatJoinRequested(this.request);

  @override
  List<Object?> get props => [request];
}

/// Pending join requests loaded
class GroupChatPendingRequestsLoaded extends GroupChatState {
  final List<JoinRequest> requests;
  final String liveSessionId;

  const GroupChatPendingRequestsLoaded({
    required this.requests,
    required this.liveSessionId,
  });

  @override
  List<Object?> get props => [requests, liveSessionId];
}

/// Join request approved
class GroupChatRequestApproved extends GroupChatState {
  final String requestId;

  const GroupChatRequestApproved(this.requestId);

  @override
  List<Object?> get props => [requestId];
}

/// Join request rejected
class GroupChatRequestRejected extends GroupChatState {
  final String requestId;

  const GroupChatRequestRejected(this.requestId);

  @override
  List<Object?> get props => [requestId];
}

/// Participant added successfully
class GroupChatParticipantAdded extends GroupChatState {
  final String conversationId;
  final String userId;

  const GroupChatParticipantAdded({
    required this.conversationId,
    required this.userId,
  });

  @override
  List<Object?> get props => [conversationId, userId];
}

/// Participant removed successfully
class GroupChatParticipantRemoved extends GroupChatState {
  final String conversationId;
  final String userId;

  const GroupChatParticipantRemoved({
    required this.conversationId,
    required this.userId,
  });

  @override
  List<Object?> get props => [conversationId, userId];
}

/// User reported successfully
class GroupChatUserReported extends GroupChatState {
  const GroupChatUserReported();
}

// ==================== REAL-TIME UPDATE STATES ====================

/// New join request received (WebSocket)
class GroupChatJoinRequestReceived extends GroupChatState {
  final JoinRequest request;
  final List<JoinRequest> allRequests;

  const GroupChatJoinRequestReceived({
    required this.request,
    required this.allRequests,
  });

  @override
  List<Object?> get props => [request, allRequests];
}

/// Join request was approved (WebSocket)
class GroupChatJoinWasApproved extends GroupChatState {
  final JoinRequest request;

  const GroupChatJoinWasApproved(this.request);

  @override
  List<Object?> get props => [request];
}

/// Join request was rejected (WebSocket)
class GroupChatJoinWasRejected extends GroupChatState {
  final JoinRequest request;

  const GroupChatJoinWasRejected(this.request);

  @override
  List<Object?> get props => [request];
}

/// New participant joined (WebSocket)
class GroupChatParticipantJoinedLive extends GroupChatState {
  final GroupParticipant participant;

  const GroupChatParticipantJoinedLive(this.participant);

  @override
  List<Object?> get props => [participant];
}

/// Participant left (WebSocket)
class GroupChatParticipantLeftLive extends GroupChatState {
  final GroupParticipant participant;

  const GroupChatParticipantLeftLive(this.participant);

  @override
  List<Object?> get props => [participant];
}

/// Live session started (WebSocket)
class GroupChatSessionStartedLive extends GroupChatState {
  final LiveSession session;

  const GroupChatSessionStartedLive(this.session);

  @override
  List<Object?> get props => [session];
}

/// Live session ended (WebSocket)
class GroupChatSessionEndedLive extends GroupChatState {
  final LiveSession session;

  const GroupChatSessionEndedLive(this.session);

  @override
  List<Object?> get props => [session];
}

// ==================== ERROR STATES ====================

/// Error state
class GroupChatError extends GroupChatState {
  final String message;
  final String? details;

  const GroupChatError(this.message, {this.details});

  @override
  List<Object?> get props => [message, details];
}

// ==================== WEBSOCKET STATES ====================

/// WebSocket connected
class GroupChatWebSocketConnected extends GroupChatState {
  const GroupChatWebSocketConnected();
}

/// WebSocket disconnected
class GroupChatWebSocketDisconnected extends GroupChatState {
  const GroupChatWebSocketDisconnected();
}

/// WebSocket error
class GroupChatWebSocketError extends GroupChatState {
  final String error;

  const GroupChatWebSocketError(this.error);

  @override
  List<Object?> get props => [error];
}
