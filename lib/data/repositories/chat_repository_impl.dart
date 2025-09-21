import 'package:logger/logger.dart';
import 'package:pulse_dating_app/data/models/message.dart' as data_message;

import '../models/chat_model.dart';
import '../datasources/remote/chat_remote_data_source.dart';
import '../../domain/services/websocket_service.dart';
import '../services/websocket_service_impl.dart';
import '../../domain/entities/message.dart' as domain;
import 'chat_repository.dart';

/// Implementation of ChatRepository with real-time Socket.IO support
class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource _remoteDataSource;
  final WebSocketService _webSocketService;
  final Logger _logger = Logger();

  ChatRepositoryImpl({
    required ChatRemoteDataSource remoteDataSource,
    WebSocketService? webSocketService,
  }) : _remoteDataSource = remoteDataSource,
       _webSocketService = webSocketService ?? WebSocketServiceImpl.instance;

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
    required data_message.MessageType type,
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
      final optimisticMessage = MessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        conversationId: conversationId,
        senderId: 'current_user', // This should be set from auth state
        senderUsername: 'You', // This should be set from auth state
        type: _convertToDomainMessageType(type),
        content: content,
        status: MessageStatus.sending,
        mediaUrls: mediaIds,
        metadata: metadata,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
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
  Future<ConversationModel> createConversation(String participantId) async {
    try {
      _logger.d('Creating conversation with participant: $participantId');
      final conversation = await _remoteDataSource.createConversation(
        type: ConversationType.direct, // Default to direct conversation
        participantIds: [participantId],
      );
      _logger.d('Successfully created conversation: ${conversation.id}');
      return conversation;
    } catch (e) {
      _logger.e('Error creating conversation: $e');
      rethrow;
    }
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
  Future<void> markConversationAsRead(String conversationId) async {
    try {
      _logger.d('Marking conversation as read: $conversationId');
      await _remoteDataSource.markConversationAsRead(conversationId);
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
}