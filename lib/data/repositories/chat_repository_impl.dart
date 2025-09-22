import 'dart:async';
import 'package:logger/logger.dart';
import 'package:pulse_dating_app/data/models/message.dart' as data_message;

import '../models/chat_model.dart';
import '../models/message.dart' as msg;
import '../datasources/remote/chat_remote_data_source.dart';
import '../../domain/services/websocket_service.dart';
import '../services/websocket_service_impl.dart';
import '../../domain/entities/message.dart' as domain;
import '../exceptions/app_exceptions.dart';
import '../../core/network/api_client.dart';
import 'chat_repository.dart';

/// Implementation of ChatRepository with real-time Socket.IO support
class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource _remoteDataSource;
  final WebSocketService _webSocketService;
  final ApiClient _apiClient;
  final Logger _logger = Logger();

  // Stream controllers for real-time events
  final StreamController<MessageModel> _incomingMessagesController =
      StreamController<MessageModel>.broadcast();
  final StreamController<msg.MessageDeliveryUpdate> _deliveryUpdatesController =
      StreamController<msg.MessageDeliveryUpdate>.broadcast();
  
  // Track optimistic message ID to real message ID mapping
  final Map<String, String> _optimisticToRealIdMap = {};

  ChatRepositoryImpl({
    required ChatRemoteDataSource remoteDataSource,
    WebSocketService? webSocketService,
    ApiClient? apiClient,
  }) : _remoteDataSource = remoteDataSource,
       _webSocketService = webSocketService ?? WebSocketServiceImpl.instance,
       _apiClient = apiClient ?? ApiClient.instance {
    _setupWebSocketListeners();
  }

  @override
  Stream<MessageModel> get incomingMessages =>
      _incomingMessagesController.stream;

  @override
  Stream<msg.MessageDeliveryUpdate> get messageDeliveryUpdates =>
      _deliveryUpdatesController.stream;

  /// Setup WebSocket listeners for real-time message events
  void _setupWebSocketListeners() {
    // Listen for incoming messages (backend emits 'messageReceived')
    _webSocketService.on('messageReceived', (data) {
      try {
        _logger.d('Received messageReceived event: $data');

        // Parse the backend event structure: { type, data, timestamp }
        if (data is Map<String, dynamic> && data.containsKey('data')) {
          final messageData = data['data'] as Map<String, dynamic>;
          final message = MessageModel.fromJson(messageData);
          
          // Check if this is a real message for an optimistic message we sent
          // Look for optimistic messages with similar content and timestamp
          final optimisticEntries = _optimisticToRealIdMap.entries.where((
            entry,
          ) {
            return entry.value ==
                entry.key; // Still mapping to itself (not yet replaced)
          });

          for (final entry in optimisticEntries) {
            // Update the mapping to point to the real message ID
            _optimisticToRealIdMap[entry.key] = message.id;
            _logger.d(
              'Mapped optimistic ID ${entry.key} to real ID ${message.id}',
            );
            break; // Assume first match is correct for now
          }
          
          _incomingMessagesController.add(message);
          _logger.d('Added incoming message to stream: ${message.id}');
        }
      } catch (e) {
        _logger.e('Error processing incoming message: $e');
      }
    });

    // Listen for message delivery confirmations
    _webSocketService.on('messageDelivered', (data) {
      try {
        _logger.d('Received messageDelivered event: $data');

        if (data is Map<String, dynamic>) {
          final update = msg.MessageDeliveryUpdate.fromJson(data);
          
          // Check if this delivery update is for an optimistic message
          // If so, create a delivery update with the optimistic ID instead
          final optimisticId = _optimisticToRealIdMap.entries
              .firstWhere(
                (entry) => entry.value == update.messageId,
                orElse: () => MapEntry(update.messageId, update.messageId),
              )
              .key;

          if (optimisticId != update.messageId) {
            // Create delivery update with optimistic ID so ChatBloc can find it
            final optimisticUpdate = msg.MessageDeliveryUpdate(
              messageId: optimisticId,
              status: update.status,
              timestamp: update.timestamp,
            );
            _deliveryUpdatesController.add(optimisticUpdate);
            _logger.d(
              'Mapped delivery update from real ID ${update.messageId} to optimistic ID $optimisticId',
            );
          } else {
            _deliveryUpdatesController.add(update);
            _logger.d('Added delivery update to stream: ${update.messageId}');
          }
        }
      } catch (e) {
        _logger.e('Error processing delivery update: $e');
      }
    });
  }

  /// Dispose of stream controllers
  void dispose() {
    _incomingMessagesController.close();
    _deliveryUpdatesController.close();
    _optimisticToRealIdMap.clear();
  }

  @override
  Future<List<ConversationModel>> getConversations() async {
    try {
      _logger.d('Fetching conversations');
      final conversations = await _remoteDataSource.getConversations();
      _logger.d('Successfully fetched ${conversations.length} conversations');
      return conversations;
    } catch (e) {
      _logger.e('Error fetching conversations: $e');
      rethrow;
    }
  }

  @override
  Future<List<MessageModel>> getMessages({
    required String conversationId,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      _logger.d('Fetching messages for conversation: $conversationId');
      
      // Join conversation for real-time updates
      _webSocketService.joinRoom(conversationId);
      
      final messages = await _remoteDataSource.getMessages(
        conversationId,
        limit: limit,
        // For pagination, we could use beforeMessageId from previous requests
      );
      _logger.d('Successfully fetched ${messages.length} messages');
      return messages;
    } catch (e) {
      _logger.e('Error fetching messages: $e');
      rethrow;
    }
  }

  @override
  Future<MessageModel> sendMessage({
    required String conversationId,
    required msg.MessageType type,
    String? content,
    List<String>? mediaIds,
    Map<String, dynamic>? metadata,
    String? replyToMessageId,
  }) async {
    try {
      _logger.d('Sending message to conversation: $conversationId via Socket.IO');
      
      // Send via Socket.IO for real-time delivery
      _webSocketService.emit('send_message', {
        'conversationId': conversationId,
        'content': content,
        'type': type.name,
        'metadata': metadata,
      });
      
      // Create optimistic message for immediate UI update
      final optimisticId = DateTime.now().millisecondsSinceEpoch.toString();
      final optimisticMessage = MessageModel(
        id: optimisticId,
        conversationId: conversationId,
        senderId:
            'optimistic_user', // Temporary placeholder - will be updated when real message arrives
        senderUsername: 'You',
        type: _convertToDomainMessageType(type),
        content: content,
        status: MessageStatus.sending,
        mediaUrls: mediaIds,
        metadata: metadata,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Store the optimistic ID for later mapping to real ID
      _optimisticToRealIdMap[optimisticId] =
          optimisticId; // Will be updated when real message arrives
      
      _logger.d('Successfully sent message via Socket.IO');
      return optimisticMessage;
    } catch (e) {
      _logger.e('Error sending message: $e');
      rethrow;
    }
  }

  @override
  Future<void> markMessageAsRead(String messageId) async {
    try {
      _logger.d('Marking message as read: $messageId');
      await _remoteDataSource.markMessageAsRead(messageId);
      _logger.d('Successfully marked message as read');
    } catch (e) {
      _logger.e('Error marking message as read: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    try {
      _logger.d('Deleting message: $messageId');
      await _remoteDataSource.deleteMessage(messageId);
      _logger.d('Successfully deleted message');
    } catch (e) {
      _logger.e('Error deleting message: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateTypingStatus(String conversationId, bool isTyping) async {
    try {
      _logger.d('Updating typing status for conversation: $conversationId via Socket.IO');
      
      // Use Socket.IO for real-time typing indicators
      if (isTyping) {
        _webSocketService.emit('typing_start', {
          'conversationId': conversationId,
        });
      } else {
        _webSocketService.emit('typing_stop', {
          'conversationId': conversationId,
        });
      }
      
      _logger.d('Successfully updated typing status');
    } catch (e) {
      _logger.e('Error updating typing status: $e');
      rethrow;
    }
  }

  @override
  Future<ConversationModel> createConversation(String matchId) async {
    try {
      _logger.d(
        'Creating conversation with participant: $matchId via REST API',
      );
      
      final response = await _apiClient.createConversation(
        participantId: matchId,
        isGroup: false,
      );

      if (response.statusCode == 201 && response.data != null) {
        _logger.d('🐛 Full API response: ${response.data}');

        // Check if response is wrapped in 'data' field like other endpoints
        final responseData = response.data['data'] ?? response.data;
        _logger.d('🐛 Extracted response data: $responseData');
        
        final conversation = _conversationFromApiResponse(
          responseData,
          matchId,
        );
        _logger.d('Successfully created conversation: ${conversation.id}');
        return conversation;
      } else {
        throw NetworkException(
          'Failed to create conversation: ${response.statusMessage}',
        );
      }
    } catch (e) {
      _logger.e('Error creating conversation: $e');
      throw NetworkException('Failed to create conversation: $e');
    }
  }

  /// Transform API response to ConversationModel
  ConversationModel _conversationFromApiResponse(
    Map<String, dynamic> data,
    String otherUserId,
  ) {
    _logger.d('🐛 Transforming API response to ConversationModel: $data');
    
    // Get participants list
    final participants = (data['participants'] as List<dynamic>?) ?? [];
    final participantIds = participants
        .map((p) => p['userId']?.toString())
        .where((id) => id != null)
        .cast<String>()
        .toList();
    
    // Log the conversation ID to debug - check multiple possible fields
    final conversationId =
        data['id']?.toString() ??
        data['conversationId']?.toString() ??
        data['_id']?.toString() ??
        '';
    _logger.d('🐛 Creating ConversationModel with ID: $conversationId');

    return ConversationModel(
      id: conversationId,
      type: ConversationType.direct, // Direct conversation for 1-on-1 chat
      participantIds: participantIds,
      name: null, // Direct chats don't have names
      description: null,
      imageUrl: null,
      lastMessage: null, // Will be populated when messages are loaded
      lastMessageAt: data['lastMessageAt'] != null
          ? DateTime.tryParse(data['lastMessageAt'].toString())
          : null,
      unreadCount: (data['unreadCount'] as num?)?.toInt() ?? 0,
      settings: null, // Default settings
      createdAt: data['createdAt'] != null
          ? DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? DateTime.tryParse(data['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  @override
  Future<ConversationModel?> getConversation(String conversationId) async {
    try {
      _logger.d('Fetching conversation: $conversationId');
      final conversation = await _remoteDataSource.getConversation(conversationId);
      _logger.d('Successfully fetched conversation');
      return conversation;
    } catch (e) {
      _logger.e('Error fetching conversation: $e');
      rethrow;
    }
  }

  @override
  Future<ConversationModel> updateConversation({
    required String conversationId,
    Map<String, dynamic>? settings,
  }) async {
    try {
      _logger.d('Updating conversation: $conversationId');
      final conversation = await _remoteDataSource.updateConversation(
        conversationId,
        settings ?? {},
      );
      _logger.d('Successfully updated conversation');
      return conversation;
    } catch (e) {
      _logger.e('Error updating conversation: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteConversation(String conversationId) async {
    try {
      _logger.d('Deleting conversation: $conversationId');
      await _remoteDataSource.deleteConversation(conversationId);
      _logger.d('Successfully deleted conversation');
    } catch (e) {
      _logger.e('Error deleting conversation: $e');
      rethrow;
    }
  }

  @override
  Future<void> markConversationAsRead(
    String conversationId, {
    List<String>? messageIds,
  }) async {
    try {
      _logger.d(
        'Marking conversation as read: $conversationId with ${messageIds?.length ?? 0} message IDs',
      );
      await _remoteDataSource.markConversationAsRead(
        conversationId,
        messageIds: messageIds,
      );
      _logger.d('Successfully marked conversation as read');
    } catch (e) {
      _logger.e('Error marking conversation as read: $e');
      rethrow;
    }
  }

  @override
  Future<MessageModel> getMessage(String messageId) async {
    try {
      _logger.d('Fetching message: $messageId');
      final message = await _remoteDataSource.getMessage(messageId);
      _logger.d('Successfully fetched message');
      return message;
    } catch (e) {
      _logger.e('Error fetching message: $e');
      rethrow;
    }
  }

  @override
  Future<void> copyMessageToClipboard(String messageId) async {
    try {
      _logger.d('Copying message to clipboard: $messageId');
      await _remoteDataSource.copyMessageToClipboard(messageId);
      _logger.d('Successfully copied message to clipboard');
    } catch (e) {
      _logger.e('Error copying message to clipboard: $e');
      rethrow;
    }
  }

  @override
  Future<MessageModel> editMessage(String messageId, String newContent) async {
    try {
      _logger.d('Editing message: $messageId');
      final editedMessage = await _remoteDataSource.editMessage(
        messageId,
        newContent,
      );
      _logger.d('Successfully edited message');
      return editedMessage;
    } catch (e) {
      _logger.e('Error editing message: $e');
      rethrow;
    }
  }

  @override
  Future<MessageModel> replyToMessage(
    String originalMessageId,
    String content,
    String conversationId,
  ) async {
    try {
      _logger.d('Replying to message: $originalMessageId');
      final replyMessage = await _remoteDataSource.replyToMessage(
        originalMessageId,
        content,
        conversationId,
      );
      _logger.d('Successfully sent reply');
      return replyMessage;
    } catch (e) {
      _logger.e('Error sending reply: $e');
      rethrow;
    }
  }

  @override
  Future<void> forwardMessage(
    String messageId,
    List<String> targetConversationIds,
  ) async {
    try {
      _logger.d('Forwarding message: $messageId');
      await _remoteDataSource.forwardMessage(messageId, targetConversationIds);
      _logger.d('Successfully forwarded message');
    } catch (e) {
      _logger.e('Error forwarding message: $e');
      rethrow;
    }
  }

  @override
  Future<void> bookmarkMessage(String messageId, bool isBookmarked) async {
    try {
      _logger.d('Bookmarking message: $messageId ($isBookmarked)');
      await _remoteDataSource.bookmarkMessage(messageId, isBookmarked);
      _logger.d('Successfully updated bookmark');
    } catch (e) {
      _logger.e('Error updating bookmark: $e');
      rethrow;
    }
  }

  @override
  Future<String> performContextualAction(
    String actionId,
    String actionType,
    Map<String, dynamic> actionData,
  ) async {
    try {
      _logger.d('Performing contextual action: $actionId');
      final result = await _remoteDataSource.performContextualAction(
        actionId,
        actionType,
        actionData,
      );
      _logger.d('Successfully performed contextual action');
      return result;
    } catch (e) {
      _logger.e('Error performing contextual action: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateMessageStatus(String messageId, String status) async {
    try {
      _logger.d('Updating message status: $messageId -> $status');
      await _remoteDataSource.updateMessageStatus(messageId, status);
      _logger.d('Successfully updated message status');
    } catch (e) {
      _logger.e('Error updating message status: $e');
      rethrow;
    }
  }

  @override
  Future<void> joinConversation(String conversationId) async {
    try {
      _logger.d('Joining conversation room: $conversationId');
      _webSocketService.joinRoom(conversationId);
      _logger.d('Successfully joined conversation room: $conversationId');
    } catch (e) {
      _logger.e('Error joining conversation: $e');
      rethrow;
    }
  }

  @override
  Future<void> leaveConversation(String conversationId) async {
    try {
      _logger.d('Leaving conversation room: $conversationId');
      _webSocketService.leaveRoom(conversationId);
      _logger.d('Successfully left conversation room: $conversationId');
    } catch (e) {
      _logger.e('Error leaving conversation: $e');
      rethrow;
    }
  }

  /// Convert data model MessageType to domain MessageType
  domain.MessageType _convertToDomainMessageType(
    data_message.MessageType type,
  ) {
    switch (type) {
      case data_message.MessageType.text:
        return domain.MessageType.text;
      case data_message.MessageType.image:
        return domain.MessageType.image;
      case data_message.MessageType.video:
        return domain.MessageType.video;
      case data_message.MessageType.audio:
        return domain.MessageType.audio;
      case data_message.MessageType.gif:
        return domain.MessageType.gif;
      case data_message.MessageType.sticker:
        return domain.MessageType.sticker;
      case data_message.MessageType.location:
        return domain.MessageType.location;
      case data_message.MessageType.contact:
        return domain.MessageType.contact;
      case data_message.MessageType.file:
        return domain.MessageType.file;
      case data_message.MessageType.system:
        // Map system to text as domain doesn't have system type
        return domain.MessageType.text;
    }
  }

  @override
  bool isOptimisticMessage(String? messageId, String realMessageId) {
    if (messageId == null) return false;

    // Check if this messageId is in our optimistic mapping that points to the real ID
    return _optimisticToRealIdMap[messageId] == realMessageId;
  }
}