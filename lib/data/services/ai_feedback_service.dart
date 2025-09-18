import 'dart:async';
import 'dart:convert';

/// AI Feedback and Rating Service - manages user feedback for all AI features
/// Collects ratings, satisfaction data, and improvement suggestions
/// All feedback is stored for model training and feature improvement
class AiFeedbackService {
  static AiFeedbackService? _instance;
  static AiFeedbackService get instance => 
      _instance ??= AiFeedbackService._();
  AiFeedbackService._();

  // TODO: Replace with actual API service injection when dependencies are resolved
  // final ApiService _apiService = ServiceLocator.instance.get<ApiService>();

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
      final feedback = {
        'type': 'conversation_ai_feedback',
        'userId': userId,
        'conversationId': conversationId,
        'suggestionId': suggestionId,
        'featureType': featureType,
        'ratings': {
          'overall': rating,
          'helpfulness': helpfulness,
          'accuracy': accuracy,
          'wouldRecommend': rating >= 4,
        },
        'usage': {
          'wasUsed': wasUsed,
          'usageContext': context,
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
      print('Error submitting conversation feedback: $e');
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
      print('Error submitting profile feedback: $e');
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
      print('Error submitting onboarding feedback: $e');
      return false;
    }
  }

  /// Submit general AI feature feedback
  Future<bool> submitGeneralAiFeedback({
    required String userId,
    required String featureType, // 'smart_notifications', 'insights_dashboard', 'ai_matching'
    required int rating, // 1-5 scale
    required int satisfaction, // 1-5 scale
    String? comment,
    List<String>? improvementSuggestions,
    Map<String, dynamic>? context,
  }) async {
    try {
      final feedback = {
        'type': 'general_ai_feedback',
        'userId': userId,
        'featureType': featureType,
        'ratings': {
          'overall': rating,
          'satisfaction': satisfaction,
          'wouldContinueUsing': rating >= 3,
        },
        'feedback': {
          'comment': comment,
          'improvementSuggestions': improvementSuggestions,
        },
        'context': context,
        'metadata': {
          'platform': 'mobile',
          'timestamp': DateTime.now().toIso8601String(),
          'version': '1.0.0',
        },
      };

      return await _submitFeedback(feedback);
    } catch (e) {
      print('Error submitting general AI feedback: $e');
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
      final queryParams = {
        'userId': userId,
        if (featureType != null) 'featureType': featureType,
        if (limit != null) 'limit': limit.toString(),
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
      };

      // TODO: Implement actual API call when dependencies are available
      /*
      final response = await _apiService.get(
        '/ai/feedback/history',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['feedbackHistory']);
      }
      */

      // Return mock feedback history for now
      return _getMockFeedbackHistory(userId);
    } catch (e) {
      print('Error getting feedback history: $e');
      return null;
    }
  }

  /// Get feedback analytics/insights
  Future<Map<String, dynamic>?> getFeedbackAnalytics({
    required String userId,
  }) async {
    try {
      final queryParams = {
        'userId': userId,
        'includeAggregates': 'true',
        'includeTrends': 'true',
      };

      // TODO: Implement actual API call when dependencies are available
      /*
      final response = await _apiService.get(
        '/ai/feedback/analytics',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['analytics'];
      }
      */

      // Return mock analytics for now
      return _getMockFeedbackAnalytics();
    } catch (e) {
      print('Error getting feedback analytics: $e');
      return null;
    }
  }

  /// Request feedback reminder for incomplete interactions
  Future<bool> requestFeedbackReminder({
    required String userId,
    required String interactionId,
    required String featureType,
    DateTime? reminderTime,
  }) async {
    try {
      final request = {
        'userId': userId,
        'interactionId': interactionId,
        'featureType': featureType,
        'reminderTime': reminderTime?.toIso8601String() ?? 
            DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
        'requestedAt': DateTime.now().toIso8601String(),
      };

      // TODO: Implement actual API call when dependencies are available
      /*
      final response = await _apiService.post(
        '/ai/feedback/request-reminder',
        body: request,
      );

      return response.statusCode == 200;
      */

      // Mock success for now
      print('Feedback reminder scheduled for $featureType');
      return true;
    } catch (e) {
      print('Error requesting feedback reminder: $e');
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
      final quickRating = {
        'type': 'quick_rating',
        'userId': userId,
        'suggestionId': suggestionId,
        'featureType': featureType,
        'rating': isPositive ? 'positive' : 'negative',
        'quickComment': quickComment,
        'timestamp': DateTime.now().toIso8601String(),
      };

      return await _submitFeedback(quickRating);
    } catch (e) {
      print('Error submitting quick rating: $e');
      return false;
    }
  }

  // Private helper methods

  /// Submit feedback to backend
  Future<bool> _submitFeedback(Map<String, dynamic> feedback) async {
    try {
      // TODO: Implement actual API call when dependencies are available
      /*
      final response = await _apiService.post(
        '/ai/feedback',
        body: feedback,
      );

      if (response.statusCode == 200) {
        print('Feedback submitted successfully');
        return true;
      } else {
        print('Failed to submit feedback: ${response.statusCode}');
        return false;
      }
      */

      // Mock success for now
      print('Feedback submitted: ${feedback['type']} - Rating: ${feedback['ratings']?['overall'] ?? 'N/A'}');
      return true;
    } catch (e) {
      print('Error submitting feedback: $e');
      return false;
    }
  }

  /// Mock feedback history for development
  List<Map<String, dynamic>> _getMockFeedbackHistory(String userId) {
    return [
      {
        'id': 'feedback_1',
        'type': 'conversation_ai_feedback',
        'featureType': 'suggestion',
        'ratings': {'overall': 4, 'helpfulness': 5, 'accuracy': 4},
        'comment': 'Really helpful conversation starter!',
        'timestamp': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      },
      {
        'id': 'feedback_2',
        'type': 'profile_ai_feedback',
        'featureType': 'analysis',
        'ratings': {'overall': 5, 'relevance': 5, 'usefulness': 4},
        'comment': 'Spot-on analysis of my profile',
        'timestamp': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
      },
      {
        'id': 'feedback_3',
        'type': 'onboarding_ai_feedback',
        'ratings': {'overall': 4, 'questionQuality': 4, 'profileAccuracy': 5},
        'comment': 'Great onboarding experience',
        'timestamp': DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
      },
    ];
  }

  /// Mock feedback analytics for development
  Map<String, dynamic> _getMockFeedbackAnalytics() {
    return {
      'summary': {
        'totalFeedbacks': 15,
        'averageRating': 4.2,
        'positivePercentage': 87.5,
        'responseRate': 73.2,
      },
      'byFeature': {
        'conversation_suggestions': {'count': 8, 'avgRating': 4.3, 'satisfaction': 89.0},
        'profile_analysis': {'count': 4, 'avgRating': 4.5, 'satisfaction': 92.0},
        'onboarding': {'count': 3, 'avgRating': 3.8, 'satisfaction': 78.0},
      },
      'trends': {
        'ratingTrend': 'improving',
        'usageTrend': 'increasing',
        'lastUpdated': DateTime.now().toIso8601String(),
      },
      'topImprovements': [
        'More conversation context needed',
        'Faster response times',
        'More personalized suggestions',
      ],
    };
  }
}