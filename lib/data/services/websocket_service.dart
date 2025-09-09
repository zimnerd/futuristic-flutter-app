import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:logger/logger.dart';

import '../../../core/constants/api_constants.dart';
import '../../../domain/entities/message.dart';

class WebSocketService {
  static WebSocketService? _instance;
  static WebSocketService get instance => _instance ??= WebSocketService._();
  
  WebSocketService._();

  final Logger _logger = Logger();
  io.Socket? _socket;
  bool _isConnected = false;

  // Event callbacks
  Function(Message)? onMessageReceived;
  Function(String, String)? onTypingReceived;
  Function(String)? onTypingStoppedReceived;
  Function(String, bool)? onUserStatusChanged;
  Function(String)? onCallReceived;
  Function(String)? onCallEnded;

  bool get isConnected => _isConnected;

  Future<void> connect(String userId, String token) async {
    if (_isConnected) return;

    try {
      _socket = io.io(
        ApiConstants.websocketUrl,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .setAuth({'token': token, 'userId': userId})
            .enableReconnection()
            .build(),
      );

      _socket?.onConnect((_) {
        _logger.d('WebSocket connected');
        _isConnected = true;
      });

      _socket?.onDisconnect((_) {
        _logger.d('WebSocket disconnected');
        _isConnected = false;
      });

      _socket?.onConnectError((error) {
        _logger.e('WebSocket connection error: $error');
        _isConnected = false;
      });

      _setupEventListeners();
      _socket?.connect();
    } catch (e) {
      _logger.e('Failed to connect WebSocket: $e');
      _isConnected = false;
    }
  }

  void _setupEventListeners() {
    // Message events
    _socket?.on('new_message', (data) {
      try {
        final messageData = data as Map<String, dynamic>;
        final message = Message.fromJson(messageData);
        onMessageReceived?.call(message);
      } catch (e) {
        _logger.e('Error parsing new message: $e');
      }
    });

    // Typing events
    _socket?.on('user_typing', (data) {
      try {
        final typingData = data as Map<String, dynamic>;
        final userId = typingData['userId'] as String;
        final conversationId = typingData['conversationId'] as String;
        onTypingReceived?.call(userId, conversationId);
      } catch (e) {
        _logger.e('Error parsing typing event: $e');
      }
    });

    _socket?.on('user_stopped_typing', (data) {
      try {
        final typingData = data as Map<String, dynamic>;
        final userId = typingData['userId'] as String;
        onTypingStoppedReceived?.call(userId);
      } catch (e) {
        _logger.e('Error parsing stopped typing event: $e');
      }
    });

    // User status events
    _socket?.on('user_online', (data) {
      try {
        final statusData = data as Map<String, dynamic>;
        final userId = statusData['userId'] as String;
        onUserStatusChanged?.call(userId, true);
      } catch (e) {
        _logger.e('Error parsing user online event: $e');
      }
    });

    _socket?.on('user_offline', (data) {
      try {
        final statusData = data as Map<String, dynamic>;
        final userId = statusData['userId'] as String;
        onUserStatusChanged?.call(userId, false);
      } catch (e) {
        _logger.e('Error parsing user offline event: $e');
      }
    });

    // Call events
    _socket?.on('incoming_call', (data) {
      try {
        final callData = data as Map<String, dynamic>;
        final callId = callData['callId'] as String;
        onCallReceived?.call(callId);
      } catch (e) {
        _logger.e('Error parsing incoming call: $e');
      }
    });

    _socket?.on('call_ended', (data) {
      try {
        final callData = data as Map<String, dynamic>;
        final callId = callData['callId'] as String;
        onCallEnded?.call(callId);
      } catch (e) {
        _logger.e('Error parsing call ended: $e');
      }
    });
  }

  // Send message
  void sendMessage(String conversationId, String content, MessageType type) {
    if (!_isConnected) return;

    _socket?.emit('send_message', {
      'conversationId': conversationId,
      'content': content,
      'type': type.name,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Send typing indicator
  void sendTyping(String conversationId) {
    if (!_isConnected) return;

    _socket?.emit('typing', {
      'conversationId': conversationId,
    });
  }

  void sendStoppedTyping(String conversationId) {
    if (!_isConnected) return;

    _socket?.emit('stopped_typing', {
      'conversationId': conversationId,
    });
  }

  // Join conversation
  void joinConversation(String conversationId) {
    if (!_isConnected) return;

    _socket?.emit('join_conversation', {
      'conversationId': conversationId,
    });
  }

  void leaveConversation(String conversationId) {
    if (!_isConnected) return;

    _socket?.emit('leave_conversation', {
      'conversationId': conversationId,
    });
  }

  // Call events
  void initiateCall(String userId, String callType) {
    if (!_isConnected) return;

    _socket?.emit('initiate_call', {
      'targetUserId': userId,
      'callType': callType, // 'video' or 'audio'
    });
  }

  void acceptCall(String callId) {
    if (!_isConnected) return;

    _socket?.emit('accept_call', {
      'callId': callId,
    });
  }

  void rejectCall(String callId) {
    if (!_isConnected) return;

    _socket?.emit('reject_call', {
      'callId': callId,
    });
  }

  void endCall(String callId) {
    if (!_isConnected) return;

    _socket?.emit('end_call', {
      'callId': callId,
    });
  }

  // Update user status
  void updateUserStatus(bool isOnline) {
    if (!_isConnected) return;

    _socket?.emit('update_status', {
      'isOnline': isOnline,
    });
  }

  // Disconnect
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }

  // Clear callbacks
  void clearCallbacks() {
    onMessageReceived = null;
    onTypingReceived = null;
    onTypingStoppedReceived = null;
    onUserStatusChanged = null;
    onCallReceived = null;
    onCallEnded = null;
  }
}
