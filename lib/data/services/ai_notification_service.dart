import 'dart:async';
import 'package:logger/logger.dart';

import '../../domain/services/api_service.dart';

/// AI Smart Notification Service - provides AI-driven notifications for conversation prompts,
/// match suggestions, and profile optimization recommendations
class AiNotificationService {
  static AiNotificationService? _instance;

  final ApiService _apiService;
  final Logger _logger = Logger();

  // Private constructor for singleton
  AiNotificationService._(this._apiService);

  // Constructor for dependency injection
  AiNotificationService.withDependencies(this._apiService);

  // Singleton getter with lazy initialization
  static AiNotificationService get instance {
    if (_instance == null) {
      throw StateError(
        'AiNotificationService must be initialized with dependencies first',
      );
    }
    return _instance!;
  }

  // Initialize singleton with dependencies
  static void initialize(ApiService apiService) {
    _instance = AiNotificationService._(apiService);
  }

  /// Generate conversation prompt notifications based on user behavior
  Future<List<AiNotification>?> generateConversationPrompts({
    required String userId,
    int? limit = 5,
  }) async {
    try {
      final request = {
        'limit': limit,
        'context': {
          'platform': 'mobile',
          'timezone': DateTime.now().timeZoneName,
          'timestamp': DateTime.now().toIso8601String(),
        },
      };

      _logger.d('Generating conversation prompts for user $userId');

      final response = await _apiService.post(
        '/ai/notifications/conversation-prompts',
        data: request,
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as List;
        final notifications = data
            .map(
              (item) => AiNotification.fromJson(item as Map<String, dynamic>),
            )
            .toList();

        _logger.d(
          'Successfully generated ${notifications.length} conversation prompts',
        );
        return notifications;
      }

      return null;
    } catch (e) {
      _logger.e('Error generating conversation prompts: $e');
      return null;
    }
  }

  /// Generate match suggestion notifications
  Future<List<AiNotification>?> generateMatchSuggestions({
    required String userId,
    int? limit = 3,
  }) async {
    try {
      final request = {
        'limit': limit,
        'context': {
          'platform': 'mobile',
          'timezone': DateTime.now().timeZoneName,
          'timestamp': DateTime.now().toIso8601String(),
        },
      };

      _logger.d('Generating match suggestions for user $userId');

      final response = await _apiService.post(
        '/ai/notifications/match-suggestions',
        data: request,
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as List;
        final notifications = data
            .map(
              (item) => AiNotification.fromJson(item as Map<String, dynamic>),
            )
            .toList();

        _logger.d(
          'Successfully generated ${notifications.length} match suggestions',
        );
        return notifications;
      }

      return null;
    } catch (e) {
      _logger.e('Error generating match suggestions: $e');
      return null;
    }
  }

  /// Generate profile optimization recommendations
  Future<List<AiNotification>?> generateProfileOptimization({
    required String userId,
    int? limit = 3,
  }) async {
    try {
      final request = {
        'limit': limit,
        'context': {
          'platform': 'mobile',
          'timezone': DateTime.now().timeZoneName,
          'timestamp': DateTime.now().toIso8601String(),
        },
      };

      _logger.d(
        'Generating profile optimization recommendations for user $userId',
      );

      final response = await _apiService.post(
        '/ai/notifications/profile-optimization',
        data: request,
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as List;
        final notifications = data
            .map(
              (item) => AiNotification.fromJson(item as Map<String, dynamic>),
            )
            .toList();

        _logger.d(
          'Successfully generated ${notifications.length} profile optimization recommendations',
        );
        return notifications;
      }

      return null;
    } catch (e) {
      _logger.e('Error generating profile optimization recommendations: $e');
      return null;
    }
  }

  /// Schedule smart notification based on user activity patterns
  Future<bool> scheduleSmartNotification({
    required String userId,
    required AiNotification notification,
    DateTime? preferredTime,
  }) async {
    try {
      final request = {
        'notification': notification.toJson(),
        'scheduling': {
          'preferredTime': preferredTime?.toIso8601String(),
          'useOptimalTiming': preferredTime == null,
          'respectQuietHours': true,
        },
        'context': {
          'platform': 'mobile',
          'timezone': DateTime.now().timeZoneName,
        },
      };

      _logger.d('Scheduling smart notification for user $userId');

      final response = await _apiService.post(
        '/ai/notifications/schedule',
        data: request,
      );

      if (response.statusCode == 201) {
        _logger.d('Successfully scheduled notification: ${notification.title}');
        return true;
      }

      return false;
    } catch (e) {
      _logger.e('Error scheduling smart notification: $e');
      return false;
    }
  }

  /// Get optimal notification timing based on user behavior
  Future<DateTime?> getOptimalNotificationTime({
    required String userId,
    required String notificationType,
  }) async {
    try {
      _logger.d(
        'Getting optimal notification time for user $userId, type: $notificationType',
      );

      final response = await _apiService.get(
        '/ai/notifications/optimal-timing',
        queryParameters: {
          'notificationType': notificationType,
          'currentTime': DateTime.now().toIso8601String(),
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        if (data['optimalTime'] != null) {
          final optimalTime = DateTime.parse(data['optimalTime']);
          _logger.d('Retrieved optimal notification time: $optimalTime');
          return optimalTime;
        }
      }

      return null;
    } catch (e) {
      _logger.e('Error getting optimal notification time: $e');
      return null;
    }
  }

  /// Mark notification as interacted with (for learning)
  Future<bool> markNotificationInteraction({
    required String userId,
    required String notificationId,
    required String
    interactionType, // 'opened', 'dismissed', 'acted_upon', 'ignored'
    Map<String, dynamic>? context,
  }) async {
    try {
      final request = {
        'notificationId': notificationId,
        'interaction': {
          'type': interactionType,
          'context': context,
          'timestamp': DateTime.now().toIso8601String(),
        },
      };

      _logger.d(
        'Tracking notification interaction for user $userId: $notificationId - $interactionType',
      );

      final response = await _apiService.post(
        '/ai/notifications/interaction',
        data: request,
      );

      if (response.statusCode == 200) {
        _logger.d('Successfully tracked notification interaction');
        return true;
      }

      return false;
    } catch (e) {
      _logger.e('Error tracking notification interaction: $e');
      return false;
    }
  }

  /// Get user notification preferences and engagement patterns
  Future<Map<String, dynamic>?> getNotificationInsights({
    required String userId,
  }) async {
    try {
      _logger.d('Getting notification insights for user $userId');

      final response = await _apiService.get(
        '/ai/notifications/insights',
        queryParameters: {
          'includeEngagementPatterns': 'true',
          'includePreferences': 'true',
          'includeOptimalTiming': 'true',
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        _logger.d('Successfully retrieved notification insights');
        return data;
      }

      return null;
    } catch (e) {
      _logger.e('Error getting notification insights: $e');
      return null;
    }
  }

  /// Update notification preferences based on user feedback
  Future<bool> updateNotificationPreferences({
    required String userId,
    required Map<String, dynamic> preferences,
  }) async {
    try {
      final request = {
        'preferences': preferences,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      _logger.d('Updating notification preferences for user $userId');

      final response = await _apiService.put(
        '/ai/notifications/preferences',
        data: request,
      );

      if (response.statusCode == 200) {
        _logger.d('Successfully updated notification preferences');
        return true;
      }

      return false;
    } catch (e) {
      _logger.e('Error updating notification preferences: $e');
      return false;
    }
  }
}

/// AI Notification model
class AiNotification {
  final String id;
  final String type;
  final String title;
  final String message;
  final NotificationPriority priority;
  final Map<String, dynamic> actionData;
  final DateTime generatedAt;
  final DateTime expiresAt;

  const AiNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.priority,
    required this.actionData,
    required this.generatedAt,
    required this.expiresAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'message': message,
      'priority': priority.name,
      'actionData': actionData,
      'generatedAt': generatedAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  factory AiNotification.fromJson(Map<String, dynamic> json) {
    return AiNotification(
      id: json['id'],
      type: json['type'],
      title: json['title'],
      message: json['message'],
      priority: NotificationPriority.values.firstWhere(
        (p) => p.name == json['priority'],
        orElse: () => NotificationPriority.medium,
      ),
      actionData: Map<String, dynamic>.from(json['actionData']),
      generatedAt: DateTime.parse(json['generatedAt']),
      expiresAt: DateTime.parse(json['expiresAt']),
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => !isExpired;

  Duration get timeUntilExpiry => expiresAt.difference(DateTime.now());
  Duration get timeSinceGenerated => DateTime.now().difference(generatedAt);
}

/// Notification priority levels
enum NotificationPriority { low, medium, high, urgent }

extension NotificationPriorityExtension on NotificationPriority {
  String get displayName {
    switch (this) {
      case NotificationPriority.low:
        return 'Low';
      case NotificationPriority.medium:
        return 'Medium';
      case NotificationPriority.high:
        return 'High';
      case NotificationPriority.urgent:
        return 'Urgent';
    }
  }

  int get importance {
    switch (this) {
      case NotificationPriority.low:
        return 1;
      case NotificationPriority.medium:
        return 2;
      case NotificationPriority.high:
        return 3;
      case NotificationPriority.urgent:
        return 4;
    }
  }
}
