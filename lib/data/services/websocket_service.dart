import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:logger/logger.dart';
import 'dart:async';

import '../../../core/constants/api_constants.dart';
import '../../../domain/entities/message.dart' as domain;
import '../models/call_model.dart';
import '../models/chat_model.dart';
import '../models/notification_model.dart';

class WebSocketService {
  static WebSocketService? _instance;
  static WebSocketService get instance => _instance ??= WebSocketService._();
  
  WebSocketService._();

  final Logger _logger = Logger();
  io.Socket? _socket;
  bool _isConnected = false;

  // Event callbacks
  Function(domain.Message)? onMessageReceived;
  Function(NotificationModel)? onNotificationReceived;
  Function(String, String)? onTypingReceived;
  Function(String)? onTypingStoppedReceived;
  Function(String, bool)? onUserStatusChanged;
  Function(String)? onCallReceived;
  Function(String)? onCallEnded;
  Function(CallSignalModel)? onCallSignalReceived;
  Function(bool)? onConnectionStatusChanged;

  // Stream controllers for real-time coordination
  final StreamController<MessageModel> _messageController =
      StreamController<MessageModel>.broadcast();
  final StreamController<NotificationModel> _notificationController =
      StreamController<NotificationModel>.broadcast();
  final StreamController<CallSignalModel> _callController =
      StreamController<CallSignalModel>.broadcast();

  // Stream getters
  Stream<MessageModel> get messageStream => _messageController.stream;
  Stream<NotificationModel> get notificationStream =>
      _notificationController.stream;
  Stream<CallSignalModel> get callStream => _callController.stream;

  // Controller getters for backward compatibility
  StreamController<MessageModel> get messageController => _messageController;
  StreamController<NotificationModel> get notificationController =>
      _notificationController;
  StreamController<CallSignalModel> get callController => _callController;

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
        onConnectionStatusChanged?.call(true);
      });

      _socket?.onDisconnect((_) {
        _logger.d('WebSocket disconnected');
        _isConnected = false;
        onConnectionStatusChanged?.call(false);
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
    _socket?.on('messageReceived', (data) {
      try {
        final messageData = data['data'] as Map<String, dynamic>;
        final message = domain.Message.fromJson(messageData);
        onMessageReceived?.call(message);
        
        // Also emit to stream if it's a MessageModel
        if (messageData.containsKey('conversationId')) {
          final messageModel = MessageModel.fromJson(messageData);
          _messageController.add(messageModel);
        }
      } catch (e) {
        _logger.e('Error parsing messageReceived: $e');
      }
    });

    _socket?.on('messageDelivered', (data) {
      try {
        _logger.d('Message delivered: $data');
        // Handle message delivery confirmation
      } catch (e) {
        _logger.e('Error parsing messageDelivered: $e');
      }
    });

    _socket?.on('messageFailed', (data) {
      try {
        _logger.e('Message failed: $data');
        // Handle message failure
      } catch (e) {
        _logger.e('Error parsing messageFailed: $e');
      }
    });

    // Typing events
    _socket?.on('typingIndicatorUpdate', (data) {
      try {
        final typingData = data as Map<String, dynamic>;
        final userId = typingData['userId'] as String;
        final conversationId = typingData['conversationId'] as String;
        final isTyping = typingData['isTyping'] as bool;

        if (isTyping) {
          onTypingReceived?.call(userId, conversationId);
        } else {
          onTypingStoppedReceived?.call(userId);
        }
      } catch (e) {
        _logger.e('Error parsing typing indicator: $e');
      }
    });

    // User status events
    _socket?.on('userStatusUpdate', (data) {
      try {
        final statusData = data as Map<String, dynamic>;
        final userId = statusData['userId'] as String;
        final status = statusData['status'] as String;
        final isOnline = status == 'ONLINE';
        onUserStatusChanged?.call(userId, isOnline);
      } catch (e) {
        _logger.e('Error parsing user status event: $e');
      }
    });

    // Call events
    _socket?.on('callInitiated', (data) {
      try {
        final callData = data as Map<String, dynamic>;
        final callId = callData['callId'] as String;
        onCallReceived?.call(callId);
      } catch (e) {
        _logger.e('Error parsing call initiated: $e');
      }
    });

    _socket?.on('callEnded', (data) {
      try {
        final callData = data as Map<String, dynamic>;
        final callId = callData['callId'] as String;
        onCallEnded?.call(callId);
      } catch (e) {
        _logger.e('Error parsing call ended: $e');
      }
    });

    // Call signal events
    _socket?.on('callSignal', (data) {
      try {
        final signalData = data as Map<String, dynamic>;
        final signal = CallSignalModel.fromJson(signalData);
        onCallSignalReceived?.call(signal);
        _callController.add(signal);
      } catch (e) {
        _logger.e('Error parsing call signal: $e');
      }
    });

    // Notification events
    _socket?.on('newNotification', (data) {
      try {
        final notificationData = data as Map<String, dynamic>;
        final notification = NotificationModel.fromJson(notificationData);
        onNotificationReceived?.call(notification);
        _notificationController.add(notification);
      } catch (e) {
        _logger.e('Error parsing notification: $e');
      }
    });
  }

  // Send message
  void sendMessage(
    String conversationId,
    String content,
    domain.MessageType type, {
    List<String>? mediaIds,
    Map<String, dynamic>? metadata,
    String? replyToMessageId,
    bool? isForwarded,
    String? forwardedFromConversationId,
  }) {
    if (!_isConnected) return;

    // Match backend SendMessageDto structure exactly
    final Map<String, dynamic> payload = {
      'conversationId': conversationId,
      'type': type.name,
      'content': content,
    };

    // Add optional fields only if provided
    if (mediaIds != null && mediaIds.isNotEmpty) {
      payload['mediaIds'] = mediaIds;
    }
    if (metadata != null && metadata.isNotEmpty) {
      payload['metadata'] = metadata;
    }
    if (replyToMessageId != null && replyToMessageId.isNotEmpty) {
      payload['replyToMessageId'] = replyToMessageId;
    }
    if (isForwarded != null) {
      payload['isForwarded'] = isForwarded;
    }
    if (forwardedFromConversationId != null &&
        forwardedFromConversationId.isNotEmpty) {
      payload['forwardedFromConversationId'] = forwardedFromConversationId;
    }

    _logger.d('Sending message with payload: $payload');
    _socket?.emit('sendMessage', payload);
  }

  // Send typing indicator
  void sendTyping(String conversationId) {
    if (!_isConnected) return;

    _socket?.emit('typingIndicator', {
      'conversationId': conversationId,
      'isTyping': true,
    });
  }

  void sendTypingIndicator(String conversationId, bool isTyping) {
    if (!_isConnected) return;

    _socket?.emit('typingIndicator', {
      'conversationId': conversationId,
      'isTyping': isTyping,
    });
  }

  void sendStoppedTyping(String conversationId) {
    if (!_isConnected) return;

    _socket?.emit('typingIndicator', {
      'conversationId': conversationId,
      'isTyping': false,
    });
  }

  // Send AI message
  void sendAiMessage(String message, String? companionId) {
    if (!_isConnected) {
      _logger.w('Cannot send AI message: not connected');
      return;
    }

    _socket?.emit('sendAiMessage', {
      'companionId': companionId,
      'message': message,
      'messageType': 'text',
      'metadata': {},
    });
  }

  // Join conversation
  void joinConversation(String conversationId) {
    if (!_isConnected) return;

    _socket?.emit('joinConversation', {
      'conversationId': conversationId,
    });
  }

  void leaveConversation(String conversationId) {
    if (!_isConnected) return;

    _socket?.emit('leaveConversation', {
      'conversationId': conversationId,
    });
  }

  // Call events
  void initiateCall(String userId, String callType) {
    if (!_isConnected) return;

    _socket?.emit('initiateCall', {
      'targetUserId': userId,
      'callType': callType, // 'video' or 'audio'
    });
  }

  void acceptCall(String callId) {
    if (!_isConnected) return;

    _socket?.emit('acceptCall', {
      'callId': callId,
    });
  }

  void rejectCall(String callId) {
    if (!_isConnected) return;

    _socket?.emit('rejectCall', {
      'callId': callId,
    });
  }

  void endCall(String callId) {
    if (!_isConnected) return;

    _socket?.emit('end_call', {
      'callId': callId,
    });
  }

  // Send call signal
  void sendCallSignal(CallSignalModel signal) {
    if (!_isConnected) return;

    _socket?.emit('call_signal', signal.toJson());
  }

  // Update user status
  void updateUserStatus(bool isOnline) {
    if (!_isConnected) return;

    _socket?.emit('update_status', {
      'isOnline': isOnline,
    });
  }

  // Toggle video during call
  void toggleCallVideo(String callId, bool enabled) {
    if (!_isConnected) return;

    _socket?.emit('toggle_call_video', {
      'callId': callId,
      'enabled': enabled,
    });
  }

  // Toggle audio during call
  void toggleCallAudio(String callId, bool enabled) {
    if (!_isConnected) return;

    _socket?.emit('toggle_call_audio', {
      'callId': callId,
      'enabled': enabled,
    });
  }

  // Switch camera during call
  void switchCallCamera(String callId, bool isFrontCamera) {
    if (!_isConnected) return;

    _socket?.emit('switch_call_camera', {
      'callId': callId,
      'isFrontCamera': isFrontCamera,
    });
  }

  // Send WebRTC signaling data
  void sendWebRTCSignaling(String callId, Map<String, dynamic> signalingData) {
    if (!_isConnected) return;

    _socket?.emit('webrtc_signaling', {
      'callId': callId,
      'signalingData': signalingData,
    });
  }

  // Disconnect
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    onConnectionStatusChanged?.call(false);
  }

  // Clear callbacks and close streams
  void clearCallbacks() {
    onMessageReceived = null;
    onNotificationReceived = null;
    onTypingReceived = null;
    onTypingStoppedReceived = null;
    onUserStatusChanged = null;
    onCallReceived = null;
    onCallEnded = null;
    onCallSignalReceived = null;
    onConnectionStatusChanged = null;
  }

  // Dispose streams
  void dispose() {
    clearCallbacks();
    _messageController.close();
    _notificationController.close();
    _callController.close();
    disconnect();
  }
}
