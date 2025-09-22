import '../models/chat_model.dart';
import '../database/models/database_models.dart';
import '../../domain/entities/message.dart' show MessageType;

/// Utility class for converting between API models and database models
/// Handles data transformation for local caching and network synchronization
class ModelConverters {
  
  // ================== MESSAGE CONVERSIONS ==================

  /// Convert API MessageModel to database MessageDbModel
  static MessageDbModel messageToDbModel(MessageModel message) {
    return MessageDbModel(
      id: message.id,
      conversationId: message.conversationId,
      senderId: message.senderId,
      senderUsername: message.senderUsername,
      senderAvatar: message.senderAvatar,
      type: message.type.name,
      content: message.content,
      mediaUrls: message.mediaUrls,
      metadata: message.metadata,
      status: message.status.name,
      reactions: _reactionsToMap(message.reactions),
      replyToId: message.replyTo?.id,
      tempId: message.tempId,
      createdAt: message.createdAt,
      updatedAt: message.updatedAt,
      syncStatus: 'synced', // API messages are considered synced
    );
  }

  /// Convert database MessageDbModel to API MessageModel
  static MessageModel dbModelToMessage(MessageDbModel dbMessage) {
    return MessageModel(
      id: dbMessage.id,
      conversationId: dbMessage.conversationId,
      senderId: dbMessage.senderId,
      senderUsername: dbMessage.senderUsername ?? 'Unknown',
      senderAvatar: dbMessage.senderAvatar,
      type: MessageType.values.byName(dbMessage.type),
      content: dbMessage.content,
      mediaUrls: dbMessage.mediaUrls,
      metadata: dbMessage.metadata,
      status: MessageStatus.values.byName(dbMessage.status),
      reactions: _mapToReactions(dbMessage.reactions),
      createdAt: dbMessage.createdAt,
      updatedAt: dbMessage.updatedAt,
      tempId: dbMessage.tempId,
    );
  }

  /// Convert list of API messages to database models
  static List<MessageDbModel> messagesToDbModels(List<MessageModel> messages) {
    return messages.map((message) => messageToDbModel(message)).toList();
  }

  /// Convert list of database models to API messages
  static List<MessageModel> dbModelsToMessages(List<MessageDbModel> dbMessages) {
    return dbMessages.map((dbMessage) => dbModelToMessage(dbMessage)).toList();
  }

  /// Create optimistic database message from send parameters
  static MessageDbModel createOptimisticDbMessage({
    required String tempId,
    required String conversationId,
    required String senderId,
    required String type,
    String? content,
    List<String>? mediaUrls,
    Map<String, dynamic>? metadata,
    String? replyToId,
    String? senderUsername,
    String? senderAvatar,
  }) {
    final now = DateTime.now();
    
    return MessageDbModel(
      id: tempId, // Use tempId as ID for optimistic messages
      conversationId: conversationId,
      senderId: senderId,
      senderUsername: senderUsername,
      senderAvatar: senderAvatar,
      type: type,
      content: content,
      mediaUrls: mediaUrls,
      metadata: metadata,
      status: 'sending',
      reactions: null,
      replyToId: replyToId,
      tempId: tempId,
      createdAt: now,
      updatedAt: now,
      syncStatus: 'pending', // Mark as unsynced
    );
  }

  // ================== CONVERSATION CONVERSIONS ==================

  /// Convert API ConversationModel to database ConversationDbModel
  static ConversationDbModel conversationToDbModel(ConversationModel conversation) {
    return ConversationDbModel(
      id: conversation.id,
      type: conversation.type.name,
      participantIds: conversation.participantIds,
      name: conversation.name,
      description: conversation.description,
      imageUrl: conversation.imageUrl,
      lastMessageId: conversation.lastMessage?.id,
      lastMessageAt: conversation.lastMessage?.createdAt,
      unreadCount: conversation.unreadCount,
      settings: conversation.settings?.toJson(),
      createdAt: conversation.createdAt,
      updatedAt: conversation.updatedAt,
      syncStatus: 'synced',
    );
  }

  /// Convert database ConversationDbModel to API ConversationModel
  static ConversationModel dbModelToConversation(
    ConversationDbModel dbConversation, {
    MessageModel? lastMessage,
  }) {
    return ConversationModel(
      id: dbConversation.id,
      type: ConversationType.values.byName(dbConversation.type),
      participantIds: dbConversation.participantIds,
      name: dbConversation.name,
      description: dbConversation.description,
      imageUrl: dbConversation.imageUrl,
      lastMessage: lastMessage,
      lastMessageAt: dbConversation.lastMessageAt,
      unreadCount: dbConversation.unreadCount,
      settings: dbConversation.settings != null 
          ? ConversationSettings.fromJson(dbConversation.settings!)
          : null,
      createdAt: dbConversation.createdAt,
      updatedAt: dbConversation.updatedAt,
    );
  }

  /// Convert list of API conversations to database models
  static List<ConversationDbModel> conversationsToDbModels(List<ConversationModel> conversations) {
    return conversations.map((conversation) => conversationToDbModel(conversation)).toList();
  }

  /// Convert list of database models to API conversations
  static List<ConversationModel> dbModelsToConversations(
    List<ConversationDbModel> dbConversations, {
    Map<String, MessageModel> lastMessages = const {},
  }) {
    return dbConversations.map((dbConversation) {
      final lastMessage = lastMessages[dbConversation.lastMessageId];
      return dbModelToConversation(dbConversation, lastMessage: lastMessage);
    }).toList();
  }

  // ================== PAGINATION HELPERS ==================

  /// Create initial pagination metadata for a conversation
  static PaginationMetadata createInitialPaginationMetadata(
    String conversationId,
  ) {
    return PaginationMetadata(
      conversationId: conversationId,
      oldestMessageId: null,
      hasMoreMessages: true,
      lastSyncAt: null,
      totalMessagesCount: 0,
    );
  }

  /// Update pagination metadata after loading messages
  static PaginationMetadata updatePaginationMetadata(
    PaginationMetadata currentMetadata,
    List<MessageDbModel> loadedMessages,
    bool hasMore,
  ) {
    String? oldestMessageId = currentMetadata.oldestMessageId;
    
    if (loadedMessages.isNotEmpty) {
      // Find the oldest message from the loaded batch
      final oldestMessage = loadedMessages.reduce((a, b) => 
        a.createdAt.isBefore(b.createdAt) ? a : b
      );
      oldestMessageId = oldestMessage.id;
    }
    
    return currentMetadata.copyWith(
      oldestMessageId: oldestMessageId,
      hasMoreMessages: hasMore,
      lastSyncAt: DateTime.now(),
      totalMessagesCount: currentMetadata.totalMessagesCount + loadedMessages.length,
    );
  }

  // ================== VALIDATION HELPERS ==================

  /// Validate if a message can be converted to database model
  static bool isValidForDatabase(MessageModel message) {
    return message.id.isNotEmpty &&
           message.conversationId.isNotEmpty &&
           message.senderId.isNotEmpty;
  }

  /// Validate if a conversation can be converted to database model
  static bool isValidConversationForDatabase(ConversationModel conversation) {
    return conversation.id.isNotEmpty &&
           conversation.participantIds.isNotEmpty;
  }

  // ================== SYNC STATUS HELPERS ==================

  /// Mark database message as needing sync
  static MessageDbModel markAsNeedsSync(MessageDbModel dbMessage) {
    return dbMessage.copyWith(
      syncStatus: 'pending',
      updatedAt: DateTime.now(),
    );
  }

  /// Mark database message as synced
  static MessageDbModel markAsSynced(MessageDbModel dbMessage) {
    return dbMessage.copyWith(
      syncStatus: 'synced',
      updatedAt: DateTime.now(),
    );
  }

  /// Mark database conversation as needing sync
  static ConversationDbModel markConversationAsNeedsSync(ConversationDbModel dbConversation) {
    return dbConversation.copyWith(
      syncStatus: 'pending',
      updatedAt: DateTime.now(),
    );
  }

  /// Mark database conversation as synced
  static ConversationDbModel markConversationAsSynced(ConversationDbModel dbConversation) {
    return dbConversation.copyWith(
      syncStatus: 'synced',
      updatedAt: DateTime.now(),
    );
  }

  // ================== OPTIMISTIC UPDATE HELPERS ==================

  /// Create a successful message from optimistic message
  static MessageDbModel optimisticToSuccessful({
    required MessageDbModel optimisticMessage,
    required String serverId,
    String? serverStatus,
  }) {
    return optimisticMessage.copyWith(
      id: serverId,
      status: serverStatus ?? 'sent',
      syncStatus: 'synced',
      updatedAt: DateTime.now(),
    );
  }

  /// Create a failed message from optimistic message
  static MessageDbModel optimisticToFailed(
    MessageDbModel optimisticMessage, {
    String? errorMessage,
  }) {
    final metadata = Map<String, dynamic>.from(optimisticMessage.metadata ?? {});
    if (errorMessage != null) {
      metadata['error'] = errorMessage;
    }
    
    return optimisticMessage.copyWith(
      status: 'failed',
      metadata: metadata,
      syncStatus: 'failed',
      updatedAt: DateTime.now(),
    );
  }

  // ================== PRIVATE HELPER METHODS ==================

  /// Convert reactions list to map for database storage
  static Map<String, dynamic>? _reactionsToMap(List<MessageReaction>? reactions) {
    if (reactions == null || reactions.isEmpty) return null;
    
    final Map<String, dynamic> reactionMap = {};
    for (final reaction in reactions) {
      final emoji = reaction.emoji;
      if (reactionMap.containsKey(emoji)) {
        final data = reactionMap[emoji] as Map<String, dynamic>;
        (data['userIds'] as List<String>).add(reaction.userId);
        (data['usernames'] as List<String>).add(reaction.username);
        (data['timestamps'] as List<int>).add(reaction.createdAt.millisecondsSinceEpoch);
      } else {
        reactionMap[emoji] = {
          'userIds': [reaction.userId],
          'usernames': [reaction.username],
          'timestamps': [reaction.createdAt.millisecondsSinceEpoch],
        };
      }
    }
    return reactionMap;
  }

  /// Convert reactions map to list for API model
  static List<MessageReaction>? _mapToReactions(Map<String, dynamic>? reactionsMap) {
    if (reactionsMap == null || reactionsMap.isEmpty) return null;
    
    final List<MessageReaction> reactions = [];
    reactionsMap.forEach((emoji, reactionData) {
      if (reactionData is List) {
        // Legacy format: just user IDs
        for (final userId in reactionData) {
          reactions.add(MessageReaction(
            emoji: emoji,
            userId: userId.toString(),
            username: 'Unknown', // Default username for legacy data
            createdAt: DateTime.now(),
          ));
        }
      } else if (reactionData is Map) {
        // New format: with usernames and timestamps
        final userIds = reactionData['userIds'] as List? ?? [];
        final usernames = reactionData['usernames'] as List? ?? [];
        final timestamps = reactionData['timestamps'] as List? ?? [];
        
        for (int i = 0; i < userIds.length; i++) {
          reactions.add(MessageReaction(
            emoji: emoji,
            userId: userIds[i].toString(),
            username: i < usernames.length ? usernames[i].toString() : 'Unknown',
            createdAt: i < timestamps.length 
                ? DateTime.fromMillisecondsSinceEpoch(timestamps[i] as int)
                : DateTime.now(),
          ));
        }
      }
    });
    return reactions.isEmpty ? null : reactions;
  }
}