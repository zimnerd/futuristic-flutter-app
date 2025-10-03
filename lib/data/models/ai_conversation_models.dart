import 'package:equatable/equatable.dart';

/// Request model for AI conversation analysis
class AiConversationAnalysisRequest extends Equatable {
  final String conversationId;
  final String userId;
  final String matchId;
  final List<AiMessageData> messages;
  final AiUserProfileData userProfile;
  final AiUserProfileData matchProfile;
  final Map<String, dynamic>? context;

  const AiConversationAnalysisRequest({
    required this.conversationId,
    required this.userId,
    required this.matchId,
    required this.messages,
    required this.userProfile,
    required this.matchProfile,
    this.context,
  });

  Map<String, dynamic> toJson() {
    return {
      'conversationId': conversationId,
      'userId': userId,
      'matchId': matchId,
      'messages': messages.map((m) => m.toJson()).toList(),
      'userProfile': userProfile.toJson(),
      'matchProfile': matchProfile.toJson(),
      'context': context,
    };
  }

  @override
  List<Object?> get props => [
        conversationId,
        userId,
        matchId,
        messages,
        userProfile,
        matchProfile,
        context,
      ];
}

/// Message data for AI analysis
class AiMessageData extends Equatable {
  final String id;
  final String senderId;
  final String content;
  final DateTime timestamp;
  final String? type;
  final Map<String, dynamic>? metadata;

  const AiMessageData({
    required this.id,
    required this.senderId,
    required this.content,
    required this.timestamp,
    this.type,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
      'metadata': metadata,
    };
  }

  factory AiMessageData.fromJson(Map<String, dynamic> json) {
    return AiMessageData(
      id: json['id'],
      senderId: json['senderId'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      type: json['type'],
      metadata: json['metadata'],
    );
  }

  @override
  List<Object?> get props => [id, senderId, content, timestamp, type, metadata];
}

/// User profile data for AI analysis
class AiUserProfileData extends Equatable {
  final String id;
  final String name;
  final int age;
  final String? bio;
  final List<String> interests;
  final List<String> photos;
  final Map<String, dynamic>? preferences;
  final Map<String, dynamic>? personality;

  const AiUserProfileData({
    required this.id,
    required this.name,
    required this.age,
    this.bio,
    this.interests = const [],
    this.photos = const [],
    this.preferences,
    this.personality,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'bio': bio,
      'interests': interests,
      'photos': photos,
      'preferences': preferences,
      'personality': personality,
    };
  }

  factory AiUserProfileData.fromJson(Map<String, dynamic> json) {
    return AiUserProfileData(
      id: json['id'],
      name: json['name'],
      age: json['age'],
      bio: json['bio'],
      interests:
          (json['interests'] as List?)
              ?.map((item) {
                // Handle new nested structure: {id, interest: {id, name}}
                if (item is String) return item; // Backward compatibility
                if (item is Map<String, dynamic>) {
                  return item['interest']?['name'] as String? ?? '';
                }
                return item.toString();
              })
              .where((name) => name.isNotEmpty)
              .toList() ??
          [],
      photos:
          (json['photos'] as List?)
              ?.map((photo) {
                // Handle new nested structure: {id, url, ...}
                if (photo is String) return photo; // Backward compatibility
                if (photo is Map<String, dynamic>) {
                  return photo['url'] as String? ?? '';
                }
                return photo.toString();
              })
              .where((url) => url.isNotEmpty)
              .toList() ??
          [],
      preferences: json['preferences'],
      personality: json['personality'],
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        age,
        bio,
        interests,
        photos,
        preferences,
        personality,
      ];
}

/// Response model for AI conversation analysis
class AiConversationAnalysisResponse extends Equatable {
  final String requestId;
  final AiConversationHealth health;
  final AiConversationMetrics metrics;
  final List<AiConversationSuggestion> suggestions;
  final List<AiCompatibilityInsight> compatibilityInsights;
  final AiConversationRevivalPlan? revivalPlan;
  final double confidence;
  final DateTime generatedAt;

  const AiConversationAnalysisResponse({
    required this.requestId,
    required this.health,
    required this.metrics,
    required this.suggestions,
    required this.compatibilityInsights,
    this.revivalPlan,
    required this.confidence,
    required this.generatedAt,
  });

  factory AiConversationAnalysisResponse.fromJson(Map<String, dynamic> json) {
    return AiConversationAnalysisResponse(
      requestId: json['requestId'],
      health: AiConversationHealth.fromJson(json['health']),
      metrics: AiConversationMetrics.fromJson(json['metrics']),
      suggestions: (json['suggestions'] as List)
          .map((s) => AiConversationSuggestion.fromJson(s))
          .toList(),
      compatibilityInsights: (json['compatibilityInsights'] as List)
          .map((i) => AiCompatibilityInsight.fromJson(i))
          .toList(),
      revivalPlan: json['revivalPlan'] != null
          ? AiConversationRevivalPlan.fromJson(json['revivalPlan'])
          : null,
      confidence: json['confidence'].toDouble(),
      generatedAt: DateTime.parse(json['generatedAt']),
    );
  }

  @override
  List<Object?> get props => [
        requestId,
        health,
        metrics,
        suggestions,
        compatibilityInsights,
        revivalPlan,
        confidence,
        generatedAt,
      ];
}

/// Conversation health assessment from AI
class AiConversationHealth extends Equatable {
  final String status; // 'healthy', 'declining', 'dying', 'revived'
  final double score; // 0.0 to 1.0
  final List<String> concerns;
  final List<String> strengths;
  final String summary;

  const AiConversationHealth({
    required this.status,
    required this.score,
    required this.concerns,
    required this.strengths,
    required this.summary,
  });

  factory AiConversationHealth.fromJson(Map<String, dynamic> json) {
    return AiConversationHealth(
      status: json['status'],
      score: json['score'].toDouble(),
      concerns: List<String>.from(json['concerns']),
      strengths: List<String>.from(json['strengths']),
      summary: json['summary'],
    );
  }

  @override
  List<Object?> get props => [status, score, concerns, strengths, summary];
}

/// Conversation metrics from AI analysis
class AiConversationMetrics extends Equatable {
  final int messageCount;
  final double engagementScore;
  final double responseTimeScore;
  final double topicDiversityScore;
  final double emotionalConnectionScore;
  final List<String> dominantTopics;
  final Map<String, double> sentimentAnalysis;

  const AiConversationMetrics({
    required this.messageCount,
    required this.engagementScore,
    required this.responseTimeScore,
    required this.topicDiversityScore,
    required this.emotionalConnectionScore,
    required this.dominantTopics,
    required this.sentimentAnalysis,
  });

  factory AiConversationMetrics.fromJson(Map<String, dynamic> json) {
    return AiConversationMetrics(
      messageCount: json['messageCount'],
      engagementScore: json['engagementScore'].toDouble(),
      responseTimeScore: json['responseTimeScore'].toDouble(),
      topicDiversityScore: json['topicDiversityScore'].toDouble(),
      emotionalConnectionScore: json['emotionalConnectionScore'].toDouble(),
      dominantTopics: List<String>.from(json['dominantTopics']),
      sentimentAnalysis: Map<String, double>.from(json['sentimentAnalysis']),
    );
  }

  @override
  List<Object?> get props => [
        messageCount,
        engagementScore,
        responseTimeScore,
        topicDiversityScore,
        emotionalConnectionScore,
        dominantTopics,
        sentimentAnalysis,
      ];
}

/// AI-generated conversation suggestion
class AiConversationSuggestion extends Equatable {
  final String id;
  final String type; // 'reply', 'question', 'topic_change', 'icebreaker'
  final String content;
  final String reasoning;
  final double confidence;
  final List<String> tags;
  final String? category;
  final Map<String, dynamic>? metadata;

  const AiConversationSuggestion({
    required this.id,
    required this.type,
    required this.content,
    required this.reasoning,
    required this.confidence,
    required this.tags,
    this.category,
    this.metadata,
  });

  factory AiConversationSuggestion.fromJson(Map<String, dynamic> json) {
    return AiConversationSuggestion(
      id: json['id'],
      type: json['type'],
      content: json['content'],
      reasoning: json['reasoning'],
      confidence: json['confidence'].toDouble(),
      tags: List<String>.from(json['tags']),
      category: json['category'],
      metadata: json['metadata'],
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        content,
        reasoning,
        confidence,
        tags,
        category,
        metadata,
      ];
}

/// AI compatibility insight
class AiCompatibilityInsight extends Equatable {
  final String type; // 'strength', 'concern', 'neutral'
  final String category; // 'interests', 'personality', 'communication', 'lifestyle'
  final String insight;
  final double impact; // -1.0 to 1.0
  final List<String> evidence;
  final String? recommendation;

  const AiCompatibilityInsight({
    required this.type,
    required this.category,
    required this.insight,
    required this.impact,
    required this.evidence,
    this.recommendation,
  });

  factory AiCompatibilityInsight.fromJson(Map<String, dynamic> json) {
    return AiCompatibilityInsight(
      type: json['type'],
      category: json['category'],
      insight: json['insight'],
      impact: json['impact'].toDouble(),
      evidence: List<String>.from(json['evidence']),
      recommendation: json['recommendation'],
    );
  }

  @override
  List<Object?> get props => [
        type,
        category,
        insight,
        impact,
        evidence,
        recommendation,
      ];
}

/// AI-generated conversation revival plan
class AiConversationRevivalPlan extends Equatable {
  final String planId;
  final String strategy;
  final List<String> suggestedMessages;
  final List<String> topicsToExplore;
  final String reasoning;
  final double successProbability;
  final String timeToAct;

  const AiConversationRevivalPlan({
    required this.planId,
    required this.strategy,
    required this.suggestedMessages,
    required this.topicsToExplore,
    required this.reasoning,
    required this.successProbability,
    required this.timeToAct,
  });

  factory AiConversationRevivalPlan.fromJson(Map<String, dynamic> json) {
    return AiConversationRevivalPlan(
      planId: json['planId'],
      strategy: json['strategy'],
      suggestedMessages: List<String>.from(json['suggestedMessages']),
      topicsToExplore: List<String>.from(json['topicsToExplore']),
      reasoning: json['reasoning'],
      successProbability: json['successProbability'].toDouble(),
      timeToAct: json['timeToAct'],
    );
  }

  @override
  List<Object?> get props => [
        planId,
        strategy,
        suggestedMessages,
        topicsToExplore,
        reasoning,
        successProbability,
        timeToAct,
      ];
}