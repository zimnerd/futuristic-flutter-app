import 'package:socket_io_client/socket_io_client.dart' as io;
import 'dart:async';
import '../data/models.dart';

class GroupChatWebSocketService {
  late io.Socket socket;
  final String baseUrl;
  final String accessToken;

  // Stream controllers for real-time events
  final _joinRequestReceivedController = StreamController<JoinRequest>.broadcast();
  final _joinRequestApprovedController = StreamController<JoinRequest>.broadcast();
  final _joinRequestRejectedController = StreamController<JoinRequest>.broadcast();
  final _participantJoinedController = StreamController<GroupParticipant>.broadcast();
  final _participantLeftController = StreamController<GroupParticipant>.broadcast();
  final _liveSessionStartedController = StreamController<LiveSession>.broadcast();
  final _liveSessionEndedController = StreamController<LiveSession>.broadcast();
  final _participantRemovedController = StreamController<Map<String, dynamic>>.broadcast();
  final _groupSettingsUpdatedController = StreamController<GroupSettings>.broadcast();
  final _typingController = StreamController<Map<String, dynamic>>.broadcast();
  final _messageReceivedController = StreamController<GroupMessage>.broadcast();
  final _messageConfirmedController = StreamController<GroupMessage>.broadcast();
  final _messageDeletedController = StreamController<String>.broadcast();
  final _reactionAddedController = StreamController<Map<String, dynamic>>.broadcast();
  final _reactionRemovedController = StreamController<Map<String, dynamic>>.broadcast();
  final _messageReadController = StreamController<Map<String, dynamic>>.broadcast();

  // Public streams
  Stream<JoinRequest> get onJoinRequestReceived => _joinRequestReceivedController.stream;
  Stream<JoinRequest> get onJoinRequestApproved => _joinRequestApprovedController.stream;
  Stream<JoinRequest> get onJoinRequestRejected => _joinRequestRejectedController.stream;
  Stream<GroupParticipant> get onParticipantJoined => _participantJoinedController.stream;
  Stream<GroupParticipant> get onParticipantLeft => _participantLeftController.stream;
  Stream<LiveSession> get onLiveSessionStarted => _liveSessionStartedController.stream;
  Stream<LiveSession> get onLiveSessionEnded => _liveSessionEndedController.stream;
  Stream<Map<String, dynamic>> get onParticipantRemoved => _participantRemovedController.stream;
  Stream<GroupSettings> get onGroupSettingsUpdated => _groupSettingsUpdatedController.stream;
  Stream<Map<String, dynamic>> get onTyping => _typingController.stream;
  Stream<GroupMessage> get onMessageReceived => _messageReceivedController.stream;
  Stream<GroupMessage> get onMessageConfirmed => _messageConfirmedController.stream;
  Stream<String> get onMessageDeleted => _messageDeletedController.stream;
  Stream<Map<String, dynamic>> get onReactionAdded => _reactionAddedController.stream;
  Stream<Map<String, dynamic>> get onReactionRemoved => _reactionRemovedController.stream;
  Stream<Map<String, dynamic>> get onMessageRead => _messageReadController.stream;

  GroupChatWebSocketService({
    required this.baseUrl,
    required this.accessToken,
  });

  /// Connect to the WebSocket server
  void connect() {
    socket = io.io(
      baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setExtraHeaders({'Authorization': 'Bearer $accessToken'})
          .setAuth({'token': accessToken})
          .build(),
    );

    socket.connect();

    // Connection events
    socket.onConnect((_) {
      print('🟢 Connected to Group Chat WebSocket');
    });

    socket.onDisconnect((_) {
      print('🔴 Disconnected from Group Chat WebSocket');
    });

    socket.onConnectError((error) {
      print('❌ Connection Error: $error');
    });

    socket.onError((error) {
      print('❌ Socket Error: $error');
    });

    // Listen to real-time events
    _setupEventListeners();
  }

  void _setupEventListeners() {
    // Join request received (for hosts)
    socket.on('join_request_received', (data) {
      try {
        final request = JoinRequest.fromJson(data as Map<String, dynamic>);
        _joinRequestReceivedController.add(request);
      } catch (e) {
        print('Error parsing join_request_received: $e');
      }
    });

    // Join request approved (for requesters)
    socket.on('join_request_approved', (data) {
      try {
        final request = JoinRequest.fromJson(data as Map<String, dynamic>);
        _joinRequestApprovedController.add(request);
      } catch (e) {
        print('Error parsing join_request_approved: $e');
      }
    });

    // Join request rejected (for requesters)
    socket.on('join_request_rejected', (data) {
      try {
        final request = JoinRequest.fromJson(data as Map<String, dynamic>);
        _joinRequestRejectedController.add(request);
      } catch (e) {
        print('Error parsing join_request_rejected: $e');
      }
    });

    // Participant joined
    socket.on('participant_joined', (data) {
      try {
        final participant = GroupParticipant.fromJson(data as Map<String, dynamic>);
        _participantJoinedController.add(participant);
      } catch (e) {
        print('Error parsing participant_joined: $e');
      }
    });

    // Participant left
    socket.on('participant_left', (data) {
      try {
        final participant = GroupParticipant.fromJson(data as Map<String, dynamic>);
        _participantLeftController.add(participant);
      } catch (e) {
        print('Error parsing participant_left: $e');
      }
    });

    // Live session started
    socket.on('live_session_started', (data) {
      try {
        final session = LiveSession.fromJson(data as Map<String, dynamic>);
        _liveSessionStartedController.add(session);
      } catch (e) {
        print('Error parsing live_session_started: $e');
      }
    });

    // Live session ended
    socket.on('live_session_ended', (data) {
      try {
        final session = LiveSession.fromJson(data as Map<String, dynamic>);
        _liveSessionEndedController.add(session);
      } catch (e) {
        print('Error parsing live_session_ended: $e');
      }
    });

    // Participant removed
    socket.on('participant_removed', (data) {
      _participantRemovedController.add(data as Map<String, dynamic>);
    });

    // Group settings updated
    socket.on('group_settings_updated', (data) {
      try {
        final settings = GroupSettings.fromJson(data as Map<String, dynamic>);
        _groupSettingsUpdatedController.add(settings);
      } catch (e) {
        print('Error parsing group_settings_updated: $e');
      }
    });

    // Typing indicator
    socket.on('group_typing', (data) {
      _typingController.add(data as Map<String, dynamic>);
    });

    // New message received
    socket.on('new_message', (data) {
      try {
        final message = GroupMessage.fromJson(data as Map<String, dynamic>);
        _messageReceivedController.add(message);
        print('📨 New message received: ${message.content}');
      } catch (e) {
        print('Error parsing new_message: $e');
      }
    });

    // Message confirmed (sent successfully)
    socket.on('messageConfirmed', (data) {
      try {
        final messageData = (data as Map<String, dynamic>)['data'];
        if (messageData != null) {
          final message = GroupMessage.fromJson(messageData as Map<String, dynamic>);
          _messageConfirmedController.add(message);
          print('✅ Message confirmed: ${message.id}');
        }
      } catch (e) {
        print('Error parsing messageConfirmed: $e');
      }
    });

    // Message deleted
    socket.on('message_deleted', (data) {
      try {
        final messageId = (data as Map<String, dynamic>)['messageId'] as String;
        _messageDeletedController.add(messageId);
        print('🗑️ Message deleted: $messageId');
      } catch (e) {
        print('Error parsing message_deleted: $e');
      }
    });

    // Reaction added
    socket.on('reaction_added', (data) {
      try {
        _reactionAddedController.add(data as Map<String, dynamic>);
        print('👍 Reaction added');
      } catch (e) {
        print('Error parsing reaction_added: $e');
      }
    });

    // Reaction removed
    socket.on('reaction_removed', (data) {
      try {
        _reactionRemovedController.add(data as Map<String, dynamic>);
        print('👎 Reaction removed');
      } catch (e) {
        print('Error parsing reaction_removed: $e');
      }
    });

    // Message read
    socket.on('message_read', (data) {
      try {
        _messageReadController.add(data as Map<String, dynamic>);
        print('👁️ Message read');
      } catch (e) {
        print('Error parsing message_read: $e');
      }
    });
  }

  /// Join a live session room
  void joinLiveSession(String liveSessionId) {
    socket.emit('join_live_session', {'liveSessionId': liveSessionId});
  }

  /// Leave a live session room
  void leaveLiveSession(String liveSessionId) {
    socket.emit('leave_live_session', {'liveSessionId': liveSessionId});
  }

  /// Join a group conversation room
  void joinGroup(String conversationId) {
    socket.emit('join_group', {'conversationId': conversationId});
  }


  /// Leave a group conversation room
  void leaveGroup(String conversationId) {
    socket.emit('leave_group', {'conversationId': conversationId});
  }

  /// Send a message to the group
  void sendMessage({
    required String conversationId,
    required String content,
    String type = 'text',
    String? replyToMessageId,
    String? tempId,
    Map<String, dynamic>? metadata,
  }) {
    socket.emit('send_message', {
      'conversationId': conversationId,
      'content': content,
      'type': type,
      'replyToMessageId': replyToMessageId,
      'tempId': tempId,
      'metadata': metadata,
    });
  }

  /// Send typing indicator
  void sendTypingIndicator({
    required String conversationId,
    required bool isTyping,
  }) {
    socket.emit('group_typing', {
      'conversationId': conversationId,
      'isTyping': isTyping,
    });
  }

  /// Delete a message
  void deleteMessage({
    required String conversationId,
    required String messageId,
  }) {
    socket.emit('delete_message', {
      'conversationId': conversationId,
      'messageId': messageId,
    });
  }

  /// Add reaction to message
  void addReaction({
    required String conversationId,
    required String messageId,
    required String emoji,
  }) {
    socket.emit('add_reaction', {
      'conversationId': conversationId,
      'messageId': messageId,
      'emoji': emoji,
    });
  }

  /// Remove reaction from message
  void removeReaction({
    required String conversationId,
    required String messageId,
    required String emoji,
  }) {
    socket.emit('remove_reaction', {
      'conversationId': conversationId,
      'messageId': messageId,
      'emoji': emoji,
    });
  }

  /// Mark message as read
  void markMessageAsRead({
    required String conversationId,
    required String messageId,
  }) {
    socket.emit('mark_read', {
      'conversationId': conversationId,
      'messageId': messageId,
    });
  }

  /// Disconnect from WebSocket
  void disconnect() {
    socket.disconnect();
    _closeStreams();
  }

  void _closeStreams() {
    _joinRequestReceivedController.close();
    _joinRequestApprovedController.close();
    _joinRequestRejectedController.close();
    _participantJoinedController.close();
    _participantLeftController.close();
    _liveSessionStartedController.close();
    _liveSessionEndedController.close();
    _participantRemovedController.close();
    _groupSettingsUpdatedController.close();
    _typingController.close();
    _messageReceivedController.close();
    _messageConfirmedController.close();
    _messageDeletedController.close();
    _reactionAddedController.close();
    _reactionRemovedController.close();
    _messageReadController.close();
  }
}

