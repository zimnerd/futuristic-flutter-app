import 'package:logger/logger.dart';
import 'dart:io';
import '../models/ai_companion.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/http_status_utils.dart';
import 'file_upload_service.dart';

/// Service for AI Companion interactions and management
class AiCompanionService {
  final ApiClient _apiClient;
  final FileUploadService _fileUploadService;
  final Logger _logger = Logger();

  AiCompanionService(this._apiClient, this._fileUploadService);

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
        final companion = AICompanion.fromJson(response.data['data']);
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
        // Try data wrapper first, then direct response
        final responseData = response.data['data'] ?? response.data;
        final List<dynamic> data = responseData['companions'] ?? [];
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
          id: messageData['id'],
          companionId: companionId,
          userId: messageData['isFromUser'] ? 'current-user' : companionId,
          content: messageData['content'],
          isFromCompanion: !messageData['isFromUser'],
          timestamp: DateTime.parse(messageData['sentAt']),
          type: _parseMessageType(messageData['messageType']),
          suggestedResponses:
              (messageData['metadata']?['suggestedResponses'] as List<dynamic>?)
                  ?.cast<String>() ??
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
      // Upload image first
      final imageUrl = await _fileUploadService.uploadImage(imageFile.path);

      // Send message with image URL
      final response = await _apiClient.post(
        '/ai-companions/$companionId/message',
        data: {
          'message': 'I shared an image with you',
          'messageType': 'image',
          'imageUrl': imageUrl,
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
      // Upload audio first
      final audioUrl = await _fileUploadService.uploadAudio(audioFile.path);

      // Send message with audio URL
      final response = await _apiClient.post(
        '/ai-companions/$companionId/message',
        data: {
          'message': 'I sent you an audio message',
          'messageType': 'audio',
          'audioUrl': audioUrl,
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
            timestamp: DateTime.parse(msgData['sentAt']),
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
    // For AI companion messages, we primarily use text type
    // The backend might send different types, but we treat most as text
    switch (type?.toLowerCase()) {
      case 'text':
      case 'image':
      case 'audio':
      case 'video':
      default:
        return MessageType
            .text; // AI companion MessageType only has specific conversation types
    }
  }

  /// Get AI companion analytics
  Future<CompanionAnalytics?> getCompanionAnalytics(String companionId) async {
    try {
      final response = await _apiClient.get(
        '/ai-companions/$companionId/analytics',
      );

      if (response.data != null) {
        return CompanionAnalytics(
          companionId: companionId,
          totalInteractions: response.data['totalConversations'] ?? 0,
          totalMessages: response.data['totalMessages'] ?? 0,
          averageResponseTime: 0.0, // Backend doesn't provide this yet
          userSatisfactionScore: 0.0, // Backend doesn't provide this yet
          topicFrequency: _convertTopTopicsToFrequency(
            response.data['topTopics'],
          ),
          emotionalTones: const {}, // Backend doesn't provide this yet
          mostUsedFeatures: const [], // Backend doesn't provide this yet
          lastAnalysisDate: DateTime.now(),
        );
      }
      return null;
    } catch (e) {
      _logger.e('Error getting companion analytics: $e');
      return null;
    }
  }

  /// Helper method to convert top topics array to frequency map
  Map<String, int> _convertTopTopicsToFrequency(dynamic topTopics) {
    if (topTopics is List) {
      final Map<String, int> frequency = {};
      for (final item in topTopics) {
        if (item is Map<String, dynamic>) {
          final topic = item['topic'] as String?;
          final count = item['count'] as int?;
          if (topic != null && count != null) {
            frequency[topic] = count;
          }
        }
      }
      return frequency;
    }
    return {};
  }

  /// Request dating advice from AI companion
  Future<String?> getDatingAdvice({
    required String companionId,
    required String situation,
    String? context,
  }) async {
    try {
      // Dating advice endpoint not implemented in backend yet
      // Use sendMessage instead to get advice through regular chat
      final adviceMessage =
          "I need some dating advice about this situation: $situation${context != null ? ' Additional context: $context' : ''}";

      final response = await sendMessage(
        companionId: companionId,
        message: adviceMessage,
      );
      
      return response.content;
    } catch (e) {
      _logger.e('Error getting dating advice: $e');
      return null;
    }
  }

  /// Get profile optimization suggestions
  Future<List<String>> getProfileOptimizationTips(String companionId) async {
    try {
      // Profile optimization endpoint not implemented in backend yet
      // Use sendMessage to get profile tips through regular chat
      final response = await sendMessage(
        companionId: companionId,
        message:
            "Can you give me some tips on how to optimize my dating profile to be more attractive and engaging?",
      );

      // Parse the response into tips (split by line breaks or bullets)
      final tips = response.content
          .split(RegExp(r'[•\n-]'))
          .map((tip) => tip.trim())
          .where((tip) => tip.isNotEmpty && tip.length > 10)
          .take(5)
          .toList();
      
      return tips.isNotEmpty
          ? tips
          : [
        'Add more variety to your photos - show different activities and settings',
        'Write a bio that showcases your personality and interests',
        'Include photos that show you smiling and having fun',
        'Mention specific hobbies or activities you enjoy',
        'Keep your profile updated with recent photos',
      ];
    } catch (e) {
      _logger.e('Error getting profile optimization tips: $e');
      return [
        'Add more variety to your photos',
        'Write an engaging bio',
        'Show your personality',
        'Include recent photos',
        'Mention your interests',
      ];
    }
  }

  /// Generate conversation starters
  Future<List<String>> generateConversationStarters(String companionId) async {
    try {
      // Conversation starters endpoint not implemented in backend yet
      // Use sendMessage to get conversation starters through regular chat
      final response = await sendMessage(
        companionId: companionId,
        message:
            "Can you suggest some good conversation starters for dating apps? Give me 5 interesting questions or topics.",
      );

      // Parse the response into conversation starters
      final starters = response.content
          .split(RegExp(r'[•\n-]|\d+\.'))
          .map((starter) => starter.trim())
          .where(
            (starter) =>
                starter.isNotEmpty &&
                starter.length > 10 &&
                starter.contains('?'),
          )
          .take(5)
          .toList();
      
      return starters.isNotEmpty
          ? starters
          : [
        'What\'s been the highlight of your week so far?',
        'If you could travel anywhere right now, where would you go?',
        'What\'s something you\'ve learned recently that excited you?',
        'What kind of music have you been listening to lately?',
        'Do you have any fun plans for the weekend?',
      ];
    } catch (e) {
      _logger.e('Error generating conversation starters: $e');
      return [
        'What\'s your favorite way to spend weekends?',
        'What\'s the most interesting place you\'ve visited?',
        'What are you passionate about?',
        'What\'s your favorite type of music?',
        'What\'s something that always makes you smile?',
      ];
    }
  }

  /// Analyze message and suggest response
  Future<String?> suggestResponse({
    required String companionId,
    required String receivedMessage,
    String? conversationContext,
  }) async {
    try {
      // Response suggestion endpoint not implemented in backend yet
      // Use sendMessage to get response suggestions through regular chat
      final contextMessage = conversationContext != null
          ? "Given this conversation context: '$conversationContext', "
          : "";

      final response = await sendMessage(
        companionId: companionId,
        message:
            "${contextMessage}Someone sent me this message: '$receivedMessage'. What would be a good way to respond?",
      );
      
      return response.content;
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
      // Feedback endpoint not implemented in backend yet
      // For now, log the feedback locally and return success
      _logger.d('Feedback collected for companion $companionId: $feedbackType');
      if (comments != null) {
        _logger.d('Feedback comments: $comments');
      }
      await Future.delayed(const Duration(milliseconds: 300));
      return true;
    } catch (e) {
      _logger.e('Error providing feedback: $e');
      return false;
    }
  }

  /// Get AI companion settings
  Future<CompanionSettings?> getCompanionSettings(String companionId) async {
    try {
      // Settings endpoint not implemented in backend yet
      // Return null until backend settings service is ready
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
      // Settings update endpoint not implemented in backend yet
      // For now, log the settings and return success
      _logger.d('Settings update not yet implemented for: $companionId');
      await Future.delayed(const Duration(milliseconds: 300));
      return true;
    } catch (e) {
      _logger.e('Error updating companion settings: $e');
      return false;
    }
  }

  /// Get available companion personalities
  Future<List<CompanionPersonality>> getAvailablePersonalities() async {
    try {
      // Personalities endpoint not implemented in backend yet
      // Return all available personalities from the enum
      await Future.delayed(const Duration(milliseconds: 300));
      _logger.d('Using local companion personalities');
      return CompanionPersonality.values;
    } catch (e) {
      _logger.e('Error getting available personalities: $e');
      return CompanionPersonality.values;
    }
  }
}
