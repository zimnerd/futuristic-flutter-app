import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'dart:async';
import '../../../data/services/ai_companion_service.dart';
import '../../../data/models/ai_companion.dart';
import 'ai_companion_event.dart';
import 'ai_companion_state.dart';

class AiCompanionBloc extends Bloc<AiCompanionEvent, AiCompanionState> {
  final AiCompanionService _aiCompanionService;
  final Logger _logger = Logger();
  static const String _tag = 'AiCompanionBloc';
  
  StreamSubscription<CompanionMessage>? _messageSubscription;
  StreamSubscription<Map<String, dynamic>>? _errorSubscription;

  AiCompanionBloc({
    required AiCompanionService aiCompanionService,
  })  : _aiCompanionService = aiCompanionService,
        super(AiCompanionInitial()) {
    on<LoadUserCompanions>(_onLoadUserCompanions);
    on<CreateCompanion>(_onCreateCompanion);
    on<UpdateCompanion>(_onUpdateCompanion);
    on<DeleteCompanion>(_onDeleteCompanion);
    on<SendMessageToCompanion>(_onSendMessageToCompanion);
    on<SendImageMessage>(_onSendImageMessage);
    on<SendAudioMessage>(_onSendAudioMessage);
    on<LoadConversationHistory>(_onLoadConversationHistory);
    on<UpdateCompanionSettings>(_onUpdateCompanionSettings);
    on<GetCompanionAnalytics>(_onGetCompanionAnalytics);
    on<GenerateCompanionSuggestion>(_onGenerateCompanionSuggestion);
    on<RefreshCompanionData>(_onRefreshCompanionData);
    on<MessageReceived>(_onMessageReceived);
    on<MessageError>(_onMessageError);

    _setupStreamListeners();
  }

  void _setupStreamListeners() {
    // Listen for real-time messages
    _messageSubscription = _aiCompanionService.messageStream.listen((message) {
      add(MessageReceived(message));
    });

    // Listen for errors
    _errorSubscription = _aiCompanionService.errorStream.listen((error) {
      add(MessageError(error['error'] ?? 'Unknown error'));
    });
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    _errorSubscription?.cancel();
    _aiCompanionService.dispose();
    return super.close();
  }

  Future<void> _onLoadUserCompanions(
    LoadUserCompanions event,
    Emitter<AiCompanionState> emit,
  ) async {
    try {
      emit(AiCompanionLoading());
      _logger.d('$_tag: Loading user companions');

      final companions = await _aiCompanionService.getUserCompanions();

      emit(AiCompanionLoaded(companions: companions));
      _logger.d('$_tag: Loaded ${companions.length} companions');
    } catch (e, stackTrace) {
      _logger.e('$_tag: Failed to load companions', error: e, stackTrace: stackTrace);
      emit(AiCompanionError('Failed to load companions: ${e.toString()}'));
    }
  }

  Future<void> _onCreateCompanion(
    CreateCompanion event,
    Emitter<AiCompanionState> emit,
  ) async {
    try {
      emit(AiCompanionCreating());
      _logger.d('$_tag: Creating companion: ${event.name}');

      final companion = await _aiCompanionService.createCompanion(
        name: event.name,
        personality: event.personality,
        appearance: event.appearance,
      );

      if (companion != null) {
        emit(AiCompanionCreated(companion));
        _logger.d('$_tag: Companion created successfully: ${companion.id}');
        
        // Refresh companions list
        add(RefreshCompanionData());
      } else {
        emit(AiCompanionError('Failed to create companion'));
      }
    } catch (e, stackTrace) {
      _logger.e('$_tag: Failed to create companion', error: e, stackTrace: stackTrace);
      emit(AiCompanionError('Failed to create companion: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateCompanion(
    UpdateCompanion event,
    Emitter<AiCompanionState> emit,
  ) async {
    try {
      emit(AiCompanionUpdating(event.companionId));
      _logger.d('$_tag: Updating companion: ${event.companionId}');

      final companion = await _aiCompanionService.updateCompanion(
        companionId: event.companionId,
        name: event.name,
        personality: event.personality,
        appearance: event.appearance,
      );

      if (companion != null) {
        emit(AiCompanionUpdated(companion));
        _logger.d('$_tag: Companion updated successfully');
        
        // Refresh companions list
        add(RefreshCompanionData());
      } else {
        emit(AiCompanionError('Failed to update companion'));
      }
    } catch (e, stackTrace) {
      _logger.e('$_tag: Failed to update companion', error: e, stackTrace: stackTrace);
      emit(AiCompanionError('Failed to update companion: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteCompanion(
    DeleteCompanion event,
    Emitter<AiCompanionState> emit,
  ) async {
    try {
      emit(AiCompanionDeleting(event.companionId));
      _logger.d('$_tag: Deleting companion: ${event.companionId}');

      final success = await _aiCompanionService.deleteCompanion(event.companionId);

      if (success) {
        emit(AiCompanionDeleted(event.companionId));
        _logger.d('$_tag: Companion deleted successfully');
        
        // Refresh companions list
        add(RefreshCompanionData());
      } else {
        emit(AiCompanionError('Failed to delete companion'));
      }
    } catch (e, stackTrace) {
      _logger.e('$_tag: Failed to delete companion', error: e, stackTrace: stackTrace);
      emit(AiCompanionError('Failed to delete companion: ${e.toString()}'));
    }
  }

  Future<void> _onSendMessageToCompanion(
    SendMessageToCompanion event,
    Emitter<AiCompanionState> emit,
  ) async {
    // Create user message immediately for instant UI update with 'sending' status
    final userMessage = CompanionMessage(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      companionId: event.companionId,
      userId: '', // Will be filled by backend
      content: event.message,
      isFromCompanion: false,
      timestamp: DateTime.now(),
      type: MessageType.text,
      status: MessageStatus.sending,
      suggestedResponses: [],
    );

    try {
      _logger.d('$_tag: Sending message to companion: ${event.companionId}');

      // Update UI immediately with user message
      List<CompanionMessage> updatedMessages = [];
      if (state is AiCompanionLoaded) {
        final currentState = state as AiCompanionLoaded;
        updatedMessages = [...currentState.conversationHistory, userMessage];
        emit(currentState.copyWith(conversationHistory: updatedMessages));
      }

      // Send message via WebSocket (now async for connection check)
      await _aiCompanionService.sendMessage(
        companionId: event.companionId,
        message: event.message,
      );

      // Update message status to 'sent' after server confirmation
      if (state is AiCompanionLoaded) {
        final currentState = state as AiCompanionLoaded;
        final messageIndex = currentState.conversationHistory.indexWhere(
          (m) => m.id == userMessage.id,
        );

        if (messageIndex != -1) {
          final updatedMessages = List<CompanionMessage>.from(
            currentState.conversationHistory,
          );
          updatedMessages[messageIndex] = userMessage.copyWith(
            status: MessageStatus.sent,
          );
          emit(currentState.copyWith(conversationHistory: updatedMessages));
        }
      }

      // No loading state needed - WebSocket messages are instant
      // The UI will be updated via the messageStream when response comes back
      _logger.d('$_tag: Message sent via WebSocket');
    } catch (e, stackTrace) {
      _logger.e(
        '$_tag: Failed to send message',
        error: e,
        stackTrace: stackTrace,
      );

      // Update message status to 'failed' on error
      if (state is AiCompanionLoaded) {
        final currentState = state as AiCompanionLoaded;
        final messageIndex = currentState.conversationHistory.indexWhere(
          (m) => m.id == userMessage.id,
        );

        if (messageIndex != -1) {
          final updatedMessages = List<CompanionMessage>.from(
            currentState.conversationHistory,
          );
          updatedMessages[messageIndex] = userMessage.copyWith(
            status: MessageStatus.failed,
          );
          emit(currentState.copyWith(conversationHistory: updatedMessages));
        }
      }

      emit(AiCompanionError('Failed to send message: ${e.toString()}'));
    }
  }

  void _onMessageReceived(
    MessageReceived event,
    Emitter<AiCompanionState> emit,
  ) {
    _logger.d('$_tag: Real-time message received: ${event.message.id}');

    // Update the current state with the new message
    if (state is AiCompanionLoaded) {
      final currentState = state as AiCompanionLoaded;
      
      // Check if message already exists to avoid duplicates
      final existingMessageIndex = currentState.conversationHistory.indexWhere(
        (msg) => msg.id == event.message.id,
      );

      List<CompanionMessage> updatedMessages;
      if (existingMessageIndex >= 0) {
        // Update existing message - ensure AI messages have 'delivered' status
        final updatedMessage = event.message.isFromCompanion
            ? event.message.copyWith(status: MessageStatus.delivered)
            : event.message;
        updatedMessages = [...currentState.conversationHistory];
        updatedMessages[existingMessageIndex] = updatedMessage;
      } else {
        // Add new message - ensure AI messages have 'delivered' status
        final newMessage = event.message.isFromCompanion
            ? event.message.copyWith(status: MessageStatus.delivered)
            : event.message;
        updatedMessages = [...currentState.conversationHistory, newMessage];
      }
      
      emit(currentState.copyWith(conversationHistory: updatedMessages));
    } else {
      // Initialize state with this message if no state exists
      final initialMessage = event.message.isFromCompanion
          ? event.message.copyWith(status: MessageStatus.delivered)
          : event.message;
      emit(AiCompanionLoaded(conversationHistory: [initialMessage]));
    }
  }

  void _onMessageError(MessageError event, Emitter<AiCompanionState> emit) {
    _logger.e('$_tag: Message error: ${event.error}');
    emit(AiCompanionError(event.error));
  }

  Future<void> _onSendImageMessage(
    SendImageMessage event,
    Emitter<AiCompanionState> emit,
  ) async {
    try {
      emit(AiCompanionMessageSending(event.companionId, 'Sending image...'));
      _logger.d(
        '$_tag: Sending image message to companion: ${event.companionId}',
      );

      final result = await _aiCompanionService.sendImageMessage(
        companionId: event.companionId,
        imageFile: event.imageFile,
      );

      if (result != null) {
        emit(AiCompanionMessageSent(result, null));
        _logger.d('$_tag: Image message sent successfully');

        // Refresh conversation history
        add(
          LoadConversationHistory(
            companionId: event.companionId,
            conversationId: event.conversationId,
          ),
        );
      } else {
        emit(AiCompanionError('Failed to send image message'));
      }
    } catch (e, stackTrace) {
      _logger.e(
        '$_tag: Failed to send image message',
        error: e,
        stackTrace: stackTrace,
      );
      emit(AiCompanionError('Failed to send image message: ${e.toString()}'));
    }
  }

  Future<void> _onSendAudioMessage(
    SendAudioMessage event,
    Emitter<AiCompanionState> emit,
  ) async {
    try {
      emit(AiCompanionMessageSending(event.companionId, 'Sending audio...'));
      _logger.d(
        '$_tag: Sending audio message to companion: ${event.companionId}',
      );

      final result = await _aiCompanionService.sendAudioMessage(
        companionId: event.companionId,
        audioFile: event.audioFile,
      );

      if (result != null) {
        emit(AiCompanionMessageSent(result, null));
        _logger.d('$_tag: Audio message sent successfully');
        
        // Refresh conversation history
        add(
          LoadConversationHistory(
            companionId: event.companionId,
            conversationId: event.conversationId,
          ),
        );
      } else {
        emit(AiCompanionError('Failed to send audio message'));
      }
    } catch (e, stackTrace) {
      _logger.e(
        '$_tag: Failed to send audio message',
        error: e,
        stackTrace: stackTrace,
      );
      emit(AiCompanionError('Failed to send audio message: ${e.toString()}'));
    }
  }

  Future<void> _onLoadConversationHistory(
    LoadConversationHistory event,
    Emitter<AiCompanionState> emit,
  ) async {
    try {
      emit(AiCompanionConversationLoading(event.companionId));
      _logger.d('$_tag: Loading conversation history for: ${event.companionId}');

      final messages = await _aiCompanionService.getConversationHistory(
        companionId: event.companionId,
        conversationId: event.conversationId,
        page: event.page,
        limit: event.limit,
      );

      if (state is AiCompanionLoaded) {
        final currentState = state as AiCompanionLoaded;
        emit(currentState.copyWith(conversationHistory: messages));
      } else {
        emit(AiCompanionLoaded(conversationHistory: messages));
      }

      _logger.d('$_tag: Loaded ${messages.length} conversation messages');
    } catch (e, stackTrace) {
      _logger.e('$_tag: Failed to load conversation history', error: e, stackTrace: stackTrace);
      emit(AiCompanionError('Failed to load conversation: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateCompanionSettings(
    UpdateCompanionSettings event,
    Emitter<AiCompanionState> emit,
  ) async {
    try {
      emit(AiCompanionSettingsUpdating(event.companionId));
      _logger.d('$_tag: Updating companion settings: ${event.companionId}');

      final success = await _aiCompanionService.updateCompanionSettings(
        companionId: event.companionId,
        settings: event.settings.toJson(),
      );

      if (success) {
        emit(AiCompanionSettingsUpdated(event.companionId, event.settings));
        _logger.d('$_tag: Settings updated successfully');
        
        // Refresh companions list
        add(RefreshCompanionData());
      } else {
        emit(AiCompanionError('Failed to update settings'));
      }
    } catch (e, stackTrace) {
      _logger.e('$_tag: Failed to update settings', error: e, stackTrace: stackTrace);
      emit(AiCompanionError('Failed to update settings: ${e.toString()}'));
    }
  }

  Future<void> _onGetCompanionAnalytics(
    GetCompanionAnalytics event,
    Emitter<AiCompanionState> emit,
  ) async {
    try {
      emit(AiCompanionAnalyticsLoading(event.companionId));
      _logger.d('$_tag: Loading analytics for companion: ${event.companionId}');

      final analytics = await _aiCompanionService.getCompanionAnalytics(event.companionId);

      if (analytics != null) {
        emit(AiCompanionAnalyticsLoaded(analytics));
        
        // Also update the main state if loaded
        if (state is AiCompanionLoaded) {
          final currentState = state as AiCompanionLoaded;
          emit(currentState.copyWith(analytics: analytics));
        }
        
        _logger.d('$_tag: Analytics loaded successfully');
      } else {
        emit(AiCompanionError('Failed to load analytics'));
      }
    } catch (e, stackTrace) {
      _logger.e('$_tag: Failed to load analytics', error: e, stackTrace: stackTrace);
      emit(AiCompanionError('Failed to load analytics: ${e.toString()}'));
    }
  }

  Future<void> _onGenerateCompanionSuggestion(
    GenerateCompanionSuggestion event,
    Emitter<AiCompanionState> emit,
  ) async {
    try {
      emit(AiCompanionGeneratingSuggestion(event.companionId, event.topic));
      _logger.d('$_tag: Generating suggestion for topic: ${event.topic}');

      final suggestion = "Please use regular messaging for advice requests";
      emit(AiCompanionSuggestionGenerated(suggestion));
      _logger.d('$_tag: Redirected to regular messaging');
    } catch (e, stackTrace) {
      _logger.e('$_tag: Failed to generate suggestion', error: e, stackTrace: stackTrace);
      emit(AiCompanionError('Failed to generate suggestion: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshCompanionData(
    RefreshCompanionData event,
    Emitter<AiCompanionState> emit,
  ) async {
    // Only refresh if we're currently in a loaded state
    if (state is AiCompanionLoaded) {
      add(LoadUserCompanions());
    }
  }
}
