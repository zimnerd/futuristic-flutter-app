import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../data/services/websocket_service_impl.dart';
import '../../presentation/blocs/auth/auth_bloc.dart';
import '../../presentation/blocs/auth/auth_state.dart';

/// Manages the app lifecycle and coordinates services
class AppLifecycleManager extends WidgetsBindingObserver {
  static final AppLifecycleManager _instance = AppLifecycleManager._internal();
  factory AppLifecycleManager() => _instance;
  AppLifecycleManager._internal();

  final Logger _logger = Logger();
  BuildContext? _context;

  void initialize(BuildContext context) {
    _context = context;
    WidgetsBinding.instance.addObserver(this);
    _logger.i('AppLifecycleManager initialized');
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _logger.i('AppLifecycleManager disposed');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (_context == null) return;

    switch (state) {
      case AppLifecycleState.resumed:
        _onAppResumed();
        break;
      case AppLifecycleState.paused:
        _onAppPaused();
        break;
      case AppLifecycleState.inactive:
        _onAppInactive();
        break;
      case AppLifecycleState.detached:
        _onAppDetached();
        break;
      case AppLifecycleState.hidden:
        _onAppHidden();
        break;
    }
  }

  void _onAppResumed() async {
    _logger.i('App resumed - reconnecting services');

    // Reconnect WebSocket if needed
    final webSocketService = WebSocketServiceImpl.instance;
    if (!webSocketService.isConnected) {
      // Get auth data for reconnection
      if (_context != null) {
        final authBloc = _context!.read<AuthBloc>();
        final currentState = authBloc.state;
        if (currentState is AuthAuthenticated) {
          await webSocketService.connect();
        }
      }
    }

    // Check authentication status
    if (_context != null) {
      final authBloc = _context!.read<AuthBloc>();
      final currentState = authBloc.state;
      if (currentState is! AuthAuthenticated) {
        // Handle authentication refresh if needed
        _logger.w('User not authenticated on app resume');
      }
    }
  }

  void _onAppPaused() {
    _logger.i('App paused - maintaining essential connections');
    // Keep WebSocket connected for notifications
  }

  void _onAppInactive() {
    _logger.i('App inactive');
  }

  void _onAppDetached() {
    _logger.i('App detached - cleaning up');
    WebSocketServiceImpl.instance.disconnect();
  }

  void _onAppHidden() {
    _logger.i('App hidden');
  }
}
