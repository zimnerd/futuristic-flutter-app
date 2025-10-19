part of 'messaging_bloc.dart';

/// Base class for all messaging events
abstract class MessagingEvent extends Equatable {
  const MessagingEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load conversations list
class LoadConversations extends MessagingEvent {
  const LoadConversations({this.refresh = false});

  final bool refresh;

  @override
  List<Object?> get props => [refresh];
}

/// Event to load messages for a conversation
class LoadMessages extends MessagingEvent {
  const LoadMessages({required this.conversationId, this.refresh = false});

  final String conversationId;
  final bool refresh;

  @override
  List<Object?> get props => [conversationId, refresh];
}

/// Event to send a message
class SendMessage extends MessagingEvent {
  const SendMessage({
    required this.conversationId,
    required this.senderId,
    required this.content,
    this.type = MessageType.text,
    this.replyToMessageId,
    this.mediaUrl,
  });

  final String conversationId;
  final String senderId;
  final String content;
  final MessageType type;
  final String? replyToMessageId;
  final String? mediaUrl;

  @override
  List<Object?> get props => [
    conversationId,
    senderId,
    content,
    type,
    replyToMessageId,
    mediaUrl,
  ];
}

/// Event when a message is received via WebSocket
class MessageReceived extends MessagingEvent {
  const MessageReceived({required this.message});

  final Message message;

  @override
  List<Object?> get props => [message];
}

/// Event to mark conversation as read
class MarkConversationAsRead extends MessagingEvent {
  const MarkConversationAsRead({required this.conversationId});

  final String conversationId;

  @override
  List<Object?> get props => [conversationId];
}

/// Event to delete a conversation
class DeleteConversation extends MessagingEvent {
  const DeleteConversation({required this.conversationId});

  final String conversationId;

  @override
  List<Object?> get props => [conversationId];
}

/// Event to block a user
class BlockUser extends MessagingEvent {
  const BlockUser({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Event to report a conversation
class ReportConversation extends MessagingEvent {
  const ReportConversation({
    required this.conversationId,
    required this.reason,
    this.description,
  });

  final String conversationId;
  final String reason;
  final String? description;

  @override
  List<Object?> get props => [conversationId, reason, description];
}

/// Event to start typing indicator
class StartTyping extends MessagingEvent {
  const StartTyping({required this.conversationId});

  final String conversationId;

  @override
  List<Object?> get props => [conversationId];
}

/// Event to stop typing indicator
class StopTyping extends MessagingEvent {
  const StopTyping({required this.conversationId});

  final String conversationId;

  @override
  List<Object?> get props => [conversationId];
}

/// Event when user typing status changes
class UserTyping extends MessagingEvent {
  const UserTyping({required this.userId, required this.isTyping});

  final String userId;
  final bool isTyping;

  @override
  List<Object?> get props => [userId, isTyping];
}

/// Event to update user online status
class UpdateOnlineStatus extends MessagingEvent {
  const UpdateOnlineStatus({required this.userId, required this.isOnline});

  final String userId;
  final bool isOnline;

  @override
  List<Object?> get props => [userId, isOnline];
}

/// Event to start a conversation with a match
class StartConversation extends MessagingEvent {
  const StartConversation({
    required this.matchId,
    required this.initialMessage,
  });

  final String matchId;
  final String initialMessage;

  @override
  List<Object?> get props => [matchId, initialMessage];
}
