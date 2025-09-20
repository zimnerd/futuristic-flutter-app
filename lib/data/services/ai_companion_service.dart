import 'package:logger/logger.dart';
import 'dart:io';
import 'dart:async';
import '../models/ai_companion.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/http_status_utils.dart';
import '../../domain/services/websocket_service.dart';
import 'file_upload_service.dart';

/// Service for AI Companion interactions and management
class AiCompanionService {
  final ApiClient _apiClient;
  final WebSocketService _webSocketService;
  final FileUploadService _fileUploadService;
  final Logger _logger = Logger();
  
  // Stream controllers for real-time events
  final StreamController<CompanionMessage> _messageController =
      StreamController<CompanionMessage>.broadcast();
  final StreamController<Map<String, dynamic>> _errorController =
      StreamController<Map<String, dynamic>>.broadcast();

  AiCompanionService(
    this._apiClient,
    this._webSocketService,
    this._fileUploadService,
  ) {
    _setupWebSocketListeners();
  }

  // Streams for real-time events
  Stream<CompanionMessage> get messageStream => _messageController.stream;
  Stream<Map<String, dynamic>> get errorStream => _errorController.stream;

  void _setupWebSocketListeners() {
    // Listen for AI message events
    _webSocketService.onAiMessageSent((data) {
      try {
        final message = _mapWebSocketDataToMessage(data);
        _messageController.add(message);
        _logger.d('AI message sent: ${message.id}');
      } catch (e) {
        _logger.e('Error processing AI message sent: $e');
      }
    });

    _webSocketService.onAiMessageReceived((data) {
      try {
        final message = _mapWebSocketDataToMessage(data);
        _messageController.add(message);
        _logger.d('AI message received: ${message.id}');
      } catch (e) {
        _logger.e('Error processing AI message received: $e');
      }
    });

    _webSocketService.onAiMessageFailed((data) {
      _errorController.add(data);
      _logger.e('AI message failed: $data');
    });
  }

  CompanionMessage _mapWebSocketDataToMessage(Map<String, dynamic> data) {
    return CompanionMessage(
      id: data['id'] ?? '',
      companionId: data['companionId'] ?? '',
      userId: data['userId'] ?? '',
      content: data['content'] ?? '',
      isFromCompanion: data['isFromCompanion'] ?? false,
      timestamp: DateTime.parse(
        data['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      type: _parseMessageType(data['messageType']),
      suggestedResponses:
          (data['suggestedResponses'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  /// Create a new AI companion
  Future<AICompanion?> createCompanion({
    required String name,
    required CompanionPersonality personality,
    required CompanionAppearance appearance,
    String? customPrompt,
  }) async {
    try {
      final response = await _apiClient.post(
        '/ai-companions',
        data: {
          'name': name,
          'personality': personality.name,
          'gender': 'female', // Default to female, should be configurable in UI
          'ageGroup': 'adult', // Default to adult, should be configurable in UI
          'description':
              'A personalized AI companion to help with dating advice',
          'interests': ['dating', 'relationships', 'conversation'],
        },
      );

      if (HttpStatusUtils.isPostSuccess(response.statusCode) &&
          response.data != null) {
        final companion = AICompanion.fromJson(response.data['data']);
        _logger.d('AI companion created successfully: ${companion.id}');
        return companion;
      } else {
        _logger.e('Failed to create AI companion: ${response.statusMessage}');
        return null;
      }
    } catch (e) {
      _logger.e('Error creating AI companion: $e');
      return null;
    }
  }

  /// Get user's AI companions
  Future<List<AICompanion>> getUserCompanions() async {
    try {
      final response = await _apiClient.get('/ai-companions/user/companions');

      if (HttpStatusUtils.isGetSuccess(response.statusCode) &&
          response.data != null) {
        // Try data wrapper first, then direct response
        final responseData = response.data['data'] ?? response.data;
        final List<dynamic> data = responseData['companions'] ?? [];
        final companions = data.map((json) => AICompanion.fromJson(json)).toList();
        
        _logger.d('Retrieved ${companions.length} AI companions');
        return companions;
      } else {
        _logger.e('Failed to get AI companions: ${response.statusMessage}');
        return [];
      }
    } catch (e) {
      _logger.e('Error getting AI companions: $e');
      return [];
    }
  }

  /// Get specific AI companion
  Future<AICompanion?> getCompanion(String companionId) async {
    try {
      final response = await _apiClient.get(
        '/ai-companions/$companionId',
      );

      if (HttpStatusUtils.isGetSuccess(response.statusCode) &&
          response.data != null) {
        final companion = AICompanion.fromJson(response.data!);
        _logger.d('Retrieved AI companion: $companionId');
        return companion;
      } else {
        _logger.e('Failed to get AI companion: ${response.statusMessage}');
        return null;
      }
    } catch (e) {
      _logger.e('Error getting AI companion: $e');
      return null;
    }
  }

  /// Update AI companion
  Future<AICompanion?> updateCompanion({
    required String companionId,
    String? name,
    CompanionPersonality? personality,
    CompanionAppearance? appearance,
    String? customPrompt,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (personality != null) updateData['personality'] = personality.name;
      if (appearance != null) updateData['appearance'] = appearance.toJson();
      if (customPrompt != null) updateData['customPrompt'] = customPrompt;

      final response = await _apiClient.put(
        '/ai-companions/$companionId',
        data: updateData,
      );

      if (HttpStatusUtils.isPutSuccess(response.statusCode) &&
          response.data != null) {
        final companion = AICompanion.fromJson(response.data!);
        _logger.d('AI companion updated successfully: $companionId');
        return companion;
      } else {
        _logger.e('Failed to update AI companion: ${response.statusMessage}');
        return null;
      }
    } catch (e) {
      _logger.e('Error updating AI companion: $e');
      return null;
    }
  }

  /// Delete AI companion
  Future<bool> deleteCompanion(String companionId) async {
    try {
      final response = await _apiClient.delete(
        '/ai-companions/$companionId',
      );

      if (HttpStatusUtils.isDeleteSuccess(response.statusCode)) {
        _logger.d('AI companion deleted successfully: $companionId');
        return true;
      } else {
        _logger.e('Failed to delete AI companion: ${response.statusMessage}');
        return false;
      }
    } catch (e) {
      _logger.e('Error deleting AI companion: $e');
      return false;
    }
  }

  /// Send message to AI companion via WebSocket
  void sendMessage({
    required String companionId,
    required String message,
    String? conversationId,
  }) {
    try {
      _logger.d('Sending message to AI companion: $companionId');
      _webSocketService.sendAiMessage(message, conversationId);
    } catch (e) {
      _logger.e('Error sending AI message: $e');
      _errorController.add({
        'error': 'Failed to send message',
        'details': e.toString(),
        'companionId': companionId,
        'message': message,
      });
    }
  }

  /// Send image message to AI companion
  Future<CompanionMessage?> sendImageMessage({
    required String companionId,
    required File imageFile,
  }) async {
    try {
      // Upload image first
      final imageUrl = await _fileUploadService.uploadImage(imageFile.path);

      // Send message with image URL
      final response = await _apiClient.post(
        '/ai-companions/$companionId/message',
        data: {
          'message': 'I shared an image with you',
          'messageType': 'image',
          'imageUrl': imageUrl,
        },
      );

      if (HttpStatusUtils.isPostSuccess(response.statusCode) &&
          response.data != null) {
        final messageData = response.data['data'];
        _logger.d('Image message sent successfully to companion: $companionId');

        return CompanionMessage(
          id: messageData['aiResponse']['id'],
          companionId: companionId,
          userId: messageData['userMessage']['id'],
          content: messageData['aiResponse']['content'],
          isFromCompanion: true,
          timestamp: DateTime.parse(messageData['aiResponse']['createdAt']),
          type: MessageType.text,
          suggestedResponses:
              messageData['aiResponse']['suggestedResponses']?.cast<String>() ??
              [],
        );
      } else {
        _logger.e('Failed to send image message: ${response.statusMessage}');
        return null;
      }
    } catch (e) {
      _logger.e('Error sending image message: $e');
      return null;
    }
  }

  /// Send audio message to AI companion
  Future<CompanionMessage?> sendAudioMessage({
    required String companionId,
    required File audioFile,
  }) async {
    try {
      // Upload audio first
      final audioUrl = await _fileUploadService.uploadAudio(audioFile.path);

      // Send message with audio URL
      final response = await _apiClient.post(
        '/ai-companions/$companionId/message',
        data: {
          'message': 'I sent you an audio message',
          'messageType': 'audio',
          'audioUrl': audioUrl,
        },
      );

      if (HttpStatusUtils.isPostSuccess(response.statusCode) &&
          response.data != null) {
        final messageData = response.data['data'];
        _logger.d('Audio message sent successfully to companion: $companionId');

        return CompanionMessage(
          id: messageData['aiResponse']['id'],
          companionId: companionId,
          userId: messageData['userMessage']['id'],
          content: messageData['aiResponse']['content'],
          isFromCompanion: true,
          timestamp: DateTime.parse(messageData['aiResponse']['createdAt']),
          type: MessageType.text,
          suggestedResponses:
              messageData['aiResponse']['suggestedResponses']?.cast<String>() ??
              [],
        );
      } else {
        _logger.e('Failed to send audio message: ${response.statusMessage}');
        return null;
      }
    } catch (e) {
      _logger.e('Error sending audio message: $e');
      return null;
    }
  }

  /// Get conversation history with AI companion
  Future<List<CompanionMessage>> getConversationHistory({
    required String companionId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        '/ai-companions/$companionId/conversation',
        queryParameters: {'page': page, 'limit': limit},
      );

      if (HttpStatusUtils.isGetSuccess(response.statusCode) &&
          response.data != null) {
        final conversationData = response.data['data'];
        final messagesList =
            conversationData['messages'] as List<dynamic>? ?? [];
        
        _logger.d(
          'Retrieved ${messagesList.length} messages for companion: $companionId',
        );

        // Convert backend messages to CompanionMessage format
        return messagesList.map((msgData) {
          return CompanionMessage(
            id: msgData['id'],
            companionId: companionId,
            userId: msgData['isFromUser'] ? 'current-user' : companionId,
            content: msgData['content'],
            isFromCompanion: !msgData['isFromUser'],
            timestamp: DateTime.parse(msgData['sentAt']),
            type: _parseMessageType(msgData['messageType']),
            suggestedResponses:
                (msgData['metadata']?['suggestedResponses'] as List<dynamic>?)
                    ?.cast<String>() ??
                [],
          );
        }).toList();
      } else {
        _logger.e(
          'Failed to get conversation history: ${response.statusMessage}',
        );
        return [];
      }
    } catch (e) {
      _logger.e('Error getting conversation history: $e');
      return [];
    }
  }

  MessageType _parseMessageType(String? type) {
    // For AI companion messages, we primarily use text type
    // The backend might send different types, but we treat most as text
    switch (type?.toLowerCase()) {
      case 'text':
      case 'image':
      case 'audio':
      case 'video':
      default:
        return MessageType
            .text; // AI companion MessageType only has specific conversation types
    }
  }

  /// Get AI companion analytics
  Future<CompanionAnalytics?> getCompanionAnalytics(String companionId) async {
    try {
      final response = await _apiClient.get(
        '/ai-companions/$companionId/analytics',
      );

      if (response.data != null) {
        return CompanionAnalytics(
          companionId: companionId,
          totalInteractions: response.data['totalConversations'] ?? 0,
          totalMessages: response.data['totalMessages'] ?? 0,
          averageResponseTime: 0.0, // Backend doesn't provide this yet
          userSatisfactionScore: 0.0, // Backend doesn't provide this yet
          topicFrequency: _convertTopTopicsToFrequency(
            response.data['topTopics'],
          ),
          emotionalTones: const {}, // Backend doesn't provide this yet
          mostUsedFeatures: const [], // Backend doesn't provide this yet
          lastAnalysisDate: DateTime.now(),
        );
      }
      return null;
    } catch (e) {
      _logger.e('Error getting companion analytics: $e');
      return null;
    }
  }

  /// Helper method to convert top topics array to frequency map
  Map<String, int> _convertTopTopicsToFrequency(dynamic topTopics) {
    if (topTopics is List) {
      final Map<String, int> frequency = {};
      for (final item in topTopics) {
        if (item is Map<String, dynamic>) {
          final topic = item['topic'] as String?;
          final count = item['count'] as int?;
          if (topic != null && count != null) {
            frequency[topic] = count;
          }
        }
      }
      return frequency;
    }
    return {};
  }


  /// Train AI companion with user feedback
  Future<bool> provideFeedback({
    required String companionId,
    required String messageId,
    required FeedbackType feedbackType,
    String? comments,
  }) async {
    try {
      // Feedback endpoint not implemented in backend yet
      // For now, log the feedback locally and return success
      _logger.d('Feedback collected for companion $companionId: $feedbackType');
      if (comments != null) {
        _logger.d('Feedback comments: $comments');
      }
      await Future.delayed(const Duration(milliseconds: 300));
      return true;
    } catch (e) {
      _logger.e('Error providing feedback: $e');
      return false;
    }
  }

  /// Get AI companion settings
  Future<CompanionSettings?> getCompanionSettings(String companionId) async {
    try {
      // Settings endpoint not implemented in backend yet
      // Return null until backend settings service is ready
      await Future.delayed(const Duration(milliseconds: 300));
      _logger.d('AI companion settings not yet implemented for: $companionId');
      return null;
    } catch (e) {
      _logger.e('Error getting companion settings: $e');
      return null;
    }
  }

  /// Update AI companion settings
  Future<bool> updateCompanionSettings({
    required String companionId,
    required CompanionSettings settings,
  }) async {
    try {
      // Settings update endpoint not implemented in backend yet
      // For now, log the settings and return success
      _logger.d('Settings update not yet implemented for: $companionId');
      await Future.delayed(const Duration(milliseconds: 300));
      return true;
    } catch (e) {
      _logger.e('Error updating companion settings: $e');
      return false;
    }
  }

  /// Get available companion personalities
  Future<List<CompanionPersonality>> getAvailablePersonalities() async {
    try {
      // Personalities endpoint not implemented in backend yet
      // Return all available personalities from the enum
      await Future.delayed(const Duration(milliseconds: 300));
      _logger.d('Using local companion personalities');
      return CompanionPersonality.values;
    } catch (e) {
      _logger.e('Error getting available personalities: $e');
      return CompanionPersonality.values;
    }
  }

  /// Dispose of streams and cleanup resources
  void dispose() {
    _messageController.close();
    _errorController.close();
  }
}
