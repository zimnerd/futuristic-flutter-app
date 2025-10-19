import 'package:logger/logger.dart';
import '../../core/network/api_client.dart';
import '../models/match_model.dart';

/// Service for AI-powered matching functionality
class AiMatchingService {
  final ApiClient _apiClient;
  final Logger _logger = Logger();

  AiMatchingService(this._apiClient);

  /// AI-powered descriptive matching
  Future<List<MatchModel>> descriptiveMatching({
    required String description,
    int maxResults = 10,
    double? minCompatibilityScore,
  }) async {
    try {
      final response = await _apiClient.post(
        '/ai-matching/descriptive-matching',
        data: {
          'description': description,
          'maxResults': maxResults,
          'minCompatibilityScore': minCompatibilityScore,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> matchesData = response.data['matches'] ?? [];
        final matches = matchesData
            .map((json) => MatchModel.fromJson(json))
            .toList();

        _logger.d('AI descriptive matching found ${matches.length} matches');
        return matches;
      } else {
        _logger.e('Failed to get AI matches: ${response.statusMessage}');
        return [];
      }
    } catch (e) {
      _logger.e('Error in AI descriptive matching: $e');
      return [];
    }
  }

  /// Generate AI profile suggestions
  Future<Map<String, dynamic>?> generateProfileSuggestions({
    required Map<String, dynamic> currentProfile,
    String? targetAudience,
  }) async {
    try {
      final response = await _apiClient.post(
        '/ai-matching/profile-generation',
        data: {
          'currentProfile': currentProfile,
          'targetAudience': targetAudience,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        _logger.d('AI profile suggestions generated');
        return response.data;
      } else {
        _logger.e(
          'Failed to generate profile suggestions: ${response.statusMessage}',
        );
        return null;
      }
    } catch (e) {
      _logger.e('Error generating profile suggestions: $e');
      return null;
    }
  }

  /// AI photo selection recommendations
  Future<Map<String, dynamic>?> getPhotoRecommendations({
    required List<String> photoUrls,
    String? targetDemographic,
  }) async {
    try {
      final response = await _apiClient.post(
        '/ai-matching/photo-selection',
        data: {'photoUrls': photoUrls, 'targetDemographic': targetDemographic},
      );

      if (response.statusCode == 200 && response.data != null) {
        _logger.d('AI photo recommendations received');
        return response.data;
      } else {
        _logger.e(
          'Failed to get photo recommendations: ${response.statusMessage}',
        );
        return null;
      }
    } catch (e) {
      _logger.e('Error getting photo recommendations: $e');
      return null;
    }
  }

  /// Q&A profile builder assistance
  Future<Map<String, dynamic>?> getProfileBuilderQuestions({
    Map<String, dynamic>? currentAnswers,
  }) async {
    try {
      final response = await _apiClient.post(
        '/ai-matching/qa-profile-builder',
        data: {'currentAnswers': currentAnswers ?? {}},
      );

      if (response.statusCode == 200 && response.data != null) {
        _logger.d('AI profile builder questions generated');
        return response.data;
      } else {
        _logger.e(
          'Failed to get profile builder questions: ${response.statusMessage}',
        );
        return null;
      }
    } catch (e) {
      _logger.e('Error getting profile builder questions: $e');
      return null;
    }
  }

  /// Personality analysis
  Future<Map<String, dynamic>?> analyzePersonality({
    required Map<String, dynamic> profileData,
    List<String>? messagingHistory,
  }) async {
    try {
      final response = await _apiClient.post(
        '/ai-matching/personality-analysis',
        data: {
          'profileData': profileData,
          'messagingHistory': messagingHistory ?? [],
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        _logger.d('AI personality analysis completed');
        return response.data;
      } else {
        _logger.e('Failed to analyze personality: ${response.statusMessage}');
        return null;
      }
    } catch (e) {
      _logger.e('Error analyzing personality: $e');
      return null;
    }
  }

  /// Compatibility analysis between users
  Future<Map<String, dynamic>?> analyzeCompatibility({
    required String otherUserId,
    List<String>? conversationHistory,
  }) async {
    try {
      final response = await _apiClient.post(
        '/ai-matching/compatibility-analysis',
        data: {
          'otherUserId': otherUserId,
          'conversationHistory': conversationHistory ?? [],
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        _logger.d('AI compatibility analysis completed');
        return response.data;
      } else {
        _logger.e('Failed to analyze compatibility: ${response.statusMessage}');
        return null;
      }
    } catch (e) {
      _logger.e('Error analyzing compatibility: $e');
      return null;
    }
  }

  /// Get conversation coaching suggestions
  Future<Map<String, dynamic>?> getConversationCoaching({
    required String conversationId,
    String? currentMessage,
  }) async {
    try {
      final response = await _apiClient.post(
        '/ai-matching/conversation-coaching',
        data: {
          'conversationId': conversationId,
          'currentMessage': currentMessage,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        _logger.d('AI conversation coaching suggestions received');
        return response.data;
      } else {
        _logger.e(
          'Failed to get conversation coaching: ${response.statusMessage}',
        );
        return null;
      }
    } catch (e) {
      _logger.e('Error getting conversation coaching: $e');
      return null;
    }
  }

  /// Get predictive analytics for matching success
  Future<Map<String, dynamic>?> getPredictiveAnalytics({
    String? timeframe,
    List<String>? metrics,
  }) async {
    try {
      final response = await _apiClient.post(
        '/ai-matching/predictive-analytics',
        data: {
          'timeframe': timeframe ?? '30d',
          'metrics':
              metrics ??
              [
                'match_probability',
                'conversation_success',
                'meeting_likelihood',
              ],
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        _logger.d('AI predictive analytics received');
        return response.data;
      } else {
        _logger.e(
          'Failed to get predictive analytics: ${response.statusMessage}',
        );
        return null;
      }
    } catch (e) {
      _logger.e('Error getting predictive analytics: $e');
      return null;
    }
  }

  /// Get advanced personalization recommendations
  Future<Map<String, dynamic>?> getPersonalizationRecommendations({
    String? focusArea,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      final response = await _apiClient.post(
        '/ai-matching/advanced-personalization',
        data: {'focusArea': focusArea, 'preferences': preferences ?? {}},
      );

      if (response.statusCode == 200 && response.data != null) {
        _logger.d('AI personalization recommendations received');
        return response.data;
      } else {
        _logger.e(
          'Failed to get personalization recommendations: ${response.statusMessage}',
        );
        return null;
      }
    } catch (e) {
      _logger.e('Error getting personalization recommendations: $e');
      return null;
    }
  }

  /// Check AI token usage and limits
  Future<Map<String, dynamic>?> getTokenUsage() async {
    try {
      final response = await _apiClient.get('/ai-matching/token-usage');

      if (response.statusCode == 200 && response.data != null) {
        _logger.d('AI token usage information retrieved');
        return response.data;
      } else {
        _logger.e('Failed to get token usage: ${response.statusMessage}');
        return null;
      }
    } catch (e) {
      _logger.e('Error getting token usage: $e');
      return null;
    }
  }

  /// Moderate content using AI
  Future<Map<String, dynamic>?> moderateContent({
    required String content,
    String? contentType,
  }) async {
    try {
      final response = await _apiClient.post(
        '/ai-matching/content-moderation',
        data: {'content': content, 'contentType': contentType ?? 'text'},
      );

      if (response.statusCode == 200 && response.data != null) {
        _logger.d('AI content moderation completed');
        return response.data;
      } else {
        _logger.e('Failed to moderate content: ${response.statusMessage}');
        return null;
      }
    } catch (e) {
      _logger.e('Error moderating content: $e');
      return null;
    }
  }

  /// Analyze visual preferences
  Future<Map<String, dynamic>?> analyzeVisualPreferences({
    required List<String> likedPhotoIds,
    required List<String> passedPhotoIds,
  }) async {
    try {
      final response = await _apiClient.post(
        '/ai-matching/visual-preference-analysis',
        data: {
          'likedPhotoIds': likedPhotoIds,
          'passedPhotoIds': passedPhotoIds,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        _logger.d('AI visual preference analysis completed');
        return response.data;
      } else {
        _logger.e(
          'Failed to analyze visual preferences: ${response.statusMessage}',
        );
        return null;
      }
    } catch (e) {
      _logger.e('Error analyzing visual preferences: $e');
      return null;
    }
  }

  /// Get AI-powered user recommendations
  Future<List<MatchModel>> getRecommendations({
    String? userId,
    int limit = 10,
    double? minCompatibility,
  }) async {
    try {
      final queryParams = <String, dynamic>{'limit': limit.toString()};
      if (userId != null) queryParams['userId'] = userId;
      if (minCompatibility != null)
        {
        queryParams['minCompatibility'] = minCompatibility.toString();
      }

      final response = await _apiClient.get(
        '/matching/ai/recommendations',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> recommendationsData = response.data['data'] ?? [];
        final recommendations = recommendationsData
            .map((r) => MatchModel.fromJson(r))
            .toList();

        _logger.d('AI recommendations found ${recommendations.length} matches');
        return recommendations;
      } else {
        _logger.e(
          'Failed to get AI recommendations: ${response.statusMessage}',
        );
        return [];
      }
    } catch (e) {
      _logger.e('Error getting AI recommendations: $e');
      return [];
    }
  }

  /// Calculate compatibility score between users
  Future<Map<String, dynamic>?> calculateCompatibilityScore({
    required String userId,
    required String targetUserId,
  }) async {
    try {
      final response = await _apiClient.post(
        '/matching/ai/score',
        data: {'userId': userId, 'targetUserId': targetUserId},
      );

      if (response.statusCode == 200 && response.data != null) {
        _logger.d('Compatibility score calculated');
        return response.data['data'];
      } else {
        _logger.e(
          'Failed to calculate compatibility score: ${response.statusMessage}',
        );
        return null;
      }
    } catch (e) {
      _logger.e('Error calculating compatibility score: $e');
      return null;
    }
  }

  /// Submit feedback to improve AI recommendations
  Future<bool> submitFeedback({
    required String userId,
    required String targetUserId,
    required String action,
    Map<String, dynamic>? context,
  }) async {
    try {
      final response = await _apiClient.post(
        '/matching/ai/feedback',
        data: {
          'userId': userId,
          'targetUserId': targetUserId,
          'action': action,
          'context': context ?? {},
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        _logger.d('AI feedback submitted successfully');
        return response.data['success'] == true;
      } else {
        _logger.e('Failed to submit feedback: ${response.statusMessage}');
        return false;
      }
    } catch (e) {
      _logger.e('Error submitting feedback: $e');
      return false;
    }
  }
}
