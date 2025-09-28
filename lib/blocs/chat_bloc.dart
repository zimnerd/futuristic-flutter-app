import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:logger/logger.dart';
import 'dart:async';

import '../data/models/chat_model.dart' hide ConversationModel;
import '../data/models/conversation_model.dart';
import '../data/models/message.dart' show MessageDeliveryUpdate;
import '../domain/entities/message.dart' show MessageType;
import '../data/repositories/chat_repository.dart';
import '../data/services/background_sync_manager.dart';

// Events
abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class LoadConversations extends ChatEvent {
  const LoadConversations();
}

class LoadMessages extends ChatEvent {
  final String conversationId;
  final int page;
  final int limit;

  const LoadMessages({
    required this.conversationId,
    this.page = 1,
    this.limit = 50,
  });

  @override
  List<Object?> get props => [conversationId, page, limit];
}

class LoadLatestMessages extends ChatEvent {
  final String conversationId;
  final int limit;

  const LoadLatestMessages({required this.conversationId, this.limit = 20});

  @override
  List<Object?> get props => [conversationId, limit];
}

class LoadMoreMessages extends ChatEvent {
  final String conversationId;
  final String? oldestMessageId;
  final int limit;

  const LoadMoreMessages({
    required this.conversationId,
    this.oldestMessageId,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [conversationId, oldestMessageId, limit];
}

class RefreshMessages extends ChatEvent {
  final String conversationId;

  const RefreshMessages({required this.conversationId});

  @override
  List<Object?> get props => [conversationId];
}

class SyncConversations extends ChatEvent {
  const SyncConversations();
}

class SendMessage extends ChatEvent {
  final String conversationId;
  final MessageType type;
  final String? content;
  final List<String>? mediaIds;
  final Map<String, dynamic>? metadata;
  final String? replyToMessageId;
  final String? currentUserId;

  const SendMessage({
    required this.conversationId,
    required this.type,
    this.content,
    this.mediaIds,
    this.metadata,
    this.replyToMessageId,
    this.currentUserId,
  });

  @override
  List<Object?> get props => [
    conversationId,
    type,
    content,
    mediaIds,
    metadata,
    replyToMessageId,
    currentUserId,
  ];
}

class MarkMessageAsRead extends ChatEvent {
  final String messageId;

  const MarkMessageAsRead({required this.messageId});

  @override
  List<Object?> get props => [messageId];
}

class DeleteMessage extends ChatEvent {
  final String messageId;

  const DeleteMessage({required this.messageId});

  @override
  List<Object?> get props => [messageId];
}

class UpdateTypingStatus extends ChatEvent {
  final String conversationId;
  final bool isTyping;

  const UpdateTypingStatus({
    required this.conversationId,
    required this.isTyping,
  });

  @override
  List<Object?> get props => [conversationId, isTyping];
}

class MarkConversationAsRead extends ChatEvent {
  final String conversationId;

  const MarkConversationAsRead({required this.conversationId});

  @override
  List<Object?> get props => [conversationId];
}

class CreateConversation extends ChatEvent {
  final String participantId;

  const CreateConversation({required this.participantId});

  @override
  List<Object?> get props => [participantId];
}

class EditMessage extends ChatEvent {
  final String messageId;
  final String newContent;

  const EditMessage({required this.messageId, required this.newContent});

  @override
  List<Object?> get props => [messageId, newContent];
}

class CopyMessage extends ChatEvent {
  final String messageId;

  const CopyMessage({required this.messageId});

  @override
  List<Object?> get props => [messageId];
}

class ReplyToMessage extends ChatEvent {
  final String originalMessageId;
  final String conversationId;
  final String content;
  final MessageType type;

  const ReplyToMessage({
    required this.originalMessageId,
    required this.conversationId,
    required this.content,
    this.type = MessageType.text,
  });

  @override
  List<Object?> get props => [originalMessageId, conversationId, content, type];
}

class ForwardMessage extends ChatEvent {
  final String messageId;
  final List<String> targetConversationIds;

  const ForwardMessage({
    required this.messageId,
    required this.targetConversationIds,
  });

  @override
  List<Object?> get props => [messageId, targetConversationIds];
}

class BookmarkMessage extends ChatEvent {
  final String messageId;
  final bool isBookmarked;

  const BookmarkMessage({required this.messageId, required this.isBookmarked});

  @override
  List<Object?> get props => [messageId, isBookmarked];
}

class PerformContextualAction extends ChatEvent {
  final String actionId;
  final String actionType;
  final Map<String, dynamic> actionData;

  const PerformContextualAction({
    required this.actionId,
    required this.actionType,
    required this.actionData,
  });

  @override
  List<Object?> get props => [actionId, actionType, actionData];
}

class UpdateMessageStatus extends ChatEvent {
  final String messageId;
  final String status;

  const UpdateMessageStatus({required this.messageId, required this.status});

  @override
  List<Object?> get props => [messageId, status];
}

class MessageReceived extends ChatEvent {
  final MessageModel message;

  const MessageReceived({required this.message});

  @override
  List<Object?> get props => [message];
}

class MessageDeliveryStatusUpdated extends ChatEvent {
  final String messageId;
  final MessageStatus status;

  const MessageDeliveryStatusUpdated({
    required this.messageId,
    required this.status,
  });

  @override
  List<Object?> get props => [messageId, status];
}

// States
abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {
  const ChatInitial();
}

class ChatLoading extends ChatState {
  const ChatLoading();
}

class ConversationsLoaded extends ChatState {
  final List<ConversationModel> conversations;

  const ConversationsLoaded({required this.conversations});

  @override
  List<Object?> get props => [conversations];
}

class MessagesLoaded extends ChatState {
  final String conversationId;
  final List<MessageModel> messages;
  final bool hasMoreMessages;
  final Map<String, bool> typingUsers;
  final bool isLoadingMore;
  final bool isRefreshing;

  const MessagesLoaded({
    required this.conversationId,
    required this.messages,
    required this.hasMoreMessages,
    this.typingUsers = const {},
    this.isLoadingMore = false,
    this.isRefreshing = false,
  });

  MessagesLoaded copyWith({
    String? conversationId,
    List<MessageModel>? messages,
    bool? hasMoreMessages,
    Map<String, bool>? typingUsers,
    bool? isLoadingMore,
    bool? isRefreshing,
  }) {
    return MessagesLoaded(
      conversationId: conversationId ?? this.conversationId,
      messages: messages ?? this.messages,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
      typingUsers: typingUsers ?? this.typingUsers,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [
    conversationId,
    messages,
    hasMoreMessages,
    typingUsers,
    isLoadingMore,
    isRefreshing,
  ];
}

class MessageSent extends ChatState {
  final MessageModel message;

  const MessageSent({required this.message});

  @override
  List<Object?> get props => [message];
}

class MessageUpdated extends ChatState {
  final MessageModel message;

  const MessageUpdated({required this.message});

  @override
  List<Object?> get props => [message];
}

class ConversationCreated extends ChatState {
  final ConversationModel conversation;

  const ConversationCreated({required this.conversation});

  @override
  List<Object?> get props => [conversation];
}

class ChatError extends ChatState {
  final String message;

  const ChatError({required this.message});

  @override
  List<Object?> get props => [message];
}

class MessageCopied extends ChatState {
  final String content;

  const MessageCopied({required this.content});

  @override
  List<Object?> get props => [content];
}

class MessageEdited extends ChatState {
  final MessageModel editedMessage;

  const MessageEdited({required this.editedMessage});

  @override
  List<Object?> get props => [editedMessage];
}

class ContextualActionPerformed extends ChatState {
  final String actionId;
  final String result;

  const ContextualActionPerformed({
    required this.actionId,
    required this.result,
  });

  @override
  List<Object?> get props => [actionId, result];
}

class MessageStatusUpdated extends ChatState {
  final String messageId;
  final String status;

  const MessageStatusUpdated({required this.messageId, required this.status});

  @override
  List<Object?> get props => [messageId, status];
}

class MessageForwarded extends ChatState {
  const MessageForwarded();

  @override
  List<Object?> get props => [];
}

class FirstMessageSent extends ChatState {
  final MessageModel message;
  final String conversationId;

  const FirstMessageSent({required this.message, required this.conversationId});

  @override
  List<Object?> get props => [message, conversationId];
}

// BLoC
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _chatRepository;
  final Logger _logger = Logger();
  
  // Stream subscriptions
  late StreamSubscription<MessageModel> _messageSubscription;
  late StreamSubscription<MessageDeliveryUpdate> _deliverySubscription;

  ChatBloc({required ChatRepository chatRepository})
      : _chatRepository = chatRepository,
        super(const ChatInitial()) {
    on<LoadConversations>(_onLoadConversations);
    on<LoadMessages>(_onLoadMessages);
    on<LoadLatestMessages>(_onLoadLatestMessages);
    on<LoadMoreMessages>(_onLoadMoreMessages);
    on<RefreshMessages>(_onRefreshMessages);
    on<SyncConversations>(_onSyncConversations);
    on<SendMessage>(_onSendMessage);
    on<MarkMessageAsRead>(_onMarkMessageAsRead);
    on<DeleteMessage>(_onDeleteMessage);
    on<UpdateTypingStatus>(_onUpdateTypingStatus);
    on<MarkConversationAsRead>(_onMarkConversationAsRead);
    on<CreateConversation>(_onCreateConversation);
    on<EditMessage>(_onEditMessage);
    on<CopyMessage>(_onCopyMessage);
    on<ReplyToMessage>(_onReplyToMessage);
    on<ForwardMessage>(_onForwardMessage);
    on<BookmarkMessage>(_onBookmarkMessage);
    on<PerformContextualAction>(_onPerformContextualAction);
    on<UpdateMessageStatus>(_onUpdateMessageStatus);
    on<MessageReceived>(_onMessageReceived);
    on<MessageDeliveryStatusUpdated>(_onMessageDeliveryStatusUpdated);

    _initializeStreamSubscriptions();
  }

  void _initializeStreamSubscriptions() {
    // Subscribe to incoming messages stream
    _messageSubscription = _chatRepository.incomingMessages.listen((message) {
      _logger.d(
        'ChatBloc: Received message from repository stream - ID: ${message.id}, senderId: ${message.senderId}',
      );
      add(MessageReceived(message: message));
    });

    // Subscribe to delivery status updates
    _deliverySubscription = _chatRepository.messageDeliveryUpdates.listen((
      update,
    ) {
      _logger.d(
        'ChatBloc: Received delivery update from repository stream - messageId: ${update.messageId}, status: ${update.status}',
      );
      
      // Convert MessageStatus from message.dart to MessageStatus from chat_model.dart
      MessageStatus chatModelStatus;
      switch (update.status.name) {
        case 'sending':
          chatModelStatus = MessageStatus.sending;
          break;
        case 'sent':
          chatModelStatus = MessageStatus.sent;
          break;
        case 'delivered':
          chatModelStatus = MessageStatus.delivered;
          break;
        case 'read':
          chatModelStatus = MessageStatus.read;
          break;
        case 'failed':
          chatModelStatus = MessageStatus.failed;
          break;
        default:
          chatModelStatus = MessageStatus.sent;
      }
      
      add(
        MessageDeliveryStatusUpdated(
          messageId: update.messageId,
          status: chatModelStatus,
        ),
      );
    });
  }

  Future<void> _onLoadConversations(
    LoadConversations event,
    Emitter<ChatState> emit,
  ) async {
    try {
      emit(const ChatLoading());
      
      final conversations = await _chatRepository.getConversations();
      
      emit(ConversationsLoaded(conversations: conversations));
      _logger.d('Loaded ${conversations.length} conversations');
    } catch (e) {
      _logger.e('Error loading conversations: $e');
      emit(ChatError(message: 'Failed to load conversations: $e'));
    }
  }

  Future<void> _onLoadMessages(
    LoadMessages event,
    Emitter<ChatState> emit,
  ) async {
    try {
      emit(const ChatLoading());
      
      final messages = await _chatRepository.getMessages(
        conversationId: event.conversationId,
        page: event.page,
        limit: event.limit,
      );
      
      // Join the conversation room for real-time updates
      await _chatRepository.joinConversation(event.conversationId);
      _logger.d('Joined conversation room: ${event.conversationId}');
      
      // Check if there are more messages available
      final hasMoreMessages = await _chatRepository.hasMoreMessages(
        event.conversationId,
      );
      
      emit(MessagesLoaded(
        conversationId: event.conversationId,
        messages: messages,
        hasMoreMessages: hasMoreMessages,
      ));
      
      _logger.d('Loaded ${messages.length} messages for conversation ${event.conversationId}');
    } catch (e) {
      _logger.e('Error loading messages: $e');
      emit(ChatError(message: 'Failed to load messages: $e'));
    }
  }

  Future<void> _onLoadLatestMessages(
    LoadLatestMessages event,
    Emitter<ChatState> emit,
  ) async {
    try {
      // Don't show loading screen for latest messages (quick cache response)

      final cachedMessages = await _chatRepository.getLatestMessages(
        conversationId: event.conversationId,
        limit: event.limit,
      );

      // Join the conversation room for real-time updates
      await _chatRepository.joinConversation(event.conversationId);
      _logger.d('Joined conversation room: ${event.conversationId}');

      // Check if there are more messages available
      final hasMoreMessages = await _chatRepository.hasMoreMessages(
        event.conversationId,
      );

      // Emit cached messages first (fast response)
      emit(
        MessagesLoaded(
          conversationId: event.conversationId,
          messages: cachedMessages,
          hasMoreMessages: hasMoreMessages,
        ),
      );

      _logger.d(
        'Loaded ${cachedMessages.length} cached messages for conversation ${event.conversationId}',
      );

      // Now fetch fresh messages from the network (this ensures we get the latest)
      try {
        final freshMessages = await _chatRepository.getMessages(
          conversationId: event.conversationId,
          limit: event.limit,
        );

        // Only emit if the fresh messages are different from cached ones
        if (freshMessages.length != cachedMessages.length ||
            (freshMessages.isNotEmpty &&
                cachedMessages.isNotEmpty &&
                freshMessages.first.id != cachedMessages.first.id)) {
          _logger.d(
            'Fresh messages differ from cache, updating UI: ${freshMessages.length} vs ${cachedMessages.length}',
          );

          emit(
            MessagesLoaded(
              conversationId: event.conversationId,
              messages: freshMessages,
              hasMoreMessages: hasMoreMessages,
            ),
          );
        } else {
          _logger.d('Fresh messages same as cache, no UI update needed');
        }
      } catch (networkError) {
        _logger.w(
          'Network refresh failed, using cached messages: $networkError',
        );
        // Keep the cached messages that were already emitted
      }
    } catch (e) {
      _logger.e('Error loading latest messages: $e');
      emit(ChatError(message: 'Failed to load latest messages: $e'));
    }
  }

  Future<void> _onLoadMoreMessages(
    LoadMoreMessages event,
    Emitter<ChatState> emit,
  ) async {
    try {
      // Get current state to maintain existing messages
      final currentState = state;
      if (currentState is! MessagesLoaded ||
          currentState.conversationId != event.conversationId) {
        _logger.w('Cannot load more messages: invalid state');
        return;
      }

      // Set loading more flag (non-intrusive loading)
      emit(currentState.copyWith(isLoadingMore: true));

      final moreMessages = await _chatRepository.loadMoreMessages(
        conversationId: event.conversationId,
        oldestMessageId: event.oldestMessageId,
        limit: event.limit,
      );

      // Merge new messages with existing ones (older messages go to the end)
      final allMessages = [...currentState.messages, ...moreMessages];

      // Check if there are even more messages available
      final hasMoreMessages = await _chatRepository.hasMoreMessages(
        event.conversationId,
      );

      emit(
        MessagesLoaded(
          conversationId: event.conversationId,
          messages: allMessages,
          hasMoreMessages: hasMoreMessages,
          typingUsers: currentState.typingUsers,
          isLoadingMore: false,
        ),
      );

      _logger.d(
        'Loaded ${moreMessages.length} more messages. Total: ${allMessages.length}',
      );
    } catch (e) {
      _logger.e('Error loading more messages: $e');

      // Revert loading state on error
      final currentState = state;
      if (currentState is MessagesLoaded) {
        emit(currentState.copyWith(isLoadingMore: false));
      }
    }
  }

  Future<void> _onRefreshMessages(
    RefreshMessages event,
    Emitter<ChatState> emit,
  ) async {
    try {
      // Get current state to maintain existing messages during refresh
      final currentState = state;
      if (currentState is! MessagesLoaded ||
          currentState.conversationId != event.conversationId) {
        _logger.w('Cannot refresh messages: invalid state');
        return;
      }

      // Set refreshing flag (pull-to-refresh indicator)
      emit(currentState.copyWith(isRefreshing: true));

      // Get fresh messages from network (bypasses cache initially)
      final refreshedMessages = await _chatRepository.getMessagesPaginated(
        conversationId: event.conversationId,
        cursorMessageId: null,
        limit: 50,
        fromCache: false, // Force network refresh
      );

      // Check if there are more messages available
      final hasMoreMessages = await _chatRepository.hasMoreMessages(
        event.conversationId,
      );

      emit(
        MessagesLoaded(
          conversationId: event.conversationId,
          messages: refreshedMessages,
          hasMoreMessages: hasMoreMessages,
          typingUsers: currentState.typingUsers,
          isRefreshing: false,
        ),
      );

      _logger.d(
        'Refreshed ${refreshedMessages.length} messages for conversation ${event.conversationId}',
      );
    } catch (e) {
      _logger.e('Error refreshing messages: $e');

      // Revert refreshing state on error
      final currentState = state;
      if (currentState is MessagesLoaded) {
        emit(currentState.copyWith(isRefreshing: false));
      }
    }
  }

  Future<void> _onSyncConversations(
    SyncConversations event,
    Emitter<ChatState> emit,
  ) async {
    try {
      _logger.d('ChatBloc: Manually triggering sync of all conversations');

      // Use BackgroundSyncManager to trigger manual sync
      final syncManager = BackgroundSyncManager.instance;
      await syncManager.forceSync();

      _logger.i('ChatBloc: Manual sync completed successfully');

      // Optionally reload conversations to show updated data
      add(const LoadConversations());
    } catch (e, stackTrace) {
      _logger.e(
        'ChatBloc: Failed to sync conversations',
        error: e,
        stackTrace: stackTrace,
      );
      // Could emit an error state or show a toast notification
    }
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatState> emit,
  ) async {
    try {
      _logger.d(
        'ChatBloc: Sending message with currentUserId: ${event.currentUserId}',
      );
      
      // Check if this conversation has any messages before sending
      final currentState = state;
      final isFirstMessage = currentState is MessagesLoaded && 
          currentState.conversationId == event.conversationId && 
          currentState.messages.isEmpty;
      
      final message = await _chatRepository.sendMessage(
        conversationId: event.conversationId,
        type: event.type,
        content: event.content,
        mediaIds: event.mediaIds,
        metadata: event.metadata,
        replyToMessageId: event.replyToMessageId,
        currentUserId: event.currentUserId,
      );
      
      _logger.d(
        'ChatBloc: Received optimistic message: ${message.id} from senderId: ${message.senderId}',
      );
      
      // Update the current messages list if we're viewing this conversation
      if (currentState is MessagesLoaded &&
          currentState.conversationId == event.conversationId) {
        final updatedMessages = List<MessageModel>.from(currentState.messages)
          ..insert(0, message); // Insert at beginning for reverse ListView
        _logger.d(
          'ChatBloc: Adding optimistic message to existing MessagesLoaded state with ${currentState.messages.length} messages',
        );
        emit(currentState.copyWith(messages: updatedMessages));
        
        // If this was the first message, also emit FirstMessageSent state
        if (isFirstMessage) {
          _logger.d(
            'First message sent in conversation - emitting FirstMessageSent state',
          );
          emit(
            FirstMessageSent(
              message: message,
              conversationId: event.conversationId,
            ),
          );
        }
      } else {
        _logger.d(
          'ChatBloc: Emitting MessageSent state (not in MessagesLoaded for this conversation)',
        );
        emit(MessageSent(message: message));
      }
      
      _logger.d('Message sent: ${message.id}');
    } catch (e) {
      _logger.e('Error sending message: $e');
      emit(ChatError(message: 'Failed to send message: $e'));
    }
  }

  Future<void> _onMarkMessageAsRead(
    MarkMessageAsRead event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _chatRepository.markMessageAsRead(event.messageId);
      _logger.d('Message marked as read: ${event.messageId}');
    } catch (e) {
      _logger.e('Error marking message as read: $e');
      emit(ChatError(message: 'Failed to mark message as read: $e'));
    }
  }

  Future<void> _onDeleteMessage(
    DeleteMessage event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _chatRepository.deleteMessage(event.messageId);
      _logger.d('Message deleted: ${event.messageId}');
    } catch (e) {
      _logger.e('Error deleting message: $e');
      emit(ChatError(message: 'Failed to delete message: $e'));
    }
  }

  Future<void> _onUpdateTypingStatus(
    UpdateTypingStatus event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _chatRepository.updateTypingStatus(
        event.conversationId,
        event.isTyping,
      );
      _logger.d('Typing status updated: ${event.isTyping}');
      
      // Don't add fake typing indicators - only real ones from backend WebSocket
      // should show typing status. The current implementation creates fake typing
      // indicators that confuse users.
    } catch (e) {
      _logger.e('Error updating typing status: $e');
    }
  }

  Future<void> _onMarkConversationAsRead(
    MarkConversationAsRead event,
    Emitter<ChatState> emit,
  ) async {
    try {
      // Get current message IDs to mark as read
      List<String> messageIds = [];
      if (state is MessagesLoaded) {
        final messagesState = state as MessagesLoaded;
        // Get all message IDs (backend will filter out own messages)
        // Filter to only valid UUIDs to avoid validation error
        final RegExp uuidPattern = RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
          caseSensitive: false,
        );
        messageIds = messagesState.messages
            .map((message) => message.id)
            .where((id) => uuidPattern.hasMatch(id))
            .toList();
        
        _logger.d(
          'Filtered ${messagesState.messages.length} messages to ${messageIds.length} valid UUIDs',
        );
      }

      await _chatRepository.markConversationAsRead(
        event.conversationId,
        messageIds: messageIds,
      );
      _logger.d(
        'Conversation marked as read: ${event.conversationId} (${messageIds.length} messages)',
      );

      // ✅ DON'T reload conversations - it destroys the current MessagesLoaded state!
      // The read status will be updated via WebSocket events or next conversation load
      // Keeping current state intact preserves chat interface
      _logger.d('Conversation marked as read - keeping current state intact');
    } catch (e) {
      _logger.e('Error marking conversation as read: $e');
    }
  }

  Future<void> _onCreateConversation(
    CreateConversation event,
    Emitter<ChatState> emit,
  ) async {
    try {
      emit(const ChatLoading());
      
      final conversation = await _chatRepository.createConversation(
        event.participantId,
      );
      
      emit(ConversationCreated(conversation: conversation));
      _logger.d('Conversation created: ${conversation.id}');
    } catch (e) {
      _logger.e('Error creating conversation: $e');
      emit(ChatError(message: 'Failed to create conversation: $e'));
    }
  }

  Future<void> _onEditMessage(
    EditMessage event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final editedMessage = await _chatRepository.editMessage(
        event.messageId,
        event.newContent,
      );

      emit(MessageEdited(editedMessage: editedMessage));
      _logger.d('Message edited: ${event.messageId}');
    } catch (e) {
      _logger.e('Error editing message: $e');
      emit(ChatError(message: 'Failed to edit message: $e'));
    }
  }

  Future<void> _onCopyMessage(
    CopyMessage event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _chatRepository.copyMessageToClipboard(event.messageId);

      // Get the message content for the state
      final message = await _chatRepository.getMessage(event.messageId);
      emit(MessageCopied(content: message.content ?? ''));
      _logger.d('Message copied: ${event.messageId}');
    } catch (e) {
      _logger.e('Error copying message: $e');
      emit(ChatError(message: 'Failed to copy message: $e'));
    }
  }

  Future<void> _onReplyToMessage(
    ReplyToMessage event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final replyMessage = await _chatRepository.replyToMessage(
        event.originalMessageId,
        event.content,
        event.conversationId,
      );

      emit(MessageSent(message: replyMessage));
      _logger.d('Reply sent to message: ${event.originalMessageId}');
    } catch (e) {
      _logger.e('Error replying to message: $e');
      emit(ChatError(message: 'Failed to send reply: $e'));
    }
  }

  Future<void> _onForwardMessage(
    ForwardMessage event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _chatRepository.forwardMessage(
        event.messageId,
        event.targetConversationIds,
      );

      emit(const MessageForwarded());
      _logger.d('Message forwarded: ${event.messageId}');
    } catch (e) {
      _logger.e('Error forwarding message: $e');
      emit(ChatError(message: 'Failed to forward message: $e'));
    }
  }

  Future<void> _onBookmarkMessage(
    BookmarkMessage event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _chatRepository.bookmarkMessage(
        event.messageId,
        event.isBookmarked,
      );

      // Optionally emit a state to update UI
      _logger.d('Message bookmark updated: ${event.messageId}');
    } catch (e) {
      _logger.e('Error updating bookmark: $e');
      emit(ChatError(message: 'Failed to update bookmark: $e'));
    }
  }

  Future<void> _onPerformContextualAction(
    PerformContextualAction event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final result = await _chatRepository.performContextualAction(
        event.actionId,
        event.actionType,
        event.actionData,
      );

      emit(ContextualActionPerformed(actionId: event.actionId, result: result));
      _logger.d('Contextual action performed: ${event.actionId}');
    } catch (e) {
      _logger.e('Error performing contextual action: $e');
      emit(ChatError(message: 'Failed to perform action: $e'));
    }
  }

  Future<void> _onUpdateMessageStatus(
    UpdateMessageStatus event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _chatRepository.updateMessageStatus(event.messageId, event.status);

      emit(
        MessageStatusUpdated(messageId: event.messageId, status: event.status),
      );
      _logger.d(
        'Message status updated: ${event.messageId} -> ${event.status}',
      );
    } catch (e) {
      _logger.e('Error updating message status: $e');
      emit(ChatError(message: 'Failed to update message status: $e'));
    }
  }

  Future<void> _onMessageReceived(
    MessageReceived event,
    Emitter<ChatState> emit,
  ) async {
    try {
      _logger.d(
        'ChatBloc: Processing MessageReceived event - messageId: ${event.message.id}, senderId: ${event.message.senderId}',
      );
      
      if (state is MessagesLoaded) {
        final currentState = state as MessagesLoaded;
        final messages = List<MessageModel>.from(currentState.messages);

        _logger.e(
          '🔍 [CONVERSATION ID DEBUG] Current conversation: "${currentState.conversationId}" | Message conversation: "${event.message.conversationId}"',
        );
        _logger.e(
          '🔍 [CONVERSATION ID DEBUG] Are they equal? ${currentState.conversationId == event.message.conversationId}',
        );
        _logger.e(
          '🔍 [CONVERSATION ID DEBUG] Current length: ${currentState.conversationId.length} | Message length: ${event.message.conversationId.length}',
        );

        // Only add messages for the current conversation
        if (currentState.conversationId != event.message.conversationId) {
          _logger.e(
            '❌ [CONVERSATION ID DEBUG] FILTERING OUT MESSAGE - conversation ID mismatch!',
          );
          _logger.e(
            '❌ [CONVERSATION ID DEBUG] Current: "${currentState.conversationId}"',
          );
          _logger.e(
            '❌ [CONVERSATION ID DEBUG] Message: "${event.message.conversationId}"',
          );
          return;
        }

        _logger.e(
          '✅ [CONVERSATION ID DEBUG] Conversation IDs match - processing message',
        );

        // Check if this message already exists (by ID or temporary ID mapping)
        final existingIndex = messages.indexWhere(
          (msg) =>
              msg.id == event.message.id ||
              _chatRepository.isOptimisticMessage(msg.id, event.message.id),
        );

        if (existingIndex != -1) {
          // Replace optimistic message with real message
          _logger.d(
            'ChatBloc: Replacing optimistic message at index $existingIndex with real message: ${event.message.id}',
          );
          messages[existingIndex] = event.message;
        } else {
          // This is a new message (either from current user after sending or from another user)
          _logger.d('ChatBloc: Adding new message: ${event.message.id}');
          messages.insert(
            0,
            event.message,
          ); // Insert at beginning for reverse ListView
        }
        
        emit(
          MessagesLoaded(
            messages: messages,
            conversationId: currentState.conversationId,
            hasMoreMessages: currentState.hasMoreMessages,
            typingUsers: currentState.typingUsers,
          ),
        );
        _logger.d(
          'ChatBloc: Emitted MessagesLoaded with ${messages.length} messages',
        );
      } else if (state is MessageSent) {
        final currentState = state as MessageSent;

        // Check if this message is for the same conversation
        if (currentState.message.conversationId ==
            event.message.conversationId) {
          _logger.d(
            'ChatBloc: In MessageSent state, transitioning to MessagesLoaded with received message: ${event.message.id}',
          );

          // Check if this is confirming our optimistic message
          final isOptimisticConfirmation = _chatRepository.isOptimisticMessage(
            currentState.message.id,
            event.message.id,
          );

          List<MessageModel> messages;
          if (isOptimisticConfirmation) {
            // Replace optimistic message with confirmed message
            messages = [event.message];
            _logger.d(
              'ChatBloc: Replaced optimistic message ${currentState.message.id} with confirmed message ${event.message.id}',
            );
          } else {
            // This is a different message, keep both (optimistic + new)
            messages = [event.message, currentState.message];
            _logger.d(
              'ChatBloc: Added new message ${event.message.id} alongside existing optimistic message ${currentState.message.id}',
            );
          }

          emit(
            MessagesLoaded(
              messages: messages,
              conversationId: currentState.message.conversationId,
              hasMoreMessages: false, // Fresh conversation
              typingUsers: const {},
            ),
          );
        } else {
          _logger.d(
            'ChatBloc: In MessageSent state, but message is for different conversation. Current: ${currentState.message.conversationId}, Message: ${event.message.conversationId}',
          );
        }
      } else if (state is FirstMessageSent) {
        final currentState = state as FirstMessageSent;

        // Check if this message is for the same conversation
        if (currentState.conversationId == event.message.conversationId) {
          _logger.d(
            'ChatBloc: In FirstMessageSent state, transitioning to MessagesLoaded with received message: ${event.message.id}',
          );

          // Check if this is confirming our optimistic message
          final isOptimisticConfirmation = _chatRepository.isOptimisticMessage(
            currentState.message.id,
            event.message.id,
          );

          List<MessageModel> messages;
          if (isOptimisticConfirmation) {
            // Replace optimistic message with confirmed message
            messages = [event.message];
            _logger.d(
              'ChatBloc: Replaced optimistic first message ${currentState.message.id} with confirmed message ${event.message.id}',
            );
          } else {
            // This is a different message, keep both (optimistic + new)
            messages = [event.message, currentState.message];
            _logger.d(
              'ChatBloc: Added new message ${event.message.id} alongside existing optimistic first message ${currentState.message.id}',
            );
          }

          emit(
            MessagesLoaded(
              messages: messages,
              conversationId: currentState.conversationId,
              hasMoreMessages: false, // Fresh conversation
              typingUsers: const {},
            ),
          );
        } else {
          _logger.d(
            'ChatBloc: In FirstMessageSent state, but message is for different conversation. Current: ${currentState.conversationId}, Message: ${event.message.conversationId}',
          );
        }
      } else {
        _logger.d(
          'ChatBloc: Not in MessagesLoaded, MessageSent, or FirstMessageSent state (${state.runtimeType}), ignoring received message',
        );
      }
    } catch (e) {
      _logger.e('Error handling received message: $e');
      emit(ChatError(message: 'Failed to handle received message: $e'));
    }
  }

  Future<void> _onMessageDeliveryStatusUpdated(
    MessageDeliveryStatusUpdated event,
    Emitter<ChatState> emit,
  ) async {
    try {
      _logger.d(
        'Message delivery status updated: ${event.messageId} -> ${event.status}',
      );

      // Update message status in the current state if it's MessagesLoaded
      if (state is MessagesLoaded) {
        final messagesState = state as MessagesLoaded;
        final updatedMessages = messagesState.messages.map((message) {
          if (message.id == event.messageId) {
            _logger.d(
              'Updating message ${message.id} status from ${message.status} to ${event.status}',
            );
            return message.copyWith(status: event.status);
          }
          return message;
        }).toList();

        // Maintain MessagesLoaded state with updated messages
        emit(messagesState.copyWith(messages: updatedMessages));
        _logger.d(
          'Updated message delivery status while preserving MessagesLoaded state',
        );
      } else {
        // If not in MessagesLoaded state, just log the update
        _logger.d(
          'Delivery status update received but not in MessagesLoaded state: ${state.runtimeType}',
        );
      }
    } catch (e) {
      _logger.e('Error handling delivery status update: $e');
      emit(ChatError(message: 'Failed to handle delivery status update: $e'));
    }
  }

  @override
  Future<void> close() {
    _messageSubscription.cancel();
    _deliverySubscription.cancel();
    return super.close();
  }
}