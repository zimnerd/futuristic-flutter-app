/// Compatibility analysis between users
class CompatibilityAnalysis {
  final String userId1;
  final String userId2;
  final CompatibilityScore score;
  final List<CompatibilityFactor> factors;
  final List<CompatibilityInsight> insights;
  final DateTime analyzedAt;

  const CompatibilityAnalysis({
    required this.userId1,
    required this.userId2,
    required this.score,
    required this.factors,
    required this.insights,
    required this.analyzedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId1': userId1,
      'userId2': userId2,
      'score': score.toJson(),
      'factors': factors.map((f) => f.toJson()).toList(),
      'insights': insights.map((i) => i.toJson()).toList(),
      'analyzedAt': analyzedAt.toIso8601String(),
    };
  }

  factory CompatibilityAnalysis.fromJson(Map<String, dynamic> json) {
    return CompatibilityAnalysis(
      userId1: json['userId1'],
      userId2: json['userId2'],
      score: CompatibilityScore.fromJson(json['score']),
      factors: (json['factors'] as List)
          .map((f) => CompatibilityFactor.fromJson(f))
          .toList(),
      insights: (json['insights'] as List)
          .map((i) => CompatibilityInsight.fromJson(i))
          .toList(),
      analyzedAt: DateTime.parse(json['analyzedAt']),
    );
  }
}

/// Detailed compatibility scoring
class CompatibilityScore {
  final double overall; // 0.0 to 1.0
  final double communicationStyle;
  final double interests;
  final double values;
  final double humor;
  final double pace;
  final String explanation;

  const CompatibilityScore({
    required this.overall,
    required this.communicationStyle,
    required this.interests,
    required this.values,
    required this.humor,
    required this.pace,
    required this.explanation,
  });

  /// Get compatibility level description
  String get levelDescription {
    if (overall >= 0.9) return 'Exceptional Match';
    if (overall >= 0.8) return 'Highly Compatible';
    if (overall >= 0.7) return 'Very Compatible';
    if (overall >= 0.6) return 'Good Compatibility';
    if (overall >= 0.5) return 'Moderate Compatibility';
    if (overall >= 0.4) return 'Limited Compatibility';
    return 'Low Compatibility';
  }

  /// Get compatibility percentage
  int get percentage => (overall * 100).round();

  Map<String, dynamic> toJson() {
    return {
      'overall': overall,
      'communicationStyle': communicationStyle,
      'interests': interests,
      'values': values,
      'humor': humor,
      'pace': pace,
      'explanation': explanation,
    };
  }

  factory CompatibilityScore.fromJson(Map<String, dynamic> json) {
    return CompatibilityScore(
      overall: json['overall'],
      communicationStyle: json['communicationStyle'],
      interests: json['interests'],
      values: json['values'],
      humor: json['humor'],
      pace: json['pace'],
      explanation: json['explanation'],
    );
  }
}

/// Individual compatibility factors
class CompatibilityFactor {
  final FactorType type;
  final String name;
  final double score; // 0.0 to 1.0
  final String description;
  final List<String> positives;
  final List<String> concerns;

  const CompatibilityFactor({
    required this.type,
    required this.name,
    required this.score,
    required this.description,
    required this.positives,
    required this.concerns,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString().split('.').last,
      'name': name,
      'score': score,
      'description': description,
      'positives': positives,
      'concerns': concerns,
    };
  }

  factory CompatibilityFactor.fromJson(Map<String, dynamic> json) {
    return CompatibilityFactor(
      type: FactorType.values.firstWhere(
        (t) => t.toString().split('.').last == json['type'],
      ),
      name: json['name'],
      score: json['score'],
      description: json['description'],
      positives: List<String>.from(json['positives']),
      concerns: List<String>.from(json['concerns']),
    );
  }
}

/// Types of compatibility factors
enum FactorType {
  communication,
  interests,
  lifestyle,
  personalValues,
  personality,
  goals,
  humor,
  emotional,
}

/// Compatibility insights and recommendations
class CompatibilityInsight {
  final InsightCategory category;
  final String title;
  final String description;
  final InsightLevel level;
  final List<String> recommendations;

  const CompatibilityInsight({
    required this.category,
    required this.title,
    required this.description,
    required this.level,
    required this.recommendations,
  });

  Map<String, dynamic> toJson() {
    return {
      'category': category.toString().split('.').last,
      'title': title,
      'description': description,
      'level': level.toString().split('.').last,
      'recommendations': recommendations,
    };
  }

  factory CompatibilityInsight.fromJson(Map<String, dynamic> json) {
    return CompatibilityInsight(
      category: InsightCategory.values.firstWhere(
        (c) => c.toString().split('.').last == json['category'],
      ),
      title: json['title'],
      description: json['description'],
      level: InsightLevel.values.firstWhere(
        (l) => l.toString().split('.').last == json['level'],
      ),
      recommendations: List<String>.from(json['recommendations']),
    );
  }
}

/// Categories of compatibility insights
enum InsightCategory { strength, opportunity, challenge, warning }

/// Levels of insight importance
enum InsightLevel { low, medium, high, critical }

/// Personality compatibility analysis
class PersonalityCompatibility {
  final Map<String, double> traitScores;
  final double overallScore;
  final List<String> compatibleTraits;
  final List<String> conflictingTraits;
  final String summary;

  const PersonalityCompatibility({
    required this.traitScores,
    required this.overallScore,
    required this.compatibleTraits,
    required this.conflictingTraits,
    required this.summary,
  });

  Map<String, dynamic> toJson() {
    return {
      'traitScores': traitScores,
      'overallScore': overallScore,
      'compatibleTraits': compatibleTraits,
      'conflictingTraits': conflictingTraits,
      'summary': summary,
    };
  }

  factory PersonalityCompatibility.fromJson(Map<String, dynamic> json) {
    return PersonalityCompatibility(
      traitScores: Map<String, double>.from(json['traitScores']),
      overallScore: json['overallScore'],
      compatibleTraits: List<String>.from(json['compatibleTraits']),
      conflictingTraits: List<String>.from(json['conflictingTraits']),
      summary: json['summary'],
    );
  }
}

/// Lifestyle compatibility factors
class LifestyleCompatibility {
  final double scheduleAlignment;
  final double socialPreferences;
  final double activityLevel;
  final double communicationFrequency;
  final List<String> sharedActivities;
  final List<String> potentialConflicts;

  const LifestyleCompatibility({
    required this.scheduleAlignment,
    required this.socialPreferences,
    required this.activityLevel,
    required this.communicationFrequency,
    required this.sharedActivities,
    required this.potentialConflicts,
  });

  Map<String, dynamic> toJson() {
    return {
      'scheduleAlignment': scheduleAlignment,
      'socialPreferences': socialPreferences,
      'activityLevel': activityLevel,
      'communicationFrequency': communicationFrequency,
      'sharedActivities': sharedActivities,
      'potentialConflicts': potentialConflicts,
    };
  }

  factory LifestyleCompatibility.fromJson(Map<String, dynamic> json) {
    return LifestyleCompatibility(
      scheduleAlignment: json['scheduleAlignment'],
      socialPreferences: json['socialPreferences'],
      activityLevel: json['activityLevel'],
      communicationFrequency: json['communicationFrequency'],
      sharedActivities: List<String>.from(json['sharedActivities']),
      potentialConflicts: List<String>.from(json['potentialConflicts']),
    );
  }
}
