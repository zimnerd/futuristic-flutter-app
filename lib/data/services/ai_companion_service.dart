import 'package:logger/logger.dart';
import 'dart:async';
import '../models/ai_companion.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/http_status_utils.dart';
import 'ai_companion_websocket_service.dart';
import 'token_service.dart';
import 'local_chat_storage_service.dart';

/// Service for AI Companion interactions and management
class AiCompanionService {
  final StreamController<CompanionMessage> _messageController =
      StreamController<CompanionMessage>.broadcast();
  final StreamController<Map<String, dynamic>> _errorController =
      StreamController<Map<String, dynamic>>.broadcast();

  final AiCompanionWebSocketService _aiWebSocketService =
      AiCompanionWebSocketService.instance;
  final ApiClient _apiClient = ApiClient.instance;
  final LocalChatStorageService _localStorage = LocalChatStorageService();
  final Logger _logger = Logger();
  
  StreamSubscription<Map<String, dynamic>>? _webSocketMessageSubscription;
  StreamSubscription<Map<String, dynamic>>? _webSocketErrorSubscription;

  AiCompanionService() {
    _initializeWebSocketListeners();
  }

  void _initializeWebSocketListeners() {
    // Listen to WebSocket messages and forward to our stream
    _webSocketMessageSubscription = _aiWebSocketService.messageStream.listen((
      data,
    ) {
      try {
        // Handle ai_message_received events (only AI companion responses, not user message confirmations)
        if (data.containsKey('message') && data.containsKey('companionId')) {
          final messageData = data['message'] as Map<String, dynamic>;
          
          // Only process messages from AI companions (not user message confirmations)
          // This prevents duplicate user messages in the chat
          if (messageData['isFromCompanion'] == true) {
            // Add companionId and conversationId from the outer data to the message data
            if (data.containsKey('companionId')) {
              messageData['companionId'] = data['companionId'];
            }
            if (data.containsKey('conversationId') &&
                data['conversationId'] != null) {
              messageData['conversationId'] = data['conversationId'];
            }

            final message = CompanionMessage.fromJson(messageData);
            _messageController.add(message);

            // Save to local storage
            _localStorage.saveAiMessage(message);

            _logger.d(
              'Received AI companion response and forwarded to stream: ${message.id}',
            );
          } else {
            _logger.d(
              'Ignored user message confirmation from WebSocket: ${messageData['id']} (already handled by BLoC)',
            );
          }
        }
      } catch (e) {
        _logger.e('Error processing WebSocket message: $e');
      }
    });

    // Listen to WebSocket errors
    _webSocketErrorSubscription = _aiWebSocketService.errorStream.listen((
      error,
    ) {
      _errorController.add(error);
    });
  }

  // Streams for real-time events
  Stream<CompanionMessage> get messageStream => _messageController.stream;
  Stream<Map<String, dynamic>> get errorStream => _errorController.stream;

  void dispose() {
    _webSocketMessageSubscription?.cancel();
    _webSocketErrorSubscription?.cancel();
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

  /// Fetch paginated conversation history for a companion (local first, then REST)
  Future<List<CompanionMessage>> getConversationHistory({
    required String companionId,
    String? conversationId, // Optional since backend doesn't use it
    int page = 1,
    int limit = 20,
  }) async {
    try {
      // First try local storage for offline access
      final localMessages = await _localStorage.getAiMessages(companionId);
      if (localMessages.isNotEmpty) {
        _logger.d(
          'Retrieved ${localMessages.length} messages from local storage',
        );
        // If we have local messages, return them and sync in background
        _syncMessagesInBackground(companionId, page, limit);
        return localMessages;
      }
      
      // If no local messages, fetch from server
      final response = await _apiClient.get(
        '/ai-companions/$companionId/conversation',
        queryParameters: {'page': page, 'limit': limit},
      );
      if (HttpStatusUtils.isGetSuccess(response.statusCode) &&
          response.data != null) {
        final List<dynamic> data = response.data['data']?['messages'] ?? [];
        final messages = data
            .map((json) => CompanionMessage.fromJson(json))
            .toList();
        _logger.d('Fetched ${messages.length} messages via REST');
        
        // Save to local storage for offline access
        for (final message in messages) {
          await _localStorage.saveAiMessage(message);
        }
        
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

  /// Background sync for messages when local cache exists
  void _syncMessagesInBackground(String companionId, int page, int limit) {
    // Run sync in background without blocking UI
    Future.delayed(Duration.zero, () async {
      try {
        final response = await _apiClient.get(
          '/ai-companions/$companionId/conversation',
          queryParameters: {'page': page, 'limit': limit},
        );
        if (HttpStatusUtils.isGetSuccess(response.statusCode) &&
            response.data != null) {
          final List<dynamic> data = response.data['messages'] ?? [];
          final serverMessages = data
              .map((json) => CompanionMessage.fromJson(json))
              .toList();

          // Update local storage with server messages
          for (final message in serverMessages) {
            await _localStorage.saveAiMessage(message);
          }
          _logger.d(
            'Background sync: Updated ${serverMessages.length} messages',
          );
        }
      } catch (e) {
        _logger.w('Background sync failed: $e');
      }
    });
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
    CompanionGender? gender,
    CompanionAge? ageGroup,
    String? description,
    List<String>? interests,
    Map<String, dynamic>? voiceSettings,
    String? customPrompt,
  }) async {
    try {
      final requestData = {
        'name': name,
        'personality': personality.name,
        'gender': gender?.name ?? 'female', // Default to female
        'ageGroup': ageGroup?.name ?? 'adult', // Default to adult
        'description':
            description ??
            'A personalized AI companion to help with dating advice',
        'interests': interests ?? ['dating', 'relationships', 'conversation'],
      };

      // Add voice settings if provided
      if (voiceSettings != null && voiceSettings.isNotEmpty) {
        requestData['voiceSettings'] = voiceSettings;
      }

      final response = await _apiClient.post(
        '/ai-companions',
        data: requestData,
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
      
      // Check if it's a foreign key constraint error
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('foreign key') ||
          errorString.contains('constraint') ||
          errorString.contains('companion_conversations_companionid_fkey')) {
        throw Exception(
          'Cannot delete companion: Active conversations exist. Please delete conversations first.',
        );
      } else if (errorString.contains('500')) {
        throw Exception(
          'Server error occurred while deleting companion. Please try again.',
        );
      }

      // Re-throw original error if not a known case
      rethrow;
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
