import 'package:equatable/equatable.dart';

/// AI Companion personality types
enum CompanionPersonality {
  mentor('Dating Mentor', '🧭', 'Wise and experienced dating coach'),
  friend('Supportive Friend', '💛', 'Encouraging and understanding companion'),
  coach('Conversation Coach', '💪', 'Helps improve dating conversations'),
  therapist('Relationship Therapist', '🧠', 'Provides emotional support and insights'),
  wingman('Digital Wingman', '😎', 'Fun and confident dating assistant'),
  custom('Custom Companion', '✨', 'Personalized AI companion');

  const CompanionPersonality(this.displayName, this.emoji, this.description);
  final String displayName;
  final String emoji;
  final String description;
}

/// AI Companion model
class AICompanion extends Equatable {
  final String id;
  final String userId;
  final String name;
  final CompanionPersonality personality;
  final String avatarUrl;
  final String description;
  final Map<String, dynamic> traits;
  final int relationshipLevel; // 1-10 scale
  final int conversationCount;
  final DateTime createdAt;
  final DateTime lastInteractionAt;
  final bool isActive;
  final Map<String, dynamic> learningData;

  const AICompanion({
    required this.id,
    required this.userId,
    required this.name,
    required this.personality,
    required this.avatarUrl,
    required this.description,
    this.traits = const {},
    this.relationshipLevel = 1,
    this.conversationCount = 0,
    required this.createdAt,
    required this.lastInteractionAt,
    this.isActive = true,
    this.learningData = const {},
  });

  factory AICompanion.fromJson(Map<String, dynamic> json) {
    return AICompanion(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      personality: CompanionPersonality.values.firstWhere(
        (e) => e.name == json['personality'],
        orElse: () => CompanionPersonality.friend,
      ),
      avatarUrl: json['avatarUrl'] as String,
      description: json['description'] as String,
      traits: Map<String, dynamic>.from(json['traits'] as Map? ?? {}),
      relationshipLevel: json['relationshipLevel'] as int? ?? 1,
      conversationCount: json['conversationCount'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastInteractionAt: DateTime.parse(json['lastInteractionAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
      learningData: Map<String, dynamic>.from(json['learningData'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'personality': personality.name,
      'avatarUrl': avatarUrl,
      'description': description,
      'traits': traits,
      'relationshipLevel': relationshipLevel,
      'conversationCount': conversationCount,
      'createdAt': createdAt.toIso8601String(),
      'lastInteractionAt': lastInteractionAt.toIso8601String(),
      'isActive': isActive,
      'learningData': learningData,
    };
  }

  AICompanion copyWith({
    String? id,
    String? userId,
    String? name,
    CompanionPersonality? personality,
    String? avatarUrl,
    String? description,
    Map<String, dynamic>? traits,
    int? relationshipLevel,
    int? conversationCount,
    DateTime? createdAt,
    DateTime? lastInteractionAt,
    bool? isActive,
    Map<String, dynamic>? learningData,
  }) {
    return AICompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      personality: personality ?? this.personality,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      description: description ?? this.description,
      traits: traits ?? this.traits,
      relationshipLevel: relationshipLevel ?? this.relationshipLevel,
      conversationCount: conversationCount ?? this.conversationCount,
      createdAt: createdAt ?? this.createdAt,
      lastInteractionAt: lastInteractionAt ?? this.lastInteractionAt,
      isActive: isActive ?? this.isActive,
      learningData: learningData ?? this.learningData,
    );
  }

  /// Get relationship level description
  String get relationshipDescription {
    switch (relationshipLevel) {
      case 1:
        return 'Getting to know each other';
      case 2:
      case 3:
        return 'Building trust';
      case 4:
      case 5:
        return 'Good understanding';
      case 6:
      case 7:
        return 'Strong connection';
      case 8:
      case 9:
        return 'Deep bond';
      case 10:
        return 'Perfect partnership';
      default:
        return 'New companion';
    }
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        personality,
        avatarUrl,
        description,
        traits,
        relationshipLevel,
        conversationCount,
        createdAt,
        lastInteractionAt,
        isActive,
        learningData,
      ];
}

/// AI Companion conversation message
class CompanionMessage extends Equatable {
  final String id;
  final String companionId;
  final String userId;
  final String content;
  final bool isFromCompanion;
  final DateTime timestamp;
  final MessageType type;
  final Map<String, dynamic>? metadata;
  final double? sentimentScore;
  final List<String> suggestedResponses;

  const CompanionMessage({
    required this.id,
    required this.companionId,
    required this.userId,
    required this.content,
    required this.isFromCompanion,
    required this.timestamp,
    this.type = MessageType.text,
    this.metadata,
    this.sentimentScore,
    this.suggestedResponses = const [],
  });

  factory CompanionMessage.fromJson(Map<String, dynamic> json) {
    return CompanionMessage(
      id: json['id'] as String,
      companionId: json['companionId'] as String,
      userId: json['userId'] as String,
      content: json['content'] as String,
      isFromCompanion: json['isFromCompanion'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.text,
      ),
      metadata: json['metadata'] as Map<String, dynamic>?,
      sentimentScore: (json['sentimentScore'] as num?)?.toDouble(),
      suggestedResponses: (json['suggestedResponses'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companionId': companionId,
      'userId': userId,
      'content': content,
      'isFromCompanion': isFromCompanion,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
      'metadata': metadata,
      'sentimentScore': sentimentScore,
      'suggestedResponses': suggestedResponses,
    };
  }

  @override
  List<Object?> get props => [
        id,
        companionId,
        userId,
        content,
        isFromCompanion,
        timestamp,
        type,
        metadata,
        sentimentScore,
        suggestedResponses,
      ];
}

/// Message types for AI conversations
enum MessageType {
  text('Text Message'),
  advice('Dating Advice'),
  question('Question'),
  encouragement('Encouragement'),
  feedback('Feedback'),
  lesson('Dating Lesson'),
  celebration('Celebration');

  const MessageType(this.displayName);
  final String displayName;
}

/// AI Companion session for tracking interactions
class CompanionSession extends Equatable {
  final String id;
  final String companionId;
  final String userId;
  final DateTime startTime;
  final DateTime? endTime;
  final int messageCount;
  final String sessionTopic;
  final double? satisfactionRating;
  final List<String> topicsDiscussed;
  final Map<String, dynamic> insights;

  const CompanionSession({
    required this.id,
    required this.companionId,
    required this.userId,
    required this.startTime,
    this.endTime,
    this.messageCount = 0,
    this.sessionTopic = 'General Chat',
    this.satisfactionRating,
    this.topicsDiscussed = const [],
    this.insights = const {},
  });

  factory CompanionSession.fromJson(Map<String, dynamic> json) {
    return CompanionSession(
      id: json['id'] as String,
      companionId: json['companionId'] as String,
      userId: json['userId'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      messageCount: json['messageCount'] as int? ?? 0,
      sessionTopic: json['sessionTopic'] as String? ?? 'General Chat',
      satisfactionRating: (json['satisfactionRating'] as num?)?.toDouble(),
      topicsDiscussed: (json['topicsDiscussed'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      insights: Map<String, dynamic>.from(json['insights'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companionId': companionId,
      'userId': userId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'messageCount': messageCount,
      'sessionTopic': sessionTopic,
      'satisfactionRating': satisfactionRating,
      'topicsDiscussed': topicsDiscussed,
      'insights': insights,
    };
  }

  /// Get session duration in minutes
  int get durationInMinutes {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime).inMinutes;
  }

  @override
  List<Object?> get props => [
        id,
        companionId,
        userId,
        startTime,
        endTime,
        messageCount,
        sessionTopic,
        satisfactionRating,
        topicsDiscussed,
        insights,
      ];
}

/// AI Companion learning progress
class CompanionLearning extends Equatable {
  final String companionId;
  final String userId;
  final Map<String, double> userPreferences;
  final Map<String, int> topicInteractions;
  final List<String> learnedInsights;
  final double adaptationScore;
  final DateTime lastLearningUpdate;

  const CompanionLearning({
    required this.companionId,
    required this.userId,
    this.userPreferences = const {},
    this.topicInteractions = const {},
    this.learnedInsights = const [],
    this.adaptationScore = 0.0,
    required this.lastLearningUpdate,
  });

  factory CompanionLearning.fromJson(Map<String, dynamic> json) {
    return CompanionLearning(
      companionId: json['companionId'] as String,
      userId: json['userId'] as String,
      userPreferences: Map<String, double>.from(json['userPreferences'] as Map? ?? {}),
      topicInteractions: Map<String, int>.from(json['topicInteractions'] as Map? ?? {}),
      learnedInsights: (json['learnedInsights'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      adaptationScore: (json['adaptationScore'] as num?)?.toDouble() ?? 0.0,
      lastLearningUpdate: DateTime.parse(json['lastLearningUpdate'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'companionId': companionId,
      'userId': userId,
      'userPreferences': userPreferences,
      'topicInteractions': topicInteractions,
      'learnedInsights': learnedInsights,
      'adaptationScore': adaptationScore,
      'lastLearningUpdate': lastLearningUpdate.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        companionId,
        userId,
        userPreferences,
        topicInteractions,
        learnedInsights,
        adaptationScore,
        lastLearningUpdate,
      ];
}

/// AI Companion appearance settings
class CompanionAppearance extends Equatable {
  final String avatarStyle;
  final String hairColor;
  final String eyeColor;
  final String skinTone;
  final String clothing;
  final String accessories;
  final Map<String, dynamic> customFeatures;

  const CompanionAppearance({
    this.avatarStyle = 'realistic',
    this.hairColor = 'brown',
    this.eyeColor = 'brown',
    this.skinTone = 'medium',
    this.clothing = 'casual',
    this.accessories = 'none',
    this.customFeatures = const {},
  });

  factory CompanionAppearance.fromJson(Map<String, dynamic> json) {
    return CompanionAppearance(
      avatarStyle: json['avatarStyle'] as String? ?? 'realistic',
      hairColor: json['hairColor'] as String? ?? 'brown',
      eyeColor: json['eyeColor'] as String? ?? 'brown',
      skinTone: json['skinTone'] as String? ?? 'medium',
      clothing: json['clothing'] as String? ?? 'casual',
      accessories: json['accessories'] as String? ?? 'none',
      customFeatures: Map<String, dynamic>.from(json['customFeatures'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'avatarStyle': avatarStyle,
      'hairColor': hairColor,
      'eyeColor': eyeColor,
      'skinTone': skinTone,
      'clothing': clothing,
      'accessories': accessories,
      'customFeatures': customFeatures,
    };
  }

  CompanionAppearance copyWith({
    String? avatarStyle,
    String? hairColor,
    String? eyeColor,
    String? skinTone,
    String? clothing,
    String? accessories,
    Map<String, dynamic>? customFeatures,
  }) {
    return CompanionAppearance(
      avatarStyle: avatarStyle ?? this.avatarStyle,
      hairColor: hairColor ?? this.hairColor,
      eyeColor: eyeColor ?? this.eyeColor,
      skinTone: skinTone ?? this.skinTone,
      clothing: clothing ?? this.clothing,
      accessories: accessories ?? this.accessories,
      customFeatures: customFeatures ?? this.customFeatures,
    );
  }

  @override
  List<Object?> get props => [
        avatarStyle,
        hairColor,
        eyeColor,
        skinTone,
        clothing,
        accessories,
        customFeatures,
      ];
}

/// AI Companion analytics data
class CompanionAnalytics extends Equatable {
  final String companionId;
  final int totalInteractions;
  final int totalMessages;
  final double averageResponseTime;
  final double userSatisfactionScore;
  final Map<String, int> topicFrequency;
  final Map<String, double> emotionalTones;
  final List<String> mostUsedFeatures;
  final DateTime lastAnalysisDate;

  const CompanionAnalytics({
    required this.companionId,
    this.totalInteractions = 0,
    this.totalMessages = 0,
    this.averageResponseTime = 0.0,
    this.userSatisfactionScore = 0.0,
    this.topicFrequency = const {},
    this.emotionalTones = const {},
    this.mostUsedFeatures = const [],
    required this.lastAnalysisDate,
  });

  factory CompanionAnalytics.fromJson(Map<String, dynamic> json) {
    return CompanionAnalytics(
      companionId: json['companionId'] as String,
      totalInteractions: json['totalInteractions'] as int? ?? 0,
      totalMessages: json['totalMessages'] as int? ?? 0,
      averageResponseTime: (json['averageResponseTime'] as num?)?.toDouble() ?? 0.0,
      userSatisfactionScore: (json['userSatisfactionScore'] as num?)?.toDouble() ?? 0.0,
      topicFrequency: Map<String, int>.from(json['topicFrequency'] as Map? ?? {}),
      emotionalTones: Map<String, double>.from(json['emotionalTones'] as Map? ?? {}),
      mostUsedFeatures: List<String>.from(json['mostUsedFeatures'] ?? []),
      lastAnalysisDate: DateTime.parse(json['lastAnalysisDate'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'companionId': companionId,
      'totalInteractions': totalInteractions,
      'totalMessages': totalMessages,
      'averageResponseTime': averageResponseTime,
      'userSatisfactionScore': userSatisfactionScore,
      'topicFrequency': topicFrequency,
      'emotionalTones': emotionalTones,
      'mostUsedFeatures': mostUsedFeatures,
      'lastAnalysisDate': lastAnalysisDate.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        companionId,
        totalInteractions,
        totalMessages,
        averageResponseTime,
        userSatisfactionScore,
        topicFrequency,
        emotionalTones,
        mostUsedFeatures,
        lastAnalysisDate,
      ];
}

/// Feedback types for AI training
enum FeedbackType {
  helpful,
  notHelpful,
  inappropriate,
  tooGeneric,
  perfectResponse,
  needsMoreContext,
}

/// AI Companion settings
class CompanionSettings extends Equatable {
  final String companionId;
  final bool enableNotifications;
  final bool enableLearning;
  final String responseStyle; // 'casual', 'formal', 'playful'
  final double creativityLevel; // 0.0 - 1.0
  final bool enableEmotionalSupport;
  final bool enableDatingAdvice;
  final bool enableProfileOptimization;
  final List<String> preferredTopics;
  final List<String> avoidedTopics;
  final Map<String, dynamic> customSettings;

  const CompanionSettings({
    required this.companionId,
    this.enableNotifications = true,
    this.enableLearning = true,
    this.responseStyle = 'casual',
    this.creativityLevel = 0.7,
    this.enableEmotionalSupport = true,
    this.enableDatingAdvice = true,
    this.enableProfileOptimization = true,
    this.preferredTopics = const [],
    this.avoidedTopics = const [],
    this.customSettings = const {},
  });

  factory CompanionSettings.fromJson(Map<String, dynamic> json) {
    return CompanionSettings(
      companionId: json['companionId'] as String,
      enableNotifications: json['enableNotifications'] as bool? ?? true,
      enableLearning: json['enableLearning'] as bool? ?? true,
      responseStyle: json['responseStyle'] as String? ?? 'casual',
      creativityLevel: (json['creativityLevel'] as num?)?.toDouble() ?? 0.7,
      enableEmotionalSupport: json['enableEmotionalSupport'] as bool? ?? true,
      enableDatingAdvice: json['enableDatingAdvice'] as bool? ?? true,
      enableProfileOptimization: json['enableProfileOptimization'] as bool? ?? true,
      preferredTopics: List<String>.from(json['preferredTopics'] ?? []),
      avoidedTopics: List<String>.from(json['avoidedTopics'] ?? []),
      customSettings: Map<String, dynamic>.from(json['customSettings'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'companionId': companionId,
      'enableNotifications': enableNotifications,
      'enableLearning': enableLearning,
      'responseStyle': responseStyle,
      'creativityLevel': creativityLevel,
      'enableEmotionalSupport': enableEmotionalSupport,
      'enableDatingAdvice': enableDatingAdvice,
      'enableProfileOptimization': enableProfileOptimization,
      'preferredTopics': preferredTopics,
      'avoidedTopics': avoidedTopics,
      'customSettings': customSettings,
    };
  }

  CompanionSettings copyWith({
    String? companionId,
    bool? enableNotifications,
    bool? enableLearning,
    String? responseStyle,
    double? creativityLevel,
    bool? enableEmotionalSupport,
    bool? enableDatingAdvice,
    bool? enableProfileOptimization,
    List<String>? preferredTopics,
    List<String>? avoidedTopics,
    Map<String, dynamic>? customSettings,
  }) {
    return CompanionSettings(
      companionId: companionId ?? this.companionId,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      enableLearning: enableLearning ?? this.enableLearning,
      responseStyle: responseStyle ?? this.responseStyle,
      creativityLevel: creativityLevel ?? this.creativityLevel,
      enableEmotionalSupport: enableEmotionalSupport ?? this.enableEmotionalSupport,
      enableDatingAdvice: enableDatingAdvice ?? this.enableDatingAdvice,
      enableProfileOptimization: enableProfileOptimization ?? this.enableProfileOptimization,
      preferredTopics: preferredTopics ?? this.preferredTopics,
      avoidedTopics: avoidedTopics ?? this.avoidedTopics,
      customSettings: customSettings ?? this.customSettings,
    );
  }

  @override
  List<Object?> get props => [
        companionId,
        enableNotifications,
        enableLearning,
        responseStyle,
        creativityLevel,
        enableEmotionalSupport,
        enableDatingAdvice,
        enableProfileOptimization,
        preferredTopics,
        avoidedTopics,
        customSettings,
      ];
}
