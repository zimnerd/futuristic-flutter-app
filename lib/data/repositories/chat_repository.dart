import '../models/chat_model.dart';
import '../models/message.dart';

/// Abstract repository for chat operations
abstract class ChatRepository {
  /// Get list of conversations for the current user
  Future<List<ConversationModel>> getConversations();

  /// Get messages for a specific conversation
  Future<List<MessageModel>> getMessages({
    required String conversationId,
    int page = 1,
    int limit = 50,
  });

  /// Send a new message
  Future<MessageModel> sendMessage({
    required String conversationId,
    required MessageType type,
    String? content,
    List<String>? mediaIds,
    Map<String, dynamic>? metadata,
    String? replyToMessageId,
  });

  /// Mark a message as read
  Future<void> markMessageAsRead(String messageId);

  /// Delete a message
  Future<void> deleteMessage(String messageId);

  /// Update typing status
  Future<void> updateTypingStatus(String conversationId, bool isTyping);

  /// Create a new conversation
  Future<ConversationModel> createConversation(String participantId);

  /// Get conversation by ID
  Future<ConversationModel?> getConversation(String conversationId);

  /// Update conversation settings
  Future<ConversationModel> updateConversation({
    required String conversationId,
    Map<String, dynamic>? settings,
  });

  /// Delete/leave a conversation
  Future<void> deleteConversation(String conversationId);

  /// Mark conversation as read
  Future<void> markConversationAsRead(String conversationId);
}