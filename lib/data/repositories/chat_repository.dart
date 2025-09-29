import 'dart:async';
import '../models/chat_model.dart' hide ConversationModel;
import '../models/conversation_model.dart';
import '../models/message.dart' show MessageDeliveryUpdate;
import '../../domain/entities/message.dart' show MessageType;

/// Abstract repository for chat operations
abstract class ChatRepository {
  /// Stream of incoming messages
  Stream<MessageModel> get incomingMessages;

  /// Stream of message delivery confirmations
  Stream<MessageDeliveryUpdate> get messageDeliveryUpdates;
  /// Get list of conversations for the current user
  Future<List<ConversationModel>> getConversations();

  /// Get messages for a specific conversation
  Future<List<MessageModel>> getMessages({
    required String conversationId,
    int page = 1,
    int limit = 50,
  });

  /// Get messages with cursor-based pagination (new SQLite implementation)
  Future<List<MessageModel>> getMessagesPaginated({
    required String conversationId,
    String? cursorMessageId,
    int limit = 20,
    bool fromCache = true,
  });

  /// Load more messages (pagination helper)
  Future<List<MessageModel>> loadMoreMessages({
    required String conversationId,
    String? oldestMessageId,
    int limit = 20,
  });

  /// Get latest messages for real-time updates
  Future<List<MessageModel>> getLatestMessages({
    required String conversationId,
    int limit = 20,
  });

  /// Check if conversation has more messages to load
  Future<bool> hasMoreMessages(String conversationId);

  /// Send a new message
  Future<MessageModel> sendMessage({
    required String conversationId,
    required MessageType type,
    String? content,
    List<String>? mediaIds,
    Map<String, dynamic>? metadata,
    String? replyToMessageId,
    String? currentUserId,
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

  /// Check if a message ID is mapped from an optimistic message
  bool isOptimisticMessage(String? messageId, String realMessageId);

  /// Add reaction to a message
  Future<void> addReaction(String messageId, String emoji);

  /// Remove reaction from a message
  Future<void> removeReaction(String messageId, String emoji);
}