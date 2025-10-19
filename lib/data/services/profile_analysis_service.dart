import 'dart:async';
import 'package:logger/logger.dart';

import '../models/user_profile.dart';
import 'ai_preferences_service.dart';
import '../../core/services/service_locator.dart';

/// AI-powered profile analysis and enhancement service
class ProfileAnalysisService {
  static ProfileAnalysisService? _instance;
  static ProfileAnalysisService get instance =>
      _instance ??= ProfileAnalysisService._();
  ProfileAnalysisService._();

  final Logger logger = Logger();
  AiPreferencesService get _preferencesService =>
      ServiceLocator.instance.aiPreferences;

  /// Analyze a match's profile for conversation starters
  Future<List<ConversationStarter>> analyzeProfileForConversation({
    required UserProfile matchProfile,
    required UserProfile currentUserProfile,
  }) async {
    try {
      final preferences = await _preferencesService.getAiPreferences();
      if (!preferences.profile.profileOptimizationEnabled) {
        return [];
      }

      final starters = <ConversationStarter>[];

      // Analyze bio for conversation topics
      if (matchProfile.bio != null && matchProfile.bio!.isNotEmpty) {
        starters.addAll(await _analyzeBioForStarters(matchProfile.bio!));
      }

      // Analyze interests for shared topics
      starters.addAll(
        await _analyzeInterestsForStarters(
          matchProfile.interests,
          currentUserProfile.interests,
        ),
      );

      // Analyze photos for visual conversation starters
      if (matchProfile.photos.isNotEmpty) {
        starters.addAll(
          await _analyzePhotosForStarters(
            matchProfile.photos.map((photo) => photo.url).toList(),
          ),
        );
      }

      // Analyze location for local conversation topics
      if (matchProfile.location != null) {
        starters.addAll(
          await _analyzeLocationForStarters(
            matchProfile.location!,
            currentUserProfile.location,
          ),
        );
      }

      // Analyze lifestyle choices
      if (matchProfile.lifestyle.isNotEmpty) {
        starters.addAll(
          await _analyzeLifestyleForStarters(matchProfile.lifestyle),
        );
      }

      return starters
        ..sort((a, b) => b.confidence.compareTo(a.confidence))
        ..take(10).toList();
    } catch (e) {
      logger.e('Error analyzing profile for conversation: $e');
      return [];
    }
  }

  /// Get profile improvement suggestions
  Future<ProfileImprovementPlan> analyzeProfileForImprovement({
    required UserProfile userProfile,
  }) async {
    try {
      final preferences = await _preferencesService.getAiPreferences();
      if (!preferences.profile.profileOptimizationEnabled) {
        return ProfileImprovementPlan.empty();
      }

      final strengths = <ProfileStrength>[];
      final weaknesses = <ProfileWeakness>[];
      final suggestions = <ProfileSuggestion>[];

      // Analyze bio
      final bioAnalysis = _analyzeBio(userProfile.bio);
      strengths.addAll(bioAnalysis.strengths);
      weaknesses.addAll(bioAnalysis.weaknesses);
      suggestions.addAll(bioAnalysis.suggestions);

      // Analyze photos
      final photoAnalysis = _analyzePhotos(
        userProfile.photos.map((photo) => photo.url).toList(),
      );
      strengths.addAll(photoAnalysis.strengths);
      weaknesses.addAll(photoAnalysis.weaknesses);
      suggestions.addAll(photoAnalysis.suggestions);

      // Analyze interests
      final interestAnalysis = _analyzeInterests(userProfile.interests);
      strengths.addAll(interestAnalysis.strengths);
      weaknesses.addAll(interestAnalysis.weaknesses);
      suggestions.addAll(interestAnalysis.suggestions);

      // Calculate overall profile score
      final profileScore = _calculateProfileScore(userProfile);

      return ProfileImprovementPlan(
        profileScore: profileScore,
        strengths: strengths,
        weaknesses: weaknesses,
        suggestions: suggestions,
        priority: _determinePriority(profileScore),
        estimatedImpact: _estimateImpact(suggestions),
      );
    } catch (e) {
      logger.e('Error analyzing profile for improvement: $e');
      return ProfileImprovementPlan.empty();
    }
  }

  /// Analyze compatibility between two profiles
  Future<ProfileCompatibilityInsight> analyzeCompatibility({
    required UserProfile userProfile1,
    required UserProfile userProfile2,
  }) async {
    try {
      final preferences = await _preferencesService.getAiPreferences();
      if (!preferences.profile.profileOptimizationEnabled) {
        return ProfileCompatibilityInsight.empty();
      }

      // Analyze shared interests
      final sharedInterests = _findSharedInterests(userProfile1, userProfile2);
      final interestCompatibility =
          sharedInterests.length /
          (userProfile1.interests.length +
              userProfile2.interests.length -
              sharedInterests.length);

      // Analyze lifestyle compatibility
      final lifestyleCompatibility = _analyzeLifestyleCompatibility(
        userProfile1.lifestyle,
        userProfile2.lifestyle,
      );

      // Analyze personality compatibility
      final personalityCompatibility = _analyzePersonalityCompatibility(
        userProfile1.personality,
        userProfile2.personality,
      );

      // Analyze location compatibility
      final locationCompatibility = _analyzeLocationCompatibility(
        userProfile1.location,
        userProfile2.location,
      );

      // Calculate overall compatibility
      final overallScore =
          (interestCompatibility +
              lifestyleCompatibility +
              personalityCompatibility +
              locationCompatibility) /
          4;

      return ProfileCompatibilityInsight(
        overallCompatibility: overallScore,
        sharedInterests: sharedInterests,
        compatibilityFactors: [
          CompatibilityFactor(
            name: 'Interests',
            score: interestCompatibility,
            description: _generateInterestCompatibilityDescription(
              sharedInterests,
            ),
          ),
          CompatibilityFactor(
            name: 'Lifestyle',
            score: lifestyleCompatibility,
            description: _generateLifestyleCompatibilityDescription(
              userProfile1.lifestyle,
              userProfile2.lifestyle,
            ),
          ),
          CompatibilityFactor(
            name: 'Personality',
            score: personalityCompatibility,
            description: _generatePersonalityCompatibilityDescription(
              userProfile1.personality,
              userProfile2.personality,
            ),
          ),
        ],
        conversationSuggestions: await _generateCompatibilityBasedSuggestions(
          userProfile1,
          userProfile2,
          sharedInterests,
        ),
      );
    } catch (e) {
      logger.e('Error analyzing compatibility: $e');
      return ProfileCompatibilityInsight.empty();
    }
  }

  /// Analyze images for conversation ideas
  Future<List<ImageAnalysisResult>> analyzeImagesForConversation({
    required List<String> imageUrls,
  }) async {
    try {
      final preferences = await _preferencesService.getAiPreferences();
      if (!preferences.profile.profileOptimizationEnabled) {
        return [];
      }

      final results = <ImageAnalysisResult>[];

      for (final imageUrl in imageUrls) {
        final analysis = await _analyzeImage(imageUrl);
        if (analysis != null) {
          results.add(analysis);
        }
      }

      return results;
    } catch (e) {
      logger.e('Error analyzing images: $e');
      return [];
    }
  }

  /// Generate ice breakers based on profile analysis
  Future<List<String>> generateProfileBasedIceBreakers({
    required UserProfile matchProfile,
    required UserProfile currentUserProfile,
  }) async {
    try {
      final starters = await analyzeProfileForConversation(
        matchProfile: matchProfile,
        currentUserProfile: currentUserProfile,
      );

      return starters
          .where((starter) => starter.type == StarterType.iceBreaker)
          .map((starter) => starter.text)
          .take(5)
          .toList();
    } catch (e) {
      logger.e('Error generating profile-based ice breakers: $e');
      return [];
    }
  }

  // Private helper methods

  Future<List<ConversationStarter>> _analyzeBioForStarters(String bio) async {
    final starters = <ConversationStarter>[];

    // Simple keyword analysis (in real implementation, use NLP)
    final keywords = _extractKeywords(bio);

    for (final keyword in keywords) {
      starters.add(
        ConversationStarter(
          text:
              "I noticed you mentioned $keyword in your bio. Tell me more about that!",
          type: StarterType.bio,
          confidence: 0.8,
          category: StarterCategory.personal,
          context: 'Bio keyword: $keyword',
        ),
      );
    }

    return starters;
  }

  Future<List<ConversationStarter>> _analyzeInterestsForStarters(
    List<String> matchInterests,
    List<String> currentUserInterests,
  ) async {
    final starters = <ConversationStarter>[];
    final sharedInterests = _findSharedInterests(
      UserProfile(id: '1', interests: matchInterests),
      UserProfile(id: '2', interests: currentUserInterests),
    );

    for (final interest in sharedInterests) {
      starters.add(
        ConversationStarter(
          text: "I see we both love $interest! What got you started with it?",
          type: StarterType.interest,
          confidence: 0.9,
          category: StarterCategory.shared,
          context: 'Shared interest: $interest',
        ),
      );
    }

    // Also suggest unique interests
    final uniqueInterests = matchInterests
        .where((interest) => !currentUserInterests.contains(interest))
        .take(3);

    for (final interest in uniqueInterests) {
      starters.add(
        ConversationStarter(
          text: "I'd love to hear about your interest in $interest!",
          type: StarterType.interest,
          confidence: 0.7,
          category: StarterCategory.discovery,
          context: 'Unique interest: $interest',
        ),
      );
    }

    return starters;
  }

  Future<List<ConversationStarter>> _analyzePhotosForStarters(
    List<String> photos,
  ) async {
    final starters = <ConversationStarter>[];

    // Analyze photo content (placeholder implementation)
    for (int i = 0; i < photos.length && i < 3; i++) {
      final photoAnalysis = await _analyzePhoto(photos[i]);
      if (photoAnalysis != null) {
        starters.add(
          ConversationStarter(
            text: photoAnalysis.conversationStarter,
            type: StarterType.photo,
            confidence: photoAnalysis.confidence,
            category: StarterCategory.visual,
            context: 'Photo analysis: ${photoAnalysis.description}',
          ),
        );
      }
    }

    return starters;
  }

  Future<List<ConversationStarter>> _analyzeLocationForStarters(
    String matchLocation,
    String? currentUserLocation,
  ) async {
    final starters = <ConversationStarter>[];

    if (currentUserLocation != null && currentUserLocation == matchLocation) {
      starters.add(
        ConversationStarter(
          text: "Hey, a local! What's your favorite spot in $matchLocation?",
          type: StarterType.location,
          confidence: 0.8,
          category: StarterCategory.local,
          context: 'Same location: $matchLocation',
        ),
      );
    } else {
      starters.add(
        ConversationStarter(
          text: "How do you like living in $matchLocation?",
          type: StarterType.location,
          confidence: 0.6,
          category: StarterCategory.discovery,
          context: 'Different location: $matchLocation',
        ),
      );
    }

    return starters;
  }

  Future<List<ConversationStarter>> _analyzeLifestyleForStarters(
    List<String> lifestyle,
  ) async {
    final starters = <ConversationStarter>[];

    for (final choice in lifestyle.take(2)) {
      starters.add(
        ConversationStarter(
          text: "I see you're into $choice. What's that like?",
          type: StarterType.lifestyle,
          confidence: 0.7,
          category: StarterCategory.lifestyle,
          context: 'Lifestyle choice: $choice',
        ),
      );
    }

    return starters;
  }

  ProfileAnalysisResult _analyzeBio(String? bio) {
    final strengths = <ProfileStrength>[];
    final weaknesses = <ProfileWeakness>[];
    final suggestions = <ProfileSuggestion>[];

    if (bio == null || bio.isEmpty) {
      weaknesses.add(
        ProfileWeakness(
          area: 'Bio',
          description: 'No bio provided',
          impact: ImpactLevel.high,
        ),
      );
      suggestions.add(
        ProfileSuggestion(
          area: 'Bio',
          suggestion: 'Add a bio that showcases your personality and interests',
          priority: Priority.high,
          estimatedImpact: 0.8,
        ),
      );
    } else {
      if (bio.length < 50) {
        weaknesses.add(
          ProfileWeakness(
            area: 'Bio',
            description: 'Bio is too short',
            impact: ImpactLevel.medium,
          ),
        );
        suggestions.add(
          ProfileSuggestion(
            area: 'Bio',
            suggestion:
                'Expand your bio with more details about your interests and personality',
            priority: Priority.medium,
            estimatedImpact: 0.6,
          ),
        );
      } else if (bio.length > 500) {
        weaknesses.add(
          ProfileWeakness(
            area: 'Bio',
            description: 'Bio is too long',
            impact: ImpactLevel.low,
          ),
        );
        suggestions.add(
          ProfileSuggestion(
            area: 'Bio',
            suggestion: 'Consider shortening your bio to highlight key points',
            priority: Priority.low,
            estimatedImpact: 0.3,
          ),
        );
      } else {
        strengths.add(
          ProfileStrength(area: 'Bio', description: 'Good bio length'),
        );
      }
    }

    return ProfileAnalysisResult(
      strengths: strengths,
      weaknesses: weaknesses,
      suggestions: suggestions,
    );
  }

  ProfileAnalysisResult _analyzePhotos(List<String> photos) {
    final strengths = <ProfileStrength>[];
    final weaknesses = <ProfileWeakness>[];
    final suggestions = <ProfileSuggestion>[];

    if (photos.isEmpty) {
      weaknesses.add(
        ProfileWeakness(
          area: 'Photos',
          description: 'No photos uploaded',
          impact: ImpactLevel.critical,
        ),
      );
      suggestions.add(
        ProfileSuggestion(
          area: 'Photos',
          suggestion:
              'Add at least 3-5 high-quality photos that show your face and interests',
          priority: Priority.critical,
          estimatedImpact: 0.9,
        ),
      );
    } else if (photos.length < 3) {
      weaknesses.add(
        ProfileWeakness(
          area: 'Photos',
          description: 'Too few photos',
          impact: ImpactLevel.high,
        ),
      );
      suggestions.add(
        ProfileSuggestion(
          area: 'Photos',
          suggestion: 'Add more photos to give a better sense of who you are',
          priority: Priority.high,
          estimatedImpact: 0.7,
        ),
      );
    } else {
      strengths.add(
        ProfileStrength(area: 'Photos', description: 'Good number of photos'),
      );
    }

    return ProfileAnalysisResult(
      strengths: strengths,
      weaknesses: weaknesses,
      suggestions: suggestions,
    );
  }

  ProfileAnalysisResult _analyzeInterests(List<String> interests) {
    final strengths = <ProfileStrength>[];
    final weaknesses = <ProfileWeakness>[];
    final suggestions = <ProfileSuggestion>[];

    if (interests.isEmpty) {
      weaknesses.add(
        ProfileWeakness(
          area: 'Interests',
          description: 'No interests listed',
          impact: ImpactLevel.high,
        ),
      );
      suggestions.add(
        ProfileSuggestion(
          area: 'Interests',
          suggestion: 'Add interests to help matches find common ground',
          priority: Priority.high,
          estimatedImpact: 0.8,
        ),
      );
    } else if (interests.length < 3) {
      weaknesses.add(
        ProfileWeakness(
          area: 'Interests',
          description: 'Too few interests',
          impact: ImpactLevel.medium,
        ),
      );
      suggestions.add(
        ProfileSuggestion(
          area: 'Interests',
          suggestion: 'Add more interests to increase match compatibility',
          priority: Priority.medium,
          estimatedImpact: 0.6,
        ),
      );
    } else {
      strengths.add(
        ProfileStrength(
          area: 'Interests',
          description: 'Good variety of interests',
        ),
      );
    }

    return ProfileAnalysisResult(
      strengths: strengths,
      weaknesses: weaknesses,
      suggestions: suggestions,
    );
  }

  double _calculateProfileScore(UserProfile profile) {
    double score = 0.0;
    int factors = 0;

    // Bio score
    if (profile.bio != null && profile.bio!.isNotEmpty) {
      score += profile.bio!.length >= 50 && profile.bio!.length <= 500
          ? 1.0
          : 0.5;
    }
    factors++;

    // Photos score
    if (profile.photos.isNotEmpty) {
      score += profile.photos.length >= 3 ? 1.0 : profile.photos.length * 0.33;
    }
    factors++;

    // Interests score
    if (profile.interests.isNotEmpty) {
      score += profile.interests.length >= 3
          ? 1.0
          : profile.interests.length * 0.33;
    }
    factors++;

    return factors > 0 ? score / factors : 0.0;
  }

  Priority _determinePriority(double profileScore) {
    if (profileScore < 0.3) return Priority.critical;
    if (profileScore < 0.6) return Priority.high;
    if (profileScore < 0.8) return Priority.medium;
    return Priority.low;
  }

  double _estimateImpact(List<ProfileSuggestion> suggestions) {
    if (suggestions.isEmpty) return 0.0;
    return suggestions.map((s) => s.estimatedImpact).reduce((a, b) => a + b) /
        suggestions.length;
  }

  List<String> _findSharedInterests(
    UserProfile profile1,
    UserProfile profile2,
  ) {
    return profile1.interests
        .where(
          (interest) => profile2.interests.any(
            (other) => interest.toLowerCase() == other.toLowerCase(),
          ),
        )
        .toList();
  }

  double _analyzeLifestyleCompatibility(
    List<String> lifestyle1,
    List<String> lifestyle2,
  ) {
    if (lifestyle1.isEmpty && lifestyle2.isEmpty) return 0.5;
    if (lifestyle1.isEmpty || lifestyle2.isEmpty) return 0.3;

    final shared = lifestyle1.where((l) => lifestyle2.contains(l)).length;
    final total = (lifestyle1.length + lifestyle2.length - shared);
    return total > 0 ? shared / total : 0.0;
  }

  double _analyzePersonalityCompatibility(
    ProfilePersonality? personality1,
    ProfilePersonality? personality2,
  ) {
    if (personality1 == null || personality2 == null) return 0.5;

    // Simple compatibility based on personality differences
    final differences = [
      (personality1.openness - personality2.openness).abs(),
      (personality1.conscientiousness - personality2.conscientiousness).abs(),
      (personality1.extraversion - personality2.extraversion).abs(),
      (personality1.agreeableness - personality2.agreeableness).abs(),
      (personality1.neuroticism - personality2.neuroticism).abs(),
    ];

    final avgDifference =
        differences.reduce((a, b) => a + b) / differences.length;
    return 1.0 - avgDifference; // Lower differences = higher compatibility
  }

  double _analyzeLocationCompatibility(String? location1, String? location2) {
    if (location1 == null || location2 == null) return 0.5;
    if (location1 == location2) return 1.0;

    // Simple proximity analysis (would use actual geolocation in real app)
    return 0.3; // Different locations
  }

  /// Enhanced keyword extraction with filtering
  List<String> _extractKeywords(String text) {
    if (text.isEmpty) return [];

    // Common stop words to filter out
    final stopWords = {
      'the',
      'and',
      'for',
      'are',
      'but',
      'not',
      'you',
      'all',
      'can',
      'had',
      'was',
      'one',
      'our',
      'out',
      'day',
      'get',
      'has',
      'him',
      'his',
      'how',
      'its',
      'may',
      'new',
      'now',
      'old',
      'see',
      'two',
      'who',
      'boy',
      'man',
      'men',
      'way',
      'she',
      'too',
      'any',
      'use',
      'her',
      'oil',
      'sit',
      'set',
      'run',
      'big',
      'end',
      'why',
      'let',
      'say',
      'try',
      'ask',
      'that',
      'this',
      'with',
      'have',
      'from',
      'they',
      'said',
      'each',
      'which',
      'their',
      'time',
      'will',
      'about',
      'would',
      'there',
      'could',
      'other',
      'after',
      'first',
      'well',
      'water',
      'been',
      'call',
      'find',
      'long',
      'down',
      'come',
      'made',
      'part',
    };

    // Split text and clean words
    final words = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.length > 3 && !stopWords.contains(word))
        .toList();

    // Count word frequencies
    final wordCounts = <String, int>{};
    for (final word in words) {
      wordCounts[word] = (wordCounts[word] ?? 0) + 1;
    }

    // Sort by frequency and take top keywords
    final sortedWords = wordCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedWords.take(8).map((e) => e.key).toList();
  }

  /// Analyze photo with intelligent content detection
  Future<PhotoAnalysisResult?> _analyzePhoto(String photoUrl) async {
    try {
      // Extract photo context from URL or filename patterns
      final url = photoUrl.toLowerCase();

      // Determine photo category based on common patterns
      String description = 'A great photo';
      String conversationStarter = 'Tell me about this photo!';
      List<String> tags = [];
      double confidence = 0.6;

      if (url.contains('travel') ||
          url.contains('vacation') ||
          url.contains('beach')) {
        description = 'Looks like an amazing travel experience';
        conversationStarter =
            'This looks like an incredible trip! Where was this taken?';
        tags = ['travel', 'adventure', 'vacation'];
        confidence = 0.8;
      } else if (url.contains('selfie') || url.contains('portrait')) {
        description = 'A lovely portrait photo';
        conversationStarter = 'Great photo! You have a wonderful smile.';
        tags = ['portrait', 'selfie', 'personal'];
        confidence = 0.7;
      } else if (url.contains('food') || url.contains('restaurant')) {
        description = 'Delicious looking food';
        conversationStarter =
            'That looks delicious! What kind of cuisine do you enjoy?';
        tags = ['food', 'dining', 'culinary'];
        confidence = 0.8;
      } else if (url.contains('sport') ||
          url.contains('fitness') ||
          url.contains('gym')) {
        description = 'Active lifestyle photo';
        conversationStarter =
            'Love seeing someone who stays active! What\'s your favorite workout?';
        tags = ['fitness', 'sports', 'active'];
        confidence = 0.8;
      } else if (url.contains('pet') ||
          url.contains('dog') ||
          url.contains('cat')) {
        description = 'Adorable pet photo';
        conversationStarter = 'Aww, such a cute pet! What\'s their name?';
        tags = ['pets', 'animals', 'cute'];
        confidence = 0.9;
      } else if (url.contains('nature') ||
          url.contains('outdoor') ||
          url.contains('hiking')) {
        description = 'Beautiful nature photo';
        conversationStarter =
            'Beautiful scenery! Do you enjoy spending time outdoors?';
        tags = ['nature', 'outdoor', 'scenery'];
        confidence = 0.8;
      } else {
        // Generic analysis
        tags = ['lifestyle', 'personal'];
      }

      return PhotoAnalysisResult(
        description: description,
        conversationStarter: conversationStarter,
        confidence: confidence,
        tags: tags,
      );
    } catch (e) {
      return null;
    }
  }

  /// Advanced image analysis with context awareness
  Future<ImageAnalysisResult?> _analyzeImage(String imageUrl) async {
    try {
      final url = imageUrl.toLowerCase();

      // Generate multiple conversation starters based on image context
      List<String> conversationStarters = [];
      List<String> tags = [];
      String description = 'Interesting image';
      double confidence = 0.6;

      if (url.contains('group') || url.contains('friends')) {
        description = 'Fun group photo with friends';
        conversationStarters = [
          'Looks like you have great friends! How did you all meet?',
          'Group photos are the best! What was the occasion?',
          'Your friend group seems really fun to be around!',
        ];
        tags = ['friends', 'social', 'group'];
        confidence = 0.8;
      } else if (url.contains('graduation') || url.contains('achievement')) {
        description = 'Celebration of an important milestone';
        conversationStarters = [
          'Congratulations on this achievement! What are you most proud of?',
          'This looks like a special moment! Tell me about this milestone.',
          'Amazing accomplishment! What\'s next for you?',
        ];
        tags = ['achievement', 'milestone', 'celebration'];
        confidence = 0.9;
      } else if (url.contains('hobby') ||
          url.contains('art') ||
          url.contains('music')) {
        description = 'Creative and artistic expression';
        conversationStarters = [
          'I love seeing creative people! How long have you been doing this?',
          'Your artistic side is really impressive! What inspires you?',
          'This is so cool! Do you have any other creative hobbies?',
        ];
        tags = ['creative', 'artistic', 'hobby'];
        confidence = 0.8;
      } else {
        // Default conversation starters
        conversationStarters = [
          'This is a great photo! What\'s the story behind it?',
          'I\'d love to hear more about this!',
          'This looks interesting! Tell me more.',
        ];
        tags = ['general', 'lifestyle'];
      }

      return ImageAnalysisResult(
        imageUrl: imageUrl,
        description: description,
        conversationStarters: conversationStarters,
        tags: tags,
        confidence: confidence,
      );
    } catch (e) {
      return null;
    }
  }

  String _generateInterestCompatibilityDescription(
    List<String> sharedInterests,
  ) {
    if (sharedInterests.isEmpty) {
      return 'No shared interests found, but that could lead to interesting discoveries!';
    }
    return 'You both enjoy ${sharedInterests.join(', ')}';
  }

  String _generateLifestyleCompatibilityDescription(
    List<String> lifestyle1,
    List<String> lifestyle2,
  ) {
    final shared = lifestyle1.where((l) => lifestyle2.contains(l));
    if (shared.isEmpty) {
      return 'Different lifestyle preferences could bring new perspectives';
    }
    return 'Similar lifestyle preferences in ${shared.join(', ')}';
  }

  String _generatePersonalityCompatibilityDescription(
    ProfilePersonality? personality1,
    ProfilePersonality? personality2,
  ) {
    if (personality1 == null || personality2 == null) {
      return 'Personality compatibility cannot be determined';
    }
    return 'Personality traits show good potential for compatibility';
  }

  Future<List<String>> _generateCompatibilityBasedSuggestions(
    UserProfile profile1,
    UserProfile profile2,
    List<String> sharedInterests,
  ) async {
    final suggestions = <String>[];

    for (final interest in sharedInterests.take(2)) {
      suggestions.add("Ask about their experience with $interest");
    }

    if (profile1.location == profile2.location) {
      suggestions.add("Suggest meeting at a local spot you both might enjoy");
    }

    return suggestions;
  }
}

// Supporting models for profile analysis

class ConversationStarter {
  final String text;
  final StarterType type;
  final double confidence;
  final StarterCategory category;
  final String context;

  const ConversationStarter({
    required this.text,
    required this.type,
    required this.confidence,
    required this.category,
    required this.context,
  });
}

class ProfileImprovementPlan {
  final double profileScore;
  final List<ProfileStrength> strengths;
  final List<ProfileWeakness> weaknesses;
  final List<ProfileSuggestion> suggestions;
  final Priority priority;
  final double estimatedImpact;

  const ProfileImprovementPlan({
    required this.profileScore,
    required this.strengths,
    required this.weaknesses,
    required this.suggestions,
    required this.priority,
    required this.estimatedImpact,
  });

  factory ProfileImprovementPlan.empty() {
    return const ProfileImprovementPlan(
      profileScore: 0.0,
      strengths: [],
      weaknesses: [],
      suggestions: [],
      priority: Priority.low,
      estimatedImpact: 0.0,
    );
  }
}

class ProfileCompatibilityInsight {
  final double overallCompatibility;
  final List<String> sharedInterests;
  final List<CompatibilityFactor> compatibilityFactors;
  final List<String> conversationSuggestions;

  const ProfileCompatibilityInsight({
    required this.overallCompatibility,
    required this.sharedInterests,
    required this.compatibilityFactors,
    required this.conversationSuggestions,
  });

  factory ProfileCompatibilityInsight.empty() {
    return const ProfileCompatibilityInsight(
      overallCompatibility: 0.0,
      sharedInterests: [],
      compatibilityFactors: [],
      conversationSuggestions: [],
    );
  }
}

class ProfileAnalysisResult {
  final List<ProfileStrength> strengths;
  final List<ProfileWeakness> weaknesses;
  final List<ProfileSuggestion> suggestions;

  const ProfileAnalysisResult({
    required this.strengths,
    required this.weaknesses,
    required this.suggestions,
  });
}

class ProfileStrength {
  final String area;
  final String description;

  const ProfileStrength({required this.area, required this.description});
}

class ProfileWeakness {
  final String area;
  final String description;
  final ImpactLevel impact;

  const ProfileWeakness({
    required this.area,
    required this.description,
    required this.impact,
  });
}

class ProfileSuggestion {
  final String area;
  final String suggestion;
  final Priority priority;
  final double estimatedImpact;

  const ProfileSuggestion({
    required this.area,
    required this.suggestion,
    required this.priority,
    required this.estimatedImpact,
  });
}

class PhotoAnalysisResult {
  final String description;
  final String conversationStarter;
  final double confidence;
  final List<String> tags;

  const PhotoAnalysisResult({
    required this.description,
    required this.conversationStarter,
    required this.confidence,
    required this.tags,
  });
}

class ImageAnalysisResult {
  final String imageUrl;
  final String description;
  final List<String> conversationStarters;
  final List<String> tags;
  final double confidence;

  const ImageAnalysisResult({
    required this.imageUrl,
    required this.description,
    required this.conversationStarters,
    required this.tags,
    required this.confidence,
  });
}

class CompatibilityFactor {
  final String name;
  final double score;
  final String description;

  const CompatibilityFactor({
    required this.name,
    required this.score,
    required this.description,
  });
}

enum StarterType { bio, interest, photo, location, lifestyle, iceBreaker }

enum StarterCategory { personal, shared, discovery, visual, local, lifestyle }

enum ImpactLevel { low, medium, high, critical }

enum Priority { low, medium, high, critical }
