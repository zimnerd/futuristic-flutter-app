import 'package:equatable/equatable.dart';
import 'dart:io';
import '../../../data/models/ai_companion.dart';

abstract class AiCompanionEvent extends Equatable {
  const AiCompanionEvent();

  @override
  List<Object?> get props => [];
}

class LoadUserCompanions extends AiCompanionEvent {}

class CreateCompanion extends AiCompanionEvent {
  final String name;
  final CompanionPersonality personality;
  final CompanionAppearance appearance;
  final CompanionGender? gender;
  final CompanionAge? ageGroup;
  final String? description;
  final List<String>? interests;
  final Map<String, dynamic>? voiceSettings;

  const CreateCompanion({
    required this.name,
    required this.personality,
    required this.appearance,
    this.gender,
    this.ageGroup,
    this.description,
    this.interests,
    this.voiceSettings,
  });

  @override
  List<Object?> get props => [
    name,
    personality,
    appearance,
    gender,
    ageGroup,
    description,
    interests,
    voiceSettings,
  ];
}

class UpdateCompanion extends AiCompanionEvent {
  final String companionId;
  final String? name;
  final CompanionPersonality? personality;
  final CompanionAppearance? appearance;
  final CompanionSettings? settings;

  const UpdateCompanion({
    required this.companionId,
    this.name,
    this.personality,
    this.appearance,
    this.settings,
  });

  @override
  List<Object?> get props => [companionId, name, personality, appearance, settings];
}

class DeleteCompanion extends AiCompanionEvent {
  final String companionId;

  const DeleteCompanion(this.companionId);

  @override
  List<Object> get props => [companionId];
}

class SendMessageToCompanion extends AiCompanionEvent {
  final String companionId;
  final String message;

  const SendMessageToCompanion({
    required this.companionId,
    required this.message,
  });

  @override
  List<Object> get props => [companionId, message];
}

class LoadConversationHistory extends AiCompanionEvent {
  final String companionId;
  final String conversationId;
  final int page;
  final int limit;

  const LoadConversationHistory({
    required this.companionId,
    required this.conversationId,
    this.page = 1,
    this.limit = 50,
  });

  @override
  List<Object> get props => [companionId, conversationId, page, limit];
}

class UpdateCompanionSettings extends AiCompanionEvent {
  final String companionId;
  final CompanionSettings settings;

  const UpdateCompanionSettings({
    required this.companionId,
    required this.settings,
  });

  @override
  List<Object> get props => [companionId, settings];
}

class GetCompanionAnalytics extends AiCompanionEvent {
  final String companionId;

  const GetCompanionAnalytics(this.companionId);

  @override
  List<Object> get props => [companionId];
}

class GenerateCompanionSuggestion extends AiCompanionEvent {
  final String companionId;
  final String topic;

  const GenerateCompanionSuggestion({
    required this.companionId,
    required this.topic,
  });

  @override
  List<Object> get props => [companionId, topic];
}

class RefreshCompanionData extends AiCompanionEvent {}

class SendImageMessage extends AiCompanionEvent {
  final String companionId;
  final String conversationId;
  final File imageFile;

  const SendImageMessage({
    required this.companionId,
    required this.conversationId,
    required this.imageFile,
  });

  @override
  List<Object> get props => [companionId, conversationId, imageFile];
}

class SendAudioMessage extends AiCompanionEvent {
  final String companionId;
  final String conversationId;
  final File audioFile;

  const SendAudioMessage({
    required this.companionId,
    required this.conversationId,
    required this.audioFile,
  });

  @override
  List<Object> get props => [companionId, conversationId, audioFile];
}

class MessageReceived extends AiCompanionEvent {
  final CompanionMessage message;

  const MessageReceived(this.message);

  @override
  List<Object> get props => [message];
}

class MessageError extends AiCompanionEvent {
  final String error;

  const MessageError(this.error);

  @override
  List<Object> get props => [error];
}
