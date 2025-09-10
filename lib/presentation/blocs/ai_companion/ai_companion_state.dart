import 'package:equatable/equatable.dart';
import '../../../data/models/ai_companion.dart';

abstract class AiCompanionState extends Equatable {
  const AiCompanionState();

  @override
  List<Object?> get props => [];
}

class AiCompanionInitial extends AiCompanionState {}

class AiCompanionLoading extends AiCompanionState {}

class AiCompanionLoaded extends AiCompanionState {
  final List<AICompanion> companions;
  final AICompanion? selectedCompanion;
  final List<CompanionMessage> conversationHistory;
  final CompanionAnalytics? analytics;

  const AiCompanionLoaded({
    this.companions = const [],
    this.selectedCompanion,
    this.conversationHistory = const [],
    this.analytics,
  });

  @override
  List<Object?> get props => [companions, selectedCompanion, conversationHistory, analytics];

  AiCompanionLoaded copyWith({
    List<AICompanion>? companions,
    AICompanion? selectedCompanion,
    List<CompanionMessage>? conversationHistory,
    CompanionAnalytics? analytics,
  }) {
    return AiCompanionLoaded(
      companions: companions ?? this.companions,
      selectedCompanion: selectedCompanion ?? this.selectedCompanion,
      conversationHistory: conversationHistory ?? this.conversationHistory,
      analytics: analytics ?? this.analytics,
    );
  }
}

class AiCompanionError extends AiCompanionState {
  final String message;

  const AiCompanionError(this.message);

  @override
  List<Object> get props => [message];
}

// Specific operation states
class AiCompanionCreating extends AiCompanionState {}

class AiCompanionCreated extends AiCompanionState {
  final AICompanion companion;

  const AiCompanionCreated(this.companion);

  @override
  List<Object> get props => [companion];
}

class AiCompanionUpdating extends AiCompanionState {
  final String companionId;

  const AiCompanionUpdating(this.companionId);

  @override
  List<Object> get props => [companionId];
}

class AiCompanionUpdated extends AiCompanionState {
  final AICompanion companion;

  const AiCompanionUpdated(this.companion);

  @override
  List<Object> get props => [companion];
}

class AiCompanionDeleting extends AiCompanionState {
  final String companionId;

  const AiCompanionDeleting(this.companionId);

  @override
  List<Object> get props => [companionId];
}

class AiCompanionDeleted extends AiCompanionState {
  final String companionId;

  const AiCompanionDeleted(this.companionId);

  @override
  List<Object> get props => [companionId];
}

// Conversation states
class AiCompanionMessageSending extends AiCompanionState {
  final String companionId;
  final String message;

  const AiCompanionMessageSending(this.companionId, this.message);

  @override
  List<Object> get props => [companionId, message];
}

class AiCompanionMessageSent extends AiCompanionState {
  final CompanionMessage message;
  final String? response;

  const AiCompanionMessageSent(this.message, [this.response]);

  @override
  List<Object?> get props => [message, response];
}

class AiCompanionConversationLoading extends AiCompanionState {
  final String companionId;

  const AiCompanionConversationLoading(this.companionId);

  @override
  List<Object> get props => [companionId];
}

// Settings states
class AiCompanionSettingsUpdating extends AiCompanionState {
  final String companionId;

  const AiCompanionSettingsUpdating(this.companionId);

  @override
  List<Object> get props => [companionId];
}

class AiCompanionSettingsUpdated extends AiCompanionState {
  final String companionId;
  final CompanionSettings settings;

  const AiCompanionSettingsUpdated(this.companionId, this.settings);

  @override
  List<Object> get props => [companionId, settings];
}

// Analytics states
class AiCompanionAnalyticsLoading extends AiCompanionState {
  final String companionId;

  const AiCompanionAnalyticsLoading(this.companionId);

  @override
  List<Object> get props => [companionId];
}

class AiCompanionAnalyticsLoaded extends AiCompanionState {
  final CompanionAnalytics analytics;

  const AiCompanionAnalyticsLoaded(this.analytics);

  @override
  List<Object> get props => [analytics];
}

// Suggestion states
class AiCompanionGeneratingSuggestion extends AiCompanionState {
  final String companionId;
  final String topic;

  const AiCompanionGeneratingSuggestion(this.companionId, this.topic);

  @override
  List<Object> get props => [companionId, topic];
}

class AiCompanionSuggestionGenerated extends AiCompanionState {
  final String suggestion;

  const AiCompanionSuggestionGenerated(this.suggestion);

  @override
  List<Object> get props => [suggestion];
}
