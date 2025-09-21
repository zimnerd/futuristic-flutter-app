import 'package:logger/logger.dart';
import 'dart:async';
import '../models/ai_companion.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/http_status_utils.dart';
import 'ai_companion_websocket_service.dart';
import 'token_service.dart';

/// Service for AI Companion interactions and management
class AiCompanionService {
  final StreamController<CompanionMessage> _messageController =
      StreamController<CompanionMessage>.broadcast();
  final StreamController<Map<String, dynamic>> _errorController =
      StreamController<Map<String, dynamic>>.broadcast();

  final AiCompanionWebSocketService _aiWebSocketService =
      AiCompanionWebSocketService.instance;
  final ApiClient _apiClient = ApiClient.instance;
  final Logger _logger = Logger();

  AiCompanionService();

  // Streams for real-time events
  Stream<CompanionMessage> get messageStream => _messageController.stream;
  Stream<Map<String, dynamic>> get errorStream => _errorController.stream;

  void dispose() {
    _messageController.close();
    _errorController.close();
  }

  // Stub for image messaging (not supported via WebSocket yet)
  Future<CompanionMessage?> sendImageMessage({
    required String companionId,
    required dynamic imageFile,
  }) async {
    throw UnimplementedError(
      'Image messaging is not supported via WebSocket yet.',
    );
  }

  // Stub for audio messaging (not supported via WebSocket yet)
  Future<CompanionMessage?> sendAudioMessage({
    required String companionId,
    required dynamic audioFile,
  }) async {
    throw UnimplementedError(
      'Audio messaging is not supported via WebSocket yet.',
    );
  }

  /// Fetch paginated conversation history for a companion (WebSocket preferred, REST fallback)
  Future<List<CompanionMessage>> getConversationHistory({
    required String companionId,
    required String conversationId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      // Try WebSocket first (if supported)
      if (_aiWebSocketService.isConnected &&
          _aiWebSocketService.supportsHistory) {
        final messages = await _aiWebSocketService.getConversationHistory(
          companionId: companionId,
          conversationId: conversationId,
          page: page,
          limit: limit,
        );
        _logger.d('Fetched ${messages.length} messages via WebSocket');
        return messages;
      }
      // Fallback to REST if WebSocket not available or not supported
      final response = await _apiClient.get(
        '/ai-companions/$companionId/conversations/$conversationId/messages',
        queryParameters: {'page': page, 'limit': limit},
      );
      if (HttpStatusUtils.isGetSuccess(response.statusCode) &&
          response.data != null) {
        final List<dynamic> data = response.data['data']['messages'] ?? [];
        final messages = data
            .map((json) => CompanionMessage.fromJson(json))
            .toList();
        _logger.d('Fetched ${messages.length} messages via REST');
        return messages;
      } else {
        _logger.e(
          'Failed to fetch conversation history: ${response.statusMessage}',
        );
        return [];
      }
    } catch (e) {
      _logger.e('Error fetching conversation history: $e');
      return [];
    }
  }

  // Stub for updating companion settings
  Future<bool> updateCompanionSettings({
    required String companionId,
    required Map<String, dynamic> settings,
  }) async {
    throw UnimplementedError(
      'Update companion settings is not implemented yet.',
    );
  }

  // Stub for getting companion analytics
  Future<dynamic> getCompanionAnalytics(String companionId) async {
    throw UnimplementedError('Companion analytics is not implemented yet.');
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
        final companions = data
            .map((json) => AICompanion.fromJson(json))
            .toList();

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
      final response = await _apiClient.get('/ai-companions/$companionId');

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
      final response = await _apiClient.delete('/ai-companions/$companionId');

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
  Future<void> sendMessage({
    required String companionId,
    required String message,
    String? conversationId,
  }) async {
    try {
      _logger.d('Sending message to AI companion: $companionId');
      // Check WebSocket connection status first
      if (!_aiWebSocketService.isConnected) {
        _logger.w('AI WebSocket not connected, attempting to reconnect...');
        final tokenService = TokenService();
        final authToken = await tokenService.getAccessToken();
        if (authToken != null) {
          _logger.i(
            '🔄 Re-establishing AI WebSocket connection with auth token...',
          );
          await _aiWebSocketService.connect(authToken);
          int attempts = 0;
          while (!_aiWebSocketService.isConnected && attempts < 10) {
            await Future.delayed(const Duration(milliseconds: 100));
            attempts++;
          }
          if (_aiWebSocketService.isConnected) {
            _logger.i('✅ AI WebSocket reconnected successfully');
          } else {
            _logger.e('❌ Failed to reconnect AI WebSocket after 1 second');
            _errorController.add({
              'error': 'Connection failed',
              'details': 'Could not establish AI WebSocket connection',
              'companionId': companionId,
            });
            return;
          }
        } else {
          _logger.e('❌ No auth token available for AI WebSocket connection');
          _errorController.add({
            'error': 'Authentication required',
            'details': 'No auth token available',
            'companionId': companionId,
          });
          return;
        }
      }

      await _aiWebSocketService.sendAiMessage(
        companionId: companionId,
        message: message,
        messageType: 'text',
        metadata: {},
      );
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
}
