import 'package:logger/logger.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../../core/network/api_client.dart';

/// Service for managing conversations and messages
/// Connects to real backend API instead of using mock data
class ConversationService {
  final ApiClient _apiClient = ApiClient.instance;
  final Logger _logger = Logger();

  /// Get all user conversations
  Future<List<Conversation>> getUserConversations({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _apiClient.getConversations(
        limit: limit,
        offset: offset,
      );

      if (response.statusCode == 200 && response.data != null) {
        // Handle wrapped response structure: { data: { conversations: [...] } }
        final responseData = response.data['data'] ?? response.data;
        final List<dynamic> data =
            responseData['conversations'] ?? responseData ?? [];
        final conversations = data.map<Conversation>((json) {
          return Conversation.fromJson(json as Map<String, dynamic>);
        }).toList();
        
        _logger.d('Retrieved ${conversations.length} conversations');
        return conversations;
      } else {
        _logger.e('Failed to get conversations: ${response.statusMessage}');
        return [];
      }
    } catch (e) {
      _logger.e('Error getting conversations: $e');
      return [];
    }
  }

  /// Get messages from a specific conversation
  Future<List<Message>> getConversationMessages({
    required String conversationId,
    int limit = 50,
    String? before,
  }) async {
    try {
      final response = await _apiClient.getMessages(
        conversationId: conversationId,
        limit: limit,
        before: before,
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['data'] ?? response.data['messages'] ?? [];
        final messages = data.map((json) => Message.fromJson(json)).toList();
        
        _logger.d('Retrieved ${messages.length} messages for conversation $conversationId');
        return messages;
      } else {
        _logger.e('Failed to get messages: ${response.statusMessage}');
        return [];
      }
    } catch (e) {
      _logger.e('Error getting conversation messages: $e');
      return [];
    }
  }

  /// Send a message in a conversation
  Future<Message?> sendMessage({
    required String conversationId,
    required String content,
    String type = 'text',
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await _apiClient.sendMessage(
        conversationId: conversationId,
        content: content,
        type: type,
        metadata: metadata,
      );

      if (response.statusCode == 201 && response.data != null) {
        final message = Message.fromJson(response.data['data'] ?? response.data);
        _logger.d('Message sent successfully: ${message.id}');
        return message;
      } else {
        _logger.e('Failed to send message: ${response.statusMessage}');
        return null;
      }
    } catch (e) {
      _logger.e('Error sending message: $e');
      return null;
    }
  }

  /// Create a new conversation
  Future<Conversation?> createConversation({
    required String participantId,
    String? title,
    bool isGroup = false,
    String? initialMessage,
  }) async {
    try {
      final response = await _apiClient.createConversation(
        participantId: participantId,
        title: title,
        isGroup: isGroup,
        initialMessage: initialMessage,
      );

      if (response.statusCode == 201 && response.data != null) {
        final conversation = Conversation.fromJson(response.data);
        _logger.d('Conversation created successfully: ${conversation.id}');
        return conversation;
      } else {
        _logger.e('Failed to create conversation: ${response.statusMessage}');
        return null;
      }
    } catch (e) {
      _logger.e('Error creating conversation: $e');
      return null;
    }
  }

  /// Mark conversation as read
  Future<bool> markConversationAsRead(String conversationId) async {
    try {
      final response = await _apiClient.markConversationAsRead(conversationId);

      if (response.statusCode == 200) {
        _logger.d('Conversation marked as read: $conversationId');
        return true;
      } else {
        _logger.e('Failed to mark conversation as read: ${response.statusMessage}');
        return false;
      }
    } catch (e) {
      _logger.e('Error marking conversation as read: $e');
      return false;
    }
  }

  /// Mark specific messages as read
  Future<bool> markMessagesAsRead({
    required String conversationId,
    required List<String> messageIds,
  }) async {
    try {
      final response = await _apiClient.markMessagesAsRead(
        conversationId: conversationId,
        messageIds: messageIds,
      );

      if (response.statusCode == 200) {
        _logger.d('Messages marked as read: ${messageIds.length} messages');
        return true;
      } else {
        _logger.e('Failed to mark messages as read: ${response.statusMessage}');
        return false;
      }
    } catch (e) {
      _logger.e('Error marking messages as read: $e');
      return false;
    }
  }
}