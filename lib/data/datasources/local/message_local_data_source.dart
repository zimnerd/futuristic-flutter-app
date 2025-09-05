import '../../models/message_model.dart';

/// Local data source interface for message-related operations using Drift
abstract class MessageLocalDataSource {
  // Message CRUD operations
  Future<void> cacheMessage(MessageModel message);
  Future<MessageModel?> getCachedMessage(String messageId);
  Future<List<MessageModel>> getCachedMessages({
    String? conversationId,
    int? limit,
    String? beforeMessageId,
  });
  Future<void> updateCachedMessage(MessageModel message);
  Future<void> deleteCachedMessage(String messageId);

  // Conversation messages
  Future<List<MessageModel>> getConversationMessages(
    String conversationId, {
    int limit = 50,
    String? beforeMessageId,
  });
  Future<void> cacheConversationMessages(
    String conversationId,
    List<MessageModel> messages,
  );
  Future<void> clearConversationMessages(String conversationId);

  // Message status and read receipts
  Future<void> markMessageAsRead(String messageId, String userId);
  Future<void> markConversationAsRead(String conversationId, String userId);
  Future<List<MessageModel>> getUnreadMessages(String userId);
  Future<int> getUnreadMessageCount(String userId);
  Future<Map<String, DateTime>> getLastReadTimes(String conversationId);

  // Message delivery status
  Future<void> updateMessageDeliveryStatus(String messageId, String status);
  Future<String?> getMessageDeliveryStatus(String messageId);
  Future<List<MessageModel>> getPendingMessages();
  Future<void> markMessageAsPending(String messageId);
  Future<void> markMessageAsDelivered(String messageId);

  // Message search
  Future<List<MessageModel>> searchMessages({
    required String userId,
    required String query,
    String? conversationId,
    DateTime? startDate,
    DateTime? endDate,
    String? messageType,
    int limit = 50,
  });

  // Message reactions
  Future<void> cacheMessageReaction(
    String messageId,
    String userId,
    String reaction,
  );
  Future<void> removeMessageReaction(String messageId, String userId);
  Future<Map<String, List<String>>> getMessageReactions(String messageId);

  // Message media and attachments
  Future<void> cacheMessageMedia(
    String messageId,
    String mediaUrl,
    String localPath,
  );
  Future<String?> getLocalMediaPath(String messageId);
  Future<List<MessageModel>> getMessagesWithMedia(
    String conversationId,
    String mediaType,
  );

  // Typing indicators
  Future<void> cacheTypingIndicator(
    String conversationId,
    String userId,
    bool isTyping,
  );
  Future<Map<String, bool>> getTypingIndicators(String conversationId);
  Future<void> clearTypingIndicators(String conversationId);

  // Message queue for offline scenarios
  Future<void> queueMessage(MessageModel message);
  Future<List<MessageModel>> getQueuedMessages();
  Future<void> removeFromQueue(String messageId);
  Future<void> clearMessageQueue();

  // Message analytics and metadata
  Future<void> cacheMessageMetadata(
    String messageId,
    Map<String, dynamic> metadata,
  );
  Future<Map<String, dynamic>?> getMessageMetadata(String messageId);
  Future<Map<String, dynamic>> getConversationStats(String conversationId);

  // Offline support
  Future<void> markMessageForSync(String messageId);
  Future<List<String>> getMessagesMarkedForSync();
  Future<void> clearSyncFlag(String messageId);

  // Cache management
  Future<int> getCachedMessageCount({String? conversationId});
  Future<DateTime?> getLastMessageTime(String conversationId);
  Future<void> cleanOldMessages({Duration? maxAge, int? maxCount});
  Future<void> optimizeMessageStorage();
}
