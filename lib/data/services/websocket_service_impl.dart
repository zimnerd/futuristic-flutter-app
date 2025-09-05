import 'dart:async';

import 'package:logger/logger.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;

import '../../domain/services/websocket_service.dart';
import '../exceptions/app_exceptions.dart';

/// Concrete implementation of WebSocketService using socket_io_client
class WebSocketServiceImpl implements WebSocketService {
  socket_io.Socket? _socket;
  final Logger _logger = Logger();
  String? _authToken;
  bool _isConnected = false;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;

  // Configuration
  int _maxReconnectAttempts = 5;
  int _currentReconnectAttempt = 0;
  Duration _initialReconnectDelay = const Duration(seconds: 1);
  Duration _maxReconnectDelay = const Duration(seconds: 30);
  double _backoffFactor = 1.5;
  bool _autoReconnectEnabled = true;

  // Event history and queue
  final List<Map<String, dynamic>> _eventHistory = [];
  final List<Map<String, dynamic>> _messageQueue = [];
  int _maxEventHistory = 100;

  // Stream controllers
  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();
  final StreamController<String> _connectionStateController =
      StreamController<String>.broadcast();
  final StreamController<Duration> _latencyController =
      StreamController<Duration>.broadcast();

  // Current namespace
  String _currentNamespace = '/';

  @override
  bool get isConnected => _isConnected;

  @override
  Stream<bool> get connectionStatus => _connectionStatusController.stream;

  @override
  Stream<String> get connectionState => _connectionStateController.stream;

  @override
  Stream<Duration> get latencyStream => _latencyController.stream;

  @override
  String get currentNamespace => _currentNamespace;

  @override
  int get queuedMessageCount => _messageQueue.length;

  @override
  Future<void> connect() async {
    try {
      if (_isConnected) {
        _logger.w('🔌 Already connected to WebSocket');
        return;
      }

      _logger.i('🔌 Connecting to WebSocket...');
      _connectionStateController.add('connecting');

      _socket = socket_io.io(
        'wss://api.pulselink.com$_currentNamespace',
        socket_io.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(_maxReconnectAttempts)
            .setReconnectionDelay(_initialReconnectDelay.inMilliseconds)
            .setReconnectionDelayMax(_maxReconnectDelay.inMilliseconds)
            .setTimeout(30000)
            .build(),
      );

      _setupEventHandlers();

      // Wait for connection
      final completer = Completer<void>();
      _socket!.onConnect((_) {
        if (!completer.isCompleted) {
          completer.complete();
        }
      });

      _socket!.onConnectError((error) {
        if (!completer.isCompleted) {
          completer.completeError(
            NetworkException('Failed to connect: $error'),
          );
        }
      });

      await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw const TimeoutException(),
      );
    } catch (e) {
      _logger.e('❌ WebSocket connection failed: $e');
      _connectionStateController.add('error');
      if (e is AppException) rethrow;
      throw NetworkException('Connection failed: ${e.toString()}');
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      _logger.i('🔌 Disconnecting from WebSocket...');
      _autoReconnectEnabled = false;

      _heartbeatTimer?.cancel();
      _reconnectTimer?.cancel();

      if (_socket != null) {
        _socket!.disconnect();
        _socket!.dispose();
        _socket = null;
      }

      _isConnected = false;
      _connectionStatusController.add(false);
      _connectionStateController.add('disconnected');

      _logger.i('✅ WebSocket disconnected');
    } catch (e) {
      _logger.e('❌ Error during WebSocket disconnect: $e');
    }
  }

  @override
  Future<void> authenticate(String token) async {
    _authToken = token;
    if (_isConnected && _socket != null) {
      _socket!.emit('authenticate', {'token': token});
      _logger.i('🔑 Authentication sent');
    }
  }

  @override
  void setAuthToken(String token) {
    _authToken = token;
  }

  @override
  void clearAuthToken() {
    _authToken = null;
  }

  void _setupEventHandlers() {
    if (_socket == null) return;

    // Connection events
    _socket!.onConnect((_) {
      _logger.i('✅ WebSocket connected');
      _isConnected = true;
      _currentReconnectAttempt = 0;
      _connectionStatusController.add(true);
      _connectionStateController.add('connected');

      // Authenticate if token is available
      if (_authToken != null) {
        authenticate(_authToken!);
      }

      // Process queued messages
      processQueuedMessages();

      // Start heartbeat
      startHeartbeat();
    });

    _socket!.onDisconnect((_) {
      _logger.w('⚠️ WebSocket disconnected');
      _isConnected = false;
      _connectionStatusController.add(false);
      _connectionStateController.add('disconnected');

      _heartbeatTimer?.cancel();

      if (_autoReconnectEnabled) {
        _scheduleReconnect();
      }
    });

    _socket!.onConnectError((error) {
      _logger.e('❌ WebSocket connection error: $error');
      _connectionStateController.add('error');

      if (_autoReconnectEnabled) {
        _scheduleReconnect();
      }
    });

    _socket!.onReconnect((_) {
      _logger.i('🔄 WebSocket reconnected');
      _connectionStateController.add('connected');
    });

    // Pong handler for latency measurement
    _socket!.on('pong', (data) {
      if (data is Map && data['timestamp'] != null) {
        final sentTime = DateTime.fromMillisecondsSinceEpoch(
          data['timestamp'] as int,
        );
        final latency = DateTime.now().difference(sentTime);
        _latencyController.add(latency);
      }
    });
  }

  @override
  void emit(String event, [dynamic data]) {
    if (_isConnected && _socket != null) {
      _socket!.emit(event, data);
      _addToEventHistory(event, data, 'sent');
      _logger.d('📤 Emitted: $event with data: $data');
    } else {
      _logger.w('⚠️ Socket not connected, queueing message: $event');
      queueMessage(event, data);
    }
  }

  @override
  void emitWithAck(String event, dynamic data, Function ack) {
    if (_isConnected && _socket != null) {
      _socket!.emitWithAck(event, data, ack: ack);
      _addToEventHistory(event, data, 'sent_with_ack');
      _logger.d('📤 Emitted with ACK: $event with data: $data');
    } else {
      _logger.w('⚠️ Socket not connected, cannot emit with ACK: $event');
    }
  }

  @override
  void on(String event, Function(dynamic) callback) {
    if (_socket != null) {
      _socket!.on(event, (data) {
        _addToEventHistory(event, data, 'received');
        _logger.d('📥 Received: $event with data: $data');
        callback(data);
      });
    }
  }

  @override
  void off(String event, [Function? callback]) {
    if (_socket != null) {
      if (callback != null) {
        _socket!.off(event, callback as dynamic Function(dynamic));
      } else {
        _socket!.off(event);
      }
    }
  }

  @override
  void once(String event, Function(dynamic) callback) {
    if (_socket != null) {
      _socket!.once(event, (data) {
        _addToEventHistory(event, data, 'received_once');
        _logger.d('📥 Received once: $event with data: $data');
        callback(data);
      });
    }
  }

  // Connection Events
  @override
  void onConnect(Function() callback) {
    on('connect', (_) => callback());
  }

  @override
  void onDisconnect(Function() callback) {
    on('disconnect', (_) => callback());
  }

  @override
  void onConnectError(Function(dynamic) callback) {
    on('connect_error', callback);
  }

  @override
  void onReconnect(Function() callback) {
    on('reconnect', (_) => callback());
  }

  // Room Management
  @override
  void joinRoom(String roomId) {
    emit('join_room', {'room': roomId});
  }

  @override
  void leaveRoom(String roomId) {
    emit('leave_room', {'room': roomId});
  }

  @override
  void joinUserRoom(String userId) {
    emit('join_user_room', {'userId': userId});
  }

  @override
  void leaveUserRoom(String userId) {
    emit('leave_user_room', {'userId': userId});
  }

  // Messaging Events
  @override
  void onNewMessage(Function(Map<String, dynamic>) callback) {
    on('new_message', (data) => callback(data as Map<String, dynamic>));
  }

  @override
  void onMessageUpdate(Function(Map<String, dynamic>) callback) {
    on('message_update', (data) => callback(data as Map<String, dynamic>));
  }

  @override
  void onMessageDeleted(Function(String) callback) {
    on('message_deleted', (data) => callback(data['messageId'] as String));
  }

  @override
  void onTypingStart(Function(Map<String, dynamic>) callback) {
    on('typing_start', (data) => callback(data as Map<String, dynamic>));
  }

  @override
  void onTypingStop(Function(Map<String, dynamic>) callback) {
    on('typing_stop', (data) => callback(data as Map<String, dynamic>));
  }

  // User Presence
  @override
  void onUserOnline(Function(String) callback) {
    on('user_online', (data) => callback(data['userId'] as String));
  }

  @override
  void onUserOffline(Function(String) callback) {
    on('user_offline', (data) => callback(data['userId'] as String));
  }

  @override
  void onUserStatusChange(Function(Map<String, dynamic>) callback) {
    on('user_status_change', (data) => callback(data as Map<String, dynamic>));
  }

  @override
  void updateUserStatus(String status) {
    emit('update_status', {'status': status});
  }

  // Matching Events
  @override
  void onNewMatch(Function(Map<String, dynamic>) callback) {
    on('new_match', (data) => callback(data as Map<String, dynamic>));
  }

  @override
  void onMatchUpdate(Function(Map<String, dynamic>) callback) {
    on('match_update', (data) => callback(data as Map<String, dynamic>));
  }

  @override
  void onMatchDeleted(Function(String) callback) {
    on('match_deleted', (data) => callback(data['matchId'] as String));
  }

  // Call Events
  @override
  void onIncomingCall(Function(Map<String, dynamic>) callback) {
    on('incoming_call', (data) => callback(data as Map<String, dynamic>));
  }

  @override
  void onCallAccepted(Function(Map<String, dynamic>) callback) {
    on('call_accepted', (data) => callback(data as Map<String, dynamic>));
  }

  @override
  void onCallDeclined(Function(Map<String, dynamic>) callback) {
    on('call_declined', (data) => callback(data as Map<String, dynamic>));
  }

  @override
  void onCallEnded(Function(Map<String, dynamic>) callback) {
    on('call_ended', (data) => callback(data as Map<String, dynamic>));
  }

  @override
  void onCallUpdate(Function(Map<String, dynamic>) callback) {
    on('call_update', (data) => callback(data as Map<String, dynamic>));
  }

  // Notification Events
  @override
  void onNotification(Function(Map<String, dynamic>) callback) {
    on('notification', (data) => callback(data as Map<String, dynamic>));
  }

  @override
  void onNotificationRead(Function(String) callback) {
    on(
      'notification_read',
      (data) => callback(data['notificationId'] as String),
    );
  }

  @override
  void onNotificationCleared(Function(List<String>) callback) {
    on(
      'notifications_cleared',
      (data) => callback(List<String>.from(data['notificationIds'])),
    );
  }

  // Location Events
  @override
  void onLocationUpdate(Function(Map<String, dynamic>) callback) {
    on('location_update', (data) => callback(data as Map<String, dynamic>));
  }

  @override
  void onNearbyUsers(Function(List<Map<String, dynamic>>) callback) {
    on(
      'nearby_users',
      (data) => callback(List<Map<String, dynamic>>.from(data['users'])),
    );
  }

  // Error Handling
  @override
  void onError(Function(dynamic) callback) {
    on('error', callback);
  }

  @override
  void onTimeout(Function() callback) {
    on('timeout', (_) => callback());
  }

  // Auto-reconnection
  @override
  void enableAutoReconnect({
    int maxAttempts = 5,
    Duration initialDelay = const Duration(seconds: 1),
    Duration maxDelay = const Duration(seconds: 30),
    double backoffFactor = 1.5,
  }) {
    _autoReconnectEnabled = true;
    _maxReconnectAttempts = maxAttempts;
    _initialReconnectDelay = initialDelay;
    _maxReconnectDelay = maxDelay;
    _backoffFactor = backoffFactor;
    _logger.i('🔄 Auto-reconnect enabled');
  }

  @override
  void disableAutoReconnect() {
    _autoReconnectEnabled = false;
    _reconnectTimer?.cancel();
    _logger.i('🔄 Auto-reconnect disabled');
  }

  void _scheduleReconnect() {
    if (!_autoReconnectEnabled ||
        _currentReconnectAttempt >= _maxReconnectAttempts) {
      return;
    }

    _currentReconnectAttempt++;
    final delay = Duration(
      milliseconds:
          (_initialReconnectDelay.inMilliseconds *
                  (_backoffFactor * _currentReconnectAttempt))
              .clamp(
                _initialReconnectDelay.inMilliseconds,
                _maxReconnectDelay.inMilliseconds,
              )
              .round(),
    );

    _logger.i(
      '🔄 Scheduling reconnect attempt $_currentReconnectAttempt in ${delay.inSeconds}s',
    );

    _reconnectTimer = Timer(delay, () {
      if (!_isConnected) {
        connect();
      }
    });
  }

  // Message Queue
  @override
  void queueMessage(String event, dynamic data) {
    _messageQueue.add({
      'event': event,
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    _logger.d('📦 Message queued: $event');
  }

  @override
  void processQueuedMessages() {
    if (_messageQueue.isEmpty) return;

    _logger.i('📦 Processing ${_messageQueue.length} queued messages');
    final messages = List<Map<String, dynamic>>.from(_messageQueue);
    _messageQueue.clear();

    for (final message in messages) {
      emit(message['event'] as String, message['data']);
    }
  }

  @override
  void clearMessageQueue() {
    _messageQueue.clear();
    _logger.i('📦 Message queue cleared');
  }

  // Heartbeat
  @override
  void startHeartbeat({Duration interval = const Duration(seconds: 30)}) {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(interval, (_) {
      if (_isConnected) {
        emit('ping', {'timestamp': DateTime.now().millisecondsSinceEpoch});
      }
    });
    _logger.i('💓 Heartbeat started');
  }

  @override
  void stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _logger.i('💓 Heartbeat stopped');
  }

  // Event History
  @override
  void enableEventHistory({int maxEvents = 100}) {
    _maxEventHistory = maxEvents;
    _logger.i('📝 Event history enabled (max: $maxEvents)');
  }

  @override
  void disableEventHistory() {
    _maxEventHistory = 0;
    _eventHistory.clear();
    _logger.i('📝 Event history disabled');
  }

  @override
  List<Map<String, dynamic>> getEventHistory() {
    return List<Map<String, dynamic>>.from(_eventHistory);
  }

  @override
  void replayEvents(List<String> eventTypes) {
    final eventsToReplay = _eventHistory
        .where((event) => eventTypes.contains(event['event']))
        .toList();

    _logger.i('🔄 Replaying ${eventsToReplay.length} events');

    for (final event in eventsToReplay) {
      if (event['type'] == 'sent') {
        emit(event['event'] as String, event['data']);
      }
    }
  }

  void _addToEventHistory(String event, dynamic data, String type) {
    if (_maxEventHistory <= 0) return;

    _eventHistory.add({
      'event': event,
      'data': data,
      'type': type,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    // Keep only the last N events
    while (_eventHistory.length > _maxEventHistory) {
      _eventHistory.removeAt(0);
    }
  }

  // Namespace Support
  @override
  void switchNamespace(String namespace) {
    if (_currentNamespace == namespace) return;

    _currentNamespace = namespace;
    if (_isConnected) {
      // Reconnect with new namespace
      disconnect().then((_) => connect());
    }
    _logger.i('🔄 Switched to namespace: $namespace');
  }

  // Debug & Logging
  @override
  void enableDebugLogging() {
    _logger.i('📝 Debug logging enabled');
  }

  @override
  void disableDebugLogging() {
    _logger.i('📝 Debug logging disabled');
  }

  // Performance Monitoring
  @override
  Map<String, dynamic> getConnectionStats() {
    return {
      'isConnected': _isConnected,
      'currentNamespace': _currentNamespace,
      'reconnectAttempts': _currentReconnectAttempt,
      'queuedMessages': _messageQueue.length,
      'eventHistorySize': _eventHistory.length,
      'autoReconnectEnabled': _autoReconnectEnabled,
    };
  }

  @override
  void resetConnectionStats() {
    _currentReconnectAttempt = 0;
    _eventHistory.clear();
    _logger.i('📊 Connection stats reset');
  }

  void dispose() {
    _connectionStatusController.close();
    _connectionStateController.close();
    _latencyController.close();
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    disconnect();
  }
}
