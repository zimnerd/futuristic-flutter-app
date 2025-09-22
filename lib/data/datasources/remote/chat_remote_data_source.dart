import 'package:logger/logger.dart';

import '../../models/chat_model.dart' hide ConversationModel;
import '../../models/conversation_model.dart';
import '../../../domain/entities/message.dart' show MessageType;
import '../../../core/network/api_client.dart';
import '../../../core/network/response_parser.dart';
import '../../exceptions/app_exceptions.dart';

/// Remote data source for chat-related API operations
abstract class ChatRemoteDataSource {
  // Conversations
  Future<List<ConversationModel>> getConversations();
  Future<ConversationModel> getConversation(String conversationId);
  Future<ConversationModel> createConversation({
    required ConversationType type,
    required List<String> participantIds,
    String? name,
    String? description,
    String? imageUrl,
    ConversationSettings? settings,
  });
  Future<ConversationModel> updateConversation(
    String conversationId,
    Map<String, dynamic> updates,
  );
  Future<void> deleteConversation(String conversationId);
  Future<void> leaveConversation(String conversationId);

  // Messages
  Future<List<MessageModel>> getMessages(
    String conversationId, {
    int limit = 50,
    String? beforeMessageId,
  });
  Future<MessageModel> sendMessage({
    required String conversationId,
    required MessageType type,
    String? content,
    List<String>? mediaIds,
    Map<String, dynamic>? metadata,
    String? replyToMessageId,
  });
  Future<MessageModel> editMessage(String messageId, String newContent);
  Future<void> deleteMessage(String messageId);
  Future<void> markMessageAsRead(String messageId);
  Future<void> markConversationAsRead(
    String conversationId, {
    List<String>? messageIds,
  });

  // Message reactions
  Future<void> addReaction(String messageId, String emoji);
  Future<void> removeReaction(String messageId, String emoji);

  // Typing indicators
  Future<void> sendTypingIndicator(String conversationId, bool isTyping);

  // Media
  Future<String> uploadMedia(String filePath, MessageType type);

  // Search
  Future<List<MessageModel>> searchMessages(String query, {String? conversationId});

  // Online status
  Future<void> updateOnlineStatus(bool isOnline);

  // Advanced message actions
  Future<MessageModel> getMessage(String messageId);
  Future<void> copyMessageToClipboard(String messageId);
  Future<MessageModel> replyToMessage(
    String originalMessageId,
    String content,
    String conversationId,
  );
  Future<void> forwardMessage(
    String messageId,
    List<String> targetConversationIds,
  );
  Future<void> bookmarkMessage(String messageId, bool isBookmarked);
  Future<String> performContextualAction(
    String actionId,
    String actionType,
    Map<String, dynamic> actionData,
  );
  Future<void> updateMessageStatus(String messageId, String status);
}

/// Implementation of ChatRemoteDataSource using API service
class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final ApiClient _apiService;
  final Logger _logger = Logger();

  ChatRemoteDataSourceImpl(this._apiService);

  @override
  Future<List<ConversationModel>> getConversations() async {
    try {
      _logger.i('Getting conversations');

      final response = await _apiService.get('/chat/conversations');

      if (response.statusCode == 200) {
        _logger.d('Raw conversation response: ${response.data}');
        
        // Use centralized response parser
        final conversationsData = ResponseParser.extractList(
          response,
          'conversations',
        );
        
        _logger.d('Extracted ${conversationsData.length} conversations from response');
        
        final conversations = conversationsData
            .map((json) {
              try {
                _logger.d('Processing conversation JSON: $json');
                final conversation = ConversationModel.fromBackendJson(json);
                _logger.d('Parsed conversation: ${conversation.lastMessage}');
                return conversation;
              } catch (e) {
                _logger.e('Error parsing conversation: $e');
                _logger.e('Conversation data: $json');
                rethrow;
              }
            })
            .toList();
            
        return conversations;
      } else {
        throw ApiException(
          'Failed to get conversations: ${response.statusMessage}',
        );
      }
    } catch (e) {
      _logger.e('Get conversations error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to get conversations: ${e.toString()}');
    }
  }

  @override
  Future<ConversationModel> getConversation(String conversationId) async {
    try {
      _logger.i('Getting conversation: $conversationId');

      final response = await _apiService.get('/chat/conversations/$conversationId');

      if (response.statusCode == 200) {
        final responseData = ResponseParser.extractData(response);
        return ConversationModel.fromBackendJson(responseData);
      } else {
        throw ApiException(
          'Failed to get conversation: ${response.statusMessage}',
        );
      }
    } catch (e) {
      _logger.e('Get conversation error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to get conversation: ${e.toString()}');
    }
  }

  @override
  Future<ConversationModel> createConversation({
    required ConversationType type,
    required List<String> participantIds,
    String? name,
    String? description,
    String? imageUrl,
    ConversationSettings? settings,
  }) async {
    try {
      _logger.i('Creating conversation with ${participantIds.length} participants');

      final response = await _apiService.post(
        '/chat/conversations',
        data: {
          'type': type.name,
          'participantIds': participantIds,
          if (name != null) 'name': name,
          if (description != null) 'description': description,
          if (imageUrl != null) 'imageUrl': imageUrl,
          if (settings != null) 'settings': settings.toJson(),
        },
      );

      if (response.statusCode == 201) {
        final responseData = ResponseParser.extractData(response);
        return ConversationModel.fromBackendJson(responseData);
      } else {
        throw ApiException(
          'Failed to create conversation: ${response.statusMessage}',
        );
      }
    } catch (e) {
      _logger.e('Create conversation error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to create conversation: ${e.toString()}');
    }
  }

  @override
  Future<ConversationModel> updateConversation(
    String conversationId,
    Map<String, dynamic> updates,
  ) async {
    try {
      _logger.i('Updating conversation: $conversationId');

      final response = await _apiService.patch(
        '/chat/conversations/$conversationId',
        data: updates,
      );

      if (response.statusCode == 200) {
        final responseData = ResponseParser.extractData(response);
        return ConversationModel.fromBackendJson(responseData);
      } else {
        throw ApiException(
          'Failed to update conversation: ${response.statusMessage}',
        );
      }
    } catch (e) {
      _logger.e('Update conversation error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to update conversation: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteConversation(String conversationId) async {
    try {
      _logger.i('Deleting conversation: $conversationId');

      await _apiService.delete('/chat/conversations/$conversationId');
      _logger.i('Conversation deleted successfully');
    } catch (e) {
      _logger.e('Delete conversation error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to delete conversation: ${e.toString()}');
    }
  }

  @override
  Future<void> leaveConversation(String conversationId) async {
    try {
      _logger.i('Leaving conversation: $conversationId');

      await _apiService.post('/chat/conversations/$conversationId/leave');
      _logger.i('Left conversation successfully');
    } catch (e) {
      _logger.e('Leave conversation error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to leave conversation: ${e.toString()}');
    }
  }

  @override
  Future<List<MessageModel>> getMessages(
    String conversationId, {
    int limit = 50,
    String? beforeMessageId,
  }) async {
    try {
      _logger.i('Getting messages for conversation: $conversationId');

      final response = await _apiService.get(
        '/chat/conversations/$conversationId/messages',
        queryParameters: {
          'limit': limit,
          if (beforeMessageId != null) 'before': beforeMessageId,
        },
      );

      if (response.statusCode == 200) {
        _logger.i('Message response data: ${response.data}');
        final messagesData = ResponseParser.extractListDirect(response);
        _logger.i('Extracted messages data: $messagesData');
        _logger.i('Messages data length: ${messagesData.length}');
        final messages = messagesData
            .map((json) => MessageModel.fromJson(json))
            .toList();
        _logger.i('Parsed ${messages.length} messages');
        return messages;
      } else {
        throw ApiException('Failed to get messages: ${response.statusMessage}');
      }
    } catch (e) {
      _logger.e('Get messages error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to get messages: ${e.toString()}');
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
  }) async {
    try {
      _logger.i('Sending message to conversation: $conversationId');

      final response = await _apiService.post(
        '/chat/messages',
        data: {
          'conversationId': conversationId,
          'type': type.name,
          if (content != null) 'content': content,
          if (mediaIds != null) 'mediaIds': mediaIds,
          if (metadata != null) 'metadata': metadata,
          if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
        },
      );

      if (response.statusCode == 201) {
        final responseData = ResponseParser.extractData(response);
        return MessageModel.fromJson(responseData);
      } else {
        throw ApiException('Failed to send message: ${response.statusMessage}');
      }
    } catch (e) {
      _logger.e('Send message error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to send message: ${e.toString()}');
    }
  }

  @override
  Future<MessageModel> editMessage(String messageId, String newContent) async {
    try {
      _logger.i('Editing message: $messageId');

      final response = await _apiService.patch(
        '/chat/messages/$messageId',
        data: {'content': newContent},
      );

      if (response.statusCode == 200) {
        final responseData = ResponseParser.extractData(response);
        return MessageModel.fromJson(responseData);
      } else {
        throw ApiException('Failed to edit message: ${response.statusMessage}');
      }
    } catch (e) {
      _logger.e('Edit message error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to edit message: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    try {
      _logger.i('Deleting message: $messageId');

      await _apiService.delete('/chat/messages/$messageId');
      _logger.i('Message deleted successfully');
    } catch (e) {
      _logger.e('Delete message error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to delete message: ${e.toString()}');
    }
  }

  @override
  Future<void> markMessageAsRead(String messageId) async {
    try {
      _logger.i('Marking message as read: $messageId');

      await _apiService.patch('/chat/messages/$messageId/read');
      _logger.i('Message marked as read');
    } catch (e) {
      _logger.e('Mark message as read error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to mark message as read: ${e.toString()}');
    }
  }

  @override
  Future<void> markConversationAsRead(
    String conversationId, {
    List<String>? messageIds,
  }) async {
    try {
      _logger.i(
        'Marking conversation as read: $conversationId with ${messageIds?.length ?? 0} message IDs',
      );

      // Note: Backend expects POST to /chat/conversations/:conversationId/messages/read
      // with messageIds array in the body.
      await _apiService.post(
        '/chat/conversations/$conversationId/messages/read',
        data: {'messageIds': messageIds ?? []},
      );
      _logger.i('Conversation marked as read');
    } catch (e) {
      _logger.e('Mark conversation as read error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to mark conversation as read: ${e.toString()}');
    }
  }

  @override
  Future<void> addReaction(String messageId, String emoji) async {
    try {
      _logger.i('Adding reaction to message: $messageId');

      await _apiService.post(
        '/chat/messages/$messageId/reactions',
        data: {'emoji': emoji},
      );
      _logger.i('Reaction added successfully');
    } catch (e) {
      _logger.e('Add reaction error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to add reaction: ${e.toString()}');
    }
  }

  @override
  Future<void> removeReaction(String messageId, String emoji) async {
    try {
      _logger.i('Removing reaction from message: $messageId');

      await _apiService.delete(
        '/chat/messages/$messageId/reactions',
        data: {'emoji': emoji},
      );
      _logger.i('Reaction removed successfully');
    } catch (e) {
      _logger.e('Remove reaction error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to remove reaction: ${e.toString()}');
    }
  }

  @override
  Future<void> sendTypingIndicator(String conversationId, bool isTyping) async {
    try {
      _logger.d('Sending typing indicator for conversation: $conversationId');

      await _apiService.post(
        '/chat/conversations/$conversationId/typing',
        data: {'isTyping': isTyping},
      );
    } catch (e) {
      _logger.e('Send typing indicator error: $e');
      // Don't throw for typing indicators as they're not critical
    }
  }

  @override
  Future<String> uploadMedia(String filePath, MessageType type) async {
    try {
      _logger.i('Uploading media file: $filePath');

      final response = await _apiService.post(
        '/chat/media/upload',
        data: {
          'filePath': filePath,
          'type': type.name,
        },
      );

      if (response.statusCode == 201) {
        return response.data['mediaId'];
      } else {
        throw ApiException('Failed to upload media: ${response.statusMessage}');
      }
    } catch (e) {
      _logger.e('Upload media error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to upload media: ${e.toString()}');
    }
  }

  @override
  Future<List<MessageModel>> searchMessages(
    String query, {
    String? conversationId,
  }) async {
    try {
      _logger.i('Searching messages with query: $query');

      final response = await _apiService.get(
        '/chat/messages/search',
        queryParameters: {
          'q': query,
          if (conversationId != null) 'conversationId': conversationId,
        },
      );

      if (response.statusCode == 200) {
        final messagesData = ResponseParser.extractList(response, 'messages');
        return messagesData.map((json) => MessageModel.fromJson(json)).toList();
      } else {
        throw ApiException('Failed to search messages: ${response.statusMessage}');
      }
    } catch (e) {
      _logger.e('Search messages error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to search messages: ${e.toString()}');
    }
  }

  @override
  Future<void> updateOnlineStatus(bool isOnline) async {
    try {
      _logger.i('Updating online status: $isOnline');

      await _apiService.patch(
        '/chat/status',
        data: {'isOnline': isOnline},
      );
      _logger.i('Online status updated');
    } catch (e) {
      _logger.e('Update online status error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to update online status: ${e.toString()}');
    }
  }

  @override
  Future<MessageModel> getMessage(String messageId) async {
    try {
      _logger.i('Getting message: $messageId');

      final response = await _apiService.get('/chat/messages/$messageId');

      if (response.statusCode == 200) {
        final responseData = ResponseParser.extractData(response);
        return MessageModel.fromJson(responseData);
      } else {
        throw ApiException('Failed to get message: ${response.statusMessage}');
      }
    } catch (e) {
      _logger.e('Get message error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to get message: ${e.toString()}');
    }
  }

  @override
  Future<void> copyMessageToClipboard(String messageId) async {
    try {
      _logger.i('Copying message to clipboard: $messageId');

      await _apiService.post('/chat/messages/$messageId/copy');
      _logger.i('Message copied to clipboard');
    } catch (e) {
      _logger.e('Copy message error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to copy message: ${e.toString()}');
    }
  }

  @override
  Future<MessageModel> replyToMessage(
    String originalMessageId,
    String content,
    String conversationId,
  ) async {
    try {
      _logger.i('Replying to message: $originalMessageId');

      final response = await _apiService.post(
        '/chat/messages/$originalMessageId/reply',
        data: {'content': content, 'conversationId': conversationId},
      );

      if (response.statusCode == 201) {
        final responseData = ResponseParser.extractData(response);
        return MessageModel.fromJson(responseData);
      } else {
        throw ApiException(
          'Failed to reply to message: ${response.statusMessage}',
        );
      }
    } catch (e) {
      _logger.e('Reply to message error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to reply to message: ${e.toString()}');
    }
  }

  @override
  Future<void> forwardMessage(
    String messageId,
    List<String> targetConversationIds,
  ) async {
    try {
      _logger.i('Forwarding message: $messageId');

      await _apiService.post(
        '/chat/messages/$messageId/forward',
        data: {'targetConversationIds': targetConversationIds},
      );
      _logger.i('Message forwarded');
    } catch (e) {
      _logger.e('Forward message error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to forward message: ${e.toString()}');
    }
  }

  @override
  Future<void> bookmarkMessage(String messageId, bool isBookmarked) async {
    try {
      _logger.i('Updating bookmark for message: $messageId');

      await _apiService.patch(
        '/chat/messages/$messageId/bookmark',
        data: {'isBookmarked': isBookmarked},
      );
      _logger.i('Message bookmark updated');
    } catch (e) {
      _logger.e('Bookmark message error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to update bookmark: ${e.toString()}');
    }
  }

  @override
  Future<String> performContextualAction(
    String actionId,
    String actionType,
    Map<String, dynamic> actionData,
  ) async {
    try {
      _logger.i('Performing contextual action: $actionId');

      final response = await _apiService.post(
        '/chat/actions/contextual',
        data: {
          'actionId': actionId,
          'actionType': actionType,
          'actionData': actionData,
        },
      );

      if (response.statusCode == 200) {
        return response.data['result'] ?? 'Action completed';
      } else {
        throw ApiException(
          'Failed to perform action: ${response.statusMessage}',
        );
      }
    } catch (e) {
      _logger.e('Contextual action error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to perform action: ${e.toString()}');
    }
  }

  @override
  Future<void> updateMessageStatus(String messageId, String status) async {
    try {
      _logger.i('Updating message status: $messageId -> $status');

      await _apiService.patch(
        '/chat/messages/$messageId/status',
        data: {'status': status},
      );
      _logger.i('Message status updated');
    } catch (e) {
      _logger.e('Update message status error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to update message status: ${e.toString()}');
    }
  }
}