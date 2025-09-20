import 'dart:async';
import '../../domain/services/websocket_service.dart';

/// A comprehensive Socket.IO-based chat service that handles all real-time messaging functionality
/// This service provides a clean API for all chat operations and manages Socket.IO events
class SocketChatService {
  final WebSocketService _webSocketService;
  
  // Stream controllers for different types of events
  final StreamController<Map<String, dynamic>> _messageController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _conversationController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _typingController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _presenceController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _callController = StreamController.broadcast();
  
  // Public streams
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<Map<String, dynamic>> get conversationStream => _conversationController.stream;
  Stream<Map<String, dynamic>> get typingStream => _typingController.stream;
  Stream<Map<String, dynamic>> get presenceStream => _presenceController.stream;
  Stream<Map<String, dynamic>> get callStream => _callController.stream;

  SocketChatService(this._webSocketService) {
    _setupEventListeners();
  }

  /// Set up all Socket.IO event listeners for real-time updates
  void _setupEventListeners() {
    // Message events
    _webSocketService.onNewMessage((data) {
      _messageController.add({
        'type': 'message_received',
        'data': data,
      });
    });

    _webSocketService.onMessageUpdate((data) {
      _messageController.add({
        'type': 'message_status_updated',
        'data': data,
      });
    });

    _webSocketService.onMessageDeleted((messageId) {
      _messageController.add({
        'type': 'message_deleted',
        'data': {'messageId': messageId},
      });
    });

    // Typing events
    _webSocketService.onTypingStart((data) {
      _typingController.add({
        'type': 'typing_started',
        'data': data,
      });
    });

    _webSocketService.onTypingStop((data) {
      _typingController.add({
        'type': 'typing_stopped',
        'data': data,
      });
    });

    // User presence events
    _webSocketService.onUserOnline((userId) {
      _presenceController.add({
        'type': 'user_online',
        'data': {'userId': userId},
      });
    });

    _webSocketService.onUserOffline((userId) {
      _presenceController.add({
        'type': 'user_offline',
        'data': {'userId': userId},
      });
    });

    _webSocketService.onUserStatusChange((data) {
      _presenceController.add({
        'type': 'user_status_changed',
        'data': data,
      });
    });

    // Call events
    _webSocketService.onIncomingCall((data) {
      _callController.add({
        'type': 'call_initiated',
        'data': data,
      });
    });

    _webSocketService.onCallAccepted((data) {
      _callController.add({
        'type': 'call_answered',
        'data': data,
      });
    });

    _webSocketService.onCallDeclined((data) {
      _callController.add({
        'type': 'call_declined',
        'data': data,
      });
    });

    _webSocketService.onCallEnded((data) {
      _callController.add({
        'type': 'call_ended',
        'data': data,
      });
    });

    _webSocketService.onCallUpdate((data) {
      _callController.add({
        'type': 'call_updated',
        'data': data,
      });
    });

    // Generic event listeners for conversation updates
    _webSocketService.on('conversation_created', (data) {
      _conversationController.add({
        'type': 'conversation_created',
        'data': data,
      });
    });

    _webSocketService.on('conversation_updated', (data) {
      _conversationController.add({
        'type': 'conversation_updated',
        'data': data,
      });
    });

    _webSocketService.on('conversation_archived', (data) {
      _conversationController.add({
        'type': 'conversation_archived',
        'data': data,
      });
    });

    _webSocketService.on('conversation_deleted', (data) {
      _conversationController.add({
        'type': 'conversation_deleted',
        'data': data,
      });
    });
  }

  // === MESSAGE OPERATIONS ===

  /// Send a message through Socket.IO
  Future<void> sendMessage({
    required String conversationId,
    required String content,
    required String messageType,
    String? replyToId,
    Map<String, dynamic>? metadata,
  }) async {
    _webSocketService.emit('sendMessage', {
      'conversationId': conversationId,
      'content': content,
      'messageType': messageType,
      'replyToId': replyToId,
      'metadata': metadata,
    });
  }

  /// Reply to a specific message
  Future<void> replyToMessage({
    required String conversationId,
    required String originalMessageId,
    required String content,
    required String messageType,
  }) async {
    _webSocketService.emit('replyToMessage', {
      'conversationId': conversationId,
      'originalMessageId': originalMessageId,
      'content': content,
      'messageType': messageType,
    });
  }

  /// Mark a message as read
  Future<void> markMessageRead({
    required String conversationId,
    required String messageId,
  }) async {
    _webSocketService.emit('markMessageRead', {
      'conversationId': conversationId,
      'messageId': messageId,
    });
  }

  /// Update message status (sent, delivered, read, etc.)
  Future<void> updateMessageStatus({
    required String messageId,
    required String status,
  }) async {
    _webSocketService.emit('updateMessageStatus', {
      'messageId': messageId,
      'status': status,
    });
  }

  /// Delete a message
  Future<void> deleteMessage({
    required String messageId,
    required String conversationId,
  }) async {
    _webSocketService.emit('deleteMessage', {
      'messageId': messageId,
      'conversationId': conversationId,
    });
  }

  /// Perform message actions (like, react, etc.)
  Future<void> performMessageAction({
    required String messageId,
    required String action,
    Map<String, dynamic>? data,
  }) async {
    _webSocketService.emit('performMessageAction', {
      'messageId': messageId,
      'action': action,
      'data': data,
    });
  }

  // === CONVERSATION OPERATIONS ===

  /// Join a conversation for real-time updates
  Future<void> joinConversation(String conversationId) async {
    _webSocketService.emit('joinConversation', {
      'conversationId': conversationId,
    });
  }

  /// Leave a conversation
  Future<void> leaveConversation(String conversationId) async {
    _webSocketService.emit('leaveConversation', {
      'conversationId': conversationId,
    });
  }

  /// Create a new conversation
  Future<void> createConversation({
    required String participantId,
    required String type,
    String? title,
    Map<String, dynamic>? metadata,
  }) async {
    _webSocketService.emit('createConversation', {
      'participantId': participantId,
      'type': type,
      'title': title,
      'metadata': metadata,
    });
  }

  /// Get conversation history with pagination
  Future<void> getConversationHistory({
    required String conversationId,
    int? page,
    int? limit,
    String? cursor,
  }) async {
    _webSocketService.emit('getConversationHistory', {
      'conversationId': conversationId,
      'page': page,
      'limit': limit,
      'cursor': cursor,
    });
  }

  /// Archive a conversation
  Future<void> archiveConversation(String conversationId) async {
    _webSocketService.emit('archiveConversation', {
      'conversationId': conversationId,
    });
  }

  /// Delete a conversation
  Future<void> deleteConversation(String conversationId) async {
    _webSocketService.emit('deleteConversation', {
      'conversationId': conversationId,
    });
  }

  // === TYPING INDICATORS ===

  /// Start typing indicator
  Future<void> startTyping(String conversationId) async {
    _webSocketService.emit('typing', {
      'conversationId': conversationId,
      'isTyping': true,
    });
  }

  /// Stop typing indicator
  Future<void> stopTyping(String conversationId) async {
    _webSocketService.emit('typing', {
      'conversationId': conversationId,
      'isTyping': false,
    });
  }

  // === SEARCH AND BOOKMARKS ===

  /// Search messages
  Future<void> searchMessages({
    required String query,
    String? conversationId,
    int? page,
    int? limit,
  }) async {
    _webSocketService.emit('searchMessages', {
      'query': query,
      'conversationId': conversationId,
      'page': page,
      'limit': limit,
    });
  }

  /// Bookmark a message
  Future<void> bookmarkMessage({
    required String messageId,
    String? note,
  }) async {
    _webSocketService.emit('bookmarkMessage', {
      'messageId': messageId,
      'note': note,
    });
  }

  /// Get bookmarked messages
  Future<void> getBookmarks({
    int? page,
    int? limit,
  }) async {
    _webSocketService.emit('getBookmarks', {
      'page': page,
      'limit': limit,
    });
  }

  // === AI COMPANION OPERATIONS ===

  /// Perform AI companion actions
  Future<void> performAiCompanionAction({
    required String action,
    Map<String, dynamic>? data,
  }) async {
    _webSocketService.emit('performAiCompanionAction', {
      'action': action,
      'data': data,
    });
  }

  // === CALL OPERATIONS ===

  /// Initiate a call
  Future<void> initiateCall({
    required String recipientId,
    required String callType,
    Map<String, dynamic>? metadata,
  }) async {
    _webSocketService.emit('initiateCall', {
      'recipientId': recipientId,
      'callType': callType,
      'metadata': metadata,
    });
  }

  /// Answer a call
  Future<void> answerCall({
    required String callId,
    Map<String, dynamic>? metadata,
  }) async {
    _webSocketService.emit('answerCall', {
      'callId': callId,
      'metadata': metadata,
    });
  }

  /// End a call
  Future<void> endCall({
    required String callId,
    String? reason,
  }) async {
    _webSocketService.emit('endCall', {
      'callId': callId,
      'reason': reason,
    });
  }

  /// Send WebRTC signaling data
  Future<void> sendWebRTCSignaling({
    required String callId,
    required String type,
    required Map<String, dynamic> data,
  }) async {
    _webSocketService.emit('webrtcSignaling', {
      'callId': callId,
      'type': type,
      'data': data,
    });
  }

  /// Dispose of all resources
  void dispose() {
    _messageController.close();
    _conversationController.close();
    _typingController.close();
    _presenceController.close();
    _callController.close();
  }
}