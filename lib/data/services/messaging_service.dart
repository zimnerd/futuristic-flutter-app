import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../domain/entities/conversation.dart';
import '../../../domain/entities/message.dart';

/// Service for messaging operations that matches BLoC expectations
class MessagingService {
  final ApiClient _apiClient;

  MessagingService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Get conversations for current user
  Future<List<Conversation>> getConversations({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.getConversations,
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final conversations = data['conversations'] as List<dynamic>;

      return conversations
          .map((conv) => _conversationFromJson(conv as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get messages for a conversation
  Future<List<Message>> getMessages({
    required String conversationId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.getMessages}/$conversationId/messages',
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final messages = data['messages'] as List<dynamic>;

      return messages
          .map((msg) => _messageFromJson(msg as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Send a message
  Future<Message> sendMessage({
    required String conversationId,
    required String content,
    String type = 'text',
    String? mediaUrl,
    String? replyToMessageId,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.sendMessage}/$conversationId/messages',
        data: {
          'content': content,
          'type': type,
          'mediaUrl': mediaUrl,
          'replyToMessageId': replyToMessageId,
        },
      );

      return _messageFromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Mark conversation as read
  Future<void> markConversationAsRead(String conversationId) async {
    try {
      await _apiClient.patch('${ApiConstants.markAsRead}/$conversationId/read');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Delete conversation
  Future<void> deleteConversation(String conversationId) async {
    try {
      await _apiClient.delete('${ApiConstants.getConversations}/$conversationId');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Block user
  Future<void> blockUser(String userId) async {
    try {
      await _apiClient.post(
        '${ApiConstants.users}/block',
        data: {'userId': userId},
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Report conversation
  Future<void> reportConversation(String conversationId, String reason) async {
    try {
      await _apiClient.post(
        '${ApiConstants.getConversations}/$conversationId/report',
        data: {'reason': reason},
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Convert JSON to Conversation entity
  Conversation _conversationFromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      otherUserId: json['otherUser']['id'] as String,
      otherUserName: json['otherUser']['name'] as String,
      otherUserAvatar: json['otherUser']['avatar'] as String? ?? '',
      lastMessage: json['lastMessage']?['content'] as String? ?? '',
      lastMessageTime: json['lastMessage']?['createdAt'] != null
          ? DateTime.parse(json['lastMessage']['createdAt'] as String)
          : DateTime.now(),
      unreadCount: json['unreadCount'] as int? ?? 0,
      isOnline: json['otherUser']['isOnline'] as bool? ?? false,
      lastSeen: json['otherUser']['lastSeen'] != null
          ? DateTime.parse(json['otherUser']['lastSeen'] as String)
          : null,
      isBlocked: json['isBlocked'] as bool? ?? false,
      isMuted: json['isMuted'] as bool? ?? false,
      isPinned: json['isPinned'] as bool? ?? false,
      matchedAt: json['matchedAt'] != null
          ? DateTime.parse(json['matchedAt'] as String)
          : null,
    );
  }

  /// Convert JSON to Message entity
  Message _messageFromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      senderId: json['senderId'] as String,
      content: json['content'] as String,
      type: _messageTypeFromString(json['type'] as String? ?? 'text'),
      timestamp: DateTime.parse(json['createdAt'] as String),
      replyToMessageId: json['replyToMessageId'] as String?,
      isDelivered: json['isDelivered'] as bool? ?? true,
      isRead: json['isRead'] as bool? ?? false,
      isOptimistic: false, // Server messages are not optimistic
      mediaUrl: json['mediaUrl'] as String?,
      mediaType: json['mediaType'] as String?,
      mediaDuration: json['mediaDuration'] as int?,
      reactions: (json['reactions'] as List<dynamic>?)
              ?.map((r) => _messageReactionFromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Convert string to MessageType enum
  MessageType _messageTypeFromString(String type) {
    switch (type.toLowerCase()) {
      case 'text':
        return MessageType.text;
      case 'image':
        return MessageType.image;
      case 'video':
        return MessageType.video;
      case 'audio':
        return MessageType.audio;
      case 'gif':
        return MessageType.gif;
      case 'sticker':
        return MessageType.sticker;
      case 'location':
        return MessageType.location;
      case 'contact':
        return MessageType.contact;
      default:
        return MessageType.text;
    }
  }

  /// Convert JSON to MessageReaction entity
  MessageReaction _messageReactionFromJson(Map<String, dynamic> json) {
    return MessageReaction(
      id: json['id'] as String,
      messageId: json['messageId'] as String,
      emoji: json['emoji'] as String,
      userId: json['userId'] as String,
      timestamp: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Handle Dio errors and convert them to meaningful exceptions
  Exception _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return Exception('Request timeout. Please check your internet connection.');
      case DioExceptionType.connectionError:
        return Exception('No internet connection. Please check your network settings.');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['message'] ?? 'An error occurred';
        switch (statusCode) {
          case 400:
            return Exception('Bad request: $message');
          case 401:
            return Exception('Unauthorized: Please login again');
          case 403:
            return Exception('Forbidden: $message');
          case 404:
            return Exception('Not found: $message');
          case 429:
            return Exception('Too many requests. Please try again later.');
          case 500:
            return Exception('Server error. Please try again later.');
          default:
            return Exception('HTTP $statusCode: $message');
        }
      default:
        return Exception('An unexpected error occurred: ${e.message}');
    }
  }

  /// Start a conversation from a match and send initial message
  Future<Conversation> startConversationFromMatch({
    required String matchId,
    required String initialMessage,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.conversations}/start-from-match',
        data: {'matchId': matchId, 'message': initialMessage},
      );

      final data = response.data as Map<String, dynamic>;
      return _conversationFromJson(
        data['conversation'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
}
