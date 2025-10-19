import 'package:equatable/equatable.dart';

/// Request model for AI profile analysis
class AiProfileAnalysisRequest extends Equatable {
  final String userId;
  final String profileId;
  final AiUserProfileData profile;
  final String
  analysisType; // 'improvement', 'conversation_starters', 'compatibility'
  final AiUserProfileData? targetProfile; // For compatibility analysis
  final List<String>? images; // For image analysis
  final Map<String, dynamic>? context;

  const AiProfileAnalysisRequest({
    required this.userId,
    required this.profileId,
    required this.profile,
    required this.analysisType,
    this.targetProfile,
    this.images,
    this.context,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'profileId': profileId,
      'profile': profile.toJson(),
      'analysisType': analysisType,
      'targetProfile': targetProfile?.toJson(),
      'images': images,
      'context': context,
    };
  }

  @override
  List<Object?> get props => [
    userId,
    profileId,
    profile,
    analysisType,
    targetProfile,
    images,
    context,
  ];
}

/// User profile data for AI analysis
class AiUserProfileData extends Equatable {
  final String id;
  final String name;
  final int age;
  final String? bio;
  final List<String> interests;
  final List<AiPhotoData> photos;
  final Map<String, dynamic>? preferences;
  final Map<String, dynamic>? personality;
  final String? occupation;
  final String? education;
  final String? location;

  const AiUserProfileData({
    required this.id,
    required this.name,
    required this.age,
    this.bio,
    this.interests = const [],
    this.photos = const [],
    this.preferences,
    this.personality,
    this.occupation,
    this.education,
    this.location,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'bio': bio,
      'interests': interests,
      'photos': photos.map((p) => p.toJson()).toList(),
      'preferences': preferences,
      'personality': personality,
      'occupation': occupation,
      'education': education,
      'location': location,
    };
  }

  factory AiUserProfileData.fromJson(Map<String, dynamic> json) {
    return AiUserProfileData(
      id: json['id'],
      name: json['name'],
      age: json['age'],
      bio: json['bio'],
      interests: List<String>.from(json['interests'] ?? []),
      photos:
          (json['photos'] as List?)
              ?.map((p) => AiPhotoData.fromJson(p))
              .toList() ??
          [],
      preferences: json['preferences'],
      personality: json['personality'],
      occupation: json['occupation'],
      education: json['education'],
      location: json['location'],
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
    occupation,
    education,
    location,
  ];
}

/// Photo data for AI analysis
class AiPhotoData extends Equatable {
  final String id;
  final String url;
  final String? description;
  final Map<String, dynamic>? metadata;
  final bool isPrimary;

  const AiPhotoData({
    required this.id,
    required this.url,
    this.description,
    this.metadata,
    this.isPrimary = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'description': description,
      'metadata': metadata,
      'isPrimary': isPrimary,
    };
  }

  factory AiPhotoData.fromJson(Map<String, dynamic> json) {
    return AiPhotoData(
      id: json['id'],
      url: json['url'],
      description: json['description'],
      metadata: json['metadata'],
      isPrimary: json['isPrimary'] ?? false,
    );
  }

  @override
  List<Object?> get props => [id, url, description, metadata, isPrimary];
}

/// Response model for AI profile analysis
class AiProfileAnalysisResponse extends Equatable {
  final String requestId;
  final String analysisType;
  final AiProfileScore score;
  final List<AiProfileImprovement> improvements;
  final List<AiConversationStarter> conversationStarters;
  final List<AiImageInsight> imageInsights;
  final AiCompatibilityAssessment? compatibilityAssessment;
  final double confidence;
  final DateTime generatedAt;

  const AiProfileAnalysisResponse({
    required this.requestId,
    required this.analysisType,
    required this.score,
    required this.improvements,
    required this.conversationStarters,
    required this.imageInsights,
    this.compatibilityAssessment,
    required this.confidence,
    required this.generatedAt,
  });

  factory AiProfileAnalysisResponse.fromJson(Map<String, dynamic> json) {
    return AiProfileAnalysisResponse(
      requestId: json['requestId'],
      analysisType: json['analysisType'],
      score: AiProfileScore.fromJson(json['score']),
      improvements: (json['improvements'] as List)
          .map((i) => AiProfileImprovement.fromJson(i))
          .toList(),
      conversationStarters: (json['conversationStarters'] as List)
          .map((c) => AiConversationStarter.fromJson(c))
          .toList(),
      imageInsights: (json['imageInsights'] as List)
          .map((i) => AiImageInsight.fromJson(i))
          .toList(),
      compatibilityAssessment: json['compatibilityAssessment'] != null
          ? AiCompatibilityAssessment.fromJson(json['compatibilityAssessment'])
          : null,
      confidence: json['confidence'].toDouble(),
      generatedAt: DateTime.parse(json['generatedAt']),
    );
  }

  @override
  List<Object?> get props => [
    requestId,
    analysisType,
    score,
    improvements,
    conversationStarters,
    imageInsights,
    compatibilityAssessment,
    confidence,
    generatedAt,
  ];
}

/// AI-generated profile score
class AiProfileScore extends Equatable {
  final double overall; // 0.0 to 1.0
  final double attractiveness;
  final double completeness;
  final double authenticity;
  final double approachability;
  final Map<String, double> categoryScores;
  final String summary;

  const AiProfileScore({
    required this.overall,
    required this.attractiveness,
    required this.completeness,
    required this.authenticity,
    required this.approachability,
    required this.categoryScores,
    required this.summary,
  });

  factory AiProfileScore.fromJson(Map<String, dynamic> json) {
    return AiProfileScore(
      overall: json['overall'].toDouble(),
      attractiveness: json['attractiveness'].toDouble(),
      completeness: json['completeness'].toDouble(),
      authenticity: json['authenticity'].toDouble(),
      approachability: json['approachability'].toDouble(),
      categoryScores: Map<String, double>.from(json['categoryScores']),
      summary: json['summary'],
    );
  }

  @override
  List<Object?> get props => [
    overall,
    attractiveness,
    completeness,
    authenticity,
    approachability,
    categoryScores,
    summary,
  ];
}

/// AI-generated profile improvement suggestion
class AiProfileImprovement extends Equatable {
  final String id;
  final String category; // 'bio', 'photos', 'interests', 'general'
  final String priority; // 'high', 'medium', 'low'
  final String title;
  final String description;
  final String suggestion;
  final String reasoning;
  final double impact; // Expected improvement score 0.0 to 1.0
  final List<String>? examples;

  const AiProfileImprovement({
    required this.id,
    required this.category,
    required this.priority,
    required this.title,
    required this.description,
    required this.suggestion,
    required this.reasoning,
    required this.impact,
    this.examples,
  });

  factory AiProfileImprovement.fromJson(Map<String, dynamic> json) {
    return AiProfileImprovement(
      id: json['id'],
      category: json['category'],
      priority: json['priority'],
      title: json['title'],
      description: json['description'],
      suggestion: json['suggestion'],
      reasoning: json['reasoning'],
      impact: json['impact'].toDouble(),
      examples: json['examples'] != null
          ? List<String>.from(json['examples'])
          : null,
    );
  }

  @override
  List<Object?> get props => [
    id,
    category,
    priority,
    title,
    description,
    suggestion,
    reasoning,
    impact,
    examples,
  ];
}

/// AI-generated conversation starter
class AiConversationStarter extends Equatable {
  final String id;
  final String message;
  final String category; // 'interests', 'photos', 'personality', 'lifestyle'
  final String reasoning;
  final double confidence;
  final List<String> basedOn; // What profile elements it's based on
  final String? followUp;

  const AiConversationStarter({
    required this.id,
    required this.message,
    required this.category,
    required this.reasoning,
    required this.confidence,
    required this.basedOn,
    this.followUp,
  });

  factory AiConversationStarter.fromJson(Map<String, dynamic> json) {
    return AiConversationStarter(
      id: json['id'],
      message: json['message'],
      category: json['category'],
      reasoning: json['reasoning'],
      confidence: json['confidence'].toDouble(),
      basedOn: List<String>.from(json['basedOn']),
      followUp: json['followUp'],
    );
  }

  @override
  List<Object?> get props => [
    id,
    message,
    category,
    reasoning,
    confidence,
    basedOn,
    followUp,
  ];
}

/// AI analysis of profile images
class AiImageInsight extends Equatable {
  final String imageId;
  final String analysis;
  final List<String> detectedElements;
  final List<String> suggestions;
  final double quality; // 0.0 to 1.0
  final Map<String, double> attributes; // smile, eye_contact, lighting, etc.
  final List<AiConversationStarter> conversationStarters;

  const AiImageInsight({
    required this.imageId,
    required this.analysis,
    required this.detectedElements,
    required this.suggestions,
    required this.quality,
    required this.attributes,
    required this.conversationStarters,
  });

  factory AiImageInsight.fromJson(Map<String, dynamic> json) {
    return AiImageInsight(
      imageId: json['imageId'],
      analysis: json['analysis'],
      detectedElements: List<String>.from(json['detectedElements']),
      suggestions: List<String>.from(json['suggestions']),
      quality: json['quality'].toDouble(),
      attributes: Map<String, double>.from(json['attributes']),
      conversationStarters: (json['conversationStarters'] as List)
          .map((c) => AiConversationStarter.fromJson(c))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
    imageId,
    analysis,
    detectedElements,
    suggestions,
    quality,
    attributes,
    conversationStarters,
  ];
}

/// AI compatibility assessment between two profiles
class AiCompatibilityAssessment extends Equatable {
  final double overallScore; // 0.0 to 1.0
  final Map<String, double> categoryScores;
  final List<AiCompatibilityStrength> strengths;
  final List<AiCompatibilityConcern> concerns;
  final List<String> conversationTopics;
  final String summary;
  final String recommendation;

  const AiCompatibilityAssessment({
    required this.overallScore,
    required this.categoryScores,
    required this.strengths,
    required this.concerns,
    required this.conversationTopics,
    required this.summary,
    required this.recommendation,
  });

  factory AiCompatibilityAssessment.fromJson(Map<String, dynamic> json) {
    return AiCompatibilityAssessment(
      overallScore: json['overallScore'].toDouble(),
      categoryScores: Map<String, double>.from(json['categoryScores']),
      strengths: (json['strengths'] as List)
          .map((s) => AiCompatibilityStrength.fromJson(s))
          .toList(),
      concerns: (json['concerns'] as List)
          .map((c) => AiCompatibilityConcern.fromJson(c))
          .toList(),
      conversationTopics: List<String>.from(json['conversationTopics']),
      summary: json['summary'],
      recommendation: json['recommendation'],
    );
  }

  @override
  List<Object?> get props => [
    overallScore,
    categoryScores,
    strengths,
    concerns,
    conversationTopics,
    summary,
    recommendation,
  ];
}

/// Compatibility strength identified by AI
class AiCompatibilityStrength extends Equatable {
  final String category;
  final String description;
  final double impact;
  final List<String> evidence;

  const AiCompatibilityStrength({
    required this.category,
    required this.description,
    required this.impact,
    required this.evidence,
  });

  factory AiCompatibilityStrength.fromJson(Map<String, dynamic> json) {
    return AiCompatibilityStrength(
      category: json['category'],
      description: json['description'],
      impact: json['impact'].toDouble(),
      evidence: List<String>.from(json['evidence']),
    );
  }

  @override
  List<Object?> get props => [category, description, impact, evidence];
}

/// Compatibility concern identified by AI
class AiCompatibilityConcern extends Equatable {
  final String category;
  final String description;
  final String severity; // 'low', 'medium', 'high'
  final double impact;
  final List<String> evidence;
  final String? mitigation;

  const AiCompatibilityConcern({
    required this.category,
    required this.description,
    required this.severity,
    required this.impact,
    required this.evidence,
    this.mitigation,
  });

  factory AiCompatibilityConcern.fromJson(Map<String, dynamic> json) {
    return AiCompatibilityConcern(
      category: json['category'],
      description: json['description'],
      severity: json['severity'],
      impact: json['impact'].toDouble(),
      evidence: List<String>.from(json['evidence']),
      mitigation: json['mitigation'],
    );
  }

  @override
  List<Object?> get props => [
    category,
    description,
    severity,
    impact,
    evidence,
    mitigation,
  ];
}
