import 'dart:async';

import 'package:pulse_dating_app/data/models/ai_profile_models.dart';
import 'package:pulse_dating_app/domain/entities/user_profile.dart';

/// AI-powered profile analysis service that connects to backend LLM
/// ALL AI analysis is performed by backend - no frontend AI generation
class AiProfileAnalysisService {
  static AiProfileAnalysisService? _instance;
  static AiProfileAnalysisService get instance => 
      _instance ??= AiProfileAnalysisService._();
  AiProfileAnalysisService._();

  // TODO: Replace with actual API service when available
  // final ApiService _apiService = ServiceLocator.instance.apiClient;

  /// Get AI-powered profile analysis from backend
  Future<AiProfileAnalysisResponse?> analyzeProfile({
    required UserProfile profile,
    String analysisType = 'comprehensive',
    Map<String, dynamic>? context,
  }) async {
    try {
      // Mock response for development - replace with actual API call
      return _getMockProfileAnalysis(profile.id, analysisType);
    } catch (e) {
      print('Error analyzing profile: $e');
      return null;
    }
  }

  /// Get AI-generated profile improvement suggestions from backend
  Future<List<AiProfileImprovement>> getProfileSuggestions({
    required UserProfile profile,
    String? focusArea,
    int maxSuggestions = 5,
  }) async {
    try {
      // Mock suggestions for development - replace with actual API call
      return _getMockProfileSuggestions(maxSuggestions);
    } catch (e) {
      print('Error getting profile suggestions: $e');
      return _getEmergencyProfileSuggestions(maxSuggestions);
    }
  }

  /// Get AI photo analysis and suggestions from backend
  Future<List<AiImageInsight>> analyzePhotos({
    required List<String> photoUrls,
    required String userId,
    Map<String, dynamic>? context,
  }) async {
    try {
      // Mock photo analysis for development - replace with actual API call
      return _getMockImageInsights();
    } catch (e) {
      print('Error analyzing photos: $e');
      return [];
    }
  }

  /// Get AI-powered compatibility assessment from backend
  Future<AiCompatibilityAssessment?> getCompatibilityAssessment({
    required UserProfile profile,
    required UserProfile targetProfile,
    Map<String, dynamic>? context,
  }) async {
    try {
      // Mock compatibility analysis for development - replace with actual API call
      return _getMockCompatibilityAssessment();
    } catch (e) {
      print('Error getting compatibility assessment: $e');
      return null;
    }
  }

  // Mock data for development

  AiProfileAnalysisResponse _getMockProfileAnalysis(String profileId, String analysisType) {
    return AiProfileAnalysisResponse(
      requestId: 'profile_analysis_$profileId',
      analysisType: analysisType,
      score: _getMockProfileScore(),
      improvements: _getMockProfileSuggestions(3),
      conversationStarters: _getMockConversationStarters(),
      imageInsights: _getMockImageInsights(),
      compatibilityAssessment: null,
      confidence: 0.85,
      generatedAt: DateTime.now(),
    );
  }

  AiProfileScore _getMockProfileScore() {
    return const AiProfileScore(
      overall: 0.82,
      attractiveness: 0.78,
      completeness: 0.90,
      authenticity: 0.85,
      approachability: 0.75,
      categoryScores: {
        'bio': 0.8,
        'photos': 0.7,
        'interests': 0.9,
        'personality': 0.8,
      },
      summary: 'Your profile shows great personality with room for photo improvements',
    );
  }

  List<AiProfileImprovement> _getMockProfileSuggestions(int maxSuggestions) {
    final suggestions = [
      const AiProfileImprovement(
        id: 'suggestion_1',
        category: 'bio',
        priority: 'high',
        title: 'Add Personal Touch',
        description: 'Your bio could use more personality',
        suggestion: 'Add a fun fact about yourself to make your profile more memorable',
        reasoning: 'Profiles with unique personal details get 40% more matches',
        impact: 0.3,
        examples: ['I collect vintage postcards', 'I can solve a Rubik\'s cube in under 2 minutes'],
      ),
      const AiProfileImprovement(
        id: 'suggestion_2',
        category: 'photos',
        priority: 'medium',
        title: 'Show Your Hobbies',
        description: 'Activity photos are missing',
        suggestion: 'Consider adding a photo that shows your hobbies or interests',
        reasoning: 'Activity photos help show your personality and lifestyle',
        impact: 0.25,
        examples: ['Hiking photo', 'Cooking in kitchen', 'Playing an instrument'],
      ),
      const AiProfileImprovement(
        id: 'suggestion_3',
        category: 'interests',
        priority: 'medium',
        title: 'Be More Specific',
        description: 'General interests need detail',
        suggestion: 'Add more specific interests to help with matching',
        reasoning: 'Detailed interests improve match quality and conversation starters',
        impact: 0.2,
        examples: ['Instead of "music", try "indie rock concerts"'],
      ),
    ];
    
    return suggestions.take(maxSuggestions).toList();
  }

  List<AiConversationStarter> _getMockConversationStarters() {
    return [
      const AiConversationStarter(
        id: 'starter_1',
        message: 'I noticed you love hiking - what\'s the best trail you\'ve discovered?',
        category: 'interests',
        reasoning: 'Based on hiking photos and interests',
        confidence: 0.9,
        basedOn: ['photos', 'interests'],
      ),
      const AiConversationStarter(
        id: 'starter_2',
        message: 'Your travel photos look amazing! What\'s next on your bucket list?',
        category: 'lifestyle',
        reasoning: 'Multiple travel photos suggest love of adventure',
        confidence: 0.8,
        basedOn: ['photos'],
      ),
    ];
  }

  List<AiImageInsight> _getMockImageInsights() {
    return [
      AiImageInsight(
        imageId: 'mock_image_1',
        analysis: 'Shows outdoor activity and adventure spirit',
        detectedElements: ['hiking', 'outdoors', 'active'],
        suggestions: [
          'Great activity photo that shows your adventurous side',
          'Good lighting and composition'
        ],
        quality: 0.9,
        attributes: {
          'lighting': 0.9,
          'composition': 0.8,
          'smile': 0.7,
          'eye_contact': 0.6,
        },
        conversationStarters: [
          const AiConversationStarter(
            id: 'starter_img_1',
            message: 'I love hiking too! What\'s your favorite trail?',
            category: 'activity',
            reasoning: 'Based on hiking photo',
            confidence: 0.9,
            basedOn: ['photo_activity'],
          ),
          const AiConversationStarter(
            id: 'starter_img_2',
            message: 'That view looks incredible - where was this taken?',
            category: 'location',
            reasoning: 'Based on scenic background',
            confidence: 0.8,
            basedOn: ['photo_location'],
          ),
        ],
      ),
    ];
  }

  AiCompatibilityAssessment _getMockCompatibilityAssessment() {
    return const AiCompatibilityAssessment(
      overallScore: 0.75,
      categoryScores: {
        'interests': 0.8,
        'lifestyle': 0.6,
        'personality': 0.7,
        'values': 0.8,
      },
      strengths: [
        AiCompatibilityStrength(
          category: 'interests',
          description: 'Both enjoy outdoor activities',
          impact: 0.8,
          evidence: [
            'Both have hiking photos',
            'Similar adventure preferences',
            'Love for nature activities'
          ],
        ),
      ],
      concerns: [
        AiCompatibilityConcern(
          category: 'lifestyle',
          description: 'Different social preferences',
          severity: 'low',
          impact: 0.3,
          evidence: [
            'One prefers large groups, other small gatherings',
            'Different weekend activity patterns'
          ],
          mitigation: 'Find middle ground for social activities',
        ),
      ],
      conversationTopics: [
        'Outdoor adventures and hiking',
        'Travel experiences',
        'Favorite nature spots',
        'Weekend activity preferences'
      ],
      summary: 'Good compatibility with shared outdoor interests',
      recommendation: 'Focus conversations on shared outdoor activities and adventure planning',
    );
  }

  List<AiProfileImprovement> _getEmergencyProfileSuggestions(int maxSuggestions) {
    final emergencySuggestions = [
      'Add more details to your bio',
      'Upload additional photos',
      'Update your interests',
      'Add conversation starters',
      'Be more specific about your hobbies',
    ];

    return emergencySuggestions
        .take(maxSuggestions)
        .toList()
        .asMap()
        .entries
        .map((entry) => AiProfileImprovement(
              id: 'emergency_${entry.key}',
              category: 'general',
              priority: 'medium',
              title: 'General Improvement',
              description: 'Profile enhancement suggestion',
              suggestion: entry.value,
              reasoning: 'General profile improvement',
              impact: 0.1,
            ))
        .toList();
  }
}