import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import '../../core/utils/logger.dart';
import 'service_locator.dart';

enum AiAssistanceType {
  response,
  icebreaker,
  refinement,
  custom,
}

enum MessageTone { 
  casual, 
  formal, 
  flirty, 
  friendly, 
  witty 
}

/// Context options for AI assistance
class AiContextOptions {
  final bool includeMyProfile;
  final bool includeMatchProfile;
  final bool includeConversation;
  final bool includeMatchGallery;
  final bool includePreferences;
  final int conversationMessageLimit;

  const AiContextOptions({
    this.includeMyProfile = false,
    this.includeMatchProfile = false,
    this.includeConversation = false,
    this.includeMatchGallery = false,
    this.includePreferences = false,
    this.conversationMessageLimit = 20,
  });

  Map<String, dynamic> toJson() {
    return {
      'includeMyProfile': includeMyProfile,
      'includeMatchProfile': includeMatchProfile,
      'includeConversation': includeConversation,
      'includeMatchGallery': includeMatchGallery,
      'includePreferences': includePreferences,
      'conversationMessageLimit': conversationMessageLimit,
    };
  }
}

/// Service for comprehensive AI-powered chat assistance
class AiChatAssistantService {
  static final AiChatAssistantService _instance = AiChatAssistantService._internal();
  factory AiChatAssistantService() => _instance;
  AiChatAssistantService._internal();

  final String _baseUrl = AppConfig.apiBaseUrl;

  /// Generate comprehensive AI assistance with rich context
  Future<AiChatAssistanceResponse> getChatAssistance({
    required AiAssistanceType assistanceType,
    required String conversationId,
    required String userRequest,
    AiContextOptions contextOptions = const AiContextOptions(),
    String? specificMessage,
    MessageTone tone = MessageTone.friendly,
    int suggestionCount = 1,
  }) async {
    try {
      final authService = ServiceLocator().authService;
      final token = await authService.getAccessToken();
      
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/ai/chat-assistance'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'assistanceType': assistanceType.name,
          'conversationId': conversationId,
          'userRequest': userRequest,
          'contextOptions': contextOptions.toJson(),
          'specificMessage': specificMessage,
          'tone': tone.name,
          'suggestionCount': suggestionCount,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final data =
            responseData['data'] ??
            responseData; // Handle both wrapped and unwrapped responses
        return AiChatAssistanceResponse.fromJson(data);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to get AI assistance');
      }
    } catch (e) {
      AppLogger.error('Error getting AI chat assistance: $e');
      rethrow;
    }
  }

  /// Generate icebreakers for fresh conversations
  Future<List<String>> generateIcebreakers({
    required String conversationId,
    AiContextOptions contextOptions = const AiContextOptions(),
  }) async {
    try {
      final response = await getChatAssistance(
        assistanceType: AiAssistanceType.icebreaker,
        conversationId: conversationId,
        userRequest: 'Generate engaging icebreaker messages for starting a conversation',
        contextOptions: contextOptions,
        suggestionCount: 5,
      );

      return response.alternatives.isNotEmpty 
          ? response.alternatives 
          : [response.suggestion];
    } catch (e) {
      AppLogger.error('Error generating icebreakers: $e');
      // Fallback icebreakers
      return [
        "Hey! How's your day going? 😊",
        "I noticed you're into [interest] - that's awesome! What got you started?",
        "Your photos are amazing! Are you a photographer or just naturally photogenic? 📸",
        "I have to ask - what's your go-to comfort food? 🍕",
        "If you could travel anywhere right now, where would you go? ✈️",
      ];
    }
  }

  /// Generate response suggestions for ongoing conversations
  Future<List<String>> generateResponseSuggestions({
    required String conversationId,
    required String lastMessage,
    AiContextOptions contextOptions = const AiContextOptions(),
    MessageTone tone = MessageTone.friendly,
  }) async {
    try {
      final response = await getChatAssistance(
        assistanceType: AiAssistanceType.response,
        conversationId: conversationId,
        userRequest: 'Help me respond to: "$lastMessage"',
        contextOptions: contextOptions,
        specificMessage: lastMessage,
        tone: tone,
        suggestionCount: 3,
      );

      return response.alternatives.isNotEmpty 
          ? response.alternatives 
          : [response.suggestion];
    } catch (e) {
      AppLogger.error('Error generating response suggestions: $e');
      return ['Thanks for sharing that!', 'That sounds interesting!', 'Tell me more about that.'];
    }
  }

  /// Refine a message with AI assistance
  Future<String> refineMessage({
    required String originalMessage,
    required String refinementRequest,
    required String conversationId,
    AiContextOptions contextOptions = const AiContextOptions(),
    MessageTone targetTone = MessageTone.friendly,
  }) async {
    try {
      final response = await getChatAssistance(
        assistanceType: AiAssistanceType.refinement,
        conversationId: conversationId,
        userRequest: 'Refine this message: "$originalMessage". $refinementRequest',
        contextOptions: contextOptions,
        specificMessage: originalMessage,
        tone: targetTone,
      );

      return response.suggestion;
    } catch (e) {
      AppLogger.error('Error refining message: $e');
      return originalMessage; // Return original if refinement fails
    }
  }

  /// Get AI assistance for custom requests
  Future<AiChatAssistanceResponse> getCustomAssistance({
    required String conversationId,
    required String userRequest,
    AiContextOptions contextOptions = const AiContextOptions(),
    MessageTone tone = MessageTone.friendly,
    int suggestionCount = 3,
  }) async {
    return await getChatAssistance(
      assistanceType: AiAssistanceType.custom,
      conversationId: conversationId,
      userRequest: userRequest,
      contextOptions: contextOptions,
      tone: tone,
      suggestionCount: suggestionCount,
    );
  }
}

/// Comprehensive AI Chat Assistance Response Model
class AiChatAssistanceResponse {
  final String suggestion;
  final String reasoning;
  final List<String> alternatives;
  final AiContextInsights contextUsed;
  final Map<String, dynamic> metadata;

  const AiChatAssistanceResponse({
    required this.suggestion,
    required this.reasoning,
    required this.alternatives,
    required this.contextUsed,
    required this.metadata,
  });

  factory AiChatAssistanceResponse.fromJson(Map<String, dynamic> json) {
    return AiChatAssistanceResponse(
      suggestion: json['suggestion'] ?? '',
      reasoning: json['reasoning'] ?? '',
      alternatives: List<String>.from(json['alternatives'] ?? []),
      contextUsed: AiContextInsights.fromJson(json['contextUsed'] ?? {}),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'suggestion': suggestion,
      'reasoning': reasoning,
      'alternatives': alternatives,
      'contextUsed': contextUsed.toJson(),
      'metadata': metadata,
    };
  }
}

/// Context insights used in AI assistance
class AiContextInsights {
  final String profileInsights;
  final String conversationInsights;
  final String matchInsights;

  const AiContextInsights({
    required this.profileInsights,
    required this.conversationInsights,
    required this.matchInsights,
  });

  factory AiContextInsights.fromJson(Map<String, dynamic> json) {
    return AiContextInsights(
      profileInsights: json['profileInsights'] ?? '',
      conversationInsights: json['conversationInsights'] ?? '',
      matchInsights: json['matchInsights'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profileInsights': profileInsights,
      'conversationInsights': conversationInsights,
      'matchInsights': matchInsights,
    };
  }
}