import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

/// AI Tracking Service for monitoring AI feature usage and performance
/// Lightweight wrapper that sends tracking data to backend analytics endpoints
class AiTrackingService {
  final Dio _dio;
  final Logger _logger;

  AiTrackingService({required Dio dio, required Logger logger})
    : _dio = dio,
      _logger = logger;

  /// Track AI feature engagement
  Future<void> trackAiFeatureEngagement(
    String feature,
    String userId, {
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _dio.post(
        '/analytics/track/event',
        data: {
          'event_type': 'ai_feature_engagement',
          'event_data': {
            'feature': feature,
            'user_id': userId,
            'metadata': metadata ?? {},
          'timestamp': DateTime.now().toIso8601String(),
        },
        },
      );
      
      _logger.i('Tracked AI feature engagement: $feature for user: $userId');
    } catch (e) {
      _logger.e('Failed to track AI feature engagement: $e');
    }
  }

  /// Track compatibility analysis usage
  Future<void> trackCompatibilityAnalysis(
    String userId,
    String targetUserId, {
    double? compatibilityScore,
    List<String>? factors,
  }) async {
    try {
      await _dio.post(
        '/analytics/track/event',
        data: {
          'event_type': 'compatibility_analysis',
          'event_data': {
            'user_id': userId,
            'target_user_id': targetUserId,
            'compatibility_score': compatibilityScore,
            'factors': factors,
          'timestamp': DateTime.now().toIso8601String(),
        },
        },
      );
      
      _logger.i(
        'Tracked compatibility analysis for users: $userId -> $targetUserId',
      );
    } catch (e) {
      _logger.e('Failed to track compatibility analysis: $e');
    }
  }

  /// Track AI conversation interactions
  Future<void> trackConversationInteraction(
    String userId,
    String conversationId, {
    required String
    interactionType, // 'message_sent', 'suggestion_used', 'revival_attempt'
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _dio.post(
        '/analytics/track/event',
        data: {
          'event_type': 'ai_conversation_interaction',
          'event_data': {
            'user_id': userId,
            'conversation_id': conversationId,
            'interaction_type': interactionType,
            'metadata': metadata ?? {},
          'timestamp': DateTime.now().toIso8601String(),
        },
        },
      );
      
      _logger.i(
        'Tracked conversation interaction: $interactionType for user: $userId',
      );
    } catch (e) {
      _logger.e('Failed to track conversation interaction: $e');
    }
  }

  /// Track AI onboarding progress
  Future<void> trackOnboardingProgress(
    String userId,
    String step, {
    bool? completed,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _dio.post(
        '/analytics/track/event',
        data: {
          'event_type': 'ai_onboarding_progress',
          'event_data': {
            'user_id': userId,
            'step': step,
            'completed': completed ?? false,
            'metadata': metadata ?? {},
          'timestamp': DateTime.now().toIso8601String(),
        },
        },
      );
      
      _logger.i('Tracked onboarding progress: $step for user: $userId');
    } catch (e) {
      _logger.e('Failed to track onboarding progress: $e');
    }
  }

  /// Track AI feedback submission
  Future<void> trackAiFeedback(
    String userId,
    String featureType, {
    required double rating,
    String? comments,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _dio.post(
        '/analytics/track/event',
        data: {
          'event_type': 'ai_feedback',
          'event_data': {
            'user_id': userId,
            'feature_type': featureType,
            'rating': rating,
            'comments': comments,
            'metadata': metadata ?? {},
          'timestamp': DateTime.now().toIso8601String(),
        },
        },
      );
      
      _logger.i(
        'Tracked AI feedback: $featureType rating: $rating for user: $userId',
      );
    } catch (e) {
      _logger.e('Failed to track AI feedback: $e');
    }
  }
}