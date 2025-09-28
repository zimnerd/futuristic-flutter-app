/// WebSocket service interface for real-time communication
abstract class WebSocketService {
  // Connection Management
  Future<void> connect();
  Future<void> disconnect();
  bool get isConnected;

  // Authentication
  Future<void> authenticate(String token);
  void setAuthToken(String token);
  void clearAuthToken();

  // Event Emission
  void emit(String event, [dynamic data]);
  void emitWithAck(String event, dynamic data, Function ack);

  // Event Listening
  void on(String event, Function(dynamic) callback);
  void off(String event, [Function? callback]);
  void once(String event, Function(dynamic) callback);

  // Connection Events
  void onConnect(Function() callback);
  void onDisconnect(Function() callback);
  void onConnectError(Function(dynamic) callback);
  void onReconnect(Function() callback);

  // Room Management
  void joinRoom(String roomId);
  void leaveRoom(String roomId);
  void joinUserRoom(String userId);
  void leaveUserRoom(String userId);

  // AI Companion Pattern - Message Streams
  Stream<Map<String, dynamic>> get messageStream;
  Stream<Map<String, dynamic>> get errorStream;

  // Messaging Events
  void onNewMessage(Function(Map<String, dynamic>) callback);
  void onMessageUpdate(Function(Map<String, dynamic>) callback);
  void onMessageDeleted(Function(String) callback);
  void onTypingStart(Function(Map<String, dynamic>) callback);
  void onTypingStop(Function(Map<String, dynamic>) callback);

  // AI Companion Events
  void sendAiMessage(String message, String? companionId);
  void onAiMessageSent(Function(Map<String, dynamic>) callback);
  void onAiMessageReceived(Function(Map<String, dynamic>) callback);
  void onAiMessageFailed(Function(Map<String, dynamic>) callback);

  // User Presence
  void onUserOnline(Function(String) callback);
  void onUserOffline(Function(String) callback);
  void onUserStatusChange(Function(Map<String, dynamic>) callback);
  void updateUserStatus(String status);

  // Matching Events
  void onNewMatch(Function(Map<String, dynamic>) callback);
  void onMatchUpdate(Function(Map<String, dynamic>) callback);
  void onMatchDeleted(Function(String) callback);

  // Call Events
  void onIncomingCall(Function(Map<String, dynamic>) callback);
  void onCallAccepted(Function(Map<String, dynamic>) callback);
  void onCallDeclined(Function(Map<String, dynamic>) callback);
  void onWebRTCSignaling(Function(Map<String, dynamic>) callback);

  // Call Actions
  void initiateCall(String recipientId, String type);
  void acceptCall(String callId);
  void rejectCall(String callId);
  void endCall(String callId);
  void toggleCallVideo(String callId, bool enabled);
  void toggleCallAudio(String callId, bool enabled);
  void switchCallCamera(String callId, bool frontCamera);
  void sendWebRTCSignaling(String callId, Map<String, dynamic> signalingData);

  // Callback setters for call events (legacy support)
  set onCallReceived(Function(String) callback);
  set onCallEnded(Function(String) callback);

  // Notification Events
  void onNotification(Function(Map<String, dynamic>) callback);
  void onNotificationRead(Function(String) callback);
  void onNotificationCleared(Function(List<String>) callback);

  // Location Events
  void onLocationUpdate(Function(Map<String, dynamic>) callback);
  void onNearbyUsers(Function(List<Map<String, dynamic>>) callback);

  // Error Handling
  void onError(Function(dynamic) callback);
  void onTimeout(Function() callback);

  // Auto-reconnection
  void enableAutoReconnect({
    int maxAttempts = 5,
    Duration initialDelay = const Duration(seconds: 1),
    Duration maxDelay = const Duration(seconds: 30),
    double backoffFactor = 1.5,
  });
  void disableAutoReconnect();

  // Connection Status
  Stream<bool> get connectionStatus;
  Stream<String>
      get connectionState; // connecting, connected, disconnected, error

  // Message Queue (for offline scenarios)
  void queueMessage(String event, dynamic data);
  void processQueuedMessages();
  void clearMessageQueue();
  int get queuedMessageCount;

  // Ping/Pong for connection health
  void startHeartbeat({Duration interval = const Duration(seconds: 30)});
  void stopHeartbeat();
  Stream<Duration> get latencyStream;

  // Event History & Replay
  void enableEventHistory({int maxEvents = 100});
  void disableEventHistory();
  List<Map<String, dynamic>> getEventHistory();
  void replayEvents(List<String> eventTypes);

  // Namespace Support
  void switchNamespace(String namespace);
  String get currentNamespace;

  // Debug & Logging
  void enableDebugLogging();
  void disableDebugLogging();

  // Performance Monitoring
  Map<String, dynamic> getConnectionStats();
  void resetConnectionStats();
}
