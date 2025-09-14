import 'package:logger/logger.dart';

import '../../data/services/websocket_service.dart';
import '../../data/models/chat_model.dart';
import '../../data/models/notification_model.dart';
import '../../data/models/call_model.dart';
import '../../domain/entities/message.dart';
import 'error_handler.dart';

/// Service that coordinates all real-time features
class RealTimeCoordinator {
  static final RealTimeCoordinator _instance = RealTimeCoordinator._internal();
  factory RealTimeCoordinator() => _instance;
  RealTimeCoordinator._internal();

  final Logger _logger = Logger();
  final ErrorHandler _errorHandler = ErrorHandler();
  late WebSocketService _webSocketService;

  bool _isInitialized = false;

  /// Initialize the real-time coordinator
  Future<void> initialize(String userId, String token) async {
    if (_isInitialized) return;

    try {
      _webSocketService = WebSocketService.instance;
      
      // Connect to WebSocket
      await _webSocketService.connect(userId, token);
      
      // Set up listeners
      _setupEventListeners();
      
      _isInitialized = true;
      _logger.i('RealTimeCoordinator initialized successfully');
    } catch (e) {
      _errorHandler.logError('RealTimeCoordinator', 'Failed to initialize: $e');
      throw Exception('Failed to initialize real-time features');
    }
  }

  /// Set up WebSocket event listeners
  void _setupEventListeners() {
    // Chat message listeners - using message stream instead of callback
    _webSocketService.messageStream.listen((messageData) {
      _handleNewMessage(messageData);
    });

    // Notification listeners  
    _webSocketService.notificationStream.listen((notificationData) {
      _handleNewNotification(notificationData);
    });

    // Call signal listeners
    _webSocketService.callStream.listen((callData) {
      _handleCallSignal(callData);
    });

    // Connection status listeners
    _webSocketService.onConnectionStatusChanged = (isConnected) {
      _handleConnectionStatusChange(isConnected);
    };

    _logger.i('Real-time event listeners configured');
  }

  /// Handle incoming chat messages
  void _handleNewMessage(MessageModel messageData) {
    try {
      _logger.d('New message received: ${messageData.id}');
      
      // Message is already a model, no need to parse
      // Additional processing can be done here
      
    } catch (e) {
      _errorHandler.logError('RealTimeCoordinator', 'Failed to handle message: $e');
    }
  }

  /// Handle incoming notifications
  void _handleNewNotification(NotificationModel notificationData) {
    try {
      _logger.d('New notification received: ${notificationData.id}');
      
      // Notification is already a model, no need to parse
      // Additional processing can be done here
      
    } catch (e) {
      _errorHandler.logError('RealTimeCoordinator', 'Failed to handle notification: $e');
    }
  }

  /// Handle incoming call signals
  void _handleCallSignal(CallSignalModel callData) {
    try {
      _logger.d('Call signal received: ${callData.callId}');
      
      // Call signal is already a model, no need to parse
      // Additional processing can be done here
      
    } catch (e) {
      _errorHandler.logError('RealTimeCoordinator', 'Failed to handle call signal: $e');
    }
  }

  /// Handle connection status changes
  void _handleConnectionStatusChange(bool isConnected) {
    if (isConnected) {
      _logger.i('Real-time connection established');
    } else {
      _logger.w('Real-time connection lost - attempting reconnect');
      _attemptReconnect();
    }
  }

  /// Attempt to reconnect WebSocket
  Future<void> _attemptReconnect() async {
    try {
      await Future.delayed(const Duration(seconds: 3));
      if (!_webSocketService.isConnected) {
        _logger.i('Attempting WebSocket reconnection...');
        // Note: Need user ID and token from current auth state
        // This would typically come from AuthBloc
      }
    } catch (e) {
      _errorHandler.logError('RealTimeCoordinator', 'Reconnection failed: $e');
    }
  }

  /// Send a chat message
  Future<void> sendMessage(String conversationId, String content, MessageType type) async {
    try {
      _webSocketService.sendMessage(conversationId, content, type);
      _logger.d('Message sent to conversation: $conversationId');
    } catch (e) {
      _errorHandler.logError('RealTimeCoordinator', 'Failed to send message: $e');
      throw Exception(_errorHandler.handleApiError(e));
    }
  }

  /// Send typing indicator
  Future<void> sendTypingIndicator(String conversationId, bool isTyping) async {
    try {
      _webSocketService.sendTypingIndicator(conversationId, isTyping);
    } catch (e) {
      _errorHandler.logError('RealTimeCoordinator', 'Failed to send typing indicator: $e');
    }
  }

  /// Send call signal
  Future<void> sendCallSignal(CallSignalModel callSignal) async {
    try {
      _webSocketService.sendCallSignal(callSignal);
      _logger.d('Call signal sent: ${callSignal.callId}');
    } catch (e) {
      _errorHandler.logError('RealTimeCoordinator', 'Failed to send call signal: $e');
      throw Exception(_errorHandler.handleWebRTCError(e));
    }
  }

  /// Get connection status
  bool get isConnected => _webSocketService.isConnected;

  /// Get message stream
  Stream<MessageModel> get messageStream => _webSocketService.messageStream;

  /// Get notification stream  
  Stream<NotificationModel> get notificationStream => _webSocketService.notificationStream;

  /// Get call stream
  Stream<CallSignalModel> get callStream => _webSocketService.callStream;

  /// Dispose resources
  void dispose() {
    _webSocketService.disconnect();
    _isInitialized = false;
    _logger.i('RealTimeCoordinator disposed');
  }
}