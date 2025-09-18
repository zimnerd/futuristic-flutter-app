import 'dart:async';

import 'package:logger/logger.dart';
import 'package:pulse_dating_app/data/models/ai_profile_models.dart';
import 'package:pulse_dating_app/domain/entities/user_profile.dart';
import 'package:pulse_dating_app/core/network/api_client.dart';

/// AI-powered profile analysis service that connects to backend LLM
/// ALL AI analysis is performed by backend - no frontend AI generation
class AiProfileAnalysisService {
  static AiProfileAnalysisService? _instance;
  static AiProfileAnalysisService get instance => 
      _instance ??= AiProfileAnalysisService._();
  AiProfileAnalysisService._();

  final ApiClient _apiClient = ApiClient.instance;
  final Logger logger = Logger();

  /// Get AI-powered profile analysis from backend
  Future<AiProfileAnalysisResponse?> analyzeProfile({
    required UserProfile profile,
    String analysisType = 'comprehensive',
    Map<String, dynamic>? context,
  }) async {
    try {
      final response = await _apiClient.analyzeProfile(
        profileId: profile.id,
        analysisType: analysisType,
      );

      if (response.statusCode == 200 && response.data != null) {
        return _parseProfileAnalysisResponse(profile.id, response.data);
      } else {
        throw Exception('Failed to analyze profile: ${response.statusMessage}');
      }
    } catch (e) {
      logger.e('Error analyzing profile: $e');
      rethrow;
    }
  }

  /// Parse API response into AiProfileAnalysisResponse
  AiProfileAnalysisResponse _parseProfileAnalysisResponse(
    String profileId,
    Map<String, dynamic> apiData,
  ) {
    final analysis = apiData['analysis'] ?? {};

    return AiProfileAnalysisResponse(
      requestId: 'profile_analysis_$profileId',
      analysisType: 'comprehensive',
      score: AiProfileScore(
        overall: (analysis['overallScore'] ?? 0.8).toDouble(),
        attractiveness: (analysis['attractivenessScore'] ?? 0.7).toDouble(),
        completeness: (analysis['completenessScore'] ?? 0.9).toDouble(),
        authenticity: (analysis['authenticityScore'] ?? 0.8).toDouble(),
        approachability: (analysis['approachabilityScore'] ?? 0.7).toDouble(),
        categoryScores: Map<String, double>.from(
          analysis['categoryScores'] ?? {},
        ),
        summary:
            analysis['summary'] ??
            'Overall profile shows good potential for connections',
      ),
      improvements: _parseProfileImprovements(analysis),
      conversationStarters: _parseConversationStarters(analysis),
      imageInsights: _parseImageInsights(analysis),
      compatibilityAssessment: null,
      confidence: (analysis['confidence'] ?? 0.85).toDouble(),
      generatedAt: DateTime.now(),
    );
  }

  /// Parse profile improvements from API response
  List<AiProfileImprovement> _parseProfileImprovements(
    Map<String, dynamic> analysis,
  ) {
    final improvements = analysis['improvements'] ?? [];
    return List.generate(
      improvements.length.clamp(0, 5),
      (index) => AiProfileImprovement(
        id: 'improvement_$index',
        category: 'general',
        priority: 'medium',
        title: 'Profile Enhancement',
        description: improvements[index].toString(),
        suggestion: improvements[index].toString(),
        reasoning: 'AI-generated improvement suggestion',
        impact: 0.7,
        examples: const ['Follow the suggestion'],
      ),
    );
  }

  /// Parse conversation starters from API response
  List<AiConversationStarter> _parseConversationStarters(
    Map<String, dynamic> analysis,
  ) {
    final starters = analysis['conversationStarters'] ?? [];
    return List.generate(
      starters.length.clamp(0, 5),
      (index) => AiConversationStarter(
        id: 'starter_$index',
        message: starters[index].toString(),
        category: 'general',
        confidence: 0.8,
        reasoning: 'Based on profile analysis',
        basedOn: const ['profile'],
        followUp: null,
      ),
    );
  }

  /// Parse image insights from API response
  List<AiImageInsight> _parseImageInsights(Map<String, dynamic> analysis) {
    final insights = analysis['imageInsights'] ?? [];
    return List.generate(
      insights.length.clamp(0, 3),
      (index) => AiImageInsight(
        imageId: 'image_$index',
        analysis: insights[index].toString(),
        detectedElements: const ['profile photo'],
        suggestions: const ['Good photo'],
        quality: 0.8,
        attributes: const {'quality': 0.8},
        conversationStarters: const [],
      ),
    );
  }

  /// Get AI-generated profile improvement suggestions from backend
  Future<List<AiProfileImprovement>> getProfileSuggestions({
    required UserProfile profile,
    String? focusArea,
    int maxSuggestions = 5,
  }) async {
    try {
      final response = await _apiClient.analyzeProfile(
        profileId: profile.id,
        analysisType: 'improvement',
      );

      if (response.statusCode == 200 && response.data != null) {
        return _parseProfileImprovements(response.data['analysis'] ?? {});
      } else {
        throw Exception(
          'Failed to get profile suggestions: ${response.statusMessage}',
        );
      }
    } catch (e) {
      logger.e('Error getting profile suggestions: $e');
      rethrow;
    }
  }

  /// Get AI photo analysis and suggestions from backend
  Future<List<AiImageInsight>> analyzePhotos({
    required List<String> photoUrls,
    required String userId,
    Map<String, dynamic>? context,
  }) async {
    try {
      final response = await _apiClient.analyzePhotos(
        photoUrls: photoUrls,
        analysisType: 'comprehensive',
      );

      if (response.statusCode == 200 && response.data != null) {
        return _parseImageInsights(response.data['analysis'] ?? {});
      } else {
        throw Exception('Failed to analyze photos: ${response.statusMessage}');
      }
    } catch (e) {
      logger.e('Error analyzing photos: $e');
      rethrow;
    }
  }

  /// Get AI-powered compatibility assessment from backend
  Future<AiCompatibilityAssessment?> getCompatibilityAssessment({
    required UserProfile profile,
    required UserProfile targetProfile,
    Map<String, dynamic>? context,
  }) async {
    try {
      final response = await _apiClient.analyzeProfileCompatibility(
        profileId: profile.id,
        analysisType: 'compatibility',
        context: {...?context, 'targetProfileId': targetProfile.id},
      );

      if (response.statusCode == 200 && response.data != null) {
        return _parseCompatibilityAssessment(response.data['analysis'] ?? {});
      } else {
        throw Exception(
          'Failed to get compatibility assessment: ${response.statusMessage}',
        );
      }
    } catch (e) {
      logger.e('Error getting compatibility assessment: $e');
      rethrow;
    }
  }

  /// Parse compatibility assessment from API response
  AiCompatibilityAssessment _parseCompatibilityAssessment(
    Map<String, dynamic> analysis,
  ) {
    return AiCompatibilityAssessment(
      overallScore: (analysis['overallScore'] ?? 0.7).toDouble(),
      categoryScores: Map<String, double>.from(
        analysis['categoryScores'] ?? {},
      ),
      strengths: const [],
      concerns: const [],
      conversationTopics: List<String>.from(
        analysis['conversationTopics'] ?? [],
      ),
      summary: analysis['summary'] ?? 'Good compatibility potential',
      recommendation: analysis['recommendation'] ?? 'Proceed with conversation',
    );
  }
}