import 'dart:async';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import '../models/chat_model.dart' hide ConversationModel;
import '../models/conversation_model.dart';
import '../models/message.dart' show MessageDeliveryUpdate;
import '../../domain/entities/message.dart' show MessageType;
import '../datasources/remote/chat_remote_data_source.dart';
import '../../domain/services/websocket_service.dart';
import '../services/websocket_service_impl.dart';
import '../services/message_database_service.dart';
import '../utils/model_converters.dart';
import '../database/models/database_models.dart';
import '../exceptions/app_exceptions.dart';
import '../../core/network/api_client.dart';
import 'chat_repository.dart';

/// Implementation of ChatRepository with real-time Socket.IO support and local SQLite caching
class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource _remoteDataSource;
  final WebSocketService _webSocketService;
  final ApiClient _apiClient;
  final MessageDatabaseService _databaseService;
  final Logger _logger = Logger();
  final Uuid _uuid = Uuid();

  // Stream controllers for real-time events
  final StreamController<MessageModel> _incomingMessagesController =
      StreamController<MessageModel>.broadcast();
  final StreamController<MessageDeliveryUpdate> _deliveryUpdatesController =
      StreamController<MessageDeliveryUpdate>.broadcast();
  
  // Track optimistic message tempId to real message ID mapping
  final Map<String, String> _tempIdToRealIdMap = {};
  final Map<String, MessageModel> _pendingOptimisticMessages = {};
  
  // Stream subscription for WebSocket messages
  StreamSubscription<Map<String, dynamic>>? _messageSubscription;

  ChatRepositoryImpl({
    required ChatRemoteDataSource remoteDataSource,
    WebSocketService? webSocketService,
    ApiClient? apiClient,
    MessageDatabaseService? databaseService,
  }) : _remoteDataSource = remoteDataSource,
       _webSocketService = webSocketService ?? WebSocketServiceImpl.instance,
       _apiClient = apiClient ?? ApiClient.instance,
       _databaseService = databaseService ?? MessageDatabaseService() {
    _setupWebSocketListeners();
  }

  @override
  Stream<MessageModel> get incomingMessages =>
      _incomingMessagesController.stream;

  @override
  Stream<MessageDeliveryUpdate> get messageDeliveryUpdates =>
      _deliveryUpdatesController.stream;

  /// Setup WebSocket listeners for real-time message events
  void _setupWebSocketListeners() {
    // DEBUG: Listen for ALL events to see what's coming through
    _logger.e('🔍 [DEBUG] Setting up WebSocket listeners...');

    // First, let's verify the WebSocket connection status
    _logger.e(
      '🔍 [DEBUG] WebSocket isConnected: ${_webSocketService.isConnected}',
    );
    _logger.e(
      '🔍 [DEBUG] WebSocket namespace: ${_webSocketService.currentNamespace}',
    );

    // Note: onAny method may not be available on WebSocketService interface
    // We'll rely on specific event logging instead

    // Listen for connection events
    _webSocketService.on('connect', (_) {
      _logger.e('🔗 [DEBUG] Repository detected WebSocket connection');
    });

    _webSocketService.on('disconnect', (reason) {
      _logger.e('🔌 [DEBUG] Repository detected WebSocket disconnect: $reason');
    });
    
    // Listen for incoming messages via messageStream (like AI companion)
    _logger.e('🔧 [DEBUG] *** SETTING UP messageStream SUBSCRIPTION ***');
    final webSocketImpl = _webSocketService as WebSocketServiceImpl;
    _messageSubscription = webSocketImpl.messageStream
        .where((event) => event['type'] == 'messageReceived')
        .listen((data) async {
      try {
        _logger.e(
          '📨 [DEBUG] *** REPOSITORY RECEIVED messageReceived EVENT *** DATA: $data',
        );
        _logger.e('Repository: Processing messageReceived event: $data');

        // Parse the backend event structure: { type, data, timestamp }
        // The structure is: { type: 'messageReceived', data: { type: 'message_sent', data: {...actual message...} } }
        if (data.containsKey('data')) {
          final outerData = data['data'] as Map<String, dynamic>;
          _logger.d('Repository: Parsing message data: $outerData');
          
          // Extract the actual message data from the nested structure
          if (outerData.containsKey('data')) {
            final messageData = outerData['data'] as Map<String, dynamic>;
            _logger.d('Repository: Parsing actual message data: $messageData');
            
            // Debug: Log all fields to see what might be null
            _logger.d('Repository: DEBUG - id: ${messageData['id']} (${messageData['id'].runtimeType})');
            _logger.d('Repository: DEBUG - conversationId: ${messageData['conversationId']} (${messageData['conversationId'].runtimeType})');
            _logger.d('Repository: DEBUG - senderId: ${messageData['senderId']} (${messageData['senderId'].runtimeType})');
            _logger.d('Repository: DEBUG - senderUsername: ${messageData['senderUsername']} (${messageData['senderUsername'].runtimeType})');
            
            final message = MessageModel.fromJson(messageData);
            
            _logger.d(
              'Repository: Parsed message - ID: ${message.id}, senderId: ${message.senderId}, content: "${message.content}"',
            );
            
            // Check if this message has a tempId for correlation with optimistic messages
            if (message.tempId != null && message.tempId!.isNotEmpty) {
              final tempId = message.tempId!;
              
              // Check if we already processed this message via messageConfirmed
              if (_tempIdToRealIdMap.containsKey(tempId)) {
                _logger.d(
                  'Repository: Message already processed via messageConfirmed, skipping: $tempId',
                );
                return; // Don't process again
              }
              
              _logger.d(
                'Repository: Message contains tempId: $tempId, correlating with optimistic message',
              );

              // Update the mapping from tempId to real message ID
              _tempIdToRealIdMap[tempId] = message.id;
              
              // Remove from pending optimistic messages
              _pendingOptimisticMessages.remove(tempId);
              
              // Replace optimistic message in database with real message
              await _databaseService.replaceOptimisticMessage(
                tempId: tempId,
                serverMessage: ModelConverters.messageToDbModel(message),
              );
              
              _logger.d(
                'Repository: Mapped optimistic ID $tempId to real ID ${message.id} and updated database',
              );
            } else {
              // Save new incoming message to database
              await _databaseService.saveMessage(
                ModelConverters.messageToDbModel(message),
              );
              _logger.d(
                'Repository: Saved incoming message to database: ${message.id}',
              );
            }
            _incomingMessagesController.add(message);
            _logger.d(
              'Repository: Added incoming message to stream: ${message.id}',
            );
          } else {
            _logger.w(
              'Repository: message_sent event missing nested data field: $outerData',
            );
          }
        } else {
          _logger.w(
            'Repository: messageReceived event missing data field: $data',
          );
        }
      } catch (e) {
        _logger.e('Repository: Error processing incoming message: $e');
      }
    });

    // Listen for message delivery confirmations
    _webSocketService.on('messageDelivered', (data) {
      try {
        _logger.d('Received messageDelivered event: $data');

        if (data is Map<String, dynamic>) {
          final update = MessageDeliveryUpdate.fromJson(data);
          
          // Check if this delivery update is for an optimistic message
          // If so, create a delivery update with the optimistic ID instead
          final optimisticId = _tempIdToRealIdMap.entries
              .firstWhere(
                (entry) => entry.value == update.messageId,
                orElse: () => MapEntry(update.messageId, update.messageId),
              )
              .key;

          if (optimisticId != update.messageId) {
            // Create delivery update with optimistic ID so ChatBloc can find it
            final optimisticUpdate = MessageDeliveryUpdate(
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

    // Listen for message confirmation (new tempId-based correlation)
    _webSocketService.on('messageConfirmed', (data) {
      try {
        _logger.d('Repository: Received messageConfirmed event: $data');

        if (data is Map<String, dynamic> &&
            data.containsKey('data') &&
            data.containsKey('tempId')) {
          final tempId = data['tempId'] as String;
          final messageData = data['data'] as Map<String, dynamic>;
          final realMessage = MessageModel.fromJson(messageData);

          _logger.d(
            'Repository: Message confirmed - tempId: $tempId, realId: ${realMessage.id}',
          );

          // Update the mapping from tempId to real message ID
          _tempIdToRealIdMap[tempId] = realMessage.id;

          // Remove from pending optimistic messages
          _pendingOptimisticMessages.remove(tempId);

          // Emit the real message to replace the optimistic one
          _incomingMessagesController.add(realMessage.copyWith(tempId: tempId));

          _logger.d(
            'Repository: Replaced optimistic message tempId $tempId with real message ${realMessage.id}',
          );
        }
      } catch (e) {
        _logger.e('Repository: Error processing message confirmation: $e');
      }
    });

    // Listen for message failures (new tempId-based error handling)
    _webSocketService.on('messageFailed', (data) {
      try {
        _logger.d('Repository: Received messageFailed event: $data');

        if (data is Map<String, dynamic> && data.containsKey('tempId')) {
          final tempId = data['tempId'] as String;
          final error = data['error'] as String? ?? 'Unknown error';

          _logger.e(
            'Repository: Message failed - tempId: $tempId, error: $error',
          );

          // Get the optimistic message and mark it as failed
          final optimisticMessage = _pendingOptimisticMessages[tempId];
          if (optimisticMessage != null) {
            final failedMessage = optimisticMessage.copyWith(
              status: MessageStatus.failed,
            );

            // Update pending messages map
            _pendingOptimisticMessages[tempId] = failedMessage;

            // Emit the failed message to update UI
            _incomingMessagesController.add(failedMessage);

            _logger.d(
              'Repository: Marked optimistic message tempId $tempId as failed',
            );
          }
        }
      } catch (e) {
        _logger.e('Repository: Error processing message failure: $e');
      }
    });
  }

  /// Dispose of stream controllers
  void dispose() {
    _messageSubscription?.cancel();
    _incomingMessagesController.close();
    _deliveryUpdatesController.close();
    _tempIdToRealIdMap.clear();
    _pendingOptimisticMessages.clear();
  }

  @override
  Future<List<ConversationModel>> getConversations() async {
    try {
      _logger.d('Fetching conversations');
      final conversations = await _remoteDataSource.getConversations();
      
      // Enhance conversations with cached message data
      final enhancedConversations = <ConversationModel>[];
      
      for (final conversation in conversations) {
        try {
          // Try to get the latest message from cache for this conversation
          final latestMessages = await _databaseService.getMessages(
            conversationId: conversation.id,
            limit: 1,
          );
          
          if (latestMessages.isNotEmpty) {
            final latestMessage = latestMessages.first;
            
            // Create an updated conversation with the latest message data
            final enhancedConversation = ConversationModel(
              id: conversation.id,
              otherUserId: conversation.otherUserId,
              otherUserName: conversation.otherUserName,
              otherUserAvatar: conversation.otherUserAvatar,
              lastMessage: latestMessage.content ?? 'No message content',
              lastMessageTime: latestMessage.createdAt,
              unreadCount: conversation.unreadCount,
              isOnline: conversation.isOnline,
              lastSeen: conversation.lastSeen,
              isBlocked: conversation.isBlocked,
              isMuted: conversation.isMuted,
              isPinned: conversation.isPinned,
              matchedAt: conversation.matchedAt,
            );
            
            enhancedConversations.add(enhancedConversation);
            _logger.d('Enhanced conversation ${conversation.id} with cached message: "${latestMessage.content}"');
          } else {
            // No cached messages, use original conversation
            enhancedConversations.add(conversation);
            _logger.d('No cached messages for conversation ${conversation.id}, using: "${conversation.lastMessage}"');
          }
        } catch (e) {
          // If there's an error getting cached messages, use original conversation
          _logger.w('Error enhancing conversation ${conversation.id}: $e');
          enhancedConversations.add(conversation);
        }
      }
      
      // Sort conversations by last message time (most recent first)
      enhancedConversations.sort(
        (a, b) => b.lastMessageTime.compareTo(a.lastMessageTime),
      );

      _logger.d(
        'Successfully fetched and enhanced ${enhancedConversations.length} conversations',
      );
      return enhancedConversations;
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
      _logger.d(
        'Fetching messages for conversation: $conversationId (page: $page, limit: $limit)',
      );
      
      // Join conversation for real-time updates
      _webSocketService.joinRoom(conversationId);
      
      // Use the new paginated method for consistency and caching
      return await getMessagesPaginated(
        conversationId: conversationId,
        cursorMessageId: null, // For initial load
        limit: limit,
        fromCache: true,
      );
    } catch (e) {
      _logger.e('Error fetching messages: $e');
      rethrow;
    }
  }

  @override
  Future<MessageModel> sendMessage({
    required String conversationId,
    required MessageType type,
    String? content,
    List<String>? mediaIds,
    Map<String, dynamic>? metadata,
    String? replyToMessageId,
    String? currentUserId,
  }) async {
    try {
      _logger.d('Sending message to conversation: $conversationId via Socket.IO');
      _logger.d('Current user ID for optimistic message: $currentUserId');
      
      // Generate unique temporary ID for correlation
      final tempId = _uuid.v4();
      _logger.d('Generated tempId for message: $tempId');

      // Send via Socket.IO for real-time delivery with tempId
      _webSocketService.emit('send_message', {
        'conversationId': conversationId,
        'content': content,
        'type': type.name,
        'metadata': metadata,
        'tempId': tempId, // Include tempId for correlation
      });
      
      // Create optimistic message for immediate UI update
      final optimisticId = 'optimistic_$tempId';
      final optimisticMessage = MessageModel(
        id: optimisticId,
        conversationId: conversationId,
        senderId: currentUserId ?? 'unknown_user', // Use actual current user ID
        senderUsername: 'You',
        type: type,
        content: content,
        status: MessageStatus.sending,
        mediaUrls: mediaIds,
        metadata: metadata,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        tempId: tempId, // Store tempId for correlation
      );
      
      // Store the optimistic message and mapping
      _pendingOptimisticMessages[tempId] = optimisticMessage;
      _tempIdToRealIdMap[tempId] =
          optimisticId; // Will be updated when real message arrives

      // Save optimistic message to database for local caching
      await _databaseService.saveMessage(
        ModelConverters.messageToDbModel(optimisticMessage),
      );
      
      _logger.d(
        'Successfully sent message via Socket.IO with tempId: $tempId, optimistic ID: $optimisticId',
      );
      _logger.d('Optimistic message senderId: ${optimisticMessage.senderId}');
      _logger.d('Saved optimistic message to database');
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
    
    // Log the conversation ID to debug - check multiple possible fields
    final conversationId =
        data['id']?.toString() ??
        data['conversationId']?.toString() ??
        data['_id']?.toString() ??
        '';
    _logger.d('🐛 Creating ConversationModel with ID: $conversationId');

    return ConversationModel(
      id: conversationId,
      otherUserId: data['otherUserId']?.toString() ?? 'unknown',
      otherUserName: data['otherUserName']?.toString() ?? 'Unknown User',
      otherUserAvatar: data['otherUserAvatar']?.toString() ?? '',
      lastMessage: data['lastMessage']?.toString() ?? 'No messages yet',
      lastMessageTime: data['lastMessageTime'] != null
          ? DateTime.tryParse(data['lastMessageTime'].toString()) ??
                DateTime.now()
          : DateTime.now(),
      unreadCount: (data['unreadCount'] as num?)?.toInt() ?? 0,
      isOnline: data['isOnline'] as bool? ?? false,
      lastSeen: data['lastSeen'] != null
          ? DateTime.tryParse(data['lastSeen'].toString())
          : null,
      isBlocked: data['isBlocked'] as bool? ?? false,
      isMuted: data['isMuted'] as bool? ?? false,
      isPinned: data['isPinned'] as bool? ?? false,
      matchedAt: data['matchedAt'] != null
          ? DateTime.tryParse(data['matchedAt'].toString())
          : null,
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



  @override
  bool isOptimisticMessage(String? messageId, String realMessageId) {
    if (messageId == null) return false;

    // Method 1: Check if this messageId is a tempId that maps to the real ID
    if (_tempIdToRealIdMap[messageId] == realMessageId) {
      return true;
    }

    // Method 2: Check if this is an optimistic ID (pattern: "optimistic_tempId")
    if (messageId.startsWith('optimistic_')) {
      final tempId = messageId.substring('optimistic_'.length);
      return _tempIdToRealIdMap[tempId] == realMessageId;
    }

    return false;
  }

  // ================== NEW PAGINATION METHODS ==================

  @override
  Future<List<MessageModel>> getMessagesPaginated({
    required String conversationId,
    String? cursorMessageId,
    int limit = 20,
    bool fromCache = true,
  }) async {
    try {
      _logger.d('Getting paginated messages for conversation: $conversationId');
      _logger.d(
        'Cursor: $cursorMessageId, limit: $limit, fromCache: $fromCache',
      );

      List<MessageDbModel> dbMessages = [];

      if (fromCache) {
        // Try to get from local database first
        dbMessages = await _databaseService.getMessages(
          conversationId: conversationId,
          cursorMessageId: cursorMessageId,
          limit: limit,
        );

        _logger.d(
          'Retrieved ${dbMessages.length} messages from local database',
        );
      }

      // If we have cached messages and they satisfy the limit, return them
      if (dbMessages.length >= limit || !fromCache) {
        final messages = ModelConverters.dbModelsToMessages(dbMessages);
        _logger.d('Returning ${messages.length} cached messages');
        return messages;
      }

      // Otherwise, fetch from network and cache locally
      try {
        final networkMessages = await _remoteDataSource.getMessages(
          conversationId,
          beforeMessageId: cursorMessageId,
          limit: limit,
        );

        // Save network messages to database
        if (networkMessages.isNotEmpty) {
          final dbModelsToSave = ModelConverters.messagesToDbModels(
            networkMessages,
          );
          await _databaseService.saveMessages(dbModelsToSave);

          // Update pagination metadata
          final currentMetadata =
              await _databaseService.getPaginationMetadata(conversationId) ??
              ModelConverters.createInitialPaginationMetadata(conversationId);

          final updatedMetadata = ModelConverters.updatePaginationMetadata(
            currentMetadata,
            dbModelsToSave,
            networkMessages.length >= limit,
          );

          await _databaseService.savePaginationMetadata(updatedMetadata);

          _logger.d(
            'Cached ${networkMessages.length} network messages to database',
          );
        }

        return networkMessages;
      } catch (e) {
        _logger.w('Network fetch failed, returning cached messages: $e');
        final messages = ModelConverters.dbModelsToMessages(dbMessages);
        return messages;
      }
    } catch (e) {
      _logger.e('Error getting paginated messages: $e');
      return [];
    }
  }

  @override
  Future<List<MessageModel>> loadMoreMessages({
    required String conversationId,
    String? oldestMessageId,
    int limit = 20,
  }) async {
    try {
      _logger.d('Loading more messages for conversation: $conversationId');
      _logger.d('Oldest message ID: $oldestMessageId, limit: $limit');

      // Check pagination metadata to see if we have more messages
      final paginationData = await _databaseService.getPaginationMetadata(
        conversationId,
      );
      if (paginationData != null && !paginationData.hasMoreMessages) {
        _logger.d(
          'No more messages available for conversation: $conversationId',
        );
        return [];
      }

      // Get more messages using pagination
      return await getMessagesPaginated(
        conversationId: conversationId,
        cursorMessageId: oldestMessageId,
        limit: limit,
        fromCache: true,
      );
    } catch (e) {
      _logger.e('Error loading more messages: $e');
      return [];
    }
  }

  @override
  Future<List<MessageModel>> getLatestMessages({
    required String conversationId,
    int limit = 20,
  }) async {
    try {
      _logger.d('Getting latest messages for conversation: $conversationId');

      // Get latest messages from database first (for quick response)
      final dbMessages = await _databaseService.getLatestMessages(
        conversationId: conversationId,
        limit: limit,
      );

      final cachedMessages = ModelConverters.dbModelsToMessages(dbMessages);
      _logger.d(
        'Retrieved ${cachedMessages.length} latest messages from cache',
      );

      // Optionally refresh from network in background (fire and forget)
      _refreshLatestMessagesInBackground(conversationId, limit);

      return cachedMessages;
    } catch (e) {
      _logger.e('Error getting latest messages: $e');
      return [];
    }
  }

  @override
  Future<bool> hasMoreMessages(String conversationId) async {
    try {
      final paginationData = await _databaseService.getPaginationMetadata(
        conversationId,
      );
      final hasMore = paginationData?.hasMoreMessages ?? true;

      _logger.d('Conversation $conversationId has more messages: $hasMore');
      return hasMore;
    } catch (e) {
      _logger.e('Error checking if conversation has more messages: $e');
      return true; // Default to true if we can't determine
    }
  }

  // ================== HELPER METHODS ==================

  /// Refresh latest messages from network in background
  Future<void> _refreshLatestMessagesInBackground(
    String conversationId,
    int limit,
  ) async {
    try {
      final networkMessages = await _remoteDataSource.getMessages(
        conversationId,
        limit: limit,
      );

      if (networkMessages.isNotEmpty) {
        final dbModelsToSave = ModelConverters.messagesToDbModels(
          networkMessages,
        );
        await _databaseService.saveMessages(dbModelsToSave);
        _logger.d(
          'Background refresh: cached ${networkMessages.length} messages',
        );
      }
    } catch (e) {
      _logger.w(
        'Background refresh failed for conversation $conversationId: $e',
      );
    }
  }
}