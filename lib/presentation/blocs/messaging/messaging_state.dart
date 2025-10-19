part of 'messaging_bloc.dart';

/// Enum for messaging status
enum MessagingStatus { initial, loading, loaded, error }

/// State class for messaging functionality
class MessagingState extends Equatable {
  const MessagingState({
    this.conversationsStatus = MessagingStatus.initial,
    this.messagesStatus = MessagingStatus.initial,
    this.conversations = const [],
    this.currentMessages = const [],
    this.currentConversationId,
    this.hasReachedMaxConversations = false,
    this.hasReachedMaxMessages = false,
    this.typingUsers = const {},
    this.onlineUsers = const {},
    this.error,
  });

  final MessagingStatus conversationsStatus;
  final MessagingStatus messagesStatus;
  final List<Conversation> conversations;
  final List<Message> currentMessages;
  final String? currentConversationId;
  final bool hasReachedMaxConversations;
  final bool hasReachedMaxMessages;
  final Map<String, bool> typingUsers;
  final Map<String, bool> onlineUsers;
  final String? error;

  /// Get total unread count across all conversations
  int get totalUnreadCount {
    return conversations.fold(0, (sum, conv) => sum + conv.unreadCount);
  }

  /// Get messages for current conversation (alias for currentMessages)
  List<Message> get messages => currentMessages;

  /// Check if user is typing in current conversation
  bool isUserTyping(String userId) {
    return typingUsers[userId] ?? false;
  }

  /// Check if user is online
  bool isUserOnline(String userId) {
    return onlineUsers[userId] ?? false;
  }

  /// Get conversation by ID
  Conversation? getConversation(String conversationId) {
    try {
      return conversations.firstWhere((conv) => conv.id == conversationId);
    } catch (e) {
      return null;
    }
  }

  MessagingState copyWith({
    MessagingStatus? conversationsStatus,
    MessagingStatus? messagesStatus,
    List<Conversation>? conversations,
    List<Message>? currentMessages,
    String? currentConversationId,
    bool? hasReachedMaxConversations,
    bool? hasReachedMaxMessages,
    Map<String, bool>? typingUsers,
    Map<String, bool>? onlineUsers,
    String? error,
  }) {
    return MessagingState(
      conversationsStatus: conversationsStatus ?? this.conversationsStatus,
      messagesStatus: messagesStatus ?? this.messagesStatus,
      conversations: conversations ?? this.conversations,
      currentMessages: currentMessages ?? this.currentMessages,
      currentConversationId:
          currentConversationId ?? this.currentConversationId,
      hasReachedMaxConversations:
          hasReachedMaxConversations ?? this.hasReachedMaxConversations,
      hasReachedMaxMessages:
          hasReachedMaxMessages ?? this.hasReachedMaxMessages,
      typingUsers: typingUsers ?? this.typingUsers,
      onlineUsers: onlineUsers ?? this.onlineUsers,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    conversationsStatus,
    messagesStatus,
    conversations,
    currentMessages,
    currentConversationId,
    hasReachedMaxConversations,
    hasReachedMaxMessages,
    typingUsers,
    onlineUsers,
    error,
  ];
}
