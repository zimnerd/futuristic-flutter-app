import 'dart:convert';
import 'package:http/http.dart' as http;


import '../models/user_model.dart';
import '../models/message_model.dart';
import '../../core/config/app_config.dart';
import '../../core/utils/logger.dart';
import 'service_locator.dart';

enum AiAssistanceType {
  conversationStarter,
  responseAssistance,
  messageRefinement,
  icebreaker,
}

enum MessageRefinementType { casual, formal, flirty, friendly, witty }

/// Service for AI-powered chat assistance
class AiChatAssistantService {
  static final AiChatAssistantService _instance = AiChatAssistantService._internal();
  factory AiChatAssistantService() => _instance;
  AiChatAssistantService._internal();

  final String _baseUrl = AppConfig.apiBaseUrl;

  /// Generate AI assistance based on context and type
  Future<AiAssistanceResponse> generateAssistance(
    AiAssistanceType assistanceType,
    List<MessageModel> messages, {
    required bool includeMyProfile,
    required bool includeMatchProfile,
    required bool includeConversation,
    required bool includeMatchGallery,
    required bool includePreferences,
    String? specificMessage,
    List<String>? recentMessages,
    UserModel? currentUser,
    UserModel? matchProfile,
  }) async {
    try {
      final authService = ServiceLocator().authService;
      final token = await authService.getAccessToken();
      
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final lastMessage = messages.isNotEmpty
          ? messages.last.content
          : specificMessage ?? '';
      final conversationId = messages.isNotEmpty
          ? messages.last.conversationId
          : '';

      final response = await http.post(
        Uri.parse('$_baseUrl/ai/response-suggestions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'conversationId': conversationId,
          'lastMessage': lastMessage,
          'tone': 'friendly',
          'count': 3,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AiAssistanceResponse.fromJson(data['data']);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to generate AI assistance');
      }
    } catch (e) {
      AppLogger.error('Error generating AI assistance: $e');
      rethrow;
    }
  }

  /// Generate icebreakers for new conversations
  Future<List<String>> generateIcebreakers({
    required String conversationId,
    required String userId,
    UserModel? currentUser,
    UserModel? matchProfile,
  }) async {
    try {
      final authService = ServiceLocator().authService;
      final token = await authService.getAccessToken();
      
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/ai/generate-icebreakers'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'conversationId': conversationId,
          'userId': userId,
          'currentUserProfile': currentUser?.toJson(),
          'matchProfile': matchProfile?.toJson(),
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<String>.from(data['data']['icebreakers']);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to generate icebreakers');
      }
    } catch (e) {
      AppLogger.error('Error generating icebreakers: $e');
      return [
        "Hey! How's your day going? 😊",
        "I noticed you're into [interest] - that's awesome! What got you started?",
        "Your photos are amazing! Are you a photographer or just naturally photogenic? 📸",
        "I have to ask - what's your go-to comfort food? 🍕",
        "If you could travel anywhere right now, where would you go? ✈️",
      ];
    }
  }

  /// Refine AI-generated message
  Future<String> refineMessage({
    required String originalMessage,
    required String refinementRequest,
    required String conversationId,
  }) async {
    try {
      final authService = ServiceLocator().authService;
      final token = await authService.getAccessToken();

      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/ai/refine-message'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'originalMessage': originalMessage,
          'refinementRequest': refinementRequest,
          'conversationId': conversationId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']['refinedMessage'];
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to refine message');
      }
    } catch (e) {
      AppLogger.error('Error refining message: $e');
      rethrow;
    }
  }


}

/// AI Assistance Response Model
class AiAssistanceResponse {
  final String id;
  final String message;
  final String tone;
  final String reasoning;
  final List<String> alternatives;
  final Map<String, dynamic> metadata;

  const AiAssistanceResponse({
    required this.id,
    required this.message,
    required this.tone,
    required this.reasoning,
    required this.alternatives,
    required this.metadata,
  });

  factory AiAssistanceResponse.fromJson(Map<String, dynamic> json) {
    return AiAssistanceResponse(
      id: json['id'] ?? '',
      message: json['message'] ?? '',
      tone: json['tone'] ?? 'friendly',
      reasoning: json['reasoning'] ?? '',
      alternatives: List<String>.from(json['alternatives'] ?? []),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'tone': tone,
      'reasoning': reasoning,
      'alternatives': alternatives,
      'metadata': metadata,
    };
  }
}