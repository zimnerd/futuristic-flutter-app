import '../../data/models/message_model.dart';

/// Repository interface for chat and messaging operations
abstract class MessageRepository {
  // Sending Messages
  Future<MessageModel> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
    String type = 'text',
    String? mediaUrl,
    Map<String, dynamic>? metadata,
  });

  Future<MessageModel> sendMediaMessage({
    required String conversationId,
    required String senderId,
    required String mediaPath,
    required String mediaType, // image, video, audio
    String? caption,
  });

  // Receiving Messages
  Future<List<MessageModel>> getConversationMessages(
    String conversationId, {
    int limit = 50,
    String? beforeMessageId,
  });

  Future<MessageModel?> getMessageById(String messageId);
  Future<List<MessageModel>> getUnreadMessages(String userId);
  Future<int> getUnreadMessageCount(String userId);

  // Message Status
  Future<void> markMessageAsRead(String messageId, String userId);
  Future<void> markConversationAsRead(String conversationId, String userId);
  Future<List<MessageModel>> getMessageDeliveryStatus(List<String> messageIds);

  // Message Actions
  Future<MessageModel> editMessage(String messageId, String newContent);
  Future<void> deleteMessage(String messageId, {bool forEveryone = false});
  Future<void> reactToMessage(String messageId, String userId, String reaction);
  Future<Map<String, List<String>>> getMessageReactions(String messageId);

  // Conversation Management
  Future<String> createConversation(String user1Id, String user2Id);
  Future<List<Map<String, dynamic>>> getUserConversations(String userId);
  Future<void> deleteConversation(String conversationId, String userId);
  Future<void> clearConversation(String conversationId);

  // Media & File Handling
  Future<String> uploadMediaFile(String filePath, String mediaType);
  Future<void> downloadMediaFile(String mediaUrl, String localPath);
  Future<List<String>> getConversationMedia(
      String conversationId, String mediaType);

  // Real-time Features
  Stream<MessageModel> getMessageStream(String conversationId);
  Stream<Map<String, dynamic>> getTypingIndicators(String conversationId);
  Future<void> sendTypingIndicator(
      String conversationId, String userId, bool isTyping);

  // Message Search
  Future<List<MessageModel>> searchMessages({
    required String userId,
    required String query,
    String? conversationId,
    DateTime? startDate,
    DateTime? endDate,
    String? messageType,
    int limit = 50,
  });

  // Offline Support
  Future<void> cacheMessage(MessageModel message);
  Future<List<MessageModel>> getCachedMessages(String conversationId);
  Future<void> syncPendingMessages();
  Future<List<MessageModel>> getPendingMessages();

  // Message Analytics
  Future<Map<String, dynamic>> getConversationStats(String conversationId);
  Future<Map<String, dynamic>> getUserMessagingStats(String userId);

  // Security & Moderation
  Future<void> reportMessage(
      String messageId, String reporterId, String reason);
  Future<bool> isMessageBlocked(String messageId);
  Future<void> blockUserMessages(String blockerId, String blockedUserId);
}
