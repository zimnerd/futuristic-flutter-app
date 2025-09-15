import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../domain/entities/event_message.dart';
import '../../../../data/services/event_service.dart';
import '../../../../core/utils/logger.dart';

// Events
abstract class EventChatEvent extends Equatable {
  const EventChatEvent();

  @override
  List<Object?> get props => [];
}

class LoadEventMessages extends EventChatEvent {
  final String eventId;

  const LoadEventMessages(this.eventId);

  @override
  List<Object?> get props => [eventId];
}

class SendEventMessage extends EventChatEvent {
  final String eventId;
  final String content;

  const SendEventMessage({
    required this.eventId,
    required this.content,
  });

  @override
  List<Object?> get props => [eventId, content];
}

class RefreshEventMessages extends EventChatEvent {
  final String eventId;

  const RefreshEventMessages(this.eventId);

  @override
  List<Object?> get props => [eventId];
}

// States
abstract class EventChatState extends Equatable {
  const EventChatState();

  @override
  List<Object?> get props => [];
}

class EventChatInitial extends EventChatState {}

class EventChatLoading extends EventChatState {}

class EventChatLoaded extends EventChatState {
  final List<EventMessage> messages;

  const EventChatLoaded(this.messages);

  @override
  List<Object?> get props => [messages];
}

class EventChatError extends EventChatState {
  final String message;

  const EventChatError(this.message);

  @override
  List<Object?> get props => [message];
}

class EventChatSending extends EventChatState {
  final List<EventMessage> messages;

  const EventChatSending(this.messages);

  @override
  List<Object?> get props => [messages];
}

// Bloc
class EventChatBloc extends Bloc<EventChatEvent, EventChatState> {
  final EventService _eventService;

  EventChatBloc({EventService? eventService})
      : _eventService = eventService ?? EventService.instance,
        super(EventChatInitial()) {
    on<LoadEventMessages>(_onLoadEventMessages);
    on<SendEventMessage>(_onSendEventMessage);
    on<RefreshEventMessages>(_onRefreshEventMessages);
  }

  Future<void> _onLoadEventMessages(
    LoadEventMessages event,
    Emitter<EventChatState> emit,
  ) async {
    try {
      emit(EventChatLoading());

      final messages = await _eventService.getEventMessages(
        eventId: event.eventId,
      );

      // Sort messages by creation date (newest last for chat UI)
      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      emit(EventChatLoaded(messages));
    } catch (e) {
      AppLogger.error('Error loading event messages: $e');
      emit(EventChatError('Failed to load messages. Please try again.'));
    }
  }

  Future<void> _onSendEventMessage(
    SendEventMessage event,
    Emitter<EventChatState> emit,
  ) async {
    try {
      final currentState = state;
      List<EventMessage> currentMessages = [];
      
      if (currentState is EventChatLoaded) {
        currentMessages = currentState.messages;
      }

      emit(EventChatSending(currentMessages));

      await _eventService.sendEventMessage(
        eventId: event.eventId,
        content: event.content,
      );

      // Refresh messages to get the latest state
      add(RefreshEventMessages(event.eventId));
    } catch (e) {
      AppLogger.error('Error sending event message: $e');
      emit(EventChatError('Failed to send message. Please try again.'));
    }
  }

  Future<void> _onRefreshEventMessages(
    RefreshEventMessages event,
    Emitter<EventChatState> emit,
  ) async {
    try {
      final messages = await _eventService.getEventMessages(
        eventId: event.eventId,
      );

      // Sort messages by creation date (newest last for chat UI)
      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      emit(EventChatLoaded(messages));
    } catch (e) {
      AppLogger.error('Error refreshing event messages: $e');
      emit(EventChatError('Failed to refresh messages. Please try again.'));
    }
  }
}