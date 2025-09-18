import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/ai_preferences.dart';
import '../../data/services/ai_preferences_service.dart';

/// Events for AI preferences management
abstract class AiPreferencesEvent extends Equatable {
  const AiPreferencesEvent();

  @override
  List<Object?> get props => [];
}

class LoadAiPreferences extends AiPreferencesEvent {}

class UpdateAiPreferences extends AiPreferencesEvent {
  final AiPreferences preferences;

  const UpdateAiPreferences(this.preferences);

  @override
  List<Object?> get props => [preferences];
}

class SetAiEnabled extends AiPreferencesEvent {
  final bool enabled;

  const SetAiEnabled(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class UpdateConversationSettings extends AiPreferencesEvent {
  final AiConversationSettings settings;

  const UpdateConversationSettings(this.settings);

  @override
  List<Object?> get props => [settings];
}

class UpdateCompanionSettings extends AiPreferencesEvent {
  final AiCompanionSettings settings;

  const UpdateCompanionSettings(this.settings);

  @override
  List<Object?> get props => [settings];
}

class UpdateProfileSettings extends AiPreferencesEvent {
  final AiProfileSettings settings;

  const UpdateProfileSettings(this.settings);

  @override
  List<Object?> get props => [settings];
}

class UpdateMatchingSettings extends AiPreferencesEvent {
  final AiMatchingSettings settings;

  const UpdateMatchingSettings(this.settings);

  @override
  List<Object?> get props => [settings];
}

class UpdateIcebreakerSettings extends AiPreferencesEvent {
  final AiIcebreakerSettings settings;

  const UpdateIcebreakerSettings(this.settings);

  @override
  List<Object?> get props => [settings];
}

class UpdateGeneralSettings extends AiPreferencesEvent {
  final AiGeneralSettings settings;

  const UpdateGeneralSettings(this.settings);

  @override
  List<Object?> get props => [settings];
}

class ResetAiPreferences extends AiPreferencesEvent {}

class CompleteAiOnboarding extends AiPreferencesEvent {}

/// States for AI preferences management
abstract class AiPreferencesState extends Equatable {
  const AiPreferencesState();

  @override
  List<Object?> get props => [];
}

class AiPreferencesInitial extends AiPreferencesState {}

class AiPreferencesLoading extends AiPreferencesState {}

class AiPreferencesLoaded extends AiPreferencesState {
  final AiPreferences preferences;
  final bool hasCompletedOnboarding;

  const AiPreferencesLoaded({
    required this.preferences,
    required this.hasCompletedOnboarding,
  });

  @override
  List<Object?> get props => [preferences, hasCompletedOnboarding];
}

class AiPreferencesError extends AiPreferencesState {
  final String message;

  const AiPreferencesError(this.message);

  @override
  List<Object?> get props => [message];
}

/// BLoC for managing AI preferences
class AiPreferencesBloc extends Bloc<AiPreferencesEvent, AiPreferencesState> {
  final AiPreferencesService _preferencesService;

  AiPreferencesBloc({
    required AiPreferencesService preferencesService,
  })  : _preferencesService = preferencesService,
        super(AiPreferencesInitial()) {
    on<LoadAiPreferences>(_onLoadAiPreferences);
    on<UpdateAiPreferences>(_onUpdateAiPreferences);
    on<SetAiEnabled>(_onSetAiEnabled);
    on<UpdateConversationSettings>(_onUpdateConversationSettings);
    on<UpdateCompanionSettings>(_onUpdateCompanionSettings);
    on<UpdateProfileSettings>(_onUpdateProfileSettings);
    on<UpdateMatchingSettings>(_onUpdateMatchingSettings);
    on<UpdateIcebreakerSettings>(_onUpdateIcebreakerSettings);
    on<UpdateGeneralSettings>(_onUpdateGeneralSettings);
    on<ResetAiPreferences>(_onResetAiPreferences);
    on<CompleteAiOnboarding>(_onCompleteAiOnboarding);
  }

  Future<void> _onLoadAiPreferences(
    LoadAiPreferences event,
    Emitter<AiPreferencesState> emit,
  ) async {
    try {
      emit(AiPreferencesLoading());
      
      final preferences = await _preferencesService.getAiPreferences();
      final hasCompletedOnboarding = await _preferencesService.hasCompletedAiOnboarding();
      
      emit(AiPreferencesLoaded(
        preferences: preferences,
        hasCompletedOnboarding: hasCompletedOnboarding,
      ));
    } catch (e) {
      emit(AiPreferencesError('Failed to load AI preferences: $e'));
    }
  }

  Future<void> _onUpdateAiPreferences(
    UpdateAiPreferences event,
    Emitter<AiPreferencesState> emit,
  ) async {
    try {
      await _preferencesService.updateAiPreferences(event.preferences);
      
      final hasCompletedOnboarding = await _preferencesService.hasCompletedAiOnboarding();
      
      emit(AiPreferencesLoaded(
        preferences: event.preferences,
        hasCompletedOnboarding: hasCompletedOnboarding,
      ));
    } catch (e) {
      emit(AiPreferencesError('Failed to update AI preferences: $e'));
    }
  }

  Future<void> _onSetAiEnabled(
    SetAiEnabled event,
    Emitter<AiPreferencesState> emit,
  ) async {
    try {
      await _preferencesService.setAiEnabled(event.enabled);
      
      final preferences = await _preferencesService.getAiPreferences();
      final hasCompletedOnboarding = await _preferencesService.hasCompletedAiOnboarding();
      
      emit(AiPreferencesLoaded(
        preferences: preferences,
        hasCompletedOnboarding: hasCompletedOnboarding,
      ));
    } catch (e) {
      emit(AiPreferencesError('Failed to update AI enabled state: $e'));
    }
  }

  Future<void> _onUpdateConversationSettings(
    UpdateConversationSettings event,
    Emitter<AiPreferencesState> emit,
  ) async {
    try {
      await _preferencesService.updateConversationSettings(event.settings);
      
      final preferences = await _preferencesService.getAiPreferences();
      final hasCompletedOnboarding = await _preferencesService.hasCompletedAiOnboarding();
      
      emit(AiPreferencesLoaded(
        preferences: preferences,
        hasCompletedOnboarding: hasCompletedOnboarding,
      ));
    } catch (e) {
      emit(AiPreferencesError('Failed to update conversation settings: $e'));
    }
  }

  Future<void> _onUpdateCompanionSettings(
    UpdateCompanionSettings event,
    Emitter<AiPreferencesState> emit,
  ) async {
    try {
      await _preferencesService.updateCompanionSettings(event.settings);
      
      final preferences = await _preferencesService.getAiPreferences();
      final hasCompletedOnboarding = await _preferencesService.hasCompletedAiOnboarding();
      
      emit(AiPreferencesLoaded(
        preferences: preferences,
        hasCompletedOnboarding: hasCompletedOnboarding,
      ));
    } catch (e) {
      emit(AiPreferencesError('Failed to update companion settings: $e'));
    }
  }

  Future<void> _onUpdateProfileSettings(
    UpdateProfileSettings event,
    Emitter<AiPreferencesState> emit,
  ) async {
    try {
      await _preferencesService.updateProfileSettings(event.settings);
      
      final preferences = await _preferencesService.getAiPreferences();
      final hasCompletedOnboarding = await _preferencesService.hasCompletedAiOnboarding();
      
      emit(AiPreferencesLoaded(
        preferences: preferences,
        hasCompletedOnboarding: hasCompletedOnboarding,
      ));
    } catch (e) {
      emit(AiPreferencesError('Failed to update profile settings: $e'));
    }
  }

  Future<void> _onUpdateMatchingSettings(
    UpdateMatchingSettings event,
    Emitter<AiPreferencesState> emit,
  ) async {
    try {
      await _preferencesService.updateMatchingSettings(event.settings);
      
      final preferences = await _preferencesService.getAiPreferences();
      final hasCompletedOnboarding = await _preferencesService.hasCompletedAiOnboarding();
      
      emit(AiPreferencesLoaded(
        preferences: preferences,
        hasCompletedOnboarding: hasCompletedOnboarding,
      ));
    } catch (e) {
      emit(AiPreferencesError('Failed to update matching settings: $e'));
    }
  }

  Future<void> _onUpdateIcebreakerSettings(
    UpdateIcebreakerSettings event,
    Emitter<AiPreferencesState> emit,
  ) async {
    try {
      await _preferencesService.updateIcebreakerSettings(event.settings);
      
      final preferences = await _preferencesService.getAiPreferences();
      final hasCompletedOnboarding = await _preferencesService.hasCompletedAiOnboarding();
      
      emit(AiPreferencesLoaded(
        preferences: preferences,
        hasCompletedOnboarding: hasCompletedOnboarding,
      ));
    } catch (e) {
      emit(AiPreferencesError('Failed to update icebreaker settings: $e'));
    }
  }

  Future<void> _onUpdateGeneralSettings(
    UpdateGeneralSettings event,
    Emitter<AiPreferencesState> emit,
  ) async {
    try {
      await _preferencesService.updateGeneralSettings(event.settings);
      
      final preferences = await _preferencesService.getAiPreferences();
      final hasCompletedOnboarding = await _preferencesService.hasCompletedAiOnboarding();
      
      emit(AiPreferencesLoaded(
        preferences: preferences,
        hasCompletedOnboarding: hasCompletedOnboarding,
      ));
    } catch (e) {
      emit(AiPreferencesError('Failed to update general settings: $e'));
    }
  }

  Future<void> _onResetAiPreferences(
    ResetAiPreferences event,
    Emitter<AiPreferencesState> emit,
  ) async {
    try {
      await _preferencesService.resetPreferences();
      
      final preferences = await _preferencesService.getAiPreferences();
      final hasCompletedOnboarding = await _preferencesService.hasCompletedAiOnboarding();
      
      emit(AiPreferencesLoaded(
        preferences: preferences,
        hasCompletedOnboarding: hasCompletedOnboarding,
      ));
    } catch (e) {
      emit(AiPreferencesError('Failed to reset AI preferences: $e'));
    }
  }

  Future<void> _onCompleteAiOnboarding(
    CompleteAiOnboarding event,
    Emitter<AiPreferencesState> emit,
  ) async {
    try {
      await _preferencesService.completeAiOnboarding();
      
      final preferences = await _preferencesService.getAiPreferences();
      final hasCompletedOnboarding = await _preferencesService.hasCompletedAiOnboarding();
      
      emit(AiPreferencesLoaded(
        preferences: preferences,
        hasCompletedOnboarding: hasCompletedOnboarding,
      ));
    } catch (e) {
      emit(AiPreferencesError('Failed to complete AI onboarding: $e'));
    }
  }

  /// Helper method to check if a feature is enabled
  bool isFeatureEnabled(String feature) {
    final currentState = state;
    if (currentState is AiPreferencesLoaded) {
      final preferences = currentState.preferences;
      
      if (!preferences.isAiEnabled) {
        return false;
      }

      switch (feature) {
        case 'smart_replies':
          return preferences.conversations.smartRepliesEnabled;
        case 'custom_reply':
          return preferences.conversations.customReplyEnabled;
        case 'auto_suggestions':
          return preferences.conversations.autoSuggestionsEnabled;
        case 'companion_chat':
          return preferences.companion.companionChatEnabled;
        case 'companion_advice':
          return preferences.companion.companionAdviceEnabled;
        case 'profile_optimization':
          return preferences.profile.profileOptimizationEnabled;
        case 'bio_suggestions':
          return preferences.profile.bioSuggestionsEnabled;
        case 'smart_matching':
          return preferences.matching.smartMatchingEnabled;
        case 'icebreaker_suggestions':
          return preferences.icebreakers.icebreakerSuggestionsEnabled;
        case 'personalized_icebreakers':
          return preferences.icebreakers.personalizedIcebreakersEnabled;
        default:
          return false;
      }
    }
    return false;
  }
}