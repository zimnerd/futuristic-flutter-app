import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import '../../../data/services/ai_companion_service.dart';
import 'ai_companion_event.dart';
import 'ai_companion_state.dart';

class AiCompanionBloc extends Bloc<AiCompanionEvent, AiCompanionState> {
  final AiCompanionService _aiCompanionService;
  final Logger _logger = Logger();
  static const String _tag = 'AiCompanionBloc';

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
    try {
      emit(AiCompanionMessageSending(event.companionId, event.message));
      _logger.d('$_tag: Sending message to companion: ${event.companionId}');

      final result = await _aiCompanionService.sendMessage(
        companionId: event.companionId,
        message: event.message,
      );

      emit(AiCompanionMessageSent(result, null));
      _logger.d('$_tag: Message sent successfully');

      // Refresh conversation history
      add(LoadConversationHistory(companionId: event.companionId));
    } catch (e, stackTrace) {
      _logger.e(
        '$_tag: Failed to send message',
        error: e,
        stackTrace: stackTrace,
      );
      emit(AiCompanionError('Failed to send message: ${e.toString()}'));
    }
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
        add(LoadConversationHistory(companionId: event.companionId));
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
        add(LoadConversationHistory(companionId: event.companionId));
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
        settings: event.settings,
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

      final suggestion = await _aiCompanionService.getDatingAdvice(
        companionId: event.companionId,
        situation: event.topic,
      );

      if (suggestion != null) {
        emit(AiCompanionSuggestionGenerated(suggestion));
        _logger.d('$_tag: Suggestion generated successfully');
      } else {
        emit(AiCompanionError('Failed to generate suggestion'));
      }
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
