import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import 'background_sync_service.dart';
import '../repositories/chat_repository.dart';
import 'message_database_service.dart';

/// Manages the lifecycle of background synchronization services
/// Integrates with the app lifecycle to start/stop sync appropriately
class BackgroundSyncManager extends WidgetsBindingObserver {
  static final BackgroundSyncManager _instance = BackgroundSyncManager._internal();
  static BackgroundSyncManager get instance => _instance;
  
  BackgroundSyncManager._internal();

  final Logger _logger = Logger();
  BackgroundSyncService? _syncService;
  bool _isInitialized = false;

  /// Initialize the background sync manager with required dependencies
  Future<void> initialize({
    required ChatRepository chatRepository,
    required MessageDatabaseService databaseService,
  }) async {
    if (_isInitialized) {
      _logger.w('BackgroundSyncManager already initialized');
      return;
    }

    try {
      _logger.d('Initializing BackgroundSyncManager...');
      
      // Create and initialize the sync service
      _syncService = BackgroundSyncService(
        chatRepository: chatRepository,
        databaseService: databaseService,
      );
      
      await _syncService!.initialize();
      
      // Register as app lifecycle observer
      WidgetsBinding.instance.addObserver(this);
      
      _isInitialized = true;
      _logger.i('✅ BackgroundSyncManager initialized successfully');
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to initialize BackgroundSyncManager', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Dispose of resources and stop background sync
  Future<void> dispose() async {
    if (!_isInitialized) return;

    try {
      _logger.d('Disposing BackgroundSyncManager...');
      
      // Remove app lifecycle observer
      WidgetsBinding.instance.removeObserver(this);
      
      // Dispose sync service
      _syncService?.dispose();
      _syncService = null;
      
      _isInitialized = false;
      _logger.i('✅ BackgroundSyncManager disposed successfully');
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to dispose BackgroundSyncManager', error: e, stackTrace: stackTrace);
    }
  }

  /// Start background synchronization
  /// This is called when the app becomes active
  Future<void> startSync() async {
    if (!_isInitialized || _syncService == null) {
      _logger.w('BackgroundSyncManager not initialized, cannot start sync');
      return;
    }

    try {
      // The sync service automatically starts when initialized
      // Just trigger a manual sync to ensure we're up to date
      await _syncService!.syncNow();
      _logger.d('Background sync triggered on app resume');
    } catch (e, stackTrace) {
      _logger.e('Failed to trigger sync on resume', error: e, stackTrace: stackTrace);
    }
  }

  /// Stop background synchronization
  /// This is called when the app becomes inactive
  Future<void> stopSync() async {
    if (!_isInitialized || _syncService == null) {
      return;
    }

    try {
      // The sync service runs independently via timers
      // We could implement pause/resume logic if needed
      _logger.d('App going to background - sync will continue via timers');
    } catch (e, stackTrace) {
      _logger.e('Failed to handle background transition', error: e, stackTrace: stackTrace);
    }
  }

  /// Force a manual sync
  /// Useful for pull-to-refresh or when user manually requests sync
  Future<void> forceSync() async {
    if (!_isInitialized || _syncService == null) {
      _logger.w('BackgroundSyncManager not initialized, cannot force sync');
      return;
    }

    try {
      await _syncService!.syncNow();
      _logger.d('Manual sync completed');
    } catch (e, stackTrace) {
      _logger.e('Failed to force sync', error: e, stackTrace: stackTrace);
    }
  }

  /// Get sync status information
  Map<String, dynamic> getSyncStatus() {
    if (!_isInitialized || _syncService == null) {
      return {
        'isInitialized': false,
        'isRunning': false,
        'lastSyncTime': null,
      };
    }

    return _syncService!.getSyncStatus();
  }

  /// Handle app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    _logger.d('App lifecycle changed to: $state');
    
    switch (state) {
      case AppLifecycleState.resumed:
        // App is active, start sync
        startSync();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // App is going to background, stop sync
        stopSync();
        break;
      case AppLifecycleState.detached:
        // App is being terminated, dispose resources
        dispose();
        break;
      case AppLifecycleState.hidden:
        // App is hidden, stop sync but don't dispose
        stopSync();
        break;
    }
  }

  /// Create a provider widget that initializes the sync manager
  /// This should be placed high in the widget tree
  static Widget provider({
    required Widget child,
    required ChatRepository chatRepository,
    required MessageDatabaseService databaseService,
  }) {
    return _BackgroundSyncProvider(
      chatRepository: chatRepository,
      databaseService: databaseService,
      child: child,
    );
  }
}

/// Private widget that handles the initialization and disposal of BackgroundSyncManager
class _BackgroundSyncProvider extends StatefulWidget {
  final Widget child;
  final ChatRepository chatRepository;
  final MessageDatabaseService databaseService;

  const _BackgroundSyncProvider({
    required this.child,
    required this.chatRepository,
    required this.databaseService,
  });

  @override
  State<_BackgroundSyncProvider> createState() => _BackgroundSyncProviderState();
}

class _BackgroundSyncProviderState extends State<_BackgroundSyncProvider> {
  final Logger _logger = Logger();

  @override
  void initState() {
    super.initState();
    _initializeBackgroundSync();
  }

  Future<void> _initializeBackgroundSync() async {
    try {
      await BackgroundSyncManager.instance.initialize(
        chatRepository: widget.chatRepository,
        databaseService: widget.databaseService,
      );
    } catch (e, stackTrace) {
      _logger.e('Failed to initialize background sync', error: e, stackTrace: stackTrace);
    }
  }

  @override
  void dispose() {
    BackgroundSyncManager.instance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}