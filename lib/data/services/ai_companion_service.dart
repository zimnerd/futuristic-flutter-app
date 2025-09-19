import 'package:logger/logger.dart';
import 'dart:io';
import '../models/ai_companion.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/http_status_utils.dart';

/// Service for AI Companion interactions and management
class AiCompanionService {
  final ApiClient _apiClient;
  final Logger _logger = Logger();

  AiCompanionService(this._apiClient);

  /// Create a new AI companion
  Future<AICompanion?> createCompanion({
    required String name,
    required CompanionPersonality personality,
    required CompanionAppearance appearance,
    String? customPrompt,
  }) async {
    try {
      final response = await _apiClient.post(
        '/ai-companions',
        data: {
          'name': name,
          'personality': personality.name,
          'gender': 'female', // Default to female, should be configurable in UI
          'ageGroup': 'adult', // Default to adult, should be configurable in UI
          'description':
              'A personalized AI companion to help with dating advice',
          'interests': ['dating', 'relationships', 'conversation'],
        },
      );

      if (HttpStatusUtils.isPostSuccess(response.statusCode) &&
          response.data != null) {
        final companion = AICompanion.fromJson(response.data!);
        _logger.d('AI companion created successfully: ${companion.id}');
        return companion;
      } else {
        _logger.e('Failed to create AI companion: ${response.statusMessage}');
        return null;
      }
    } catch (e) {
      _logger.e('Error creating AI companion: $e');
      return null;
    }
  }

  /// Get user's AI companions
  Future<List<AICompanion>> getUserCompanions() async {
    try {
      final response = await _apiClient.get('/ai-companions/user/companions');

      if (HttpStatusUtils.isGetSuccess(response.statusCode) &&
          response.data != null) {
        final List<dynamic> data = response.data['companions'] ?? [];
        final companions = data.map((json) => AICompanion.fromJson(json)).toList();
        
        _logger.d('Retrieved ${companions.length} AI companions');
        return companions;
      } else {
        _logger.e('Failed to get AI companions: ${response.statusMessage}');
        return [];
      }
    } catch (e) {
      _logger.e('Error getting AI companions: $e');
      return [];
    }
  }

  /// Get specific AI companion
  Future<AICompanion?> getCompanion(String companionId) async {
    try {
      final response = await _apiClient.get(
        '/ai-companions/$companionId',
      );

      if (HttpStatusUtils.isGetSuccess(response.statusCode) &&
          response.data != null) {
        final companion = AICompanion.fromJson(response.data!);
        _logger.d('Retrieved AI companion: $companionId');
        return companion;
      } else {
        _logger.e('Failed to get AI companion: ${response.statusMessage}');
        return null;
      }
    } catch (e) {
      _logger.e('Error getting AI companion: $e');
      return null;
    }
  }

  /// Update AI companion
  Future<AICompanion?> updateCompanion({
    required String companionId,
    String? name,
    CompanionPersonality? personality,
    CompanionAppearance? appearance,
    String? customPrompt,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (personality != null) updateData['personality'] = personality.name;
      if (appearance != null) updateData['appearance'] = appearance.toJson();
      if (customPrompt != null) updateData['customPrompt'] = customPrompt;

      final response = await _apiClient.put(
        '/ai-companions/$companionId',
        data: updateData,
      );

      if (HttpStatusUtils.isPutSuccess(response.statusCode) &&
          response.data != null) {
        final companion = AICompanion.fromJson(response.data!);
        _logger.d('AI companion updated successfully: $companionId');
        return companion;
      } else {
        _logger.e('Failed to update AI companion: ${response.statusMessage}');
        return null;
      }
    } catch (e) {
      _logger.e('Error updating AI companion: $e');
      return null;
    }
  }

  /// Delete AI companion
  Future<bool> deleteCompanion(String companionId) async {
    try {
      final response = await _apiClient.delete(
        '/ai-companions/$companionId',
      );

      if (HttpStatusUtils.isDeleteSuccess(response.statusCode)) {
        _logger.d('AI companion deleted successfully: $companionId');
        return true;
      } else {
        _logger.e('Failed to delete AI companion: ${response.statusMessage}');
        return false;
      }
    } catch (e) {
      _logger.e('Error deleting AI companion: $e');
      return false;
    }
  }

  /// Send message to AI companion
  Future<CompanionMessage> sendMessage({
    required String companionId,
    required String message,
  }) async {
    try {
      final response = await _apiClient.post(
        '/ai-companions/$companionId/message',
        data: {'message': message, 'messageType': 'text'},
      );

      if (HttpStatusUtils.isPostSuccess(response.statusCode) &&
          response.data != null) {
        final messageData = response.data['data'];
        _logger.d('Message sent successfully to companion: $companionId');

        // Convert the response to CompanionMessage format
        return CompanionMessage(
          id: messageData['aiResponse']['id'],
          companionId: companionId,
          userId:
              messageData['userMessage']['id'], // Using user message ID for user field
          content: messageData['aiResponse']['content'],
          isFromCompanion: true,
          timestamp: DateTime.parse(messageData['aiResponse']['createdAt']),
          type: MessageType.text,
          suggestedResponses:
              messageData['aiResponse']['suggestedResponses']?.cast<String>() ??
              [],
        );
      } else {
        _logger.e('Failed to send message: ${response.statusMessage}');
        throw Exception('Failed to send message');
      }
    } catch (e) {
      _logger.e('Error sending message: $e');
      throw Exception('Failed to send message: $e');
    }
  }

  /// Send image message to AI companion
  Future<CompanionMessage?> sendImageMessage({
    required String companionId,
    required File imageFile,
  }) async {
    try {
      // For now, we'll upload the image and send the URL as a text message
      // This can be extended to support proper image message types
      final response = await _apiClient.post(
        '/ai-companions/$companionId/message',
        data: {
          'message': '[Image uploaded]',
          'messageType': 'image',
          // TODO: Add image file upload logic here
        },
      );

      if (HttpStatusUtils.isPostSuccess(response.statusCode) &&
          response.data != null) {
        final messageData = response.data['data'];
        _logger.d('Image message sent successfully to companion: $companionId');

        return CompanionMessage(
          id: messageData['aiResponse']['id'],
          companionId: companionId,
          userId: messageData['userMessage']['id'],
          content: messageData['aiResponse']['content'],
          isFromCompanion: true,
          timestamp: DateTime.parse(messageData['aiResponse']['createdAt']),
          type: MessageType.text,
          suggestedResponses:
              messageData['aiResponse']['suggestedResponses']?.cast<String>() ??
              [],
        );
      } else {
        _logger.e('Failed to send image message: ${response.statusMessage}');
        return null;
      }
    } catch (e) {
      _logger.e('Error sending image message: $e');
      return null;
    }
  }

  /// Send audio message to AI companion
  Future<CompanionMessage?> sendAudioMessage({
    required String companionId,
    required File audioFile,
  }) async {
    try {
      // For now, we'll send a placeholder message
      // This can be extended to support proper audio message types and transcription
      final response = await _apiClient.post(
        '/ai-companions/$companionId/message',
        data: {
          'message': '[Audio message sent]',
          'messageType': 'audio',
          // TODO: Add audio file upload and transcription logic here
        },
      );

      if (HttpStatusUtils.isPostSuccess(response.statusCode) &&
          response.data != null) {
        final messageData = response.data['data'];
        _logger.d('Audio message sent successfully to companion: $companionId');

        return CompanionMessage(
          id: messageData['aiResponse']['id'],
          companionId: companionId,
          userId: messageData['userMessage']['id'],
          content: messageData['aiResponse']['content'],
          isFromCompanion: true,
          timestamp: DateTime.parse(messageData['aiResponse']['createdAt']),
          type: MessageType.text,
          suggestedResponses:
              messageData['aiResponse']['suggestedResponses']?.cast<String>() ??
              [],
        );
      } else {
        _logger.e('Failed to send audio message: ${response.statusMessage}');
        return null;
      }
    } catch (e) {
      _logger.e('Error sending audio message: $e');
      return null;
    }
  }

  /// Get conversation history with AI companion
  Future<List<CompanionMessage>> getConversationHistory({
    required String companionId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        '/ai-companions/$companionId/conversation',
        queryParameters: {'page': page, 'limit': limit},
      );

      if (HttpStatusUtils.isGetSuccess(response.statusCode) &&
          response.data != null) {
        final conversationData = response.data['data'];
        final messagesList =
            conversationData['messages'] as List<dynamic>? ?? [];
        
        _logger.d(
          'Retrieved ${messagesList.length} messages for companion: $companionId',
        );

        // Convert backend messages to CompanionMessage format
        return messagesList.map((msgData) {
          return CompanionMessage(
            id: msgData['id'],
            companionId: companionId,
            userId: msgData['isFromUser'] ? 'current-user' : companionId,
            content: msgData['content'],
            isFromCompanion: !msgData['isFromUser'],
            timestamp: DateTime.parse(msgData['createdAt']),
            type: _parseMessageType(msgData['messageType']),
            suggestedResponses:
                (msgData['metadata']?['suggestedResponses'] as List<dynamic>?)
                    ?.cast<String>() ??
                [],
          );
        }).toList();
      } else {
        _logger.e(
          'Failed to get conversation history: ${response.statusMessage}',
        );
        return [];
      }
    } catch (e) {
      _logger.e('Error getting conversation history: $e');
      return [];
    }
  }

  MessageType _parseMessageType(String? type) {
    switch (type) {
      case 'text':
        return MessageType.text;
      case 'image':
        return MessageType.text; // TODO: Add image type to enum
      case 'audio':
        return MessageType.text; // TODO: Add audio type to enum
      default:
        return MessageType.text;
    }
  }

  /// Get AI companion analytics
  Future<CompanionAnalytics?> getCompanionAnalytics(String companionId) async {
    try {
      // TODO: Backend endpoint not implemented yet
      // For now, return null until analytics service is ready
      await Future.delayed(const Duration(milliseconds: 300));
      _logger.d('AI companion analytics not yet implemented for: $companionId');
      return null;
    } catch (e) {
      _logger.e('Error getting companion analytics: $e');
      return null;
    }
  }

  /// Request dating advice from AI companion
  Future<String?> getDatingAdvice({
    required String companionId,
    required String situation,
    String? context,
  }) async {
    try {
      // TODO: Backend endpoint not implemented yet
      // For now, return mock advice
      await Future.delayed(const Duration(milliseconds: 500));
      
      return "Thanks for sharing your situation with me! Here's some advice: Remember to be authentic and genuine in your interactions. Focus on building meaningful connections rather than trying to impress. Good communication and active listening are key to successful relationships.";
    } catch (e) {
      _logger.e('Error getting dating advice: $e');
      return null;
    }
  }

  /// Get profile optimization suggestions
  Future<List<String>> getProfileOptimizationTips(String companionId) async {
    try {
      // TODO: Backend endpoint not implemented yet
      // For now, return mock tips
      await Future.delayed(const Duration(milliseconds: 400));
      
      return [
        'Add more variety to your photos - show different activities and settings',
        'Write a bio that showcases your personality and interests',
        'Include photos that show you smiling and having fun',
        'Mention specific hobbies or activities you enjoy',
        'Keep your profile updated with recent photos',
      ];
    } catch (e) {
      _logger.e('Error getting profile optimization tips: $e');
      return [];
    }
  }

  /// Generate conversation starters
  Future<List<String>> generateConversationStarters(String companionId) async {
    try {
      // TODO: Backend endpoint not implemented yet
      // For now, return mock conversation starters
      await Future.delayed(const Duration(milliseconds: 400));
      
      return [
        'What\'s been the highlight of your week so far?',
        'If you could travel anywhere right now, where would you go?',
        'What\'s something you\'ve learned recently that excited you?',
        'What kind of music have you been listening to lately?',
        'Do you have any fun plans for the weekend?',
      ];
    } catch (e) {
      _logger.e('Error generating conversation starters: $e');
      return [];
    }
  }

  /// Analyze message and suggest response
  Future<String?> suggestResponse({
    required String companionId,
    required String receivedMessage,
    String? conversationContext,
  }) async {
    try {
      // TODO: Backend endpoint not implemented yet
      // For now, return mock suggestions
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Simple response suggestions based on message analysis
      if (receivedMessage.toLowerCase().contains('how are you')) {
        return "I'm doing great, thanks for asking! How about you?";
      } else if (receivedMessage.toLowerCase().contains('what')) {
        return "That's an interesting question! Let me think about that...";
      } else {
        return "That sounds really interesting! Tell me more about it.";
      }
    } catch (e) {
      _logger.e('Error getting response suggestion: $e');
      return null;
    }
  }

  /// Train AI companion with user feedback
  Future<bool> provideFeedback({
    required String companionId,
    required String messageId,
    required FeedbackType feedbackType,
    String? comments,
  }) async {
    try {
      // TODO: Backend endpoint not implemented yet
      // For now, return success to avoid errors
      await Future.delayed(const Duration(milliseconds: 300));
      _logger.d('AI companion feedback not yet implemented for: $companionId');
      return true;
    } catch (e) {
      _logger.e('Error providing feedback: $e');
      return false;
    }
  }

  /// Get AI companion settings
  Future<CompanionSettings?> getCompanionSettings(String companionId) async {
    try {
      // TODO: Backend endpoint not implemented yet
      // For now, return null until settings service is ready
      await Future.delayed(const Duration(milliseconds: 300));
      _logger.d('AI companion settings not yet implemented for: $companionId');
      return null;
    } catch (e) {
      _logger.e('Error getting companion settings: $e');
      return null;
    }
  }

  /// Update AI companion settings
  Future<bool> updateCompanionSettings({
    required String companionId,
    required CompanionSettings settings,
  }) async {
    try {
      // TODO: Backend endpoint not implemented yet
      // For now, return success to avoid errors
      await Future.delayed(const Duration(milliseconds: 300));
      _logger.d(
        'AI companion settings update not yet implemented for: $companionId',
      );
      return true;
    } catch (e) {
      _logger.e('Error updating companion settings: $e');
      return false;
    }
  }

  /// Get available companion personalities
  Future<List<CompanionPersonality>> getAvailablePersonalities() async {
    try {
      // TODO: Backend endpoint not implemented yet
      // For now, return all available personalities
      await Future.delayed(const Duration(milliseconds: 300));
      _logger.d(
        'AI companion personalities not yet implemented, returning defaults',
      );
      return CompanionPersonality.values;
    } catch (e) {
      _logger.e('Error getting available personalities: $e');
      return CompanionPersonality.values;
    }
  }
}
