import 'package:logger/logger.dart';
import 'package:pulse_dating_app/data/models/message.dart';

import '../models/chat_model.dart';
import '../datasources/remote/chat_remote_data_source.dart';
import 'chat_repository.dart';

/// Implementation of ChatRepository
class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource _remoteDataSource;
  final Logger _logger = Logger();

  ChatRepositoryImpl({
    required ChatRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

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
    required MessageType type,
    String? content,
    List<String>? mediaIds,
    Map<String, dynamic>? metadata,
    String? replyToMessageId,
  }) async {
    try {
      _logger.d('Sending message to conversation: $conversationId');
      final message = await _remoteDataSource.sendMessage(
        conversationId: conversationId,
        type: type,
        content: content,
        mediaIds: mediaIds,
        metadata: metadata,
        replyToMessageId: replyToMessageId,
      );
      _logger.d('Successfully sent message: ${message.id}');
      return message;
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
      _logger.d('Updating typing status for conversation: $conversationId');
      await _remoteDataSource.sendTypingIndicator(conversationId, isTyping);
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
}