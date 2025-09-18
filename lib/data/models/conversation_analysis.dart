/// Comprehensive conversation analysis result
class ConversationAnalysis {
  final String conversationId;
  final DateTime timestamp;
  final ConversationMetrics metrics;
  final EmotionalAnalysis emotionalAnalysis;
  final CompatibilityScore compatibilityScore;
  final SafetyAnalysis safetyAnalysis;
  final ConversationHealth health;
  final List<ConversationInsight> insights;
  final List<ConversationSuggestion> suggestions;

  const ConversationAnalysis({
    required this.conversationId,
    required this.timestamp,
    required this.metrics,
    required this.emotionalAnalysis,
    required this.compatibilityScore,
    required this.safetyAnalysis,
    required this.health,
    required this.insights,
    required this.suggestions,
  });

  Map<String, dynamic> toJson() {
    return {
      'conversationId': conversationId,
      'timestamp': timestamp.toIso8601String(),
      'metrics': metrics.toJson(),
      'emotionalAnalysis': emotionalAnalysis.toJson(),
      'compatibilityScore': compatibilityScore.toJson(),
      'safetyAnalysis': safetyAnalysis.toJson(),
      'health': health.toString().split('.').last,
      'insights': insights.map((i) => i.toJson()).toList(),
      'suggestions': suggestions.map((s) => s.toJson()).toList(),
    };
  }

  factory ConversationAnalysis.fromJson(Map<String, dynamic> json) {
    return ConversationAnalysis(
      conversationId: json['conversationId'],
      timestamp: DateTime.parse(json['timestamp']),
      metrics: ConversationMetrics.fromJson(json['metrics']),
      emotionalAnalysis: EmotionalAnalysis.fromJson(json['emotionalAnalysis']),
      compatibilityScore: CompatibilityScore.fromJson(json['compatibilityScore']),
      safetyAnalysis: SafetyAnalysis.fromJson(json['safetyAnalysis']),
      health: ConversationHealth.values.firstWhere((h) => h.toString().split('.').last == json['health']),
      insights: (json['insights'] as List).map((i) => ConversationInsight.fromJson(i)).toList(),
      suggestions: (json['suggestions'] as List).map((s) => ConversationSuggestion.fromJson(s)).toList(),
    );
  }
}

/// Conversation health status
enum ConversationHealth {
  excellent,
  good,
  moderate,
  low,
  declining,
  stagnant,
  dying,
}

/// Conversation metrics and statistics
class ConversationMetrics {
  final int messageCount;
  final double averageResponseTime; // in hours
  final double messageBalance; // 0.5 = perfect balance
  final double engagementScore; // 0.0 to 1.0
  final DateTime lastActivity;

  const ConversationMetrics({
    required this.messageCount,
    required this.averageResponseTime,
    required this.messageBalance,
    required this.engagementScore,
    required this.lastActivity,
  });

  factory ConversationMetrics.empty() {
    return ConversationMetrics(
      messageCount: 0,
      averageResponseTime: 0.0,
      messageBalance: 0.5,
      engagementScore: 0.0,
      lastActivity: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messageCount': messageCount,
      'averageResponseTime': averageResponseTime,
      'messageBalance': messageBalance,
      'engagementScore': engagementScore,
      'lastActivity': lastActivity.toIso8601String(),
    };
  }

  factory ConversationMetrics.fromJson(Map<String, dynamic> json) {
    return ConversationMetrics(
      messageCount: json['messageCount'],
      averageResponseTime: json['averageResponseTime'],
      messageBalance: json['messageBalance'],
      engagementScore: json['engagementScore'],
      lastActivity: DateTime.parse(json['lastActivity']),
    );
  }
}

/// Compatibility score analysis between conversation participants
class CompatibilityScore {
  final double overallScore; // 0.0 to 1.0
  final double personalityMatch; // 0.0 to 1.0
  final double communicationStyleMatch; // 0.0 to 1.0
  final double interestAlignment; // 0.0 to 1.0
  final double valuesCompatibility; // 0.0 to 1.0
  final List<String> strengthAreas;
  final List<String> potentialChallenges;
  final CompatibilityLevel level;

  const CompatibilityScore({
    required this.overallScore,
    required this.personalityMatch,
    required this.communicationStyleMatch,
    required this.interestAlignment,
    required this.valuesCompatibility,
    required this.strengthAreas,
    required this.potentialChallenges,
    required this.level,
  });

  Map<String, dynamic> toJson() {
    return {
      'overallScore': overallScore,
      'personalityMatch': personalityMatch,
      'communicationStyleMatch': communicationStyleMatch,
      'interestAlignment': interestAlignment,
      'valuesCompatibility': valuesCompatibility,
      'strengthAreas': strengthAreas,
      'potentialChallenges': potentialChallenges,
      'level': level.toString().split('.').last,
    };
  }

  factory CompatibilityScore.fromJson(Map<String, dynamic> json) {
    return CompatibilityScore(
      overallScore: json['overallScore'],
      personalityMatch: json['personalityMatch'],
      communicationStyleMatch: json['communicationStyleMatch'],
      interestAlignment: json['interestAlignment'],
      valuesCompatibility: json['valuesCompatibility'],
      strengthAreas: List<String>.from(json['strengthAreas']),
      potentialChallenges: List<String>.from(json['potentialChallenges']),
      level: CompatibilityLevel.values.firstWhere(
        (l) => l.toString().split('.').last == json['level']
      ),
    );
  }
}

/// Compatibility level categories
enum CompatibilityLevel {
  excellent,
  high,
  good,
  moderate,
  low,
  incompatible,
}

/// Emotional analysis of conversation
class EmotionalAnalysis {
  final double overallPositivity; // 0.0 to 1.0
  final double emotionalVariance; // stability of emotions
  final List<String> dominantEmotions;
  final double emotionalCompatibility;
  final CommunicationStyle communicationStyle;

  const EmotionalAnalysis({
    required this.overallPositivity,
    required this.emotionalVariance,
    required this.dominantEmotions,
    required this.emotionalCompatibility,
    required this.communicationStyle,
  });

  Map<String, dynamic> toJson() {
    return {
      'overallPositivity': overallPositivity,
      'emotionalVariance': emotionalVariance,
      'dominantEmotions': dominantEmotions,
      'emotionalCompatibility': emotionalCompatibility,
      'communicationStyle': communicationStyle.toString().split('.').last,
    };
  }

  factory EmotionalAnalysis.fromJson(Map<String, dynamic> json) {
    return EmotionalAnalysis(
      overallPositivity: json['overallPositivity'],
      emotionalVariance: json['emotionalVariance'],
      dominantEmotions: List<String>.from(json['dominantEmotions']),
      emotionalCompatibility: json['emotionalCompatibility'],
      communicationStyle: CommunicationStyle.values.firstWhere(
        (s) => s.toString().split('.').last == json['communicationStyle']
      ),
    );
  }
}

/// Communication style types
enum CommunicationStyle {
  friendly,
  formal,
  playful,
  romantic,
  intellectual,
  casual,
  expressive,
  reserved,
}

/// Message sentiment analysis
class MessageSentiment {
  final double positivity; // 0.0 to 1.0
  final List<String> emotions;
  final double confidence;

  const MessageSentiment({
    required this.positivity,
    required this.emotions,
    required this.confidence,
  });

  Map<String, dynamic> toJson() {
    return {
      'positivity': positivity,
      'emotions': emotions,
      'confidence': confidence,
    };
  }

  factory MessageSentiment.fromJson(Map<String, dynamic> json) {
    return MessageSentiment(
      positivity: json['positivity'],
      emotions: List<String>.from(json['emotions']),
      confidence: json['confidence'],
    );
  }
}

/// Response pattern metrics
class ResponseMetrics {
  final double averageResponseTime;
  final double engagementScore;
  final double messageFrequency;

  const ResponseMetrics({
    required this.averageResponseTime,
    required this.engagementScore,
    required this.messageFrequency,
  });
}

/// Safety analysis for conversations
class SafetyAnalysis {
  final RiskLevel riskLevel;
  final List<RedFlag> redFlags;
  final List<SafetyConcern> concerns;
  final List<String> recommendations;

  const SafetyAnalysis({
    required this.riskLevel,
    required this.redFlags,
    required this.concerns,
    required this.recommendations,
  });

  Map<String, dynamic> toJson() {
    return {
      'riskLevel': riskLevel.toString().split('.').last,
      'redFlags': redFlags.map((f) => f.toJson()).toList(),
      'concerns': concerns.map((c) => c.toJson()).toList(),
      'recommendations': recommendations,
    };
  }

  factory SafetyAnalysis.fromJson(Map<String, dynamic> json) {
    return SafetyAnalysis(
      riskLevel: RiskLevel.values.firstWhere((r) => r.toString().split('.').last == json['riskLevel']),
      redFlags: (json['redFlags'] as List).map((f) => RedFlag.fromJson(f)).toList(),
      concerns: (json['concerns'] as List).map((c) => SafetyConcern.fromJson(c)).toList(),
      recommendations: List<String>.from(json['recommendations']),
    );
  }
}

/// Risk levels for safety analysis
enum RiskLevel {
  low,
  medium,
  high,
  critical,
}

/// Red flag types and descriptions
class RedFlag {
  final RedFlagType type;
  final String description;
  final double severity; // 0.0 to 1.0
  final String messageId;

  const RedFlag({
    required this.type,
    required this.description,
    required this.severity,
    required this.messageId,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString().split('.').last,
      'description': description,
      'severity': severity,
      'messageId': messageId,
    };
  }

  factory RedFlag.fromJson(Map<String, dynamic> json) {
    return RedFlag(
      type: RedFlagType.values.firstWhere((t) => t.toString().split('.').last == json['type']),
      description: json['description'],
      severity: json['severity'],
      messageId: json['messageId'],
    );
  }
}

/// Types of red flags
enum RedFlagType {
  inappropriateContent,
  pressureTactics,
  manipulationAttempt,
  aggressiveBehavior,
  requestForPersonalInfo,
  financialRequest,
  suspiciousLinks,
  scamIndicators,
}

/// Safety concerns (less severe than red flags)
class SafetyConcern {
  final ConcernType type;
  final String description;
  final String messageId;

  const SafetyConcern({
    required this.type,
    required this.description,
    required this.messageId,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString().split('.').last,
      'description': description,
      'messageId': messageId,
    };
  }

  factory SafetyConcern.fromJson(Map<String, dynamic> json) {
    return SafetyConcern(
      type: ConcernType.values.firstWhere((t) => t.toString().split('.').last == json['type']),
      description: json['description'],
      messageId: json['messageId'],
    );
  }
}

/// Types of safety concerns
enum ConcernType {
  fastMoving,
  vagueness,
  inconsistentStory,
  avoidingQuestions,
  pushingToMeetQuickly,
}

/// Conversation insights with actionable recommendations
class ConversationInsight {
  final InsightType type;
  final String title;
  final String description;
  final bool actionable;
  final List<String> suggestions;

  const ConversationInsight({
    required this.type,
    required this.title,
    required this.description,
    required this.actionable,
    required this.suggestions,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString().split('.').last,
      'title': title,
      'description': description,
      'actionable': actionable,
      'suggestions': suggestions,
    };
  }

  factory ConversationInsight.fromJson(Map<String, dynamic> json) {
    return ConversationInsight(
      type: InsightType.values.firstWhere((t) => t.toString().split('.').last == json['type']),
      title: json['title'],
      description: json['description'],
      actionable: json['actionable'],
      suggestions: List<String>.from(json['suggestions']),
    );
  }
}

/// Types of conversation insights
enum InsightType {
  timing,
  engagement,
  emotional,
  compatibility,
  safety,
  progression,
}

/// AI-generated conversation suggestions
class ConversationSuggestion {
  final SuggestionType type;
  final String text;
  final double confidence; // 0.0 to 1.0
  final String context;

  const ConversationSuggestion({
    required this.type,
    required this.text,
    required this.confidence,
    required this.context,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString().split('.').last,
      'text': text,
      'confidence': confidence,
      'context': context,
    };
  }

  factory ConversationSuggestion.fromJson(Map<String, dynamic> json) {
    return ConversationSuggestion(
      type: SuggestionType.values.firstWhere((t) => t.toString().split('.').last == json['type']),
      text: json['text'],
      confidence: json['confidence'],
      context: json['context'],
    );
  }
}

/// Types of conversation suggestions
enum SuggestionType {
  revive,
  question,
  topic,
  deepening,
  icebreaker,
  compliment,
  followUp,
}