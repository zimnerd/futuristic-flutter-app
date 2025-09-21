import 'dart:async';
import '../models/chat_model.dart';
import '../models/message.dart' as msg;

/// Abstract repository for chat operations
abstract class ChatRepository {
  /// Stream of incoming messages
  Stream<MessageModel> get incomingMessages;

  /// Stream of message delivery confirmations
  Stream<msg.MessageDeliveryUpdate> get messageDeliveryUpdates;
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
    required msg.MessageType type,
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
  Future<void> markConversationAsRead(
    String conversationId, {
    List<String>? messageIds,
  });

  // Advanced message actions
  /// Get a specific message by ID
  Future<MessageModel> getMessage(String messageId);

  /// Copy message content to clipboard
  Future<void> copyMessageToClipboard(String messageId);

  /// Edit an existing message
  Future<MessageModel> editMessage(String messageId, String newContent);

  /// Reply to a specific message
  Future<MessageModel> replyToMessage(
    String originalMessageId,
    String content,
    String conversationId,
  );

  /// Forward a message to other conversations
  Future<void> forwardMessage(
    String messageId,
    List<String> targetConversationIds,
  );

  /// Bookmark or unbookmark a message
  Future<void> bookmarkMessage(String messageId, bool isBookmarked);

  /// Perform contextual AI actions
  Future<String> performContextualAction(
    String actionId,
    String actionType,
    Map<String, dynamic> actionData,
  );

  /// Update message status (delivered, read, etc.)
  Future<void> updateMessageStatus(String messageId, String status);

  /// Join a conversation room for real-time updates
  Future<void> joinConversation(String conversationId);

  /// Leave a conversation room
  Future<void> leaveConversation(String conversationId);
}