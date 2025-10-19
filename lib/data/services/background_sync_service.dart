import 'dart:async';
import 'package:logger/logger.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../repositories/chat_repository.dart';
import '../services/message_database_service.dart';
import '../../services/discovery_prefetch_manager.dart';
import '../../domain/entities/message.dart'; // For MessageType enum

/// Service to handle background synchronization of messages and conversations
class BackgroundSyncService {
  final ChatRepository _chatRepository;
  final MessageDatabaseService _databaseService;
  final Logger _logger = Logger();
  final Connectivity _connectivity = Connectivity();

  Timer? _periodicSyncTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isOnline = true;
  bool _isSyncInProgress = false;

  // Sync configuration
  static const Duration _periodicSyncInterval = Duration(minutes: 5);

  BackgroundSyncService({
    required ChatRepository chatRepository,
    required MessageDatabaseService databaseService,
  }) : _chatRepository = chatRepository,
       _databaseService = databaseService;

  /// Initialize background sync service
  Future<void> initialize() async {
    try {
      _logger.d('Initializing BackgroundSyncService');

      // Check initial connectivity
      await _checkConnectivity();

      // Set up connectivity monitoring
      _setupConnectivityMonitoring();

      // Start periodic sync
      _startPeriodicSync();

      _logger.i('BackgroundSyncService initialized successfully');
    } catch (e) {
      _logger.e('Error initializing BackgroundSyncService: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _logger.d('Disposing BackgroundSyncService');

    _periodicSyncTimer?.cancel();
    _connectivitySubscription?.cancel();

    _logger.d('BackgroundSyncService disposed');
  }

  /// Check current connectivity status
  Future<void> _checkConnectivity() async {
    try {
      final connectivityResults = await _connectivity.checkConnectivity();
      final wasOnline = _isOnline;
      _isOnline = _isConnected(connectivityResults);

      _logger.d('Connectivity check: $_isOnline (was: $wasOnline)');

      // If we just came back online, trigger a sync
      if (_isOnline && !wasOnline) {
        _logger.i('Connectivity restored, triggering sync');
        unawaited(_syncAllConversations());
      }
    } catch (e) {
      _logger.e('Error checking connectivity: $e');
    }
  }

  /// Set up connectivity monitoring
  void _setupConnectivityMonitoring() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final wasOnline = _isOnline;
        _isOnline = _isConnected(results);

        _logger.d('Connectivity changed: $_isOnline (was: $wasOnline)');

        // If we just came back online, trigger a sync
        if (_isOnline && !wasOnline) {
          _logger.i('Connectivity restored, triggering sync');
          unawaited(_syncAllConversations());
        }
      },
      onError: (error) {
        _logger.e('Error in connectivity monitoring: $error');
      },
    );
  }

  /// Check if any connectivity result indicates we're connected
  bool _isConnected(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }

  /// Start periodic sync timer
  void _startPeriodicSync() {
    _periodicSyncTimer?.cancel();

    _periodicSyncTimer = Timer.periodic(_periodicSyncInterval, (timer) {
      if (_isOnline && !_isSyncInProgress) {
        _logger.d('Periodic sync triggered');
        unawaited(_syncAllConversations());
      } else {
        _logger.d(
          'Skipping periodic sync - online: $_isOnline, inProgress: $_isSyncInProgress',
        );
      }
    });

    _logger.d('Periodic sync started with interval: $_periodicSyncInterval');
  }

  /// Trigger immediate sync for all conversations
  Future<void> syncNow() async {
    _logger.d('Manual sync triggered');
    await _syncAllConversations();
  }

  /// Trigger sync for specific conversation
  Future<void> syncConversation(String conversationId) async {
    if (!_isOnline) {
      _logger.w('Cannot sync conversation $conversationId - offline');
      return;
    }

    if (_isSyncInProgress) {
      _logger.w(
        'Sync already in progress, skipping conversation $conversationId',
      );
      return;
    }

    try {
      _isSyncInProgress = true;
      _logger.d('Syncing conversation: $conversationId');

      await _syncConversationMessages(conversationId);

      _logger.d('Successfully synced conversation: $conversationId');
    } catch (e) {
      _logger.e('Error syncing conversation $conversationId: $e');
    } finally {
      _isSyncInProgress = false;
    }
  }

  /// Sync all active conversations
  Future<void> _syncAllConversations() async {
    if (!_isOnline) {
      _logger.w('Cannot sync - offline');
      return;
    }

    if (_isSyncInProgress) {
      _logger.w('Sync already in progress');
      return;
    }

    try {
      _isSyncInProgress = true;
      _logger.d('Starting background sync for all conversations');

      // PRIORITY 1: Process outbox first (send pending messages)
      await _processOutbox();

      // PRIORITY 2: Get all conversations that have local data
      final localConversations = await _databaseService.getAllConversations();

      _logger.d(
        'Found ${localConversations.length} local conversations to sync',
      );

      // PRIORITY 3: Sync each conversation
      for (final conversation in localConversations) {
        try {
          await _syncConversationMessages(conversation.id);

          // Small delay between syncs to avoid overwhelming the server
          await Future.delayed(const Duration(milliseconds: 100));
        } catch (e) {
          _logger.e('Error syncing conversation ${conversation.id}: $e');
          // Continue with other conversations even if one fails
        }
      }

      _logger.i(
        'Background sync completed for ${localConversations.length} conversations',
      );

      // PRIORITY 4: Prefetch discovery profiles (low priority, no images)
      // This happens in background so profiles are ready when user opens discovery
      await _prefetchDiscoveryProfiles();
    } catch (e) {
      _logger.e('Error during background sync: $e');
    } finally {
      _isSyncInProgress = false;
    }
  }

  /// Prefetch discovery profiles during background sync
  ///
  /// This pre-populates the discovery feed cache so profiles are instantly
  /// available when user opens the discovery screen.
  Future<void> _prefetchDiscoveryProfiles() async {
    try {
      _logger.d('Starting discovery profile prefetch');

      await DiscoveryPrefetchManager.instance.prefetchProfilesBackground();

      _logger.d('Discovery profile prefetch complete');
    } catch (e) {
      _logger.e('Error prefetching discovery profiles: $e');
      // Don't fail the entire sync if discovery prefetch fails
    }
  }

  /// Process outbox - retry sending queued messages
  Future<void> _processOutbox() async {
    try {
      final pending = await _databaseService.getPendingOutbox();

      if (pending.isEmpty) {
        _logger.d('No pending outbox messages to process');
        return;
      }

      _logger.d('Processing ${pending.length} pending outbox messages');

      for (final item in pending) {
        try {
          final tempId = item['temp_id'] as String;
          final conversationId = item['conversation_id'] as String;
          final content = item['content'] as String;
          final type = item['type'] as String;
          final mediaLocalPath = item['media_local_path'] as String?;

          _logger.d('Attempting to send queued message: $tempId');

          // Convert string type to MessageType enum
          final messageType = _parseMessageType(type);

          // Send via API
          final sentMessage = await _chatRepository.sendMessage(
            conversationId: conversationId,
            content: content,
            type: messageType,
            mediaIds: mediaLocalPath != null ? [mediaLocalPath] : null,
          );

          // Remove from outbox on success
          await _databaseService.removeFromOutbox(tempId);

          _logger.i(
            'Successfully sent queued message: $tempId -> ${sentMessage.id}',
          );

          // Small delay to avoid overwhelming the server
          await Future.delayed(const Duration(milliseconds: 200));
        } catch (e) {
          final tempId = item['temp_id'] as String;
          _logger.e('Failed to send queued message $tempId: $e');

          // Increment retry count
          await _databaseService.incrementRetryCount(tempId, e.toString());
        }
      }

      // Clean up failed messages (exceeded max retries)
      await _databaseService.clearFailedOutbox();
    } catch (e) {
      _logger.e('Error processing outbox: $e');
    }
  }

  /// Sync messages for a specific conversation
  Future<void> _syncConversationMessages(String conversationId) async {
    try {
      // Get the latest local message timestamp for this conversation
      final latestLocalMessage = await _databaseService.getLatestMessage(
        conversationId,
      );

      // Get pagination metadata to determine sync strategy
      final paginationMetadata = await _databaseService.getPaginationMetadata(
        conversationId,
      );

      String? afterMessageId;
      if (latestLocalMessage != null) {
        afterMessageId = latestLocalMessage.id;
      }

      // Fetch new messages from server
      final newMessages = await _chatRepository.getMessagesPaginated(
        conversationId: conversationId,
        cursorMessageId: afterMessageId,
        limit: 50,
        fromCache: false, // Force network fetch for sync
      );

      if (newMessages.isNotEmpty) {
        _logger.d(
          'Synced ${newMessages.length} new messages for conversation $conversationId',
        );

        // Note: The repository implementation already saves messages to database
        // so we don't need to manually save them here

        // Update sync timestamp
        if (paginationMetadata != null) {
          final updatedMetadata = paginationMetadata.copyWith(
            lastSyncAt: DateTime.now(),
          );
          await _databaseService.savePaginationMetadata(updatedMetadata);
        }
      } else {
        _logger.d('No new messages to sync for conversation $conversationId');
      }
    } catch (e) {
      _logger.e('Error syncing messages for conversation $conversationId: $e');
      rethrow;
    }
  }

  /// Clean up old messages and optimize database
  Future<void> performDatabaseMaintenance() async {
    try {
      _logger.d('Starting database maintenance');

      // Clean up old optimistic messages that never got confirmed
      await _cleanupOldOptimisticMessages();

      // Optimize database (vacuum, analyze, etc.)
      await _databaseService.optimizeDatabase();

      _logger.i('Database maintenance completed');
    } catch (e) {
      _logger.e('Error during database maintenance: $e');
    }
  }

  /// Clean up optimistic messages that are older than threshold
  Future<void> _cleanupOldOptimisticMessages() async {
    try {
      final threshold = DateTime.now().subtract(const Duration(hours: 1));

      // Find old optimistic messages (messages with tempId that are old)
      final oldOptimisticMessages = await _databaseService
          .getOldOptimisticMessages(threshold);

      if (oldOptimisticMessages.isNotEmpty) {
        _logger.w(
          'Found ${oldOptimisticMessages.length} old optimistic messages to clean up',
        );

        for (final message in oldOptimisticMessages) {
          await _databaseService.deleteMessage(message.id);
        }

        _logger.d(
          'Cleaned up ${oldOptimisticMessages.length} old optimistic messages',
        );
      }
    } catch (e) {
      _logger.e('Error cleaning up old optimistic messages: $e');
    }
  }

  /// Get sync status information
  Future<Map<String, dynamic>> getSyncStatus() async {
    final outboxStats = await _databaseService.getOutboxStats();

    return {
      'isOnline': _isOnline,
      'isSyncInProgress': _isSyncInProgress,
      'periodicSyncEnabled': _periodicSyncTimer?.isActive ?? false,
      'syncInterval': _periodicSyncInterval.inMinutes,
      'outboxPending': outboxStats['pending'] ?? 0,
      'outboxFailed': outboxStats['failed'] ?? 0,
      'outboxTotal': outboxStats['total'] ?? 0,
    };
  }

  /// Trigger manual outbox processing
  Future<void> retryFailedMessages() async {
    if (!_isOnline) {
      _logger.w('Cannot retry failed messages - offline');
      return;
    }

    _logger.d('Manual retry of failed messages triggered');
    await _processOutbox();
  }

  /// Parse string type to MessageType enum
  MessageType _parseMessageType(String type) {
    switch (type.toLowerCase()) {
      case 'text':
        return MessageType.text;
      case 'image':
        return MessageType.image;
      case 'video':
        return MessageType.video;
      case 'audio':
        return MessageType.audio;
      case 'gif':
        return MessageType.gif;
      case 'sticker':
        return MessageType.sticker;
      case 'location':
        return MessageType.location;
      case 'contact':
        return MessageType.contact;
      case 'file':
        return MessageType.file;
      case 'system':
        return MessageType.system;
      case 'call':
        return MessageType.call;
      default:
        return MessageType.text; // Default to text
    }
  }
}

/// Extension to use unawaited for fire-and-forget operations
extension Unawaited on Future<void> {
  // This allows us to call unawaited(future) to suppress lint warnings
  // for fire-and-forget operations
}

/// Helper function for unawaited calls
void unawaited(Future<void> future) {
  // Intentionally empty - this is just to suppress linter warnings
  // for fire-and-forget Future calls
}
