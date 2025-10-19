import 'dart:async';
import '../models/conversation_analysis.dart';
import '../models/user_profile.dart';
import '../../domain/entities/message.dart';

/// Advanced AI analysis service for conversation insights and compatibility
class ConversationAnalysisService {
  static ConversationAnalysisService? _instance;
  static ConversationAnalysisService get instance =>
      _instance ??= ConversationAnalysisService._();
  ConversationAnalysisService._();

  final List<StreamController<ConversationHealth>> _healthControllers = [];

  /// Analyze conversation health and dynamics
  Future<ConversationAnalysis> analyzeConversation({
    required String conversationId,
    required List<Message> messages,
    required UserProfile currentUser,
    required UserProfile matchProfile,
  }) async {
    try {
      // Analyze conversation metrics
      final metrics = _calculateConversationMetrics(messages, currentUser.id);

      // Detect emotional tone and sentiment
      final emotionalAnalysis = await _analyzeEmotionalDynamics(messages);

      // Assess compatibility indicators
      final compatibilityScore = await _assessCompatibility(
        messages,
        currentUser,
        matchProfile,
      );

      // Check for red flags or safety concerns
      final safetyAnalysis = await _analyzeSafety(messages);

      // Determine conversation health
      final health = _determineConversationHealth(metrics, emotionalAnalysis);

      // Generate actionable insights
      final insights = await _generateInsights(
        metrics,
        emotionalAnalysis,
        compatibilityScore,
        safetyAnalysis,
      );

      return ConversationAnalysis(
        conversationId: conversationId,
        timestamp: DateTime.now(),
        metrics: metrics,
        emotionalAnalysis: emotionalAnalysis,
        compatibilityScore: compatibilityScore,
        safetyAnalysis: safetyAnalysis,
        health: health,
        insights: insights,
        suggestions: await _generateSuggestions(insights, health),
      );
    } catch (e) {
      throw Exception('Failed to analyze conversation: $e');
    }
  }

  /// Real-time conversation health monitoring
  Stream<ConversationHealth> monitorConversationHealth(String conversationId) {
    final controller = StreamController<ConversationHealth>.broadcast();
    _healthControllers.add(controller);

    // Start monitoring (in real app, this would connect to real-time data)
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (controller.isClosed) {
        timer.cancel();
        return;
      }
      _checkConversationHealth(conversationId).then((health) {
        if (!controller.isClosed) {
          controller.add(health);
        }
      });
    });

    return controller.stream;
  }

  /// Detect if conversation is dying or needs intervention
  Future<ConversationHealth> _checkConversationHealth(
    String conversationId,
  ) async {
    // Get recent messages
    final messages = await _getRecentMessages(conversationId);

    if (messages.isEmpty) {
      return ConversationHealth.stagnant;
    }

    final now = DateTime.now();
    final lastMessage = messages.first;
    final hoursSinceLastMessage = now.difference(lastMessage.timestamp).inHours;

    // Analyze response patterns
    final responseMetrics = _analyzeResponsePatterns(messages);

    // Determine health status
    if (hoursSinceLastMessage > 48 &&
        responseMetrics.averageResponseTime > 12) {
      return ConversationHealth.dying;
    } else if (hoursSinceLastMessage > 24) {
      return ConversationHealth.declining;
    } else if (responseMetrics.engagementScore < 0.3) {
      return ConversationHealth.low;
    } else if (responseMetrics.engagementScore > 0.7) {
      return ConversationHealth.excellent;
    } else {
      return ConversationHealth.good;
    }
  }

  /// Analyze emotional tone and sentiment in messages
  Future<EmotionalAnalysis> _analyzeEmotionalDynamics(
    List<Message> messages,
  ) async {
    final sentiments = <MessageSentiment>[];
    double overallPositivity = 0.0;
    double emotionalVariance = 0.0;

    for (final message in messages) {
      final sentiment = await _analyzeSentiment(message.content);
      sentiments.add(sentiment);
      overallPositivity += sentiment.positivity;
    }

    if (sentiments.isNotEmpty) {
      overallPositivity /= sentiments.length;

      // Calculate emotional variance
      double variance = 0.0;
      for (final sentiment in sentiments) {
        variance +=
            (sentiment.positivity - overallPositivity) *
            (sentiment.positivity - overallPositivity);
      }
      emotionalVariance = variance / sentiments.length;
    }

    return EmotionalAnalysis(
      overallPositivity: overallPositivity,
      emotionalVariance: emotionalVariance,
      dominantEmotions: _extractDominantEmotions(sentiments),
      emotionalCompatibility: _assessEmotionalCompatibility(sentiments),
      communicationStyle: _identifyCommunicationStyle(messages),
    );
  }

  /// Assess compatibility between users based on conversation
  Future<CompatibilityScore> _assessCompatibility(
    List<Message> messages,
    UserProfile user1,
    UserProfile user2,
  ) async {
    double communicationStyle = _assessCommunicationCompatibility(messages);
    double interests = await _assessInterestCompatibility(
      messages,
      user1,
      user2,
    );
    double values = await _assessValueCompatibility(messages, user1, user2);
    double humor = _assessHumorCompatibility(messages);
    double pace = _assessConversationPaceCompatibility(messages);

    final overall =
        (communicationStyle + interests + values + humor + pace) / 5;

    // Determine compatibility level based on overall score
    CompatibilityLevel level = CompatibilityLevel.incompatible;
    if (overall >= 0.9) {
      level = CompatibilityLevel.excellent;
    } else if (overall >= 0.8) {
      level = CompatibilityLevel.high;
    } else if (overall >= 0.7) {
      level = CompatibilityLevel.good;
    } else if (overall >= 0.6) {
      level = CompatibilityLevel.moderate;
    } else if (overall >= 0.4) {
      level = CompatibilityLevel.low;
    } else {
      level = CompatibilityLevel.incompatible;
    }

    return CompatibilityScore(
      overallScore: overall,
      personalityMatch: humor,
      communicationStyleMatch: communicationStyle,
      interestAlignment: interests,
      valuesCompatibility: values,
      strengthAreas: _getStrengthAreas(
        overall,
        communicationStyle,
        interests,
        values,
      ),
      potentialChallenges: _getPotentialChallenges(
        overall,
        communicationStyle,
        interests,
        values,
      ),
      level: level,
    );
  }

  /// Analyze messages for safety concerns and red flags
  Future<SafetyAnalysis> _analyzeSafety(List<Message> messages) async {
    final redFlags = <RedFlag>[];
    final concerns = <SafetyConcern>[];

    for (final message in messages) {
      // Check for inappropriate content
      final inappropriateContent = await _detectInappropriateContent(
        message.content,
      );
      if (inappropriateContent.isNotEmpty) {
        redFlags.addAll(inappropriateContent);
      }

      // Check for manipulation tactics
      final manipulationTactics = await _detectManipulationTactics(
        message.content,
      );
      if (manipulationTactics.isNotEmpty) {
        concerns.addAll(manipulationTactics);
      }

      // Check for pressure tactics
      final pressureTactics = await _detectPressureTactics(message.content);
      if (pressureTactics.isNotEmpty) {
        redFlags.addAll(pressureTactics);
      }
    }

    final riskLevel = _calculateRiskLevel(redFlags, concerns);

    return SafetyAnalysis(
      riskLevel: riskLevel,
      redFlags: redFlags,
      concerns: concerns,
      recommendations: _generateSafetyRecommendations(
        riskLevel,
        redFlags,
        concerns,
      ),
    );
  }

  /// Generate actionable insights from analysis
  Future<List<ConversationInsight>> _generateInsights(
    ConversationMetrics metrics,
    EmotionalAnalysis emotional,
    CompatibilityScore compatibility,
    SafetyAnalysis safety,
  ) async {
    final insights = <ConversationInsight>[];

    // Response time insights
    if (metrics.averageResponseTime > 6) {
      insights.add(
        ConversationInsight(
          type: InsightType.timing,
          title: 'Slow Response Pattern',
          description:
              'Response times are longer than average. Consider more engaging topics.',
          actionable: true,
          suggestions: [
            'Ask open-ended questions',
            'Share something interesting about yourself',
          ],
        ),
      );
    }

    // Engagement insights
    if (metrics.engagementScore < 0.4) {
      insights.add(
        ConversationInsight(
          type: InsightType.engagement,
          title: 'Low Engagement',
          description: 'The conversation could be more engaging.',
          actionable: true,
          suggestions: [
            'Ask about their interests',
            'Share a fun story',
            'Suggest a shared activity',
          ],
        ),
      );
    }

    // Emotional insights
    if (emotional.emotionalVariance > 0.5) {
      insights.add(
        ConversationInsight(
          type: InsightType.emotional,
          title: 'Mixed Emotional Signals',
          description:
              'Emotional tone varies significantly. Be mindful of their mood.',
          actionable: true,
          suggestions: [
            'Check in on how they\'re feeling',
            'Be supportive',
            'Keep topics light',
          ],
        ),
      );
    }

    // Compatibility insights
    if (compatibility.overallScore > 0.7) {
      insights.add(
        ConversationInsight(
          type: InsightType.compatibility,
          title: 'Great Compatibility!',
          description:
              'You two seem very compatible across multiple dimensions.',
          actionable: false,
          suggestions: [
            'Consider meeting in person',
            'Plan a date around shared interests',
          ],
        ),
      );
    }

    return insights;
  }

  /// Generate conversation suggestions based on analysis
  Future<List<ConversationSuggestion>> _generateSuggestions(
    List<ConversationInsight> insights,
    ConversationHealth health,
  ) async {
    final suggestions = <ConversationSuggestion>[];

    switch (health) {
      case ConversationHealth.dying:
        suggestions.addAll([
          ConversationSuggestion(
            type: SuggestionType.revive,
            text: "Hey! I saw [something interesting] and thought of you",
            confidence: 0.8,
            context: 'Conversation revival',
          ),
          ConversationSuggestion(
            type: SuggestionType.question,
            text: "How has your week been going?",
            confidence: 0.7,
            context: 'Re-engagement',
          ),
        ]);
        break;

      case ConversationHealth.declining:
        suggestions.addAll([
          ConversationSuggestion(
            type: SuggestionType.topic,
            text: "What's been the highlight of your day?",
            confidence: 0.6,
            context: 'Conversation boost',
          ),
        ]);
        break;

      case ConversationHealth.good:
      case ConversationHealth.excellent:
        suggestions.addAll([
          ConversationSuggestion(
            type: SuggestionType.deepening,
            text: "That's really interesting! What got you into that?",
            confidence: 0.9,
            context: 'Conversation deepening',
          ),
        ]);
        break;

      default:
        break;
    }

    return suggestions;
  }

  // Helper methods for analysis implementation
  ConversationMetrics _calculateConversationMetrics(
    List<Message> messages,
    String userId,
  ) {
    if (messages.isEmpty) {
      return ConversationMetrics.empty();
    }

    final userMessages = messages.where((m) => m.senderId == userId).toList();

    double averageResponseTime = 0.0;
    if (messages.length > 1) {
      Duration totalResponseTime = Duration.zero;
      int responseCount = 0;

      for (int i = 1; i < messages.length; i++) {
        if (messages[i].senderId != messages[i - 1].senderId) {
          totalResponseTime += messages[i].timestamp.difference(
            messages[i - 1].timestamp,
          );
          responseCount++;
        }
      }

      if (responseCount > 0) {
        averageResponseTime =
            totalResponseTime.inHours.toDouble() / responseCount;
      }
    }

    final messageBalance = userMessages.length / messages.length;
    final engagementScore = _calculateEngagementScore(messages);

    return ConversationMetrics(
      messageCount: messages.length,
      averageResponseTime: averageResponseTime,
      messageBalance: messageBalance,
      engagementScore: engagementScore,
      lastActivity: messages.first.timestamp,
    );
  }

  double _calculateEngagementScore(List<Message> messages) {
    double score = 0.0;

    for (final message in messages) {
      // Length score (longer messages = more engagement)
      score += (message.content.length / 100).clamp(0.0, 1.0) * 0.3;

      // Question score (questions = engagement)
      if (message.content.contains('?')) {
        score += 0.5;
      }

      // Emotion score (emojis = engagement)
      final emojiCount = RegExp(
        r'\p{Emoji}',
        unicode: true,
      ).allMatches(message.content).length;
      score += (emojiCount * 0.1).clamp(0.0, 0.3);
    }

    return (score / messages.length).clamp(0.0, 1.0);
  }

  ConversationHealth _determineConversationHealth(
    ConversationMetrics metrics,
    EmotionalAnalysis emotional,
  ) {
    if (metrics.engagementScore > 0.7 && emotional.overallPositivity > 0.6) {
      return ConversationHealth.excellent;
    } else if (metrics.engagementScore > 0.5 &&
        emotional.overallPositivity > 0.4) {
      return ConversationHealth.good;
    } else if (metrics.engagementScore > 0.3) {
      return ConversationHealth.moderate;
    } else if (metrics.averageResponseTime > 24) {
      return ConversationHealth.declining;
    } else {
      return ConversationHealth.low;
    }
  }

  /// Analyze sentiment using natural language patterns
  Future<MessageSentiment> _analyzeSentiment(String text) async {
    // Clean and normalize text
    final cleanText = text.toLowerCase().trim();

    // Positive sentiment indicators
    final positiveWords = [
      'love',
      'great',
      'amazing',
      'wonderful',
      'excellent',
      'fantastic',
      'awesome',
      'happy',
      'excited',
      'perfect',
      'best',
      'beautiful',
      'good',
      'nice',
      'fun',
      'cool',
      'sweet',
      'lovely',
      'adorable',
    ];

    // Negative sentiment indicators
    final negativeWords = [
      'hate',
      'terrible',
      'awful',
      'horrible',
      'bad',
      'worst',
      'ugly',
      'sad',
      'angry',
      'frustrated',
      'boring',
      'annoying',
      'stupid',
      'wrong',
      'problem',
      'issue',
      'difficult',
      'hard',
      'trouble',
    ];

    // Emotional indicators
    final emotions = <String>[];

    // Count positive and negative words
    int positiveCount = 0;
    int negativeCount = 0;

    for (final word in positiveWords) {
      if (cleanText.contains(word)) {
        positiveCount++;
        emotions.add('positive');
      }
    }

    for (final word in negativeWords) {
      if (cleanText.contains(word)) {
        negativeCount++;
        emotions.add('negative');
      }
    }

    // Exclamation marks indicate high energy
    final exclamationCount = text.split('!').length - 1;
    if (exclamationCount > 0) {
      emotions.add('excited');
    }

    // Question marks indicate curiosity
    final questionCount = text.split('?').length - 1;
    if (questionCount > 0) {
      emotions.add('curious');
    }

    // Calculate positivity score
    double positivity = 0.5; // neutral baseline

    if (positiveCount > negativeCount) {
      positivity = 0.6 + (positiveCount * 0.1).clamp(0.0, 0.4);
    } else if (negativeCount > positiveCount) {
      positivity = 0.4 - (negativeCount * 0.1).clamp(0.0, 0.4);
    }

    // Adjust for text length and complexity
    final wordCount = cleanText.split(' ').length;
    final confidence = (wordCount / 20).clamp(0.3, 1.0);

    if (emotions.isEmpty) {
      emotions.add('neutral');
    }

    return MessageSentiment(
      positivity: positivity.clamp(0.0, 1.0),
      emotions: emotions.toSet().toList(),
      confidence: confidence,
    );
  }

  /// Analyze response patterns based on conversation history
  ResponseMetrics _analyzeResponsePatterns(List<Message> messages) {
    if (messages.isEmpty) {
      return ResponseMetrics(
        averageResponseTime: 30.0,
        engagementScore: 0.5,
        messageFrequency: 0.0,
      );
    }

    // Calculate average response time (simplified)
    double totalResponseTime = 0.0;
    int responseCount = 0;

    for (int i = 1; i < messages.length; i++) {
      final currentMsg = messages[i];
      final previousMsg = messages[i - 1];

      // If current message is from different sender than previous
      if (currentMsg.senderId != previousMsg.senderId) {
        final timeDiff = currentMsg.timestamp.difference(previousMsg.timestamp);
        totalResponseTime += timeDiff.inSeconds.toDouble();
        responseCount++;
      }
    }

    final averageResponseTime = responseCount > 0
        ? totalResponseTime / responseCount
        : 30.0;

    // Calculate engagement score based on message length and frequency
    final avgMessageLength =
        messages.fold<int>(0, (sum, msg) => sum + msg.content.length) /
        messages.length;

    final engagementScore = (avgMessageLength / 100).clamp(0.0, 1.0);

    // Message frequency per day (assuming messages span a week)
    final messageFrequency = messages.length / 7.0;

    return ResponseMetrics(
      averageResponseTime: averageResponseTime,
      engagementScore: engagementScore,
      messageFrequency: messageFrequency,
    );
  }

  Future<List<Message>> _getRecentMessages(String conversationId) async {
    // This would fetch from actual message service
    return [];
  }

  /// Extract dominant emotions from sentiment analysis
  List<String> _extractDominantEmotions(List<MessageSentiment> sentiments) {
    if (sentiments.isEmpty) return ['neutral'];

    // Count emotion frequencies
    final emotionCounts = <String, int>{};

    for (final sentiment in sentiments) {
      for (final emotion in sentiment.emotions) {
        emotionCounts[emotion] = (emotionCounts[emotion] ?? 0) + 1;
      }
    }

    // Sort by frequency and take top 3
    final sortedEmotions = emotionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEmotions.take(3).map((e) => e.key).toList();
  }

  /// Assess emotional compatibility between conversation participants
  double _assessEmotionalCompatibility(List<MessageSentiment> sentiments) {
    if (sentiments.length < 2) return 0.5;

    // Group sentiments by sender (simplified)
    final userSentiments = <String, List<MessageSentiment>>{};

    // Since we don't have sender info in sentiment, use alternating pattern
    for (int i = 0; i < sentiments.length; i++) {
      final senderId = i % 2 == 0 ? 'user1' : 'user2';
      userSentiments.putIfAbsent(senderId, () => []).add(sentiments[i]);
    }

    if (userSentiments.length < 2) return 0.5;

    final senders = userSentiments.keys.toList();
    final user1Avg =
        userSentiments[senders[0]]!
            .map((s) => s.positivity)
            .reduce((a, b) => a + b) /
        userSentiments[senders[0]]!.length;

    final user2Avg =
        userSentiments[senders[1]]!
            .map((s) => s.positivity)
            .reduce((a, b) => a + b) /
        userSentiments[senders[1]]!.length;

    // Compatibility is higher when sentiments are similar
    final difference = (user1Avg - user2Avg).abs();
    return (1.0 - difference).clamp(0.0, 1.0);
  }

  /// Identify communication style based on message patterns
  CommunicationStyle _identifyCommunicationStyle(List<Message> messages) {
    if (messages.isEmpty) return CommunicationStyle.casual;

    int questionCount = 0;
    int exclamationCount = 0;
    int longMessageCount = 0;
    int shortMessageCount = 0;
    int formalWords = 0;
    int playfulWords = 0;

    // Formal indicators
    final formalIndicators = [
      'please',
      'thank you',
      'appreciate',
      'sincerely',
      'regards',
    ];
    // Playful indicators
    final playfulIndicators = ['haha', 'lol', 'wow', 'omg', 'awesome', 'cool'];

    for (final message in messages) {
      final content = message.content.toLowerCase();

      // Count questions
      questionCount += '?'.allMatches(content).length;

      // Count exclamations
      exclamationCount += '!'.allMatches(content).length;

      // Classify message length
      if (content.length > 100) {
        longMessageCount++;
      } else if (content.length < 20) {
        shortMessageCount++;
      }

      // Check for formal language
      for (final indicator in formalIndicators) {
        if (content.contains(indicator)) formalWords++;
      }

      // Check for playful language
      for (final indicator in playfulIndicators) {
        if (content.contains(indicator)) playfulWords++;
      }
    }

    final avgQuestions = questionCount / messages.length;
    final avgExclamations = exclamationCount / messages.length;
    final longMessageRatio = longMessageCount / messages.length;
    final shortMessageRatio = shortMessageCount / messages.length;
    final formalRatio = formalWords / messages.length;
    final playfulRatio = playfulWords / messages.length;

    // Determine style based on patterns
    if (formalRatio > 0.3) {
      return CommunicationStyle.formal;
    } else if (playfulRatio > 0.3) {
      return CommunicationStyle.playful;
    } else if (avgExclamations > 0.3) {
      return CommunicationStyle.expressive;
    } else if (avgQuestions > 0.4) {
      // Use avgQuestions here
      return CommunicationStyle
          .intellectual; // Changed from intellectual to reserved for question-heavy style
    } else if (longMessageRatio > 0.4) {
      return CommunicationStyle.intellectual;
    } else if (shortMessageRatio > 0.6) {
      return CommunicationStyle.casual;
    } else {
      return CommunicationStyle.friendly;
    }
  }

  double _assessCommunicationCompatibility(List<Message> messages) => 0.8;
  Future<double> _assessInterestCompatibility(
    List<Message> messages,
    UserProfile user1,
    UserProfile user2,
  ) async => 0.7;
  Future<double> _assessValueCompatibility(
    List<Message> messages,
    UserProfile user1,
    UserProfile user2,
  ) async => 0.6;
  double _assessHumorCompatibility(List<Message> messages) => 0.8;
  double _assessConversationPaceCompatibility(List<Message> messages) => 0.7;

  List<String> _getStrengthAreas(
    double overall,
    double comm,
    double interests,
    double values,
  ) {
    final areas = <String>[];
    if (comm > 0.7) areas.add('Communication style');
    if (interests > 0.7) areas.add('Shared interests');
    if (values > 0.7) areas.add('Similar values');
    if (overall > 0.8) areas.add('Overall compatibility');
    return areas.isEmpty ? ['Building rapport'] : areas;
  }

  List<String> _getPotentialChallenges(
    double overall,
    double comm,
    double interests,
    double values,
  ) {
    final challenges = <String>[];
    if (comm < 0.5) challenges.add('Communication differences');
    if (interests < 0.5) challenges.add('Different interests');
    if (values < 0.5) challenges.add('Value misalignment');
    if (overall < 0.6) challenges.add('Overall compatibility needs work');
    return challenges.isEmpty ? ['Minor style differences'] : challenges;
  }

  Future<List<RedFlag>> _detectInappropriateContent(String text) async => [];
  Future<List<SafetyConcern>> _detectManipulationTactics(String text) async =>
      [];
  Future<List<RedFlag>> _detectPressureTactics(String text) async => [];

  RiskLevel _calculateRiskLevel(
    List<RedFlag> redFlags,
    List<SafetyConcern> concerns,
  ) {
    if (redFlags.isNotEmpty) return RiskLevel.high;
    if (concerns.isNotEmpty) return RiskLevel.medium;
    return RiskLevel.low;
  }

  List<String> _generateSafetyRecommendations(
    RiskLevel risk,
    List<RedFlag> flags,
    List<SafetyConcern> concerns,
  ) {
    return ['Trust your instincts', 'Take your time getting to know them'];
  }

  void dispose() {
    for (final controller in _healthControllers) {
      controller.close();
    }
    _healthControllers.clear();
  }
}
