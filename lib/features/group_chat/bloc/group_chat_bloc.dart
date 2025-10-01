import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../data/models.dart';
import '../data/group_chat_service.dart';
import '../data/group_chat_websocket_service.dart';
import '../data/group_chat_webrtc_service.dart';
import 'dart:async';

// Events
abstract class GroupChatEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadActiveLiveSessions extends GroupChatEvent {
  final GroupType? filterByType;
  LoadActiveLiveSessions({this.filterByType});
  @override
  List<Object?> get props => [filterByType];
}

class LoadPendingJoinRequests extends GroupChatEvent {
  final String liveSessionId;
  LoadPendingJoinRequests(this.liveSessionId);
  @override
  List<Object?> get props => [liveSessionId];
}

class LoadUserGroups extends GroupChatEvent {}

class CreateLiveSession extends GroupChatEvent {
  final String conversationId;
  final String title;
  final String? description;
  final int? maxParticipants;
  final bool requireApproval;

  CreateLiveSession({
    required this.conversationId,
    required this.title,
    this.description,
    this.maxParticipants,
    this.requireApproval = true,
  });

  @override
  List<Object?> get props => [
        conversationId,
        title,
        description,
        maxParticipants,
        requireApproval,
      ];
}

class RequestToJoinSession extends GroupChatEvent {
  final String liveSessionId;
  final String? message;

  RequestToJoinSession({
    required this.liveSessionId,
    this.message,
  });

  @override
  List<Object?> get props => [liveSessionId, message];
}

class ApproveJoinRequest extends GroupChatEvent {
  final String requestId;
  ApproveJoinRequest(this.requestId);
  @override
  List<Object?> get props => [requestId];
}

class RejectJoinRequest extends GroupChatEvent {
  final String requestId;
  RejectJoinRequest(this.requestId);
  @override
  List<Object?> get props => [requestId];
}

class JoinLiveSessionRoom extends GroupChatEvent {
  final String liveSessionId;
  JoinLiveSessionRoom(this.liveSessionId);
  @override
  List<Object?> get props => [liveSessionId];
}

class LeaveLiveSessionRoom extends GroupChatEvent {
  final String liveSessionId;
  LeaveLiveSessionRoom(this.liveSessionId);
  @override
  List<Object?> get props => [liveSessionId];
}

class CreateGroup extends GroupChatEvent {
  final String title;
  final GroupType groupType;
  final List<String> participantUserIds;
  final int maxParticipants;
  final bool allowParticipantInvite;
  final bool requireApproval;
  final bool autoAcceptFriends;
  final bool enableVoiceChat;
  final bool enableVideoChat;

  CreateGroup({
    required this.title,
    required this.groupType,
    required this.participantUserIds,
    this.maxParticipants = 50,
    this.allowParticipantInvite = true,
    this.requireApproval = false,
    this.autoAcceptFriends = true,
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
        autoAcceptFriends,
        enableVoiceChat,
        enableVideoChat,
      ];
}

// Real-time events
class NewJoinRequestReceived extends GroupChatEvent {
  final JoinRequest request;
  NewJoinRequestReceived(this.request);
  @override
  List<Object?> get props => [request];
}

class JoinRequestApprovedEvent extends GroupChatEvent {
  final JoinRequest request;
  JoinRequestApprovedEvent(this.request);
  @override
  List<Object?> get props => [request];
}

class JoinRequestRejectedEvent extends GroupChatEvent {
  final JoinRequest request;
  JoinRequestRejectedEvent(this.request);
  @override
  List<Object?> get props => [request];
}

class NewLiveSessionStarted extends GroupChatEvent {
  final LiveSession session;
  NewLiveSessionStarted(this.session);
  @override
  List<Object?> get props => [session];
}

class LiveSessionEndedEvent extends GroupChatEvent {
  final LiveSession session;
  LiveSessionEndedEvent(this.session);
  @override
  List<Object?> get props => [session];
}

class JoinGroup extends GroupChatEvent {
  final String conversationId;
  JoinGroup(this.conversationId);
  @override
  List<Object?> get props => [conversationId];
}

class LeaveGroup extends GroupChatEvent {
  final String conversationId;
  LeaveGroup(this.conversationId);
  @override
  List<Object?> get props => [conversationId];
}

class SendTypingIndicator extends GroupChatEvent {
  final String conversationId;
  final bool isTyping;
  SendTypingIndicator({required this.conversationId, required this.isTyping});
  @override
  List<Object?> get props => [conversationId, isTyping];
}

class StartVideoCall extends GroupChatEvent {
  final String liveSessionId;
  final String token;
  final bool enableVideo;
  StartVideoCall({
    required this.liveSessionId,
    required this.token,
    this.enableVideo = true,
  });
  @override
  List<Object?> get props => [liveSessionId, token, enableVideo];
}

class EndVideoCall extends GroupChatEvent {}

class ToggleMute extends GroupChatEvent {}

class ToggleVideo extends GroupChatEvent {}

class ToggleSpeaker extends GroupChatEvent {}

class SwitchCamera extends GroupChatEvent {}

// States
abstract class GroupChatState extends Equatable {
  @override
  List<Object?> get props => [];
}

class GroupChatInitial extends GroupChatState {}

class GroupChatLoading extends GroupChatState {}

class GroupChatLoaded extends GroupChatState {
  final List<LiveSession> liveSessions;
  final List<JoinRequest> pendingRequests;
  final GroupConversation? currentGroup;
  final List<GroupConversation> userGroups;
  final List<LiveSession> activeLiveSessions;

  GroupChatLoaded({
    this.liveSessions = const [],
    this.pendingRequests = const [],
    this.currentGroup,
    this.userGroups = const [],
    this.activeLiveSessions = const [],
  });

  GroupChatLoaded copyWith({
    List<LiveSession>? liveSessions,
    List<JoinRequest>? pendingRequests,
    GroupConversation? currentGroup,
    List<GroupConversation>? userGroups,
    List<LiveSession>? activeLiveSessions,
  }) {
    return GroupChatLoaded(
      liveSessions: liveSessions ?? this.liveSessions,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      currentGroup: currentGroup ?? this.currentGroup,
      userGroups: userGroups ?? this.userGroups,
      activeLiveSessions: activeLiveSessions ?? this.activeLiveSessions,
    );
  }

  @override
  List<Object?> get props => [
    liveSessions,
    pendingRequests,
    currentGroup,
    userGroups,
    activeLiveSessions,
  ];
}

class GroupChatError extends GroupChatState {
  final String message;
  GroupChatError(this.message);
  @override
  List<Object?> get props => [message];
}

class LiveSessionCreated extends GroupChatState {
  final LiveSession session;
  LiveSessionCreated(this.session);
  @override
  List<Object?> get props => [session];
}

class JoinRequestSent extends GroupChatState {
  final JoinRequest request;
  JoinRequestSent(this.request);
  @override
  List<Object?> get props => [request];
}

class GroupCreated extends GroupChatState {
  final GroupConversation group;
  GroupCreated(this.group);
  @override
  List<Object?> get props => [group];
}

class VideoCallStarted extends GroupChatState {
  final String liveSessionId;
  final int localUid;
  VideoCallStarted({required this.liveSessionId, required this.localUid});
  @override
  List<Object?> get props => [liveSessionId, localUid];
}

class VideoCallEnded extends GroupChatState {}

class VideoCallError extends GroupChatState {
  final String message;
  VideoCallError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class GroupChatBloc extends Bloc<GroupChatEvent, GroupChatState> {
  final GroupChatService service;
  final GroupChatWebSocketService wsService;
  final GroupChatWebRTCService? webrtcService;
  StreamSubscription? _joinRequestSubscription;
  StreamSubscription? _approvedSubscription;
  StreamSubscription? _rejectedSubscription;
  StreamSubscription? _sessionStartedSubscription;
  StreamSubscription? _sessionEndedSubscription;

  GroupChatBloc({
    required this.service,
    required this.wsService,
    this.webrtcService,
  }) : super(GroupChatInitial()) {
    // Connect to WebSocket
    wsService.connect();

    // Setup real-time listeners
    _setupWebSocketListeners();

    // Event handlers
    on<LoadActiveLiveSessions>(_onLoadActiveLiveSessions);
    on<LoadPendingJoinRequests>(_onLoadPendingJoinRequests);
    on<LoadUserGroups>(_onLoadUserGroups);
    on<CreateLiveSession>(_onCreateLiveSession);
    on<RequestToJoinSession>(_onRequestToJoinSession);
    on<ApproveJoinRequest>(_onApproveJoinRequest);
    on<RejectJoinRequest>(_onRejectJoinRequest);
    on<JoinLiveSessionRoom>(_onJoinLiveSessionRoom);
    on<LeaveLiveSessionRoom>(_onLeaveLiveSessionRoom);
    on<JoinGroup>(_onJoinGroup);
    on<LeaveGroup>(_onLeaveGroup);
    on<SendTypingIndicator>(_onSendTypingIndicator);
    on<CreateGroup>(_onCreateGroup);

    // Real-time event handlers
    on<NewJoinRequestReceived>(_onNewJoinRequestReceived);
    on<JoinRequestApprovedEvent>(_onJoinRequestApprovedEvent);
    on<JoinRequestRejectedEvent>(_onJoinRequestRejectedEvent);
    on<NewLiveSessionStarted>(_onNewLiveSessionStarted);
    on<LiveSessionEndedEvent>(_onLiveSessionEndedEvent);

    // Video call event handlers
    on<StartVideoCall>(_onStartVideoCall);
    on<EndVideoCall>(_onEndVideoCall);
    on<ToggleMute>(_onToggleMute);
    on<ToggleVideo>(_onToggleVideo);
    on<ToggleSpeaker>(_onToggleSpeaker);
    on<SwitchCamera>(_onSwitchCamera);
  }

  void _setupWebSocketListeners() {
    _joinRequestSubscription = wsService.onJoinRequestReceived.listen((request) {
      add(NewJoinRequestReceived(request));
    });

    _approvedSubscription = wsService.onJoinRequestApproved.listen((request) {
      add(JoinRequestApprovedEvent(request));
    });

    _rejectedSubscription = wsService.onJoinRequestRejected.listen((request) {
      add(JoinRequestRejectedEvent(request));
    });

    _sessionStartedSubscription = wsService.onLiveSessionStarted.listen((session) {
      add(NewLiveSessionStarted(session));
    });

    _sessionEndedSubscription = wsService.onLiveSessionEnded.listen((session) {
      add(LiveSessionEndedEvent(session));
    });
  }

  Future<void> _onLoadActiveLiveSessions(
    LoadActiveLiveSessions event,
    Emitter<GroupChatState> emit,
  ) async {
    emit(GroupChatLoading());
    try {
      final sessions = await service.getActiveLiveSessions(
        groupType: event.filterByType,
      );
      emit(GroupChatLoaded(liveSessions: sessions));
    } catch (e) {
      emit(GroupChatError('Failed to load live sessions: $e'));
    }
  }

  Future<void> _onLoadPendingJoinRequests(
    LoadPendingJoinRequests event,
    Emitter<GroupChatState> emit,
  ) async {
    emit(GroupChatLoading());
    try {
      final requests = await service.getPendingJoinRequests(event.liveSessionId);
      emit(GroupChatLoaded(pendingRequests: requests));
    } catch (e) {
      emit(GroupChatError('Failed to load join requests: $e'));
    }
  }

  Future<void> _onCreateLiveSession(
    CreateLiveSession event,
    Emitter<GroupChatState> emit,
  ) async {
    emit(GroupChatLoading());
    try {
      final session = await service.createLiveSession(
        conversationId: event.conversationId,
        title: event.title,
        description: event.description,
        maxParticipants: event.maxParticipants,
        requireApproval: event.requireApproval,
      );
      emit(LiveSessionCreated(session));
    } catch (e) {
      emit(GroupChatError('Failed to create live session: $e'));
    }
  }

  Future<void> _onRequestToJoinSession(
    RequestToJoinSession event,
    Emitter<GroupChatState> emit,
  ) async {
    emit(GroupChatLoading());
    try {
      final request = await service.requestToJoinSession(
        liveSessionId: event.liveSessionId,
        message: event.message,
      );
      emit(JoinRequestSent(request));
    } catch (e) {
      emit(GroupChatError('Failed to send join request: $e'));
    }
  }

  Future<void> _onApproveJoinRequest(
    ApproveJoinRequest event,
    Emitter<GroupChatState> emit,
  ) async {
    try {
      await service.approveJoinRequest(event.requestId);
      // Reload pending requests
      if (state is GroupChatLoaded) {
        final currentState = state as GroupChatLoaded;
        final updatedRequests = currentState.pendingRequests
            .where((r) => r.id != event.requestId)
            .toList();
        emit(currentState.copyWith(pendingRequests: updatedRequests));
      }
    } catch (e) {
      emit(GroupChatError('Failed to approve request: $e'));
    }
  }

  Future<void> _onRejectJoinRequest(
    RejectJoinRequest event,
    Emitter<GroupChatState> emit,
  ) async {
    try {
      await service.rejectJoinRequest(event.requestId);
      // Reload pending requests
      if (state is GroupChatLoaded) {
        final currentState = state as GroupChatLoaded;
        final updatedRequests = currentState.pendingRequests
            .where((r) => r.id != event.requestId)
            .toList();
        emit(currentState.copyWith(pendingRequests: updatedRequests));
      }
    } catch (e) {
      emit(GroupChatError('Failed to reject request: $e'));
    }
  }

  void _onJoinLiveSessionRoom(
    JoinLiveSessionRoom event,
    Emitter<GroupChatState> emit,
  ) {
    wsService.joinLiveSession(event.liveSessionId);
  }

  void _onLeaveLiveSessionRoom(
    LeaveLiveSessionRoom event,
    Emitter<GroupChatState> emit,
  ) {
    wsService.leaveLiveSession(event.liveSessionId);
  }

  Future<void> _onCreateGroup(
    CreateGroup event,
    Emitter<GroupChatState> emit,
  ) async {
    emit(GroupChatLoading());
    try {
      final group = await service.createGroup(
        title: event.title,
        groupType: event.groupType,
        participantUserIds: event.participantUserIds,
        maxParticipants: event.maxParticipants,
        allowParticipantInvite: event.allowParticipantInvite,
        requireApproval: event.requireApproval,
        autoAcceptFriends: event.autoAcceptFriends,
        enableVoiceChat: event.enableVoiceChat,
        enableVideoChat: event.enableVideoChat,
      );
      emit(GroupCreated(group));
    } catch (e) {
      emit(GroupChatError('Failed to create group: $e'));
    }
  }

  void _onNewJoinRequestReceived(
    NewJoinRequestReceived event,
    Emitter<GroupChatState> emit,
  ) {
    if (state is GroupChatLoaded) {
      final currentState = state as GroupChatLoaded;
      final updatedRequests = [...currentState.pendingRequests, event.request];
      emit(currentState.copyWith(pendingRequests: updatedRequests));
    }
  }

  void _onJoinRequestApprovedEvent(
    JoinRequestApprovedEvent event,
    Emitter<GroupChatState> emit,
  ) {
    // Handle approved notification for requester
    // Could navigate to session or show success message
  }

  void _onJoinRequestRejectedEvent(
    JoinRequestRejectedEvent event,
    Emitter<GroupChatState> emit,
  ) {
    // Handle rejected notification for requester
    // Could show error message
  }

  void _onNewLiveSessionStarted(
    NewLiveSessionStarted event,
    Emitter<GroupChatState> emit,
  ) {
    if (state is GroupChatLoaded) {
      final currentState = state as GroupChatLoaded;
      final updatedSessions = [...currentState.liveSessions, event.session];
      emit(currentState.copyWith(liveSessions: updatedSessions));
    }
  }

  void _onLiveSessionEndedEvent(
    LiveSessionEndedEvent event,
    Emitter<GroupChatState> emit,
  ) {
    if (state is GroupChatLoaded) {
      final currentState = state as GroupChatLoaded;
      final updatedSessions = currentState.liveSessions
          .where((s) => s.id != event.session.id)
          .toList();
      emit(currentState.copyWith(liveSessions: updatedSessions));
    }
  }

  Future<void> _onLoadUserGroups(
    LoadUserGroups event,
    Emitter<GroupChatState> emit,
  ) async {
    emit(GroupChatLoading());
    try {
      final groups = await service.getUserGroups();
      emit(GroupChatLoaded(userGroups: groups));
    } catch (e) {
      emit(GroupChatError('Failed to load groups: $e'));
    }
  }

  void _onJoinGroup(JoinGroup event, Emitter<GroupChatState> emit) {
    wsService.joinGroup(event.conversationId);
  }

  void _onLeaveGroup(LeaveGroup event, Emitter<GroupChatState> emit) {
    wsService.leaveGroup(event.conversationId);
  }

  void _onSendTypingIndicator(
    SendTypingIndicator event,
    Emitter<GroupChatState> emit,
  ) {
    wsService.sendTypingIndicator(
      conversationId: event.conversationId,
      isTyping: event.isTyping,
    );
  }

  // Video call handlers
  Future<void> _onStartVideoCall(
    StartVideoCall event,
    Emitter<GroupChatState> emit,
  ) async {
    if (webrtcService == null) {
      emit(VideoCallError('WebRTC service not initialized'));
      return;
    }

    try {
      emit(GroupChatLoading());
      await webrtcService!.joinCall(
        channelId: event.liveSessionId,
        token: event.token,
        enableVideo: event.enableVideo,
      );

      final localUid = webrtcService!.localUid;
      if (localUid != null) {
        emit(
          VideoCallStarted(
            liveSessionId: event.liveSessionId,
            localUid: localUid,
          ),
        );
      }
    } catch (e) {
      emit(VideoCallError('Failed to start video call: $e'));
    }
  }

  Future<void> _onEndVideoCall(
    EndVideoCall event,
    Emitter<GroupChatState> emit,
  ) async {
    if (webrtcService == null) return;

    try {
      await webrtcService!.leaveCall();
      emit(VideoCallEnded());
    } catch (e) {
      emit(VideoCallError('Failed to end video call: $e'));
    }
  }

  Future<void> _onToggleMute(
    ToggleMute event,
    Emitter<GroupChatState> emit,
  ) async {
    if (webrtcService == null) return;

    try {
      await webrtcService!.toggleMute();
    } catch (e) {
      emit(VideoCallError('Failed to toggle mute: $e'));
    }
  }

  Future<void> _onToggleVideo(
    ToggleVideo event,
    Emitter<GroupChatState> emit,
  ) async {
    if (webrtcService == null) return;

    try {
      await webrtcService!.toggleVideo();
    } catch (e) {
      emit(VideoCallError('Failed to toggle video: $e'));
    }
  }

  Future<void> _onToggleSpeaker(
    ToggleSpeaker event,
    Emitter<GroupChatState> emit,
  ) async {
    if (webrtcService == null) return;

    try {
      await webrtcService!.toggleSpeaker();
    } catch (e) {
      emit(VideoCallError('Failed to toggle speaker: $e'));
    }
  }

  Future<void> _onSwitchCamera(
    SwitchCamera event,
    Emitter<GroupChatState> emit,
  ) async {
    if (webrtcService == null) return;

    try {
      await webrtcService!.switchCamera();
    } catch (e) {
      emit(VideoCallError('Failed to switch camera: $e'));
    }
  }

  @override
  Future<void> close() {
    _joinRequestSubscription?.cancel();
    _approvedSubscription?.cancel();
    _rejectedSubscription?.cancel();
    _sessionStartedSubscription?.cancel();
    _sessionEndedSubscription?.cancel();
    wsService.disconnect();
    return super.close();
  }
}
