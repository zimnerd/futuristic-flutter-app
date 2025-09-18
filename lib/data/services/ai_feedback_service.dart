import 'dart:async';
import 'package:logger/logger.dart';
import 'package:pulse_dating_app/core/network/api_client.dart';

/// AI Feedback and Rating Service - manages user feedback for all AI features
/// Collects ratings, satisfaction data, and improvement suggestions
/// All feedback is stored for model training and feature improvement
class AiFeedbackService {
  static AiFeedbackService? _instance;
  static AiFeedbackService get instance => 
      _instance ??= AiFeedbackService._();
  AiFeedbackService._();

  final ApiClient _apiClient = ApiClient.instance;
  static final Logger _logger = Logger();

  /// Submit feedback for conversation AI features
  Future<bool> submitConversationFeedback({
    required String userId,
    required String conversationId,
    required String suggestionId,
    required String featureType, // 'suggestion', 'analysis', 'revival', 'compatibility'
    required int rating, // 1-5 scale
    required int helpfulness, // 1-5 scale
    required int accuracy, // 1-5 scale
    bool? wasUsed,
    String? comment,
    List<String>? improvementSuggestions,
    Map<String, dynamic>? context,
  }) async {
    try {
      final response = await _apiClient.submitAiFeedback(
        aiResponseId: suggestionId,
        featureType: featureType,
        rating: rating,
        helpful: helpfulness >= 4,
        comment: comment ?? '',
        context: {
          'conversationId': conversationId,
          'helpfulness': helpfulness,
          'accuracy': accuracy,
          'wasUsed': wasUsed,
          'improvementSuggestions': improvementSuggestions,
          ...?context,
        },
      );

      if (response.statusCode == 200) {
        _logFeedbackSubmission('conversation', featureType, rating);
        return true;
      } else {
        _logger.e(
          'Failed to submit conversation feedback: ${response.statusCode}',
        );
        return false;
      }
    } catch (e) {
      _logger.e('Error submitting conversation feedback: $e');
      // Even if API fails, we'll log locally
      _logFeedbackSubmission('conversation', featureType, rating);
      return false;
    }
  }

  /// Submit feedback for profile AI features
  Future<bool> submitProfileFeedback({
    required String userId,
    required String profileAnalysisId,
    required String featureType, // 'analysis', 'improvement', 'conversation_starter', 'image_insight'
    required int rating, // 1-5 scale
    required int relevance, // 1-5 scale
    required int usefulness, // 1-5 scale
    bool? wasImplemented,
    String? comment,
    List<String>? improvementSuggestions,
    Map<String, dynamic>? context,
  }) async {
    try {
      final feedback = {
        'type': 'profile_ai_feedback',
        'userId': userId,
        'profileAnalysisId': profileAnalysisId,
        'featureType': featureType,
        'ratings': {
          'overall': rating,
          'relevance': relevance,
          'usefulness': usefulness,
          'satisfaction': rating,
        },
        'usage': {
          'wasImplemented': wasImplemented,
          'implementationContext': context,
        },
        'feedback': {
          'comment': comment,
          'improvementSuggestions': improvementSuggestions,
        },
        'metadata': {
          'platform': 'mobile',
          'timestamp': DateTime.now().toIso8601String(),
          'version': '1.0.0',
        },
      };

      return await _submitFeedback(feedback);
    } catch (e) {
      _logger.e('Error submitting profile feedback: $e');
      return false;
    }
  }

  /// Submit feedback for onboarding AI experience
  Future<bool> submitOnboardingFeedback({
    required String userId,
    required String sessionId,
    required int overallRating, // 1-5 scale
    required int questionQuality, // 1-5 scale
    required int profileAccuracy, // 1-5 scale
    required int easeOfUse, // 1-5 scale
    bool? completedFully,
    String? comment,
    List<String>? improvementSuggestions,
    List<String>? mostHelpfulFeatures,
    List<String>? leastHelpfulFeatures,
  }) async {
    try {
      final feedback = {
        'type': 'onboarding_ai_feedback',
        'userId': userId,
        'sessionId': sessionId,
        'ratings': {
          'overall': overallRating,
          'questionQuality': questionQuality,
          'profileAccuracy': profileAccuracy,
          'easeOfUse': easeOfUse,
          'wouldRecommend': overallRating >= 4,
        },
        'completion': {
          'completedFully': completedFully,
          'abandonmentReason': completedFully == false ? 'user_provided' : null,
        },
        'feedback': {
          'comment': comment,
          'improvementSuggestions': improvementSuggestions,
          'mostHelpfulFeatures': mostHelpfulFeatures,
          'leastHelpfulFeatures': leastHelpfulFeatures,
        },
        'metadata': {
          'platform': 'mobile',
          'timestamp': DateTime.now().toIso8601String(),
          'version': '1.0.0',
        },
      };

      return await _submitFeedback(feedback);
    } catch (e) {
      _logger.e('Error submitting onboarding feedback: $e');
      return false;
    }
  }

  /// Submit general AI feature feedback
  Future<bool> submitGeneralAiFeedback({
    required String userId,
    required String aiResponseId,
    required String featureType, // 'smart_notifications', 'insights_dashboard', 'ai_matching'
    required int rating, // 1-5 scale
    required int satisfaction, // 1-5 scale
    String? comment,
    List<String>? improvementSuggestions,
    Map<String, dynamic>? context,
  }) async {
    try {
      final response = await _apiClient.submitAiFeedback(
        aiResponseId: aiResponseId,
        featureType: featureType,
        rating: rating,
        comment: comment,
        helpful: satisfaction >= 4,
        context: {
          'type': 'general_ai_feedback',
          'satisfaction': satisfaction,
          if (improvementSuggestions != null)
            'improvementSuggestions': improvementSuggestions,
          ...?context,
        },
      );

      if (response.statusCode == 200) {
        _logFeedbackSubmission('general', featureType, rating);
        return true;
      }

      _logger.e('Failed to submit general AI feedback: ${response.statusCode}');
      return false;
    } catch (e) {
      _logger.e('Error submitting general AI feedback: $e');
      // Log locally for analytics even if API fails
      _logFeedbackSubmission('general', featureType, rating);
      return false;
    }
  }

  /// Get user's feedback history
  Future<List<Map<String, dynamic>>?> getUserFeedbackHistory({
    required String userId,
    String? featureType,
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Use analytics API to get user behavior data that includes feedback
      final response = await _apiClient.get(
        '/analytics/user/behavior',
        queryParameters: {
          'timeframe': 'month',
          'includeEvents': 'ai_feedback',
          if (featureType != null) 'featureType': featureType,
          if (limit != null) 'limit': limit.toString(),
          if (startDate != null) 'startDate': startDate.toIso8601String(),
          if (endDate != null) 'endDate': endDate.toIso8601String(),
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final events = data['events'] as List? ?? [];

        // Filter for feedback events and transform to expected format
        final feedbackHistory = events
            .where((event) => event['type'] == 'ai_feedback')
            .map((event) => Map<String, dynamic>.from(event))
            .toList();

        return feedbackHistory;
      } else {
        _logger.e('Failed to get feedback history: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      _logger.e('Error getting feedback history: $e');
      return [];
    }
  }

  /// Get feedback analytics/insights
  Future<Map<String, dynamic>?> getFeedbackAnalytics({
    required String userId,
  }) async {
    try {
      // Use analytics API to get engagement metrics that include feedback data
      final response = await _apiClient.get(
        '/analytics/engagement',
        queryParameters: {
          'timeframe': 'month',
          'includeMetrics': 'ai_feedback,satisfaction,ratings',
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;

        // Transform analytics data to feedback-specific format
        return {
          'summary': {
            'totalFeedbacks': data['totalInteractions'] ?? 0,
            'averageRating': data['averageRating'] ?? 0.0,
            'positivePercentage': data['positivePercentage'] ?? 0.0,
            'responseRate': data['responseRate'] ?? 0.0,
          },
          'byFeature': data['byFeature'] ?? {},
          'trends': data['trends'] ?? {},
          'topImprovements': data['suggestions'] ?? [],
        };
      } else {
        _logger.e('Failed to get feedback analytics: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      _logger.e('Error getting feedback analytics: $e');
      return null;
    }
  }

  /// Request feedback reminder for a later time
  Future<bool> requestFeedbackReminder({
    required String userId,
    required String interactionId,
    required String featureType,
    DateTime? reminderTime,
  }) async {
    try {
      // For now, just log the reminder request
      _logger.i('Feedback reminder requested for $featureType at ${reminderTime ?? DateTime.now().add(const Duration(hours: 24))}');
      return true;
    } catch (e) {
      _logger.e('Error requesting feedback reminder: $e');
      return false;
    }
  }

  /// Rate AI suggestion quickly (thumbs up/down)
  Future<bool> quickRateSuggestion({
    required String userId,
    required String suggestionId,
    required String featureType,
    required bool isPositive, // true = thumbs up, false = thumbs down
    String? quickComment,
  }) async {
    try {
      final response = await _apiClient.submitAiFeedback(
        aiResponseId: suggestionId,
        featureType: featureType,
        rating: isPositive ? 5 : 1,
        comment: quickComment,
        helpful: isPositive,
        context: {'type': 'quick_rating',
        },
      );

      if (response.statusCode == 200) {
        _logFeedbackSubmission('quick', featureType, isPositive ? 5 : 1);
        return true;
      }

      _logger.e('Failed to submit quick rating: ${response.statusCode}');
      return false;
    } catch (e) {
      _logger.e('Error submitting quick rating: $e');
      return false;
    }
  }

  // Private helper methods

  /// Submit feedback to backend
  Future<bool> _submitFeedback(Map<String, dynamic> feedback) async {
    try {
      // For complex feedback objects, we'll log them locally for now
      // Real API integration will be added when the backend endpoints are ready
      _logger.i(
        'Feedback submitted: ${feedback['type']} - Rating: ${feedback['ratings']?['overall'] ?? 'N/A'}',
      );
      return true;
    } catch (e) {
      _logger.e('Error submitting feedback: $e');
      return false;
    }
  }

  /// Log feedback submission for analytics
  void _logFeedbackSubmission(String category, String featureType, int rating) {
    _logger.d('Feedback logged: $category.$featureType - Rating: $rating');
    // Could expand this to send to analytics service
  }
}