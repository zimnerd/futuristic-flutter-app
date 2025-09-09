import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/conversation.dart';
import '../../../domain/entities/message.dart';
import '../../../data/services/messaging_service.dart';

part 'messaging_event.dart';
part 'messaging_state.dart';

/// Clean, simple BLoC for messaging using services directly
class MessagingBloc extends Bloc<MessagingEvent, MessagingState> {
  final MessagingService _messagingService;

  MessagingBloc({
    required MessagingService messagingService,
  })  : _messagingService = messagingService,
        super(const MessagingState()) {
    on<LoadConversations>(_onLoadConversations);
    on<LoadMessages>(_onLoadMessages);
    on<SendMessage>(_onSendMessage);
    on<MarkConversationAsRead>(_onMarkConversationAsRead);
    on<DeleteConversation>(_onDeleteConversation);
    on<BlockUser>(_onBlockUser);
  }

  Future<void> _onLoadConversations(
    LoadConversations event,
    Emitter<MessagingState> emit,
  ) async {
    try {
      emit(state.copyWith(conversationsStatus: MessagingStatus.loading));

      final conversations = await _messagingService.getConversations(
        limit: 50,
        offset: event.refresh ? 0 : state.conversations.length,
      );

      emit(state.copyWith(
        conversationsStatus: MessagingStatus.loaded,
        conversations: event.refresh 
            ? conversations 
            : [...state.conversations, ...conversations],
        hasReachedMaxConversations: conversations.length < 50,
      ));
    } catch (e) {
      emit(state.copyWith(
        conversationsStatus: MessagingStatus.error,
        error: 'Failed to load conversations: ${e.toString()}',
      ));
    }
  }

  Future<void> _onLoadMessages(
    LoadMessages event,
    Emitter<MessagingState> emit,
  ) async {
    try {
      emit(state.copyWith(messagesStatus: MessagingStatus.loading));

      final messages = await _messagingService.getMessages(
        conversationId: event.conversationId,
        limit: 50,
        offset: event.refresh ? 0 : state.currentMessages.length,
      );

      emit(state.copyWith(
        messagesStatus: MessagingStatus.loaded,
        currentConversationId: event.conversationId,
        currentMessages: event.refresh 
            ? messages 
            : [...state.currentMessages, ...messages],
        hasReachedMaxMessages: messages.length < 50,
      ));
    } catch (e) {
      emit(state.copyWith(
        messagesStatus: MessagingStatus.error,
        error: 'Failed to load messages: ${e.toString()}',
      ));
    }
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<MessagingState> emit,
  ) async {
    try {
      // Optimistically add message to UI
      final tempMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        conversationId: event.conversationId,
        senderId: 'current_user', // This should come from user session
        content: event.content,
        type: MessageType.text,
        timestamp: DateTime.now(),
        isRead: false,
      );

      final updatedMessages = [tempMessage, ...state.currentMessages];
      emit(state.copyWith(currentMessages: updatedMessages));

      // Send to backend
      final sentMessage = await _messagingService.sendMessage(
        conversationId: event.conversationId,
        content: event.content,
        type: event.type.name,
        mediaUrl: event.mediaUrl,
      );

      // Replace temp message with real one
      final finalMessages = updatedMessages
          .map((msg) => msg.id == tempMessage.id ? sentMessage : msg)
          .toList();

      emit(state.copyWith(currentMessages: finalMessages));
    } catch (e) {
      // Remove failed message and show error
      final messages = state.currentMessages.where((msg) => 
          msg.id != DateTime.now().millisecondsSinceEpoch.toString()).toList();
      
      emit(state.copyWith(
        currentMessages: messages,
        error: 'Failed to send message: ${e.toString()}',
      ));
    }
  }

  Future<void> _onMarkConversationAsRead(
    MarkConversationAsRead event,
    Emitter<MessagingState> emit,
  ) async {
    try {
      await _messagingService.markConversationAsRead(event.conversationId);
      
      // Update local conversation
      final updatedConversations = state.conversations.map((conv) {
        if (conv.id == event.conversationId) {
          return Conversation(
            id: conv.id,
            otherUserId: conv.otherUserId,
            otherUserName: conv.otherUserName,
            otherUserAvatar: conv.otherUserAvatar,
            lastMessage: conv.lastMessage,
            lastMessageTime: conv.lastMessageTime,
            unreadCount: 0, // Mark as read
            isOnline: conv.isOnline,
            lastSeen: conv.lastSeen,
            isBlocked: conv.isBlocked,
            isMuted: conv.isMuted,
            isPinned: conv.isPinned,
            matchedAt: conv.matchedAt,
          );
        }
        return conv;
      }).toList();

      emit(state.copyWith(conversations: updatedConversations));
    } catch (e) {
      emit(state.copyWith(
        error: 'Failed to mark conversation as read: ${e.toString()}',
      ));
    }
  }

  Future<void> _onDeleteConversation(
    DeleteConversation event,
    Emitter<MessagingState> emit,
  ) async {
    try {
      await _messagingService.deleteConversation(event.conversationId);
      
      final updatedConversations = state.conversations
          .where((conv) => conv.id != event.conversationId)
          .toList();

      emit(state.copyWith(conversations: updatedConversations));
    } catch (e) {
      emit(state.copyWith(
        error: 'Failed to delete conversation: ${e.toString()}',
      ));
    }
  }

  Future<void> _onBlockUser(
    BlockUser event,
    Emitter<MessagingState> emit,
  ) async {
    try {
      await _messagingService.blockUser(event.userId);
      
      // Remove conversations with blocked user
      final updatedConversations = state.conversations
          .where((conv) => conv.otherUserId != event.userId)
          .toList();

      emit(state.copyWith(conversations: updatedConversations));
    } catch (e) {
      emit(state.copyWith(
        error: 'Failed to block user: ${e.toString()}',
      ));
    }
  }
}
