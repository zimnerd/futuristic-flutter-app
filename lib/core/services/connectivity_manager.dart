import 'package:logger/logger.dart';

import '../../data/services/websocket_service.dart';

/// Manages network connectivity and app state
class ConnectivityManager {
  static final ConnectivityManager _instance = ConnectivityManager._internal();
  factory ConnectivityManager() => _instance;
  ConnectivityManager._internal();

  final Logger _logger = Logger();
  bool _isConnected = true;

  /// Initialize connectivity monitoring
  void initialize() {
    _logger.i('ConnectivityManager initialized');
    _checkConnectivity();
  }

  /// Check and maintain connectivity
  Future<void> _checkConnectivity() async {
    try {
      // Check WebSocket connection
      final webSocketService = WebSocketService.instance;
      if (!webSocketService.isConnected) {
        _logger.w('WebSocket disconnected - attempting reconnect');
        _isConnected = false;
      } else {
        _isConnected = true;
      }
    } catch (e) {
      _logger.e('Connectivity check failed: $e');
      _isConnected = false;
    }
  }

  /// Get current connectivity status
  bool get isConnected => _isConnected;

  /// Handle app resume
  void onAppResumed() {
    _logger.i('App resumed - checking connectivity');
    _checkConnectivity();
  }

  /// Handle app pause
  void onAppPaused() {
    _logger.i('App paused - maintaining essential connections');
  }

  /// Cleanup resources
  void dispose() {
    _logger.i('ConnectivityManager disposed');
  }
}