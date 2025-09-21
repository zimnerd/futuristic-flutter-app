import 'dart:async';
import 'package:logger/logger.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import '../../core/config/app_config.dart';
import '../models/ai_companion.dart';

/// WebSocket service specifically for AI Companion interactions
class AiCompanionWebSocketService {
  // Singleton pattern
  static AiCompanionWebSocketService? _instance;
  static AiCompanionWebSocketService get instance =>
      _instance ??= AiCompanionWebSocketService._internal();

  AiCompanionWebSocketService._internal();

  socket_io.Socket? _socket;
  final Logger _logger = Logger();
  String? _authToken;
  bool _isConnected = false;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;

  // Configuration
  final int _maxReconnectAttempts = 5;
  int _currentReconnectAttempt = 0;
  final Duration _initialReconnectDelay = const Duration(seconds: 1);
  final Duration _maxReconnectDelay = const Duration(seconds: 30);
  final double _backoffFactor = 1.5;
  final bool _autoReconnectEnabled = true;

  // Stream controllers
  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _errorController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Stream for connection status changes
  Stream<bool> get connectionStatus => _connectionStatusController.stream;

  /// Stream for AI messages received
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  /// Stream for errors
  Stream<Map<String, dynamic>> get errorStream => _errorController.stream;

  /// Whether the socket is currently connected
  bool get isConnected => _isConnected;

  /// Initialize connection with auth token
  Future<void> connect(String authToken) async {
    try {
      _authToken = authToken;
      _logger.d('[AI Companion WS] Connecting with token: ${authToken.substring(0, 20)}...');

      if (_socket != null) {
        await disconnect();
      }

      final uri = '${AppConfig.websocketUrl}/ai-companion';
      _logger.d('[AI Companion WS] Connecting to: $uri');

      _socket = socket_io.io(
        uri,
        socket_io.OptionBuilder()
            .setTransports(['websocket'])
            .enableForceNew()
            .enableAutoConnect()
            .setAuth({
              'token': authToken,
            })
            .build(),
      );

      _setupEventListeners();
      _socket!.connect();

      // Wait for connection or timeout
      await _waitForConnection();
    } catch (e) {
      _logger.e('[AI Companion WS] Connection failed: $e');
      throw Exception('Failed to connect to AI companion service: $e');
    }
  }

  /// Disconnect from the AI companion socket
  Future<void> disconnect() async {
    try {
      _logger.d('[AI Companion WS] Disconnecting...');
      _heartbeatTimer?.cancel();
      _reconnectTimer?.cancel();
      
      if (_socket != null) {
        _socket!.disconnect();
        _socket!.dispose();
        _socket = null;
      }
      
      _isConnected = false;
      _connectionStatusController.add(false);
      _logger.d('[AI Companion WS] Disconnected');
    } catch (e) {
      _logger.e('[AI Companion WS] Error during disconnect: $e');
    }
  }

  /// Whether conversation history is supported (backend must support 'get_conversation_history' event)
  bool get supportsHistory => _isConnected;

  /// Fetch paginated conversation history via WebSocket
  Future<List<CompanionMessage>> getConversationHistory({
    required String companionId,
    required String conversationId,
    int page = 1,
    int limit = 20,
  }) async {
    if (!_isConnected || _socket == null) {
      throw Exception('Not connected to AI companion service');
    }
    final completer = Completer<List<CompanionMessage>>();
    void handler(dynamic data) {
      try {
        final List<dynamic> messagesJson = data['messages'] ?? [];
        final messages = messagesJson.map((json) => CompanionMessage.fromJson(json as Map<String, dynamic>)).toList();
        _logger.d('[AI Companion WS] Received conversation history: ${messages.length} messages');
        completer.complete(messages);
      } catch (e) {
        _logger.e('[AI Companion WS] Error parsing conversation history: ${e.toString()}');
        completer.completeError(e);
      }
    }
    _socket!.once('conversationHistory', handler);
    _logger.d('[AI Companion WS] Requesting conversation history for companionId=$companionId, conversationId=$conversationId, page=$page, limit=$limit');
    _socket!.emit('getConversationHistory', {
      'companionId': companionId,
      'conversationId': conversationId,
      'page': page,
      'limit': limit,
    });
    return completer.future;
  }

  /// Send AI message
  Future<void> sendAiMessage({
    required String companionId,
    required String message,
    String messageType = 'text',
    Map<String, dynamic> metadata = const {},
  }) async {
    if (!_isConnected || _socket == null) {
      throw Exception('Not connected to AI companion service');
    }

    if (companionId.isEmpty || message.isEmpty) {
      throw Exception('companionId and message must not be empty');
    }

    try {
      // Match backend SendAiMessageDto structure (no conversationId needed)
      final messageData = {
        'companionId': companionId,
        'message': message,
        'messageType': messageType,
        'metadata': metadata,
      };

      _logger.d('[AI Companion WS] Sending message: $messageData');
      _socket!.emit('sendAiMessage', messageData);
    } catch (e) {
      _logger.e('[AI Companion WS] Failed to send AI message: $e');
      throw Exception('Failed to send AI message: $e');
    }
  }

  void _setupEventListeners() {
    if (_socket == null) return;

    // Connection events
    _socket!.onConnect((_) {
      _logger.d('[AI Companion WS] Connected successfully');
      _isConnected = true;
      _currentReconnectAttempt = 0;
      _connectionStatusController.add(true);
      _startHeartbeat();
    });

    _socket!.onDisconnect((_) {
      _logger.w('[AI Companion WS] Disconnected');
      _isConnected = false;
      _connectionStatusController.add(false);
      _heartbeatTimer?.cancel();
      
      if (_autoReconnectEnabled) {
        _scheduleReconnect();
      }
    });

    _socket!.onConnectError((error) {
      _logger.e('[AI Companion WS] Connection error: $error');
      _isConnected = false;
      _connectionStatusController.add(false);
    });

    // AI Companion specific events
    _socket!.on('connected', (data) {
  _logger.d('[AI Companion WS] [EVENT] connected | Payload: ${data.toString()}');
    });

    _socket!.on('aiMessageSent', (data) {
  _logger.d('[AI Companion WS] [EVENT] aiMessageSent | Payload: ${data.toString()}');
  // Emit this as a status update for the sent message
  _messageController.add(data as Map<String, dynamic>);
    });

    _socket!.on('ai_message_received', (data) {
  _logger.d('[AI Companion WS] [EVENT] ai_message_received | RAW Payload: ${data.toString()}');
  final dataMap = data as Map<String, dynamic>;
  _logger.d('[AI Companion WS] [EVENT] ai_message_received | MAPPED Payload: $dataMap');
  _messageController.add(dataMap);
    });

    _socket!.on('ai_message_failed', (data) {
  _logger.e('[AI Companion WS] [EVENT] ai_message_failed | Payload: ${data.toString()}');
  _errorController.add(data as Map<String, dynamic>);
    });

    _socket!.on('ai_companion_typing', (data) {
  _logger.d('[AI Companion WS] [EVENT] ai_companion_typing | Payload: ${data.toString()}');
  // You can add typing indicator handling here if needed
    });

    _socket!.on('error', (error) {
  _logger.e('[AI Companion WS] [EVENT] error | Payload: ${error.toString()}');
  _errorController.add(error as Map<String, dynamic>);
    });
  }

  Future<void> _waitForConnection() async {
    final completer = Completer<void>();
    Timer? timeoutTimer;

    late StreamSubscription subscription;
    subscription = connectionStatus.listen((connected) {
      if (connected) {
        timeoutTimer?.cancel();
        subscription.cancel();
        completer.complete();
      }
    });

    timeoutTimer = Timer(const Duration(seconds: 10), () {
      subscription.cancel();
      if (!completer.isCompleted) {
        completer.completeError(
          Exception('Connection timeout'),
        );
      }
    });

    return completer.future;
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isConnected && _socket != null) {
        _socket!.emit('ping');
      }
    });
  }

  void _scheduleReconnect() {
    if (_currentReconnectAttempt >= _maxReconnectAttempts) {
      _logger.e('[AI Companion WS] Max reconnection attempts reached');
      return;
    }

    _currentReconnectAttempt++;
    final delay = Duration(
      milliseconds: (_initialReconnectDelay.inMilliseconds *
              (_backoffFactor * _currentReconnectAttempt))
          .clamp(
        _initialReconnectDelay.inMilliseconds.toDouble(),
        _maxReconnectDelay.inMilliseconds.toDouble(),
      )
          .round(),
    );

    _logger.d('[AI Companion WS] Scheduling reconnect in $delay (attempt $_currentReconnectAttempt)');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () async {
      if (_authToken != null) {
        try {
          await connect(_authToken!);
        } catch (e) {
          _logger.e('[AI Companion WS] Reconnection failed: $e');
        }
      }
    });
  }

  void dispose() {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _connectionStatusController.close();
    _messageController.close();
    _errorController.close();
    disconnect();
  }
}