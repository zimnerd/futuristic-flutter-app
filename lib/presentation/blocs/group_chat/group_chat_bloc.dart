import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import '../../../features/group_chat/data/group_chat_service.dart';
import '../../../features/group_chat/data/group_chat_websocket_service.dart';
import '../../../features/group_chat/data/models.dart';
import 'group_chat_event.dart';
import 'group_chat_state.dart';

/// BLoC for managing Group Chat state and operations
class GroupChatBloc extends Bloc<GroupChatEvent, GroupChatState> {
  final GroupChatService _groupChatService;
  final GroupChatWebSocketService _webSocketService;
  final Logger _logger = Logger();

  // WebSocket subscription management
  StreamSubscription<JoinRequest>? _joinRequestReceivedSub;
  StreamSubscription<JoinRequest>? _joinRequestApprovedSub;
  StreamSubscription<JoinRequest>? _joinRequestRejectedSub;
  StreamSubscription<GroupParticipant>? _participantJoinedSub;
  StreamSubscription<GroupParticipant>? _participantLeftSub;
  StreamSubscription<LiveSession>? _liveSessionStartedSub;
  StreamSubscription<LiveSession>? _liveSessionEndedSub;

  // Cache for pending requests
  final Map<String, List<JoinRequest>> _pendingRequestsCache = {};

  GroupChatBloc({
    required GroupChatService groupChatService,
    required GroupChatWebSocketService webSocketService,
  })  : _groupChatService = groupChatService,
        _webSocketService = webSocketService,
        super(const GroupChatInitial()) {
    // Register event handlers
    on<LoadActiveLiveSessions>(_onLoadActiveLiveSessions);
    on<CreateLiveSession>(_onCreateLiveSession);
    on<RequestToJoinLiveSession>(_onRequestToJoinLiveSession);
    on<LoadPendingJoinRequests>(_onLoadPendingJoinRequests);
    on<ApproveJoinRequest>(_onApproveJoinRequest);
    on<RejectJoinRequest>(_onRejectJoinRequest);
    on<CreateGroupConversation>(_onCreateGroupConversation);
    on<LoadGroupDetails>(_onLoadGroupDetails);
    on<AddParticipantToGroup>(_onAddParticipantToGroup);
    on<RemoveParticipantFromGroup>(_onRemoveParticipantFromGroup);
    on<ReportGroupUser>(_onReportGroupUser);
    on<RefreshGroupChatData>(_onRefreshGroupChatData);
    on<ClearGroupChatError>(_onClearGroupChatError);
    on<InitializeGroupChatWebSocket>(_onInitializeGroupChatWebSocket);
    on<DisconnectGroupChatWebSocket>(_onDisconnectGroupChatWebSocket);

    // Real-time WebSocket event handlers
    on<JoinRequestReceived>(_onJoinRequestReceived);
    on<JoinRequestApproved>(_onJoinRequestApproved);
    on<JoinRequestRejected>(_onJoinRequestRejected);
    on<ParticipantJoined>(_onParticipantJoined);
    on<ParticipantLeft>(_onParticipantLeft);
    on<LiveSessionStarted>(_onLiveSessionStarted);
    on<LiveSessionEnded>(_onLiveSessionEnded);
  }

  // ==================== HTTP EVENT HANDLERS ====================

  Future<void> _onLoadActiveLiveSessions(
    LoadActiveLiveSessions event,
    Emitter<GroupChatState> emit,
  ) async {
    try {
      emit(const GroupChatLoadingSessions());
      _logger.i('📡 Loading active live sessions...');

      final sessions = await _groupChatService.getActiveLiveSessions(
        groupType: event.filterType,
      );

      emit(GroupChatSessionsLoaded(
        sessions: sessions,
        filterType: event.filterType,
      ));
      _logger.i('✅ Loaded ${sessions.length} active sessions');
    } catch (e) {
      _logger.e('❌ Failed to load sessions: $e');
      emit(GroupChatError(
        'Failed to load active sessions',
        details: e.toString(),
      ));
    }
  }

  Future<void> _onCreateLiveSession(
    CreateLiveSession event,
    Emitter<GroupChatState> emit,
  ) async {
    try {
      emit(const GroupChatCreatingSession());
      _logger.i('🎥 Creating live session: ${event.title}');

      // Get current user's conversation ID (would come from auth or profile)
      // For now, we'll create a session directly
      final session = await _groupChatService.createLiveSession(
        conversationId: '', // Will be created by backend
        title: event.title,
        description: event.description,
        maxParticipants: event.maxParticipants,
        requireApproval: event.requireApproval,
      );

      emit(GroupChatSessionCreated(session));
      _logger.i('✅ Live session created: ${session.id}');

      // Reload sessions to show the new one
      add(const LoadActiveLiveSessions());
    } catch (e) {
      _logger.e('❌ Failed to create session: $e');
      emit(GroupChatError(
        'Failed to create live session',
        details: e.toString(),
      ));
    }
  }

  Future<void> _onRequestToJoinLiveSession(
    RequestToJoinLiveSession event,
    Emitter<GroupChatState> emit,
  ) async {
    try {
      emit(const GroupChatRequestingJoin());
      _logger.i('🙋 Requesting to join session: ${event.liveSessionId}');

      final request = await _groupChatService.requestToJoinSession(
        liveSessionId: event.liveSessionId,
        message: event.message,
      );

      emit(GroupChatJoinRequested(request));
      _logger.i('✅ Join request sent: ${request.id}');
    } catch (e) {
      _logger.e('❌ Failed to request join: $e');
      emit(GroupChatError(
        'Failed to send join request',
        details: e.toString(),
      ));
    }
  }

  Future<void> _onLoadPendingJoinRequests(
    LoadPendingJoinRequests event,
    Emitter<GroupChatState> emit,
  ) async {
    try {
      _logger.i('📋 Loading pending requests for session: ${event.liveSessionId}');

      final requests = await _groupChatService.getPendingJoinRequests(
        event.liveSessionId,
      );

      // Cache the requests
      _pendingRequestsCache[event.liveSessionId] = requests;

      emit(GroupChatPendingRequestsLoaded(
        requests: requests,
        liveSessionId: event.liveSessionId,
      ));
      _logger.i('✅ Loaded ${requests.length} pending requests');
    } catch (e) {
      _logger.e('❌ Failed to load requests: $e');
      emit(GroupChatError(
        'Failed to load join requests',
        details: e.toString(),
      ));
    }
  }

  Future<void> _onApproveJoinRequest(
    ApproveJoinRequest event,
    Emitter<GroupChatState> emit,
  ) async {
    try {
      emit(const GroupChatProcessingRequest());
      _logger.i('✅ Approving join request: ${event.requestId}');

      await _groupChatService.approveJoinRequest(event.requestId);

      emit(GroupChatRequestApproved(event.requestId));
      _logger.i('✅ Request approved');

      // Refresh pending requests if we have the session ID cached
      for (final entry in _pendingRequestsCache.entries) {
        if (entry.value.any((r) => r.id == event.requestId)) {
          add(LoadPendingJoinRequests(entry.key));
          break;
        }
      }
    } catch (e) {
      _logger.e('❌ Failed to approve request: $e');
      emit(GroupChatError(
        'Failed to approve join request',
        details: e.toString(),
      ));
    }
  }

  Future<void> _onRejectJoinRequest(
    RejectJoinRequest event,
    Emitter<GroupChatState> emit,
  ) async {
    try {
      emit(const GroupChatProcessingRequest());
      _logger.i('❌ Rejecting join request: ${event.requestId}');

      await _groupChatService.rejectJoinRequest(event.requestId);

      emit(GroupChatRequestRejected(event.requestId));
      _logger.i('✅ Request rejected');

      // Refresh pending requests if we have the session ID cached
      for (final entry in _pendingRequestsCache.entries) {
        if (entry.value.any((r) => r.id == event.requestId)) {
          add(LoadPendingJoinRequests(entry.key));
          break;
        }
      }
    } catch (e) {
      _logger.e('❌ Failed to reject request: $e');
      emit(GroupChatError(
        'Failed to reject join request',
        details: e.toString(),
      ));
    }
  }

  Future<void> _onCreateGroupConversation(
    CreateGroupConversation event,
    Emitter<GroupChatState> emit,
  ) async {
    try {
      emit(const GroupChatCreatingGroup());
      _logger.i('👥 Creating group: ${event.title}');

      final group = await _groupChatService.createGroup(
        title: event.title,
        groupType: event.groupType,
        participantUserIds: event.participantUserIds,
        maxParticipants: event.maxParticipants,
        allowParticipantInvite: event.allowParticipantInvite,
        requireApproval: event.requireApproval,
        enableVoiceChat: event.enableVoiceChat,
        enableVideoChat: event.enableVideoChat,
      );

      emit(GroupChatGroupCreated(group));
      _logger.i('✅ Group created: ${group.id}');
    } catch (e) {
      _logger.e('❌ Failed to create group: $e');
      emit(GroupChatError(
        'Failed to create group',
        details: e.toString(),
      ));
    }
  }

  Future<void> _onLoadGroupDetails(
    LoadGroupDetails event,
    Emitter<GroupChatState> emit,
  ) async {
    try {
      emit(const GroupChatLoadingDetails());
      _logger.i('📄 Loading group details: ${event.conversationId}');

      final group = await _groupChatService.getGroupDetails(event.conversationId);

      emit(GroupChatDetailsLoaded(group));
      _logger.i('✅ Group details loaded');
    } catch (e) {
      _logger.e('❌ Failed to load group details: $e');
      emit(GroupChatError(
        'Failed to load group details',
        details: e.toString(),
      ));
    }
  }

  Future<void> _onAddParticipantToGroup(
    AddParticipantToGroup event,
    Emitter<GroupChatState> emit,
  ) async {
    try {
      emit(const GroupChatAddingParticipant());
      _logger.i('➕ Adding participant to group: ${event.conversationId}');

      await _groupChatService.addParticipant(
        conversationId: event.conversationId,
        userId: event.userId,
        role: event.role,
      );

      emit(GroupChatParticipantAdded(
        conversationId: event.conversationId,
        userId: event.userId,
      ));
      _logger.i('✅ Participant added');

      // Reload group details to show updated participant list
      add(LoadGroupDetails(event.conversationId));
    } catch (e) {
      _logger.e('❌ Failed to add participant: $e');
      emit(GroupChatError(
        'Failed to add participant',
        details: e.toString(),
      ));
    }
  }

  Future<void> _onRemoveParticipantFromGroup(
    RemoveParticipantFromGroup event,
    Emitter<GroupChatState> emit,
  ) async {
    try {
      emit(const GroupChatRemovingParticipant());
      _logger.i('➖ Removing participant from group: ${event.conversationId}');

      await _groupChatService.removeParticipant(
        conversationId: event.conversationId,
        userId: event.userId,
        reason: event.reason,
      );

      emit(GroupChatParticipantRemoved(
        conversationId: event.conversationId,
        userId: event.userId,
      ));
      _logger.i('✅ Participant removed');

      // Reload group details to show updated participant list
      add(LoadGroupDetails(event.conversationId));
    } catch (e) {
      _logger.e('❌ Failed to remove participant: $e');
      emit(GroupChatError(
        'Failed to remove participant',
        details: e.toString(),
      ));
    }
  }

  Future<void> _onReportGroupUser(
    ReportGroupUser event,
    Emitter<GroupChatState> emit,
  ) async {
    try {
      emit(const GroupChatReportingUser());
      _logger.i('🚨 Reporting user in group: ${event.conversationId}');

      await _groupChatService.reportUser(
        conversationId: event.conversationId,
        reportedUserId: event.reportedUserId,
        reason: event.reason,
        description: event.description,
      );

      emit(const GroupChatUserReported());
      _logger.i('✅ User reported');
    } catch (e) {
      _logger.e('❌ Failed to report user: $e');
      emit(GroupChatError(
        'Failed to report user',
        details: e.toString(),
      ));
    }
  }

  // ==================== WEBSOCKET EVENT HANDLERS ====================

  Future<void> _onInitializeGroupChatWebSocket(
    InitializeGroupChatWebSocket event,
    Emitter<GroupChatState> emit,
  ) async {
    try {
      _logger.i('🔌 Initializing Group Chat WebSocket...');

      // Connect to WebSocket
      _webSocketService.connect();

      // Subscribe to real-time events
      _joinRequestReceivedSub = _webSocketService.onJoinRequestReceived.listen(
        (request) => add(JoinRequestReceived(request)),
      );

      _joinRequestApprovedSub = _webSocketService.onJoinRequestApproved.listen(
        (request) => add(JoinRequestApproved(request)),
      );

      _joinRequestRejectedSub = _webSocketService.onJoinRequestRejected.listen(
        (request) => add(JoinRequestRejected(request)),
      );

      _participantJoinedSub = _webSocketService.onParticipantJoined.listen(
        (participant) => add(ParticipantJoined(participant)),
      );

      _participantLeftSub = _webSocketService.onParticipantLeft.listen(
        (participant) => add(ParticipantLeft(participant)),
      );

      _liveSessionStartedSub = _webSocketService.onLiveSessionStarted.listen(
        (session) => add(LiveSessionStarted(session)),
      );

      _liveSessionEndedSub = _webSocketService.onLiveSessionEnded.listen(
        (session) => add(LiveSessionEnded(session)),
      );

      emit(const GroupChatWebSocketConnected());
      _logger.i('✅ WebSocket connected and subscribed');
    } catch (e) {
      _logger.e('❌ Failed to initialize WebSocket: $e');
      emit(GroupChatWebSocketError(e.toString()));
    }
  }

  Future<void> _onDisconnectGroupChatWebSocket(
    DisconnectGroupChatWebSocket event,
    Emitter<GroupChatState> emit,
  ) async {
    try {
      _logger.i('🔌 Disconnecting Group Chat WebSocket...');

      // Cancel all subscriptions
      await _joinRequestReceivedSub?.cancel();
      await _joinRequestApprovedSub?.cancel();
      await _joinRequestRejectedSub?.cancel();
      await _participantJoinedSub?.cancel();
      await _participantLeftSub?.cancel();
      await _liveSessionStartedSub?.cancel();
      await _liveSessionEndedSub?.cancel();

      // Disconnect socket
      _webSocketService.disconnect();

      emit(const GroupChatWebSocketDisconnected());
      _logger.i('✅ WebSocket disconnected');
    } catch (e) {
      _logger.e('❌ Failed to disconnect WebSocket: $e');
      emit(GroupChatWebSocketError(e.toString()));
    }
  }

  Future<void> _onJoinRequestReceived(
    JoinRequestReceived event,
    Emitter<GroupChatState> emit,
  ) async {
    _logger.i('🔔 New join request received: ${event.request.id}');

    // Update cache
    final sessionId = event.request.liveSessionId;
    final cachedRequests = _pendingRequestsCache[sessionId] ?? [];
    cachedRequests.add(event.request);
    _pendingRequestsCache[sessionId] = cachedRequests;

    emit(GroupChatJoinRequestReceived(
      request: event.request,
      allRequests: cachedRequests,
    ));
  }

  Future<void> _onJoinRequestApproved(
    JoinRequestApproved event,
    Emitter<GroupChatState> emit,
  ) async {
    _logger.i('✅ Join request approved: ${event.request.id}');
    emit(GroupChatJoinWasApproved(event.request));
  }

  Future<void> _onJoinRequestRejected(
    JoinRequestRejected event,
    Emitter<GroupChatState> emit,
  ) async {
    _logger.i('❌ Join request rejected: ${event.request.id}');
    emit(GroupChatJoinWasRejected(event.request));
  }

  Future<void> _onParticipantJoined(
    ParticipantJoined event,
    Emitter<GroupChatState> emit,
  ) async {
    _logger.i('👋 Participant joined: ${event.participant.fullName}');
    emit(GroupChatParticipantJoinedLive(event.participant));
  }

  Future<void> _onParticipantLeft(
    ParticipantLeft event,
    Emitter<GroupChatState> emit,
  ) async {
    _logger.i('👋 Participant left: ${event.participant.fullName}');
    emit(GroupChatParticipantLeftLive(event.participant));
  }

  Future<void> _onLiveSessionStarted(
    LiveSessionStarted event,
    Emitter<GroupChatState> emit,
  ) async {
    _logger.i('🎬 Live session started: ${event.session.title}');
    emit(GroupChatSessionStartedLive(event.session));

    // Reload active sessions to include the new one
    add(const LoadActiveLiveSessions());
  }

  Future<void> _onLiveSessionEnded(
    LiveSessionEnded event,
    Emitter<GroupChatState> emit,
  ) async {
    _logger.i('🎬 Live session ended: ${event.session.title}');
    emit(GroupChatSessionEndedLive(event.session));

    // Reload active sessions to remove the ended one
    add(const LoadActiveLiveSessions());
  }

  // ==================== UTILITY EVENT HANDLERS ====================

  Future<void> _onRefreshGroupChatData(
    RefreshGroupChatData event,
    Emitter<GroupChatState> emit,
  ) async {
    _logger.i('🔄 Refreshing group chat data...');
    add(const LoadActiveLiveSessions());
  }

  Future<void> _onClearGroupChatError(
    ClearGroupChatError event,
    Emitter<GroupChatState> emit,
  ) async {
    emit(const GroupChatInitial());
  }

  // ==================== CLEANUP ====================

  @override
  Future<void> close() async {
    // Cancel all WebSocket subscriptions
    await _joinRequestReceivedSub?.cancel();
    await _joinRequestApprovedSub?.cancel();
    await _joinRequestRejectedSub?.cancel();
    await _participantJoinedSub?.cancel();
    await _participantLeftSub?.cancel();
    await _liveSessionStartedSub?.cancel();
    await _liveSessionEndedSub?.cancel();

    // Disconnect WebSocket
    _webSocketService.disconnect();

    return super.close();
  }
}
