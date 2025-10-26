import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../../blocs/chat_bloc.dart';
import '../../../data/services/background_sync_manager.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';
import '../common/pulse_toast.dart';

/// A widget that provides pull-to-refresh functionality with background sync
/// This can be wrapped around conversation lists or message lists
class SyncRefreshWrapper extends StatefulWidget {
  final Widget child;
  final String? conversationId; // If provided, syncs specific conversation
  final bool showSyncStatus;

  const SyncRefreshWrapper({
    super.key,
    required this.child,
    this.conversationId,
    this.showSyncStatus = false,
  });

  @override
  State<SyncRefreshWrapper> createState() => _SyncRefreshWrapperState();
}

class _SyncRefreshWrapperState extends State<SyncRefreshWrapper> {
  final Logger _logger = Logger();
  bool _isManualSyncing = false;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: Column(
        children: [
          // Optional sync status indicator
          if (widget.showSyncStatus) _buildSyncStatusIndicator(),

          // Main content
          Expanded(child: widget.child),
        ],
      ),
    );
  }

  /// Handle pull-to-refresh action
  Future<void> _handleRefresh() async {
    setState(() => _isManualSyncing = true);

    // Capture bloc reference before async operations
    final chatBloc = context.read<ChatBloc>();

    try {
      _logger.d('SyncRefreshWrapper: Starting manual refresh');

      if (widget.conversationId != null) {
        // Sync specific conversation
        final syncManager = BackgroundSyncManager.instance;
        await syncManager
            .forceSync(); // Note: We could add conversation-specific sync later

        // Trigger bloc refresh for this conversation
        chatBloc.add(RefreshMessages(conversationId: widget.conversationId!));
      } else {
        // Sync all conversations
        chatBloc.add(const SyncConversations());
      }

      _logger.i('SyncRefreshWrapper: Manual refresh completed');
    } catch (e, stackTrace) {
      _logger.e(
        'SyncRefreshWrapper: Manual refresh failed',
        error: e,
        stackTrace: stackTrace,
      );

      // Show error toast
      if (mounted) {
        PulseToast.error(context, message: 'Failed to sync. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isManualSyncing = false);
      }
    }
  }

  /// Build sync status indicator
  Widget _buildSyncStatusIndicator() {
    return FutureBuilder<Map<String, dynamic>>(
      future: BackgroundSyncManager.instance.getSyncStatus(),
      builder: (context, snapshot) {
        final syncStatus = snapshot.data ?? {};

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Sync status icon
              Icon(
                _getSyncStatusIcon(syncStatus),
                size: 16,
                color: _getSyncStatusColor(syncStatus),
              ),
              const SizedBox(width: 8),

              // Sync status text
              Expanded(
                child: Text(
                  _getSyncStatusText(syncStatus),
                  style: TextStyle(
                    fontSize: 12,
                    color: _getSyncStatusColor(syncStatus),
                  ),
                ),
              ),

              // Manual sync button
              if (!_isManualSyncing)
                IconButton(
                  icon: Icon(Icons.refresh, size: 18),
                  onPressed: _handleRefresh,
                  tooltip: 'Manual sync',
                )
              else
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        );
      },
    );
  }

  IconData _getSyncStatusIcon(Map<String, dynamic> status) {
    final isRunning = status['isRunning'] ?? false;
    final isInitialized = status['isInitialized'] ?? false;

    if (!isInitialized) return Icons.sync_disabled;
    if (_isManualSyncing) return Icons.sync;
    if (isRunning) return Icons.sync;
    return Icons.sync_problem;
  }

  Color _getSyncStatusColor(Map<String, dynamic> status) {
    final isRunning = status['isRunning'] ?? false;
    final isInitialized = status['isInitialized'] ?? false;

    if (!isInitialized) return Theme.of(context).colorScheme.error;
    if (_isManualSyncing) return Theme.of(context).colorScheme.primary;
    if (isRunning) return Theme.of(context).colorScheme.tertiary;
    return Theme.of(context).colorScheme.error;
  }

  String _getSyncStatusText(Map<String, dynamic> status) {
    final isRunning = status['isRunning'] ?? false;
    final isInitialized = status['isInitialized'] ?? false;
    final lastSyncTime = status['lastSyncTime'];

    if (!isInitialized) return 'Sync not available';
    if (_isManualSyncing) return 'Syncing...';
    if (isRunning) return 'Background sync active';

    if (lastSyncTime != null) {
      final lastSync = DateTime.tryParse(lastSyncTime.toString());
      if (lastSync != null) {
        final diff = DateTime.now().difference(lastSync);
        if (diff.inMinutes < 1) return 'Synced just now';
        if (diff.inHours < 1) return 'Synced ${diff.inMinutes}m ago';
        if (diff.inDays < 1) return 'Synced ${diff.inHours}h ago';
        return 'Synced ${diff.inDays}d ago';
      }
    }

    return 'Sync status unknown';
  }
}
