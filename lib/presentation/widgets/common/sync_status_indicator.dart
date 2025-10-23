import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/pulse_design_system.dart';
import '../../../data/services/websocket_service_impl.dart';

/// Sync Status Indicator Widget
///
/// Shows connection status in app bar:
/// - Online (green dot)
/// - Syncing (yellow pulse)
/// - Offline (red dot)
/// - Reconnecting (orange spinner)
///
/// Tap to show connection details
///
/// A widget that displays the current sync/connection status
/// Shows a colored indicator that can be displayed with or without a label
class SyncStatusIndicator extends StatefulWidget {
  final bool showLabel;
  final double size;

  const SyncStatusIndicator({
    super.key,
    this.showLabel = false,
    this.size = 8.0,
  });

  @override
  State<SyncStatusIndicator> createState() => _SyncStatusIndicatorState();
}

class _SyncStatusIndicatorState extends State<SyncStatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late WebSocketServiceImpl _webSocketService;
  StreamSubscription<String>? _connectionStateSubscription;
  ConnectionStatus _status = ConnectionStatus.disconnected;
  DateTime? _lastSyncTime;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Initialize WebSocket service
    _webSocketService = WebSocketServiceImpl.instance;
    _listenToConnectionStatus();
  }

  void _listenToConnectionStatus() {
    // Listen to WebSocket connection state changes
    _connectionStateSubscription = _webSocketService.connectionState.listen(
      (state) {
        if (!mounted) return;

        setState(() {
          // Map WebSocket state strings to ConnectionStatus enum
          switch (state) {
            case 'connected':
              _status = ConnectionStatus.connected;
              _lastSyncTime = DateTime.now();
              break;
            case 'connecting':
              _status = ConnectionStatus.connecting;
              break;
            case 'disconnected':
              _status = ConnectionStatus.disconnected;
              break;
            case 'error':
              _status = ConnectionStatus.disconnected;
              break;
            default:
              _status = ConnectionStatus.disconnected;
          }
        });
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _status = ConnectionStatus.disconnected;
        });
      },
    );

    // Set initial status based on current connection state
    setState(() {
      if (_webSocketService.isConnected) {
        _status = ConnectionStatus.connected;
        _lastSyncTime = DateTime.now();
      } else {
        _status = ConnectionStatus.disconnected;
      }
    });
  }

  @override
  void dispose() {
    _connectionStateSubscription?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Color _getStatusColor() {
    switch (_status) {
      case ConnectionStatus.connected:
        return PulseColors.success;
      case ConnectionStatus.connecting:
      case ConnectionStatus.reconnecting:
        return PulseColors.warning;
      case ConnectionStatus.disconnected:
        return PulseColors.error;
    }
  }

  IconData _getStatusIcon() {
    switch (_status) {
      case ConnectionStatus.connected:
        return Icons.check_circle;
      case ConnectionStatus.connecting:
      case ConnectionStatus.reconnecting:
        return Icons.sync;
      case ConnectionStatus.disconnected:
        return Icons.cloud_off;
    }
  }

  String _getStatusText() {
    switch (_status) {
      case ConnectionStatus.connected:
        return 'Online';
      case ConnectionStatus.connecting:
        return 'Connecting...';
      case ConnectionStatus.reconnecting:
        return 'Reconnecting...';
      case ConnectionStatus.disconnected:
        return 'Offline';
    }
  }

  String _getLastSyncText() {
    if (_lastSyncTime == null) return 'Never synced';

    final now = DateTime.now();
    final difference = now.difference(_lastSyncTime!);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _showConnectionDetails() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(_getStatusIcon(), color: _getStatusColor()),
            const SizedBox(width: 12),
            Text(_getStatusText(), style: TextStyle(color: _getStatusColor())),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Status', _getStatusText()),
            const SizedBox(height: 8),
            _buildDetailRow('Last synced', _getLastSyncText()),
            const SizedBox(height: 8),
            _buildDetailRow(
              'Connection',
              _status == ConnectionStatus.connected
                  ? 'Secure WebSocket'
                  : 'Not connected',
            ),
            if (_status != ConnectionStatus.connected) ...[
              const SizedBox(height: 16),
              const Text(
                'Messages and notifications will sync when connection is restored.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
        actions: [
          if (_status == ConnectionStatus.disconnected)
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                // Trigger WebSocket reconnection
                try {
                  setState(() {
                    _status = ConnectionStatus.connecting;
                  });
                  await _webSocketService.connect();
                } catch (e) {
                  // Connection will update through the stream listener
                  // Error state is handled by the connectionState stream
                }
              },
              child: const Text('Retry Connection'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        Text(value, style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showLabel) {
      return _buildWithLabel();
    }
    return _buildIndicatorOnly();
  }

  Widget _buildIndicatorOnly() {
    return InkWell(
      onTap: _showConnectionDetails,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: _buildStatusDot(),
      ),
    );
  }

  Widget _buildWithLabel() {
    return InkWell(
      onTap: _showConnectionDetails,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _getStatusColor().withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _getStatusColor().withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusDot(),
            const SizedBox(width: 8),
            Text(
              _getStatusText(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _getStatusColor(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDot() {
    final color = _getStatusColor();
    final shouldAnimate =
        _status == ConnectionStatus.connecting ||
        _status == ConnectionStatus.reconnecting;

    if (shouldAnimate) {
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: color.withValues(alpha: _pulseAnimation.value),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.5 * _pulseAnimation.value),
                  blurRadius: 4,
                  spreadRadius: 2,
                ),
              ],
            ),
          );
        },
      );
    }

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 2,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

/// Connection status enum
enum ConnectionStatus { connected, connecting, disconnected, reconnecting }
