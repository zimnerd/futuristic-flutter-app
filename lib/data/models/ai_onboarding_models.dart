import 'package:equatable/equatable.dart';

/// Request model for AI-assisted onboarding
class AiOnboardingRequest extends Equatable {
  final String userId;
  final String sessionId;
  final AiOnboardingStep step;
  final Map<String, dynamic> responses;
  final String? context;

  const AiOnboardingRequest({
    required this.userId,
    required this.sessionId,
    required this.step,
    required this.responses,
    this.context,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'sessionId': sessionId,
      'step': step.toJson(),
      'responses': responses,
      'context': context,
    };
  }

  @override
  List<Object?> get props => [userId, sessionId, step, responses, context];
}

/// Onboarding step information
class AiOnboardingStep extends Equatable {
  final String stepId;
  final String category; // 'personality', 'interests', 'lifestyle', 'preferences'
  final int stepNumber;
  final int totalSteps;

  const AiOnboardingStep({
    required this.stepId,
    required this.category,
    required this.stepNumber,
    required this.totalSteps,
  });

  Map<String, dynamic> toJson() {
    return {
      'stepId': stepId,
      'category': category,
      'stepNumber': stepNumber,
      'totalSteps': totalSteps,
    };
  }

  factory AiOnboardingStep.fromJson(Map<String, dynamic> json) {
    return AiOnboardingStep(
      stepId: json['stepId'],
      category: json['category'],
      stepNumber: json['stepNumber'],
      totalSteps: json['totalSteps'],
    );
  }

  @override
  List<Object?> get props => [stepId, category, stepNumber, totalSteps];
}

/// Response model for AI onboarding
class AiOnboardingResponse extends Equatable {
  final String sessionId;
  final AiOnboardingStep currentStep;
  final List<AiOnboardingQuestion> questions;
  final AiGeneratedProfileSection? generatedSection;
  final AiOnboardingProgress progress;
  final bool isComplete;
  final DateTime generatedAt;

  const AiOnboardingResponse({
    required this.sessionId,
    required this.currentStep,
    required this.questions,
    this.generatedSection,
    required this.progress,
    required this.isComplete,
    required this.generatedAt,
  });

  factory AiOnboardingResponse.fromJson(Map<String, dynamic> json) {
    return AiOnboardingResponse(
      sessionId: json['sessionId'],
      currentStep: AiOnboardingStep.fromJson(json['currentStep']),
      questions: (json['questions'] as List)
          .map((q) => AiOnboardingQuestion.fromJson(q))
          .toList(),
      generatedSection: json['generatedSection'] != null
          ? AiGeneratedProfileSection.fromJson(json['generatedSection'])
          : null,
      progress: AiOnboardingProgress.fromJson(json['progress']),
      isComplete: json['isComplete'],
      generatedAt: DateTime.parse(json['generatedAt']),
    );
  }

  @override
  List<Object?> get props => [
        sessionId,
        currentStep,
        questions,
        generatedSection,
        progress,
        isComplete,
        generatedAt,
      ];
}

/// AI-generated onboarding question
class AiOnboardingQuestion extends Equatable {
  final String id;
  final String question;
  final String type; // 'multiple_choice', 'text', 'scale', 'boolean'
  final List<String>? options;
  final Map<String, dynamic>? constraints;
  final String category;
  final String reasoning;
  final bool isRequired;

  const AiOnboardingQuestion({
    required this.id,
    required this.question,
    required this.type,
    this.options,
    this.constraints,
    required this.category,
    required this.reasoning,
    this.isRequired = true,
  });

  factory AiOnboardingQuestion.fromJson(Map<String, dynamic> json) {
    return AiOnboardingQuestion(
      id: json['id'],
      question: json['question'],
      type: json['type'],
      options: json['options'] != null 
          ? List<String>.from(json['options']) 
          : null,
      constraints: json['constraints'],
      category: json['category'],
      reasoning: json['reasoning'],
      isRequired: json['isRequired'] ?? true,
    );
  }

  @override
  List<Object?> get props => [
        id,
        question,
        type,
        options,
        constraints,
        category,
        reasoning,
        isRequired,
      ];
}

/// AI-generated profile section
class AiGeneratedProfileSection extends Equatable {
  final String sectionType; // 'bio', 'interests', 'lifestyle'
  final String content;
  final String reasoning;
  final double confidence;
  final List<String> basedOn;
  final bool requiresConfirmation;
  final List<String>? alternatives;

  const AiGeneratedProfileSection({
    required this.sectionType,
    required this.content,
    required this.reasoning,
    required this.confidence,
    required this.basedOn,
    this.requiresConfirmation = true,
    this.alternatives,
  });

  factory AiGeneratedProfileSection.fromJson(Map<String, dynamic> json) {
    return AiGeneratedProfileSection(
      sectionType: json['sectionType'],
      content: json['content'],
      reasoning: json['reasoning'],
      confidence: json['confidence'].toDouble(),
      basedOn: List<String>.from(json['basedOn']),
      requiresConfirmation: json['requiresConfirmation'] ?? true,
      alternatives: json['alternatives'] != null 
          ? List<String>.from(json['alternatives']) 
          : null,
    );
  }

  @override
  List<Object?> get props => [
        sectionType,
        content,
        reasoning,
        confidence,
        basedOn,
        requiresConfirmation,
        alternatives,
      ];
}

/// Onboarding progress tracking
class AiOnboardingProgress extends Equatable {
  final int completedSteps;
  final int totalSteps;
  final double completionPercentage;
  final List<String> completedCategories;
  final String? nextCategory;
  final Map<String, dynamic> collectedData;

  const AiOnboardingProgress({
    required this.completedSteps,
    required this.totalSteps,
    required this.completionPercentage,
    required this.completedCategories,
    this.nextCategory,
    required this.collectedData,
  });

  factory AiOnboardingProgress.fromJson(Map<String, dynamic> json) {
    return AiOnboardingProgress(
      completedSteps: json['completedSteps'],
      totalSteps: json['totalSteps'],
      completionPercentage: json['completionPercentage'].toDouble(),
      completedCategories: List<String>.from(json['completedCategories']),
      nextCategory: json['nextCategory'],
      collectedData: json['collectedData'],
    );
  }

  @override
  List<Object?> get props => [
        completedSteps,
        totalSteps,
        completionPercentage,
        completedCategories,
        nextCategory,
        collectedData,
      ];
}

/// Request model for AI feedback and rating
class AiFeedbackRequest extends Equatable {
  final String userId;
  final String sessionId;
  final String featureType; // 'conversation_analysis', 'profile_suggestion', etc.
  final String aiResponseId;
  final AiFeedbackRating rating;
  final String? comment;
  final Map<String, dynamic>? context;

  const AiFeedbackRequest({
    required this.userId,
    required this.sessionId,
    required this.featureType,
    required this.aiResponseId,
    required this.rating,
    this.comment,
    this.context,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'sessionId': sessionId,
      'featureType': featureType,
      'aiResponseId': aiResponseId,
      'rating': rating.toJson(),
      'comment': comment,
      'context': context,
    };
  }

  @override
  List<Object?> get props => [
        userId,
        sessionId,
        featureType,
        aiResponseId,
        rating,
        comment,
        context,
      ];
}

/// AI feedback rating
class AiFeedbackRating extends Equatable {
  final int overall; // 1-5 stars
  final int? accuracy;
  final int? usefulness;
  final int? relevance;
  final int? clarity;
  final bool wouldUseAgain;
  final List<String>? selectedTags; // Quick feedback tags

  const AiFeedbackRating({
    required this.overall,
    this.accuracy,
    this.usefulness,
    this.relevance,
    this.clarity,
    required this.wouldUseAgain,
    this.selectedTags,
  });

  Map<String, dynamic> toJson() {
    return {
      'overall': overall,
      'accuracy': accuracy,
      'usefulness': usefulness,
      'relevance': relevance,
      'clarity': clarity,
      'wouldUseAgain': wouldUseAgain,
      'selectedTags': selectedTags,
    };
  }

  factory AiFeedbackRating.fromJson(Map<String, dynamic> json) {
    return AiFeedbackRating(
      overall: json['overall'],
      accuracy: json['accuracy'],
      usefulness: json['usefulness'],
      relevance: json['relevance'],
      clarity: json['clarity'],
      wouldUseAgain: json['wouldUseAgain'],
      selectedTags: json['selectedTags'] != null 
          ? List<String>.from(json['selectedTags']) 
          : null,
    );
  }

  @override
  List<Object?> get props => [
        overall,
        accuracy,
        usefulness,
        relevance,
        clarity,
        wouldUseAgain,
        selectedTags,
      ];
}

/// Response model for AI feedback submission
class AiFeedbackResponse extends Equatable {
  final String feedbackId;
  final bool success;
  final String message;
  final AiFeedbackInsights? insights;
  final DateTime submittedAt;

  const AiFeedbackResponse({
    required this.feedbackId,
    required this.success,
    required this.message,
    this.insights,
    required this.submittedAt,
  });

  factory AiFeedbackResponse.fromJson(Map<String, dynamic> json) {
    return AiFeedbackResponse(
      feedbackId: json['feedbackId'],
      success: json['success'],
      message: json['message'],
      insights: json['insights'] != null
          ? AiFeedbackInsights.fromJson(json['insights'])
          : null,
      submittedAt: DateTime.parse(json['submittedAt']),
    );
  }

  @override
  List<Object?> get props => [feedbackId, success, message, insights, submittedAt];
}

/// AI feedback insights for user
class AiFeedbackInsights extends Equatable {
  final double userSatisfactionTrend; // How user's satisfaction is trending
  final Map<String, double> featurePerformance; // How each AI feature is performing for this user
  final List<String> recommendedFeatures; // AI features user might like
  final String thankYouMessage;

  const AiFeedbackInsights({
    required this.userSatisfactionTrend,
    required this.featurePerformance,
    required this.recommendedFeatures,
    required this.thankYouMessage,
  });

  factory AiFeedbackInsights.fromJson(Map<String, dynamic> json) {
    return AiFeedbackInsights(
      userSatisfactionTrend: json['userSatisfactionTrend'].toDouble(),
      featurePerformance: Map<String, double>.from(json['featurePerformance']),
      recommendedFeatures: List<String>.from(json['recommendedFeatures']),
      thankYouMessage: json['thankYouMessage'],
    );
  }

  @override
  List<Object?> get props => [
        userSatisfactionTrend,
        featurePerformance,
        recommendedFeatures,
        thankYouMessage,
      ];
}

/// Request model for AI insights dashboard
class AiInsightsRequest extends Equatable {
  final String userId;
  final String timeframe; // 'week', 'month', 'all'
  final List<String>? categories; // Filter by specific categories
  final bool includeComparisons;

  const AiInsightsRequest({
    required this.userId,
    required this.timeframe,
    this.categories,
    this.includeComparisons = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'timeframe': timeframe,
      'categories': categories,
      'includeComparisons': includeComparisons,
    };
  }

  @override
  List<Object?> get props => [userId, timeframe, categories, includeComparisons];
}

/// Response model for AI insights dashboard
class AiInsightsResponse extends Equatable {
  final String userId;
  final AiUsageStats usageStats;
  final List<AiInsightCard> insights;
  final AiProgressSummary progress;
  final List<AiRecommendation> recommendations;
  final DateTime generatedAt;

  const AiInsightsResponse({
    required this.userId,
    required this.usageStats,
    required this.insights,
    required this.progress,
    required this.recommendations,
    required this.generatedAt,
  });

  factory AiInsightsResponse.fromJson(Map<String, dynamic> json) {
    return AiInsightsResponse(
      userId: json['userId'],
      usageStats: AiUsageStats.fromJson(json['usageStats']),
      insights: (json['insights'] as List)
          .map((i) => AiInsightCard.fromJson(i))
          .toList(),
      progress: AiProgressSummary.fromJson(json['progress']),
      recommendations: (json['recommendations'] as List)
          .map((r) => AiRecommendation.fromJson(r))
          .toList(),
      generatedAt: DateTime.parse(json['generatedAt']),
    );
  }

  @override
  List<Object?> get props => [
        userId,
        usageStats,
        insights,
        progress,
        recommendations,
        generatedAt,
      ];
}

/// AI usage statistics
class AiUsageStats extends Equatable {
  final int totalInteractions;
  final Map<String, int> featureUsage;
  final double averageRating;
  final int sessionsThisWeek;
  final int improvementsImplemented;

  const AiUsageStats({
    required this.totalInteractions,
    required this.featureUsage,
    required this.averageRating,
    required this.sessionsThisWeek,
    required this.improvementsImplemented,
  });

  factory AiUsageStats.fromJson(Map<String, dynamic> json) {
    return AiUsageStats(
      totalInteractions: json['totalInteractions'],
      featureUsage: Map<String, int>.from(json['featureUsage']),
      averageRating: json['averageRating'].toDouble(),
      sessionsThisWeek: json['sessionsThisWeek'],
      improvementsImplemented: json['improvementsImplemented'],
    );
  }

  @override
  List<Object?> get props => [
        totalInteractions,
        featureUsage,
        averageRating,
        sessionsThisWeek,
        improvementsImplemented,
      ];
}

/// AI insight card for dashboard
class AiInsightCard extends Equatable {
  final String id;
  final String title;
  final String description;
  final String type; // 'metric', 'tip', 'achievement', 'trend'
  final String? value;
  final String? trend; // 'up', 'down', 'stable'
  final String? actionText;
  final String? actionRoute;

  const AiInsightCard({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.value,
    this.trend,
    this.actionText,
    this.actionRoute,
  });

  factory AiInsightCard.fromJson(Map<String, dynamic> json) {
    return AiInsightCard(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: json['type'],
      value: json['value'],
      trend: json['trend'],
      actionText: json['actionText'],
      actionRoute: json['actionRoute'],
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        type,
        value,
        trend,
        actionText,
        actionRoute,
      ];
}

/// AI progress summary
class AiProgressSummary extends Equatable {
  final double profileScore;
  final double profileScoreChange;
  final int conversationsImproved;
  final int matchesFromAiSuggestions;
  final List<String> achievements;

  const AiProgressSummary({
    required this.profileScore,
    required this.profileScoreChange,
    required this.conversationsImproved,
    required this.matchesFromAiSuggestions,
    required this.achievements,
  });

  factory AiProgressSummary.fromJson(Map<String, dynamic> json) {
    return AiProgressSummary(
      profileScore: json['profileScore'].toDouble(),
      profileScoreChange: json['profileScoreChange'].toDouble(),
      conversationsImproved: json['conversationsImproved'],
      matchesFromAiSuggestions: json['matchesFromAiSuggestions'],
      achievements: List<String>.from(json['achievements']),
    );
  }

  @override
  List<Object?> get props => [
        profileScore,
        profileScoreChange,
        conversationsImproved,
        matchesFromAiSuggestions,
        achievements,
      ];
}

/// AI recommendation for user
class AiRecommendation extends Equatable {
  final String id;
  final String title;
  final String description;
  final String category;
  final String priority; // 'high', 'medium', 'low'
  final String actionText;
  final String? actionRoute;
  final double impact; // Expected impact score

  const AiRecommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.actionText,
    this.actionRoute,
    required this.impact,
  });

  factory AiRecommendation.fromJson(Map<String, dynamic> json) {
    return AiRecommendation(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      priority: json['priority'],
      actionText: json['actionText'],
      actionRoute: json['actionRoute'],
      impact: json['impact'].toDouble(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        category,
        priority,
        actionText,
        actionRoute,
        impact,
      ];
}