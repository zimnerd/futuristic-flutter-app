/// Repository interface for chat room and conversation management
abstract class ConversationRepository {
  // Conversation Discovery
  Future<List<Map<String, dynamic>>> getActiveConversations(String userId);
  Future<List<Map<String, dynamic>>> getArchivedConversations(String userId);
  Future<Map<String, dynamic>?> getConversationById(String conversationId);
  Future<Map<String, dynamic>?> getConversationBetweenUsers(
      String user1Id, String user2Id);

  // Conversation Creation & Management
  Future<String> startConversation(String initiatorId, String receiverId);
  Future<void> updateConversationSettings({
    required String conversationId,
    String? name,
    bool? isArchived,
    bool? isMuted,
    Map<String, dynamic>? settings,
  });

  // Conversation Status
  Future<void> archiveConversation(String conversationId, String userId);
  Future<void> unarchiveConversation(String conversationId, String userId);
  Future<void> muteConversation(
      String conversationId, String userId, Duration? duration);
  Future<void> unmuteConversation(String conversationId, String userId);

  // Participant Management
  Future<List<Map<String, dynamic>>> getConversationParticipants(
      String conversationId);
  Future<void> addParticipant(String conversationId, String userId);
  Future<void> removeParticipant(String conversationId, String userId);
  Future<bool> isUserInConversation(String conversationId, String userId);

  // Last Activity & Read Receipts
  Future<void> updateLastSeen(String conversationId, String userId);
  Future<Map<String, DateTime>> getLastSeenTimes(String conversationId);
  Future<DateTime?> getLastActivity(String conversationId);

  // Conversation Metadata
  Future<int> getTotalMessageCount(String conversationId);
  Future<Map<String, dynamic>> getConversationSummary(String conversationId);
  Future<List<String>> getConversationTags(String conversationId);
  Future<void> addConversationTag(String conversationId, String tag);
  Future<void> removeConversationTag(String conversationId, String tag);

  // Search & Filtering
  Future<List<Map<String, dynamic>>> searchConversations({
    required String userId,
    String? query,
    bool? hasUnreadMessages,
    bool? isArchived,
    bool? isMuted,
    DateTime? lastActivityBefore,
    DateTime? lastActivityAfter,
  });

  // Conversation Actions
  Future<void> clearConversationHistory(String conversationId);
  Future<void> deleteConversation(String conversationId, String userId);
  Future<void> blockConversation(String conversationId, String userId);
  Future<void> unblockConversation(String conversationId, String userId);

  // Real-time Updates
  Stream<Map<String, dynamic>> getConversationUpdates(String conversationId);
  Stream<List<Map<String, dynamic>>> getUserConversationsStream(String userId);

  // Privacy & Security
  Future<bool> canUserStartConversation(String initiatorId, String receiverId);
  Future<List<String>> getBlockedConversations(String userId);
  Future<void> reportConversation(
      String conversationId, String reporterId, String reason);

  // Offline Support
  Future<void> cacheConversation(Map<String, dynamic> conversation);
  Future<List<Map<String, dynamic>>> getCachedConversations(String userId);
  Future<void> syncConversations(String userId);

  // Analytics
  Future<Map<String, dynamic>> getConversationAnalytics(String conversationId);
  Future<Map<String, dynamic>> getUserConversationStats(String userId);
}
