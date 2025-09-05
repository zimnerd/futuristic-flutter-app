import 'package:dio/dio.dart';

import '../../models/message_model.dart';

/// Remote data source interface for message-related API operations
abstract class MessageRemoteDataSource {
  // Message Sending
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
    required String mediaType,
    String? caption,
  });

  Future<void> sendTypingIndicator(String conversationId, String userId, bool isTyping);

  // Message Retrieval
  Future<List<MessageModel>> getConversationMessages(
    String conversationId, {
    int limit = 50,
    String? beforeMessageId,
    String? afterMessageId,
  });

  Future<MessageModel> getMessageById(String messageId);
  Future<List<MessageModel>> getUnreadMessages(String userId);
  Future<int> getUnreadMessageCount(String userId);

  // Message Status & Read Receipts
  Future<void> markMessageAsRead(String messageId, String userId);
  Future<void> markConversationAsRead(String conversationId, String userId);
  Future<List<MessageModel>> getMessageDeliveryStatus(List<String> messageIds);
  Future<Map<String, DateTime>> getLastReadTimes(String conversationId);

  // Message Actions
  Future<MessageModel> editMessage(String messageId, String newContent);
  Future<void> deleteMessage(String messageId, {bool forEveryone = false});
  Future<void> reactToMessage(String messageId, String userId, String reaction);
  Future<void> removeMessageReaction(String messageId, String userId);
  Future<Map<String, List<String>>> getMessageReactions(String messageId);

  // Conversation Management
  Future<String> createConversation(String user1Id, String user2Id);
  Future<List<Map<String, dynamic>>> getUserConversations(String userId);
  Future<void> deleteConversation(String conversationId, String userId);
  Future<void> clearConversation(String conversationId);
  Future<Map<String, dynamic>> getConversationInfo(String conversationId);

  // Media & File Handling
  Future<String> uploadMediaFile(String filePath, String mediaType);
  Future<String> getMediaDownloadUrl(String mediaId);
  Future<List<String>> getConversationMedia(String conversationId, String mediaType);
  Future<void> deleteMediaFile(String mediaId);

  // Message Search
  Future<List<MessageModel>> searchMessages({
    required String userId,
    required String query,
    String? conversationId,
    DateTime? startDate,
    DateTime? endDate,
    String? messageType,
    int page = 1,
    int limit = 50,
  });

  Future<List<MessageModel>> getMessagesByType(
    String conversationId,
    String messageType, {
    int limit = 50,
  });

  // Real-time Features
  Future<void> joinConversation(String conversationId, String userId);
  Future<void> leaveConversation(String conversationId, String userId);
  Future<Map<String, dynamic>> getOnlineStatus(String conversationId);

  // Message Analytics
  Future<Map<String, dynamic>> getConversationStats(String conversationId);
  Future<Map<String, dynamic>> getUserMessagingStats(String userId);
  Future<Map<String, dynamic>> getMessageAnalytics(String messageId);

  // Security & Moderation
  Future<void> reportMessage(String messageId, String reporterId, String reason);
  Future<bool> isMessageBlocked(String messageId);
  Future<void> blockUserMessages(String blockerId, String blockedUserId);
  Future<void> unblockUserMessages(String blockerId, String blockedUserId);

  // Message Encryption (for secure conversations)
  Future<String> encryptMessage(String content, String conversationId);
  Future<String> decryptMessage(String encryptedContent, String conversationId);
  Future<Map<String, dynamic>> getEncryptionInfo(String conversationId);

  // Conversation Settings
  Future<void> updateConversationSettings({
    required String conversationId,
    String? name,
    bool? isArchived,
    bool? isMuted,
    Map<String, dynamic>? settings,
  });

  Future<Map<String, dynamic>> getConversationSettings(String conversationId);

  // Message Threading & Replies
  Future<MessageModel> replyToMessage({
    required String conversationId,
    required String senderId,
    required String content,
    required String replyToMessageId,
    String type = 'text',
  });

  Future<List<MessageModel>> getMessageReplies(String messageId);
  Future<MessageModel> forwardMessage({
    required String messageId,
    required String toConversationId,
    required String senderId,
  });

  // Bulk Operations
  Future<void> markMultipleAsRead(List<String> messageIds, String userId);
  Future<void> deleteMultipleMessages(List<String> messageIds, {bool forEveryone = false});
  Future<List<MessageModel>> getMultipleMessages(List<String> messageIds);

  // Error Handling
  Future<T> handleApiCall<T>(Future<Response> Function() apiCall);
  Exception mapErrorToException(DioException error);
}
