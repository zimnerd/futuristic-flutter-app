import 'package:logger/logger.dart';

import '../../core/network/api_client.dart';
import '../../core/services/service_locator.dart';

/// Service for AI-powered auto-reply suggestions and conversation assistance
class AutoReplyService {
  final ApiClient _apiClient;
  final Logger _logger = Logger();

  AutoReplyService(this._apiClient);

  /// Generate AI reply suggestions based on conversation context
  Future<List<String>> generateReplySuggestions({
    required String conversationId,
    required String lastMessage,
    String? conversationContext,
    String? userPersonality,
    int count = 3,
  }) async {
    try {
      // Check if smart replies are enabled
      final aiPreferences = ServiceLocator.instance.aiPreferences;
      final isEnabled = await aiPreferences.isFeatureEnabled('smart_replies');

      if (!isEnabled) {
        _logger.d('Smart replies disabled in preferences');
        return [];
      }

      // Get conversation preferences
      final preferences = await aiPreferences.getConversationPreferences();

      final response = await _apiClient.post(
        '/api/v1/ai/response-suggestions',
        data: {
          'conversationId': conversationId,
          'lastMessage': lastMessage,
          'conversationContext': conversationContext,
          'userPersonality': userPersonality,
          'count': preferences['maxSuggestions'] ?? count,
          'tone': preferences['replyTone'],
          'adaptToUserStyle': preferences['adaptToUserStyle'],
          'contextAware': preferences['contextAware'],
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> suggestionsData =
            response.data['suggestions'] ?? [];
        final List<String> suggestions = suggestionsData.cast<String>();

        _logger.d('Generated ${suggestions.length} reply suggestions');
        return suggestions;
      } else {
        _logger.e(
          'Failed to generate reply suggestions: ${response.statusMessage}',
        );
        return [];
      }
    } catch (e) {
      _logger.e('Error generating reply suggestions: $e');
      return [];
    }
  }

  /// Generate custom reply based on user description and preferences
  Future<String?> generateCustomReply({
    required String conversationId,
    required String lastMessage,
    required String userInstructions,
    String? conversationContext,
    String? tone,
    String? style,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/v1/ai/custom-reply',
        data: {
          'conversationId': conversationId,
          'lastMessage': lastMessage,
          'userInstructions': userInstructions,
          'conversationContext': conversationContext,
          'tone': tone,
          'style': style,
        },
      );

      if (response.statusCode == 200) {
        final String? customReply = response.data['reply'];

        _logger.d('Generated custom reply');
        return customReply;
      } else {
        _logger.e('Failed to generate custom reply: ${response.statusMessage}');
        return null;
      }
    } catch (e) {
      _logger.e('Error generating custom reply: $e');
      return null;
    }
  }

  /// Refine an existing reply suggestion based on user feedback
  Future<String?> refineReply({
    required String originalReply,
    required String refinementInstructions,
    String? conversationContext,
    String? tone,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/v1/ai/refine-reply',
        data: {
          'originalReply': originalReply,
          'refinementInstructions': refinementInstructions,
          'conversationContext': conversationContext,
          'tone': tone,
        },
      );

      if (response.statusCode == 200) {
        final String? refinedReply = response.data['refinedReply'];

        _logger.d('Refined reply successfully');
        return refinedReply;
      } else {
        _logger.e('Failed to refine reply: ${response.statusMessage}');
        return null;
      }
    } catch (e) {
      _logger.e('Error refining reply: $e');
      return null;
    }
  }

  /// Get conversation style analysis for better AI suggestions
  Future<Map<String, dynamic>?> analyzeConversationStyle({
    required String conversationId,
    int? messageLimit,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/v1/ai/conversation-analysis',
        queryParameters: {
          'conversationId': conversationId,
          if (messageLimit != null) 'messageLimit': messageLimit,
        },
      );

      if (response.statusCode == 200) {
        final analysis = response.data['analysis'];

        _logger.d('Analyzed conversation style');
        return analysis;
      } else {
        _logger.e('Failed to analyze conversation: ${response.statusMessage}');
        return null;
      }
    } catch (e) {
      _logger.e('Error analyzing conversation: $e');
      return null;
    }
  }

  /// Get trending conversation topics for suggestion inspiration
  Future<List<String>> getTrendingTopics({
    String? category,
    int limit = 10,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/v1/ai/trending-topics',
        queryParameters: {
          if (category != null) 'category': category,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> topicsData = response.data['topics'] ?? [];
        final List<String> topics = topicsData.cast<String>();

        _logger.d('Retrieved ${topics.length} trending topics');
        return topics;
      } else {
        _logger.e('Failed to get trending topics: ${response.statusMessage}');
        return [];
      }
    } catch (e) {
      _logger.e('Error getting trending topics: $e');
      return [];
    }
  }

  /// Save user preference for reply suggestions
  Future<bool> saveReplyPreference({
    required String preferenceType,
    required Map<String, dynamic> preferences,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/v1/ai/reply-preferences',
        data: {'preferenceType': preferenceType, 'preferences': preferences},
      );

      if (response.statusCode == 200) {
        _logger.d('Saved reply preferences');
        return true;
      } else {
        _logger.e(
          'Failed to save reply preferences: ${response.statusMessage}',
        );
        return false;
      }
    } catch (e) {
      _logger.e('Error saving reply preferences: $e');
      return false;
    }
  }

  /// Get user's reply preferences
  Future<Map<String, dynamic>?> getReplyPreferences() async {
    try {
      final response = await _apiClient.get('/ai/reply-preferences');

      if (response.statusCode == 200) {
        final preferences = response.data['preferences'];

        _logger.d('Retrieved reply preferences');
        return preferences;
      } else {
        _logger.e('Failed to get reply preferences: ${response.statusMessage}');
        return null;
      }
    } catch (e) {
      _logger.e('Error getting reply preferences: $e');
      return null;
    }
  }
}
