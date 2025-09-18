import 'package:logger/logger.dart';
import '../../core/network/api_client.dart';

/// Service for AI-powered icebreaker generation and conversation starters
class IcebreakerService {
  final ApiClient _apiClient;
  final Logger _logger = Logger();

  IcebreakerService(this._apiClient);

  /// Generate personalized icebreaker questions for a specific user
  Future<List<String>> generateIcebreakers({
    required String targetUserId,
    int? count,
    String? context,
    List<String>? interests,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/v1/ai/ice-breakers/$targetUserId',
        queryParameters: {
          if (count != null) 'count': count.toString(),
          if (context != null) 'context': context,
          if (interests != null && interests.isNotEmpty) 'interests': interests.join(','),
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> icebreakersData = response.data['iceBreakers'] ?? [];
        final List<String> icebreakers = icebreakersData.cast<String>();
        
        _logger.d('Generated ${icebreakers.length} icebreakers for user $targetUserId');
        return icebreakers;
      } else {
        _logger.e('Failed to generate icebreakers: ${response.statusMessage}');
        return [];
      }
    } catch (e) {
      _logger.e('Error generating icebreakers: $e');
      return [];
    }
  }

  /// Get conversation starters based on shared interests or activities
  Future<List<Map<String, dynamic>>> getConversationStarters({
    required String targetUserId,
    String? topic,
    String? mood,
    String? conversationType,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/v1/ai/conversation-starters',
        data: {
          'targetUserId': targetUserId,
          'topic': topic,
          'mood': mood ?? 'friendly',
          'conversationType': conversationType ?? 'casual',
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> startersData = response.data['starters'] ?? [];
        final List<Map<String, dynamic>> starters = startersData
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        
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

  /// Generate response suggestions for ongoing conversations
  Future<List<String>> generateResponseSuggestions({
    required String conversationId,
    required String lastMessage,
    String? tone,
    int? count,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/v1/ai/response-suggestions',
        data: {
          'conversationId': conversationId,
          'lastMessage': lastMessage,
          'tone': tone ?? 'friendly',
          'count': count ?? 3,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> suggestionsData = response.data['suggestions'] ?? [];
        final List<String> suggestions = suggestionsData.cast<String>();
        
        _logger.d('Generated ${suggestions.length} response suggestions');
        return suggestions;
      } else {
        _logger.e('Failed to generate response suggestions: ${response.statusMessage}');
        return [];
      }
    } catch (e) {
      _logger.e('Error generating response suggestions: $e');
      return [];
    }
  }

  /// Get trending conversation topics
  Future<List<Map<String, dynamic>>> getTrendingTopics({
    String? category,
    int? limit,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/v1/ai/trending-topics',
        queryParameters: {
          if (category != null) 'category': category,
          if (limit != null) 'limit': limit.toString(),
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> topicsData = response.data['topics'] ?? [];
        final List<Map<String, dynamic>> topics = topicsData
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        
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

  /// Analyze conversation compatibility and get improvement suggestions
  Future<Map<String, dynamic>?> analyzeConversationCompatibility({
    required String targetUserId,
    List<String>? recentMessages,
    String? conversationStyle,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/v1/ai/conversation-compatibility',
        data: {
          'targetUserId': targetUserId,
          'recentMessages': recentMessages ?? [],
          'conversationStyle': conversationStyle ?? 'balanced',
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        _logger.d('Conversation compatibility analysis completed');
        return response.data;
      } else {
        _logger.e('Failed to analyze conversation compatibility: ${response.statusMessage}');
        return null;
      }
    } catch (e) {
      _logger.e('Error analyzing conversation compatibility: $e');
      return null;
    }
  }

  /// Get personalized conversation tips based on user's communication style
  Future<List<String>> getConversationTips({
    required String targetUserId,
    String? currentTopic,
    String? userPersonality,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/v1/ai/conversation-tips',
        data: {
          'targetUserId': targetUserId,
          'currentTopic': currentTopic,
          'userPersonality': userPersonality,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> tipsData = response.data['tips'] ?? [];
        final List<String> tips = tipsData.cast<String>();
        
        _logger.d('Retrieved ${tips.length} conversation tips');
        return tips;
      } else {
        _logger.e('Failed to get conversation tips: ${response.statusMessage}');
        return [];
      }
    } catch (e) {
      _logger.e('Error getting conversation tips: $e');
      return [];
    }
  }

  /// Generate opening message based on match's profile
  Future<List<String>> generateOpeningMessages({
    required String targetUserId,
    String? style,
    bool? includeQuestion,
    String? referencePoint,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/v1/ai/opening-messages',
        data: {
          'targetUserId': targetUserId,
          'style': style ?? 'casual',
          'includeQuestion': includeQuestion ?? true,
          'referencePoint': referencePoint,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> messagesData = response.data['messages'] ?? [];
        final List<String> messages = messagesData.cast<String>();
        
        _logger.d('Generated ${messages.length} opening messages');
        return messages;
      } else {
        _logger.e('Failed to generate opening messages: ${response.statusMessage}');
        return [];
      }
    } catch (e) {
      _logger.e('Error generating opening messages: $e');
      return [];
    }
  }

  /// Get conversation flow suggestions based on current conversation state
  Future<Map<String, dynamic>?> getConversationFlow({
    required String conversationId,
    required String currentPhase,
    int? messageCount,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/v1/ai/conversation-flow',
        data: {
          'conversationId': conversationId,
          'currentPhase': currentPhase,
          'messageCount': messageCount ?? 0,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        _logger.d('Conversation flow analysis completed');
        return response.data;
      } else {
        _logger.e('Failed to get conversation flow: ${response.statusMessage}');
        return null;
      }
    } catch (e) {
      _logger.e('Error getting conversation flow: $e');
      return null;
    }
  }

  /// Rate and provide feedback on generated icebreakers/suggestions
  Future<bool> provideFeedback({
    required String sessionId,
    required String itemId,
    required double rating,
    String? feedback,
    bool? wasUsed,
    bool? wasSuccessful,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/v1/ai/feedback',
        data: {
          'sessionId': sessionId,
          'itemId': itemId,
          'rating': rating,
          'feedback': feedback,
          'wasUsed': wasUsed ?? false,
          'wasSuccessful': wasSuccessful ?? false,
        },
      );

      if (response.statusCode == 200) {
        _logger.d('Feedback submitted successfully');
        return true;
      } else {
        _logger.e('Failed to submit feedback: ${response.statusMessage}');
        return false;
      }
    } catch (e) {
      _logger.e('Error submitting feedback: $e');
      return false;
    }
  }

  /// Get user's icebreaker usage statistics
  Future<Map<String, dynamic>?> getUsageStatistics({
    String? timeframe,
    bool? includeSuccessRate,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/v1/ai/icebreaker-stats',
        queryParameters: {
          if (timeframe != null) 'timeframe': timeframe,
          if (includeSuccessRate != null) 'includeSuccessRate': includeSuccessRate.toString(),
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        _logger.d('Usage statistics retrieved');
        return response.data;
      } else {
        _logger.e('Failed to get usage statistics: ${response.statusMessage}');
        return null;
      }
    } catch (e) {
      _logger.e('Error getting usage statistics: $e');
      return null;
    }
  }
}