import 'package:logger/logger.dart';
import '../models/ai_companion.dart';
import '../../core/network/api_client.dart';

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
        '/api/ai-companion/create',
        data: {
          'name': name,
          'personality': personality.name,
          'appearance': appearance.toJson(),
          'customPrompt': customPrompt,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
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
      final response = await _apiClient.get('/api/ai-companion/my-companions');

      if (response.statusCode == 200 && response.data != null) {
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
      final response = await _apiClient.get('/api/ai-companion/$companionId');

      if (response.statusCode == 200 && response.data != null) {
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
        '/api/ai-companion/$companionId',
        data: updateData,
      );

      if (response.statusCode == 200 && response.data != null) {
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
      final response = await _apiClient.delete('/api/ai-companion/$companionId');

      if (response.statusCode == 200) {
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
  Future<CompanionMessage?> sendMessage({
    required String companionId,
    required String message,
    MessageType messageType = MessageType.text,
    String? mediaUrl,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/ai-companion/$companionId/message',
        data: {
          'message': message,
          'messageType': messageType.name,
          'mediaUrl': mediaUrl,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final companionMessage = CompanionMessage.fromJson(response.data!);
        _logger.d('Message sent to AI companion: $companionId');
        return companionMessage;
      } else {
        _logger.e('Failed to send message to AI companion: ${response.statusMessage}');
        return null;
      }
    } catch (e) {
      _logger.e('Error sending message to AI companion: $e');
      return null;
    }
  }

  /// Get conversation history with AI companion
  Future<List<CompanionMessage>> getConversationHistory({
    required String companionId,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/ai-companion/$companionId/conversation',
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['messages'] ?? [];
        final messages = data.map((json) => CompanionMessage.fromJson(json)).toList();
        
        _logger.d('Retrieved ${messages.length} conversation messages (page $page)');
        return messages;
      } else {
        _logger.e('Failed to get conversation history: ${response.statusMessage}');
        return [];
      }
    } catch (e) {
      _logger.e('Error getting conversation history: $e');
      return [];
    }
  }

  /// Get AI companion analytics
  Future<CompanionAnalytics?> getCompanionAnalytics(String companionId) async {
    try {
      final response = await _apiClient.get('/api/ai-companion/$companionId/analytics');

      if (response.statusCode == 200 && response.data != null) {
        final analytics = CompanionAnalytics.fromJson(response.data!);
        _logger.d('Retrieved AI companion analytics: $companionId');
        return analytics;
      } else {
        _logger.e('Failed to get companion analytics: ${response.statusMessage}');
        return null;
      }
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
      final response = await _apiClient.post(
        '/api/ai-companion/$companionId/advice',
        data: {
          'situation': situation,
          'context': context,
          'requestType': 'dating_advice',
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final advice = response.data['advice'] as String?;
        _logger.d('Received dating advice from AI companion: $companionId');
        return advice;
      } else {
        _logger.e('Failed to get dating advice: ${response.statusMessage}');
        return null;
      }
    } catch (e) {
      _logger.e('Error getting dating advice: $e');
      return null;
    }
  }

  /// Get profile optimization suggestions
  Future<List<String>> getProfileOptimizationTips(String companionId) async {
    try {
      final response = await _apiClient.post(
        '/api/ai-companion/$companionId/profile-tips',
        data: {'requestType': 'profile_optimization'},
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['tips'] ?? [];
        final tips = data.map((tip) => tip.toString()).toList();
        
        _logger.d('Retrieved ${tips.length} profile optimization tips');
        return tips;
      } else {
        _logger.e('Failed to get profile tips: ${response.statusMessage}');
        return [];
      }
    } catch (e) {
      _logger.e('Error getting profile tips: $e');
      return [];
    }
  }

  /// Get conversation starters
  Future<List<String>> getConversationStarters({
    required String companionId,
    String? matchProfile,
    String? context,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/ai-companion/$companionId/conversation-starters',
        data: {
          'matchProfile': matchProfile,
          'context': context,
          'requestType': 'conversation_starters',
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['starters'] ?? [];
        final starters = data.map((starter) => starter.toString()).toList();
        
        _logger.d('Retrieved ${starters.length} conversation starters');
        return starters;
      } else {
        _logger.e('Failed to get conversation starters: ${response.statusMessage}');
        return [];
      }
    } catch (e) {
      _logger.e('Error getting conversation starters: $e');
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
      final response = await _apiClient.post(
        '/api/ai-companion/$companionId/suggest-response',
        data: {
          'receivedMessage': receivedMessage,
          'conversationContext': conversationContext,
          'requestType': 'response_suggestion',
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final suggestion = response.data['suggestion'] as String?;
        _logger.d('Received response suggestion from AI companion: $companionId');
        return suggestion;
      } else {
        _logger.e('Failed to get response suggestion: ${response.statusMessage}');
        return null;
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
      final response = await _apiClient.post(
        '/api/ai-companion/$companionId/feedback',
        data: {
          'messageId': messageId,
          'feedbackType': feedbackType.name,
          'comments': comments,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (response.statusCode == 200) {
        _logger.d('Feedback provided to AI companion: $companionId');
        return true;
      } else {
        _logger.e('Failed to provide feedback: ${response.statusMessage}');
        return false;
      }
    } catch (e) {
      _logger.e('Error providing feedback: $e');
      return false;
    }
  }

  /// Get AI companion settings
  Future<CompanionSettings?> getCompanionSettings(String companionId) async {
    try {
      final response = await _apiClient.get('/api/ai-companion/$companionId/settings');

      if (response.statusCode == 200 && response.data != null) {
        final settings = CompanionSettings.fromJson(response.data!);
        _logger.d('Retrieved AI companion settings: $companionId');
        return settings;
      } else {
        _logger.e('Failed to get companion settings: ${response.statusMessage}');
        return null;
      }
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
      final response = await _apiClient.put(
        '/api/ai-companion/$companionId/settings',
        data: settings.toJson(),
      );

      if (response.statusCode == 200) {
        _logger.d('AI companion settings updated: $companionId');
        return true;
      } else {
        _logger.e('Failed to update companion settings: ${response.statusMessage}');
        return false;
      }
    } catch (e) {
      _logger.e('Error updating companion settings: $e');
      return false;
    }
  }

  /// Get available companion personalities
  Future<List<CompanionPersonality>> getAvailablePersonalities() async {
    try {
      final response = await _apiClient.get('/api/ai-companion/personalities');

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['personalities'] ?? [];
        final personalities = data.map((name) {
          return CompanionPersonality.values.firstWhere(
            (p) => p.name == name,
            orElse: () => CompanionPersonality.friend,
          );
        }).toList();
        
        _logger.d('Retrieved ${personalities.length} available personalities');
        return personalities;
      } else {
        _logger.e('Failed to get available personalities: ${response.statusMessage}');
        return CompanionPersonality.values;
      }
    } catch (e) {
      _logger.e('Error getting available personalities: $e');
      return CompanionPersonality.values;
    }
  }
}
