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
        final List<dynamic> data = response.data['data'] ?? response.data['conversations'] ?? [];
        final conversations = data.map((json) {
          // Transform backend ConversationResult to frontend Conversation format
          final participants = (json['participants'] as List?) ?? [];

          final transformedJson = {
            'id': json['id'] as String? ?? '',
            'title': json['title'] as String?,
            'participants': participants
                .map(
                  (p) => {
                    'id': p['userId'] as String? ?? '',
                    'email':
                        '${p['username']}@temp.com', // Required field - use temp email
                    'username': p['username'] as String? ?? 'Unknown',
                    'displayName': p['username'] as String? ?? 'Unknown',
                    'profileImageUrl': p['avatar'] as String?,
                    'isOnline': p['isOnline'] as bool? ?? false,
                    'lastSeen': p['lastReadAt'] as String?,
                    'interests': <String>[],
                    'photos': <String>[],
                    'isVerified': false,
                    'isPremium': false,
                    'createdAt':
                        p['joinedAt'] as String? ??
                        DateTime.now().toIso8601String(),
                    'updatedAt':
                        p['joinedAt'] as String? ??
                        DateTime.now().toIso8601String(),
                  },
                )
                .toList(),
            'lastMessage':
                null, // We don't have lastMessage in this format from API
            'lastActivity': json['updatedAt'] as String?,
            'unreadCount': json['unreadCount'] as int? ?? 0,
            'isActive': true,
            'isBlocked': false,
            'metadata': null,
            'createdAt':
                json['createdAt'] as String? ??
                DateTime.now().toIso8601String(),
            'updatedAt':
                json['updatedAt'] as String? ??
                DateTime.now().toIso8601String(),
          };
          return Conversation.fromJson(transformedJson);
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