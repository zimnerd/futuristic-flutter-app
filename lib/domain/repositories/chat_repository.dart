import '../../data/models/chat_model.dart' hide ConversationModel;
import '../../data/models/conversation_model.dart';
import '../../data/models/message.dart'
    show MessageDeliveryUpdate, MessageReadUpdate;
import '../entities/message.dart' show MessageType;

/// Repository interface for chat operations
abstract class ChatRepository {
  // Conversations
  Future<List<ConversationModel>> getConversations();
  Future<ConversationModel?> getConversation(String conversationId);
  Future<ConversationModel> createConversation(String participantId);
  Future<ConversationModel> updateConversation({
    required String conversationId,
    Map<String, dynamic>? settings,
  });
  Future<void> deleteConversation(String conversationId);
  Future<void> joinConversation(String conversationId);
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
  Future<void> markMessageAsReadWithRealTimeUpdate(
    String messageId,
    String conversationId,
  );
  Future<void> markConversationAsRead(String conversationId);

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
  Stream<Map<String, bool>> getOnlineStatusUpdates();

  // Real-time updates
  Stream<MessageModel> getMessageUpdates();
  Stream<ConversationModel> getConversationUpdates();
  Stream<Map<String, bool>> getTypingUpdates();
  
  // Message delivery status updates
  Stream<MessageDeliveryUpdate> getDeliveryUpdates();
  
  // Message read status updates
  Stream<MessageReadUpdate> getMessageReadUpdates();

  // Convenient getters for streams (for backward compatibility)
  Stream<MessageModel> get messageStream => getMessageUpdates();
  Stream<MessageDeliveryUpdate> get deliveryUpdates => getDeliveryUpdates();
  Stream<MessageReadUpdate> get messageReadUpdates => getMessageReadUpdates();

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