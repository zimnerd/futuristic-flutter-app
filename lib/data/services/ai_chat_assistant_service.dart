import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/chat_model.dart';
import '../models/user_model.dart';
import '../../core/config/app_config.dart';
import '../../core/utils/logger.dart';
import 'service_locator.dart';

/// Service for AI-powered chat assistance
class AiChatAssistantService {
  static final AiChatAssistantService _instance = AiChatAssistantService._internal();
  factory AiChatAssistantService() => _instance;
  AiChatAssistantService._internal();

  final String _baseUrl = AppConfig.apiBaseUrl;

  /// Generate AI assistance for chat messages
  Future<AiAssistanceResponse> generateAssistance({
    required String userRequest,
    required String conversationId,
    required String userId,
    bool includeMyProfile = false,
    bool includeMatchProfile = true,
    bool includeConversation = true,
    bool includeMatchGallery = false,
    bool includePreferences = false,
    MessageModel? specificMessage,
    List<MessageModel> recentMessages = const [],
    UserModel? currentUser,
    UserModel? matchProfile,
  }) async {
    try {
      final authService = ServiceLocator().authService;
      final token = await authService.getAccessToken();
      
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final contextData = _buildContextData(
        includeMyProfile: includeMyProfile,
        includeMatchProfile: includeMatchProfile,
        includeConversation: includeConversation,
        includeMatchGallery: includeMatchGallery,
        includePreferences: includePreferences,
        specificMessage: specificMessage,
        recentMessages: recentMessages,
        currentUser: currentUser,
        matchProfile: matchProfile,
      );

      final response = await http.post(
        Uri.parse('$_baseUrl/ai/chat-assistance'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'userRequest': userRequest,
          'conversationId': conversationId,
          'userId': userId,
          'context': contextData,
          'assistanceType': specificMessage != null ? 'reply_assistance' : 'general_assistance',
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

  /// Build context data for AI request
  Map<String, dynamic> _buildContextData({
    required bool includeMyProfile,
    required bool includeMatchProfile,
    required bool includeConversation,
    required bool includeMatchGallery,
    required bool includePreferences,
    MessageModel? specificMessage,
    List<MessageModel> recentMessages = const [],
    UserModel? currentUser,
    UserModel? matchProfile,
  }) {
    final Map<String, dynamic> context = {};

    if (includeMyProfile && currentUser != null) {
      context['myProfile'] = {
        'name': '${currentUser.firstName ?? ''} ${currentUser.lastName ?? ''}'.trim(),
        'username': currentUser.username,
        'age': currentUser.age,
        'bio': currentUser.bio,
        'interests': currentUser.interests,
        'location': currentUser.location,
      };
    }

    if (includeMatchProfile && matchProfile != null) {
      context['matchProfile'] = {
        'name': '${matchProfile.firstName ?? ''} ${matchProfile.lastName ?? ''}'.trim(),
        'username': matchProfile.username,
        'age': matchProfile.age,
        'bio': matchProfile.bio,
        'interests': matchProfile.interests,
        'location': matchProfile.location,
      };
    }

    if (includeConversation && recentMessages.isNotEmpty) {
      // Limit to last 10 messages to reduce token usage
      final limitedMessages = recentMessages.take(10).toList();
      context['recentMessages'] = limitedMessages.map((msg) => {
        'senderId': msg.senderId,
        'content': msg.content,
        'type': msg.type.toString(),
        'createdAt': msg.createdAt.toIso8601String(),
        'isFromCurrentUser': currentUser != null && msg.senderId == currentUser.id,
      }).toList();
    }

    if (specificMessage != null) {
      context['specificMessage'] = {
        'senderId': specificMessage.senderId,
        'content': specificMessage.content,
        'type': specificMessage.type.toString(),
        'createdAt': specificMessage.createdAt.toIso8601String(),
        'isFromCurrentUser': currentUser != null && specificMessage.senderId == currentUser.id,
      };
    }

    if (includeMatchGallery && matchProfile != null) {
      // Include match's photo info for context
      context['matchGallery'] = {
        'hasPhotos': matchProfile.photos.isNotEmpty,
        'photoCount': matchProfile.photos.length,
      };
    }

    if (includePreferences) {
      context['preferences'] = {
        'communicationStyle': 'friendly', // Could be from user preferences
        'tone': 'casual',
      };
    }

    return context;
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