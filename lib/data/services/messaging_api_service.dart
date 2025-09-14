import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../core/constants/api_constants.dart';
import '../../core/utils/logger.dart';
import '../models/conversation.dart';
import '../models/message.dart';

/// Service for messaging API integration with NestJS backend
class MessagingApiService {
  static MessagingApiService? _instance;
  static MessagingApiService get instance => _instance ??= MessagingApiService._();
  MessagingApiService._();

  io.Socket? _socket;
  String? _authToken;

  /// Set authentication token
  void setAuthToken(String authToken) {
    _authToken = authToken;
  }

  /// Initialize WebSocket connection for real-time messaging
  Future<void> initializeSocket(String authToken) async {
    _authToken = authToken;
    
    try {
      _socket = io.io(
        ApiConstants.websocketUrl,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .setAuth({'token': authToken})
            .enableAutoConnect()
            .build(),
      );

      _socket!.connect();
      
      _socket!.onConnect((_) {
        AppLogger.info('Messaging WebSocket connected');
      });

      _socket!.onConnectError((error) {
        AppLogger.error('Messaging WebSocket connection error: $error');
      });

      _socket!.onDisconnect((_) {
        AppLogger.info('Messaging WebSocket disconnected');
      });

    } catch (e) {
      AppLogger.error('Failed to initialize messaging socket: $e');
      rethrow;
    }
  }

  /// Get conversations list from API
  Future<List<Conversation>> getConversations({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/conversations')
            .replace(queryParameters: queryParams),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['conversations'] as List)
            .map((json) => Conversation.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load conversations: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error fetching conversations: $e');
      rethrow;
    }
  }

  /// Get messages for a specific conversation
  Future<List<Message>> getMessages(
    String conversationId, {
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/conversations/$conversationId/messages')
            .replace(queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
        }),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['messages'] as List)
            .map((json) => Message.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load messages: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error fetching messages: $e');
      rethrow;
    }
  }

  /// Send a message via WebSocket
  void sendMessage({
    required String conversationId,
    required String content,
    required String type,
    Map<String, dynamic>? metadata,
  }) {
    if (_socket?.connected != true) {
      throw Exception('WebSocket not connected');
    }

    _socket!.emit('send_message', {
      'conversationId': conversationId,
      'content': content,
      'type': type,
      'metadata': metadata,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Listen for incoming messages
  void listenForMessages(Function(Message) onMessage) {
    _socket?.on('new_message', (data) {
      try {
        final message = Message.fromJson(data);
        onMessage(message);
      } catch (e) {
        AppLogger.error('Error parsing incoming message: $e');
      }
    });
  }

  /// Listen for typing indicators
  void listenForTyping(Function(String conversationId, String userId, bool isTyping) onTyping) {
    _socket?.on('user_typing', (data) {
      try {
        onTyping(
          data['conversationId'] as String,
          data['userId'] as String,
          data['isTyping'] as bool,
        );
      } catch (e) {
        AppLogger.error('Error parsing typing indicator: $e');
      }
    });
  }

  /// Send typing indicator
  void sendTypingIndicator({
    required String conversationId,
    required bool isTyping,
  }) {
    if (_socket?.connected == true) {
      _socket!.emit('typing', {
        'conversationId': conversationId,
        'isTyping': isTyping,
      });
    }
  }

  /// Mark conversation as read
  Future<void> markAsRead(String conversationId) async {
    try {
      final response = await http.patch(
        Uri.parse('${ApiConstants.baseUrl}/conversations/$conversationId/read'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark as read: ${response.statusCode}');
      }

      // Also emit via WebSocket for real-time updates
      if (_socket?.connected == true) {
        _socket!.emit('mark_read', {'conversationId': conversationId});
      }
    } catch (e) {
      AppLogger.error('Error marking conversation as read: $e');
      rethrow;
    }
  }

  /// Listen for message status updates (sent, delivered, read)
  void listenForMessageStatus(Function(String messageId, String status) onStatusUpdate) {
    _socket?.on('message_status', (data) {
      try {
        onStatusUpdate(
          data['messageId'] as String,
          data['status'] as String,
        );
      } catch (e) {
        AppLogger.error('Error parsing message status: $e');
      }
    });
  }

  /// Listen for online/offline status of users
  void listenForUserStatus(Function(String userId, bool isOnline) onStatusChange) {
    _socket?.on('user_status', (data) {
      try {
        onStatusChange(
          data['userId'] as String,
          data['isOnline'] as bool,
        );
      } catch (e) {
        AppLogger.error('Error parsing user status: $e');
      }
    });
  }

  /// Disconnect WebSocket
  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }

  /// Check if WebSocket is connected
  bool get isConnected => _socket?.connected == true;
}
