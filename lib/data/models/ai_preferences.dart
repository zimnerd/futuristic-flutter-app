import 'package:equatable/equatable.dart';

/// Model for AI feature preferences and settings
class AiPreferences extends Equatable {
  final bool isAiEnabled;
  final AiConversationSettings conversations;
  final AiCompanionSettings companion;
  final AiProfileSettings profile;
  final AiMatchingSettings matching;
  final AiIcebreakerSettings icebreakers;
  final AiGeneralSettings general;

  const AiPreferences({
    this.isAiEnabled = false,
    this.conversations = const AiConversationSettings(),
    this.companion = const AiCompanionSettings(),
    this.profile = const AiProfileSettings(),
    this.matching = const AiMatchingSettings(),
    this.icebreakers = const AiIcebreakerSettings(),
    this.general = const AiGeneralSettings(),
  });

  factory AiPreferences.fromJson(Map<String, dynamic> json) {
    return AiPreferences(
      isAiEnabled: json['isAiEnabled'] ?? false,
      conversations: AiConversationSettings.fromJson(
        json['conversations'] ?? {},
      ),
      companion: AiCompanionSettings.fromJson(json['companion'] ?? {}),
      profile: AiProfileSettings.fromJson(json['profile'] ?? {}),
      matching: AiMatchingSettings.fromJson(json['matching'] ?? {}),
      icebreakers: AiIcebreakerSettings.fromJson(json['icebreakers'] ?? {}),
      general: AiGeneralSettings.fromJson(json['general'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isAiEnabled': isAiEnabled,
      'conversations': conversations.toJson(),
      'companion': companion.toJson(),
      'profile': profile.toJson(),
      'matching': matching.toJson(),
      'icebreakers': icebreakers.toJson(),
      'general': general.toJson(),
    };
  }

  AiPreferences copyWith({
    bool? isAiEnabled,
    AiConversationSettings? conversations,
    AiCompanionSettings? companion,
    AiProfileSettings? profile,
    AiMatchingSettings? matching,
    AiIcebreakerSettings? icebreakers,
    AiGeneralSettings? general,
  }) {
    return AiPreferences(
      isAiEnabled: isAiEnabled ?? this.isAiEnabled,
      conversations: conversations ?? this.conversations,
      companion: companion ?? this.companion,
      profile: profile ?? this.profile,
      matching: matching ?? this.matching,
      icebreakers: icebreakers ?? this.icebreakers,
      general: general ?? this.general,
    );
  }

  @override
  List<Object?> get props => [
    isAiEnabled,
    conversations,
    companion,
    profile,
    matching,
    icebreakers,
    general,
  ];
}

/// AI settings for conversation features
class AiConversationSettings extends Equatable {
  final bool smartRepliesEnabled;
  final bool customReplyEnabled;
  final bool contextAwareReplies;
  final bool autoSuggestionsEnabled;
  final int maxSuggestions;
  final String replyTone;
  final bool adaptToUserStyle;

  const AiConversationSettings({
    this.smartRepliesEnabled = false,
    this.customReplyEnabled = false,
    this.contextAwareReplies = false,
    this.autoSuggestionsEnabled = false,
    this.maxSuggestions = 3,
    this.replyTone = 'friendly',
    this.adaptToUserStyle = false,
  });

  factory AiConversationSettings.fromJson(Map<String, dynamic> json) {
    return AiConversationSettings(
      smartRepliesEnabled: json['smartRepliesEnabled'] ?? false,
      customReplyEnabled: json['customReplyEnabled'] ?? false,
      contextAwareReplies: json['contextAwareReplies'] ?? false,
      autoSuggestionsEnabled: json['autoSuggestionsEnabled'] ?? false,
      maxSuggestions: json['maxSuggestions'] ?? 3,
      replyTone: json['replyTone'] ?? 'friendly',
      adaptToUserStyle: json['adaptToUserStyle'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'smartRepliesEnabled': smartRepliesEnabled,
      'customReplyEnabled': customReplyEnabled,
      'contextAwareReplies': contextAwareReplies,
      'autoSuggestionsEnabled': autoSuggestionsEnabled,
      'maxSuggestions': maxSuggestions,
      'replyTone': replyTone,
      'adaptToUserStyle': adaptToUserStyle,
    };
  }

  AiConversationSettings copyWith({
    bool? smartRepliesEnabled,
    bool? customReplyEnabled,
    bool? contextAwareReplies,
    bool? autoSuggestionsEnabled,
    int? maxSuggestions,
    String? replyTone,
    bool? adaptToUserStyle,
  }) {
    return AiConversationSettings(
      smartRepliesEnabled: smartRepliesEnabled ?? this.smartRepliesEnabled,
      customReplyEnabled: customReplyEnabled ?? this.customReplyEnabled,
      contextAwareReplies: contextAwareReplies ?? this.contextAwareReplies,
      autoSuggestionsEnabled:
          autoSuggestionsEnabled ?? this.autoSuggestionsEnabled,
      maxSuggestions: maxSuggestions ?? this.maxSuggestions,
      replyTone: replyTone ?? this.replyTone,
      adaptToUserStyle: adaptToUserStyle ?? this.adaptToUserStyle,
    );
  }

  @override
  List<Object?> get props => [
    smartRepliesEnabled,
    customReplyEnabled,
    contextAwareReplies,
    autoSuggestionsEnabled,
    maxSuggestions,
    replyTone,
    adaptToUserStyle,
  ];
}

/// AI settings for companion features
class AiCompanionSettings extends Equatable {
  final bool companionChatEnabled;
  final bool companionAdviceEnabled;
  final bool relationshipAnalysisEnabled;
  final bool personalityMatchingEnabled;
  final String preferredCompanionPersonality;
  final bool companionLearningEnabled;

  const AiCompanionSettings({
    this.companionChatEnabled = false,
    this.companionAdviceEnabled = false,
    this.relationshipAnalysisEnabled = false,
    this.personalityMatchingEnabled = false,
    this.preferredCompanionPersonality = 'friendly',
    this.companionLearningEnabled = false,
  });

  factory AiCompanionSettings.fromJson(Map<String, dynamic> json) {
    return AiCompanionSettings(
      companionChatEnabled: json['companionChatEnabled'] ?? false,
      companionAdviceEnabled: json['companionAdviceEnabled'] ?? false,
      relationshipAnalysisEnabled: json['relationshipAnalysisEnabled'] ?? false,
      personalityMatchingEnabled: json['personalityMatchingEnabled'] ?? false,
      preferredCompanionPersonality:
          json['preferredCompanionPersonality'] ?? 'friendly',
      companionLearningEnabled: json['companionLearningEnabled'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'companionChatEnabled': companionChatEnabled,
      'companionAdviceEnabled': companionAdviceEnabled,
      'relationshipAnalysisEnabled': relationshipAnalysisEnabled,
      'personalityMatchingEnabled': personalityMatchingEnabled,
      'preferredCompanionPersonality': preferredCompanionPersonality,
      'companionLearningEnabled': companionLearningEnabled,
    };
  }

  AiCompanionSettings copyWith({
    bool? companionChatEnabled,
    bool? companionAdviceEnabled,
    bool? relationshipAnalysisEnabled,
    bool? personalityMatchingEnabled,
    String? preferredCompanionPersonality,
    bool? companionLearningEnabled,
  }) {
    return AiCompanionSettings(
      companionChatEnabled: companionChatEnabled ?? this.companionChatEnabled,
      companionAdviceEnabled:
          companionAdviceEnabled ?? this.companionAdviceEnabled,
      relationshipAnalysisEnabled:
          relationshipAnalysisEnabled ?? this.relationshipAnalysisEnabled,
      personalityMatchingEnabled:
          personalityMatchingEnabled ?? this.personalityMatchingEnabled,
      preferredCompanionPersonality:
          preferredCompanionPersonality ?? this.preferredCompanionPersonality,
      companionLearningEnabled:
          companionLearningEnabled ?? this.companionLearningEnabled,
    );
  }

  @override
  List<Object?> get props => [
    companionChatEnabled,
    companionAdviceEnabled,
    relationshipAnalysisEnabled,
    personalityMatchingEnabled,
    preferredCompanionPersonality,
    companionLearningEnabled,
  ];
}

/// AI settings for profile features
class AiProfileSettings extends Equatable {
  final bool profileOptimizationEnabled;
  final bool bioSuggestionsEnabled;
  final bool photoAnalysisEnabled;
  final bool profileAnalyticsEnabled;
  final bool interestSuggestionsEnabled;
  final bool profileCompletionHelp;

  const AiProfileSettings({
    this.profileOptimizationEnabled = false,
    this.bioSuggestionsEnabled = false,
    this.photoAnalysisEnabled = false,
    this.profileAnalyticsEnabled = false,
    this.interestSuggestionsEnabled = false,
    this.profileCompletionHelp = false,
  });

  factory AiProfileSettings.fromJson(Map<String, dynamic> json) {
    return AiProfileSettings(
      profileOptimizationEnabled: json['profileOptimizationEnabled'] ?? false,
      bioSuggestionsEnabled: json['bioSuggestionsEnabled'] ?? false,
      photoAnalysisEnabled: json['photoAnalysisEnabled'] ?? false,
      profileAnalyticsEnabled: json['profileAnalyticsEnabled'] ?? false,
      interestSuggestionsEnabled: json['interestSuggestionsEnabled'] ?? false,
      profileCompletionHelp: json['profileCompletionHelp'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profileOptimizationEnabled': profileOptimizationEnabled,
      'bioSuggestionsEnabled': bioSuggestionsEnabled,
      'photoAnalysisEnabled': photoAnalysisEnabled,
      'profileAnalyticsEnabled': profileAnalyticsEnabled,
      'interestSuggestionsEnabled': interestSuggestionsEnabled,
      'profileCompletionHelp': profileCompletionHelp,
    };
  }

  AiProfileSettings copyWith({
    bool? profileOptimizationEnabled,
    bool? bioSuggestionsEnabled,
    bool? photoAnalysisEnabled,
    bool? profileAnalyticsEnabled,
    bool? interestSuggestionsEnabled,
    bool? profileCompletionHelp,
  }) {
    return AiProfileSettings(
      profileOptimizationEnabled:
          profileOptimizationEnabled ?? this.profileOptimizationEnabled,
      bioSuggestionsEnabled:
          bioSuggestionsEnabled ?? this.bioSuggestionsEnabled,
      photoAnalysisEnabled: photoAnalysisEnabled ?? this.photoAnalysisEnabled,
      profileAnalyticsEnabled:
          profileAnalyticsEnabled ?? this.profileAnalyticsEnabled,
      interestSuggestionsEnabled:
          interestSuggestionsEnabled ?? this.interestSuggestionsEnabled,
      profileCompletionHelp:
          profileCompletionHelp ?? this.profileCompletionHelp,
    );
  }

  @override
  List<Object?> get props => [
    profileOptimizationEnabled,
    bioSuggestionsEnabled,
    photoAnalysisEnabled,
    profileAnalyticsEnabled,
    interestSuggestionsEnabled,
    profileCompletionHelp,
  ];
}

/// AI settings for matching features
class AiMatchingSettings extends Equatable {
  final bool smartMatchingEnabled;
  final bool compatibilityAnalysisEnabled;
  final bool personalityInsightsEnabled;
  final bool behaviorAnalysisEnabled;
  final bool matchPredictionEnabled;
  final double matchingThreshold;

  const AiMatchingSettings({
    this.smartMatchingEnabled = false,
    this.compatibilityAnalysisEnabled = false,
    this.personalityInsightsEnabled = false,
    this.behaviorAnalysisEnabled = false,
    this.matchPredictionEnabled = false,
    this.matchingThreshold = 0.7,
  });

  factory AiMatchingSettings.fromJson(Map<String, dynamic> json) {
    return AiMatchingSettings(
      smartMatchingEnabled: json['smartMatchingEnabled'] ?? false,
      compatibilityAnalysisEnabled:
          json['compatibilityAnalysisEnabled'] ?? false,
      personalityInsightsEnabled: json['personalityInsightsEnabled'] ?? false,
      behaviorAnalysisEnabled: json['behaviorAnalysisEnabled'] ?? false,
      matchPredictionEnabled: json['matchPredictionEnabled'] ?? false,
      matchingThreshold: (json['matchingThreshold'] ?? 0.7).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'smartMatchingEnabled': smartMatchingEnabled,
      'compatibilityAnalysisEnabled': compatibilityAnalysisEnabled,
      'personalityInsightsEnabled': personalityInsightsEnabled,
      'behaviorAnalysisEnabled': behaviorAnalysisEnabled,
      'matchPredictionEnabled': matchPredictionEnabled,
      'matchingThreshold': matchingThreshold,
    };
  }

  AiMatchingSettings copyWith({
    bool? smartMatchingEnabled,
    bool? compatibilityAnalysisEnabled,
    bool? personalityInsightsEnabled,
    bool? behaviorAnalysisEnabled,
    bool? matchPredictionEnabled,
    double? matchingThreshold,
  }) {
    return AiMatchingSettings(
      smartMatchingEnabled: smartMatchingEnabled ?? this.smartMatchingEnabled,
      compatibilityAnalysisEnabled:
          compatibilityAnalysisEnabled ?? this.compatibilityAnalysisEnabled,
      personalityInsightsEnabled:
          personalityInsightsEnabled ?? this.personalityInsightsEnabled,
      behaviorAnalysisEnabled:
          behaviorAnalysisEnabled ?? this.behaviorAnalysisEnabled,
      matchPredictionEnabled:
          matchPredictionEnabled ?? this.matchPredictionEnabled,
      matchingThreshold: matchingThreshold ?? this.matchingThreshold,
    );
  }

  @override
  List<Object?> get props => [
    smartMatchingEnabled,
    compatibilityAnalysisEnabled,
    personalityInsightsEnabled,
    behaviorAnalysisEnabled,
    matchPredictionEnabled,
    matchingThreshold,
  ];
}

/// AI settings for icebreaker features
class AiIcebreakerSettings extends Equatable {
  final bool icebreakerSuggestionsEnabled;
  final bool personalizedIcebreakersEnabled;
  final bool contextualIcebreakersEnabled;
  final bool icebreakerAnalyticsEnabled;
  final String icebreakerStyle;
  final int maxIcebreakers;

  const AiIcebreakerSettings({
    this.icebreakerSuggestionsEnabled = false,
    this.personalizedIcebreakersEnabled = false,
    this.contextualIcebreakersEnabled = false,
    this.icebreakerAnalyticsEnabled = false,
    this.icebreakerStyle = 'casual',
    this.maxIcebreakers = 5,
  });

  factory AiIcebreakerSettings.fromJson(Map<String, dynamic> json) {
    return AiIcebreakerSettings(
      icebreakerSuggestionsEnabled:
          json['icebreakerSuggestionsEnabled'] ?? false,
      personalizedIcebreakersEnabled:
          json['personalizedIcebreakersEnabled'] ?? false,
      contextualIcebreakersEnabled:
          json['contextualIcebreakersEnabled'] ?? false,
      icebreakerAnalyticsEnabled: json['icebreakerAnalyticsEnabled'] ?? false,
      icebreakerStyle: json['icebreakerStyle'] ?? 'casual',
      maxIcebreakers: json['maxIcebreakers'] ?? 5,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'icebreakerSuggestionsEnabled': icebreakerSuggestionsEnabled,
      'personalizedIcebreakersEnabled': personalizedIcebreakersEnabled,
      'contextualIcebreakersEnabled': contextualIcebreakersEnabled,
      'icebreakerAnalyticsEnabled': icebreakerAnalyticsEnabled,
      'icebreakerStyle': icebreakerStyle,
      'maxIcebreakers': maxIcebreakers,
    };
  }

  AiIcebreakerSettings copyWith({
    bool? icebreakerSuggestionsEnabled,
    bool? personalizedIcebreakersEnabled,
    bool? contextualIcebreakersEnabled,
    bool? icebreakerAnalyticsEnabled,
    String? icebreakerStyle,
    int? maxIcebreakers,
  }) {
    return AiIcebreakerSettings(
      icebreakerSuggestionsEnabled:
          icebreakerSuggestionsEnabled ?? this.icebreakerSuggestionsEnabled,
      personalizedIcebreakersEnabled:
          personalizedIcebreakersEnabled ?? this.personalizedIcebreakersEnabled,
      contextualIcebreakersEnabled:
          contextualIcebreakersEnabled ?? this.contextualIcebreakersEnabled,
      icebreakerAnalyticsEnabled:
          icebreakerAnalyticsEnabled ?? this.icebreakerAnalyticsEnabled,
      icebreakerStyle: icebreakerStyle ?? this.icebreakerStyle,
      maxIcebreakers: maxIcebreakers ?? this.maxIcebreakers,
    );
  }

  @override
  List<Object?> get props => [
    icebreakerSuggestionsEnabled,
    personalizedIcebreakersEnabled,
    contextualIcebreakersEnabled,
    icebreakerAnalyticsEnabled,
    icebreakerStyle,
    maxIcebreakers,
  ];
}

/// General AI settings
class AiGeneralSettings extends Equatable {
  final bool dataCollectionConsent;
  final bool personalizedExperienceEnabled;
  final bool aiLearningEnabled;
  final bool analyticsEnabled;
  final String privacyLevel;
  final bool shareAnonymousUsage;

  const AiGeneralSettings({
    this.dataCollectionConsent = false,
    this.personalizedExperienceEnabled = false,
    this.aiLearningEnabled = false,
    this.analyticsEnabled = false,
    this.privacyLevel = 'standard',
    this.shareAnonymousUsage = false,
  });

  factory AiGeneralSettings.fromJson(Map<String, dynamic> json) {
    return AiGeneralSettings(
      dataCollectionConsent: json['dataCollectionConsent'] ?? false,
      personalizedExperienceEnabled:
          json['personalizedExperienceEnabled'] ?? false,
      aiLearningEnabled: json['aiLearningEnabled'] ?? false,
      analyticsEnabled: json['analyticsEnabled'] ?? false,
      privacyLevel: json['privacyLevel'] ?? 'standard',
      shareAnonymousUsage: json['shareAnonymousUsage'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dataCollectionConsent': dataCollectionConsent,
      'personalizedExperienceEnabled': personalizedExperienceEnabled,
      'aiLearningEnabled': aiLearningEnabled,
      'analyticsEnabled': analyticsEnabled,
      'privacyLevel': privacyLevel,
      'shareAnonymousUsage': shareAnonymousUsage,
    };
  }

  AiGeneralSettings copyWith({
    bool? dataCollectionConsent,
    bool? personalizedExperienceEnabled,
    bool? aiLearningEnabled,
    bool? analyticsEnabled,
    String? privacyLevel,
    bool? shareAnonymousUsage,
  }) {
    return AiGeneralSettings(
      dataCollectionConsent:
          dataCollectionConsent ?? this.dataCollectionConsent,
      personalizedExperienceEnabled:
          personalizedExperienceEnabled ?? this.personalizedExperienceEnabled,
      aiLearningEnabled: aiLearningEnabled ?? this.aiLearningEnabled,
      analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
      privacyLevel: privacyLevel ?? this.privacyLevel,
      shareAnonymousUsage: shareAnonymousUsage ?? this.shareAnonymousUsage,
    );
  }

  @override
  List<Object?> get props => [
    dataCollectionConsent,
    personalizedExperienceEnabled,
    aiLearningEnabled,
    analyticsEnabled,
    privacyLevel,
    shareAnonymousUsage,
  ];
}
