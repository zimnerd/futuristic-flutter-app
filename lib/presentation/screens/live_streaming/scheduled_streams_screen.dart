import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../blocs/live_streaming/live_streaming_bloc.dart';
import '../../blocs/live_streaming/live_streaming_event.dart';
import '../../blocs/live_streaming/live_streaming_state.dart';
import '../../widgets/common/pulse_toast.dart';
import 'schedule_stream_screen.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';

/// Screen displaying list of scheduled streams with countdown timers
class ScheduledStreamsScreen extends StatefulWidget {
  const ScheduledStreamsScreen({super.key});

  @override
  State<ScheduledStreamsScreen> createState() => _ScheduledStreamsScreenState();
}

class _ScheduledStreamsScreenState extends State<ScheduledStreamsScreen> {
  Timer? _countdownTimer;

  // Theme constants for DRY code
  static const _cardBackgroundColor = Color(0xFF1E1E1E);
  static const _lightBackgroundOpacity = Color(
    0x1AFFFFFF,
  ); // white with alpha 0.1
  static const _veryLightBackground = Color(
    0x0DFFFFFF,
  ); // white with alpha 0.05
  static const _redBackground = Color(0x1AFF0000); // red with alpha 0.1
  static const _greenBackground = Color(0x1A00FF00); // green with alpha 0.1

  @override
  void initState() {
    super.initState();
    _loadScheduledStreams();

    // Update countdown every second
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {}); // Trigger rebuild for countdown updates
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _loadScheduledStreams() {
    context.read<LiveStreamingBloc>().add(const LoadMyScheduledStreams());
  }

  Future<void> _navigateToScheduleScreen() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const ScheduleStreamScreen()),
    );

    if (result == true) {
      _loadScheduledStreams();
    }
  }

  void _handleCancel(String streamId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardBackgroundColor,
        title: Text(
          'Cancel Stream',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to cancel this scheduled stream?',
          style: TextStyle(color: context.outlineColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<LiveStreamingBloc>().add(
                CancelScheduledStream(streamId),
              );

              // Show loading and refresh after a delay
              Future.delayed(const Duration(seconds: 1), () {
                if (mounted) {
                  _loadScheduledStreams();
                }
              });
            },
            child: Text(
              'Yes, Cancel',
              style: TextStyle(color: context.errorColor),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleEdit(Map<String, dynamic> stream) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ScheduleStreamScreen(streamToEdit: stream),
      ),
    );

    // Refresh list if stream was updated
    if (result == true && mounted) {
      _loadScheduledStreams();
    }
  }

  String _formatCountdown(DateTime scheduledTime) {
    final now = DateTime.now();
    final diff = scheduledTime.difference(now);

    if (diff.isNegative) {
      return 'Starting soon';
    }

    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;
    final seconds = diff.inSeconds % 60;

    if (days > 0) {
      return '${days}d ${hours}h ${minutes}m';
    }
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    }
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Scheduled Streams',
          style: TextStyle(
            color: context.onSurfaceColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: BlocListener<LiveStreamingBloc, LiveStreamingState>(
        listener: (context, state) {
          if (state is ScheduledStreamCanceled) {
            PulseToast.success(
              context,
              message: 'Stream canceled successfully',
            );
          } else if (state is LiveStreamingError) {
            PulseToast.error(context, message: state.message);
          }
        },
        child: BlocBuilder<LiveStreamingBloc, LiveStreamingState>(
          builder: (context, state) {
            if (state is LiveStreamingLoading) {
              return Center(child: CircularProgressIndicator());
            }

            if (state is ScheduledStreamsLoaded) {
              if (state.scheduledStreams.isEmpty) {
                return _buildEmptyState();
              }

              return RefreshIndicator(
                onRefresh: () async {
                  _loadScheduledStreams();
                  await Future.delayed(const Duration(seconds: 1));
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.scheduledStreams.length,
                  itemBuilder: (context, index) {
                    return _buildStreamCard(state.scheduledStreams[index]);
                  },
                ),
              );
            }

            if (state is LiveStreamingError) {
              return _buildErrorState(state.message);
            }

            return _buildEmptyState();
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToScheduleScreen,
        backgroundColor: Theme.of(context).primaryColor,
        icon: Icon(Icons.add, color: Colors.white),
        label: Text(
          'Schedule Stream',
          style: TextStyle(
            color: context.onSurfaceColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildStreamCard(Map<String, dynamic> stream) {
    final scheduledTime = DateTime.parse(
      stream['scheduledStartTime'] as String,
    );
    final countdown = _formatCountdown(scheduledTime);
    final isPast = scheduledTime.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          if (stream['thumbnailUrl'] != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  stream['thumbnailUrl'] as String,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[900],
                      child: Center(
                        child: Icon(
                          Icons.broken_image,
                          color: context.outlineColor,
                          size: 48,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  stream['title'] as String,
                  style: TextStyle(
                    color: context.onSurfaceColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Description
                if (stream['description'] != null &&
                    (stream['description'] as String).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      stream['description'] as String,
                      style: TextStyle(
                        color: context.outlineColor,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                // Countdown or past indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isPast ? _redBackground : _greenBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPast ? Icons.error : Icons.schedule,
                        size: 16,
                        color: isPast ? Colors.red : Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isPast ? 'Time passed' : 'Starts in $countdown',
                        style: TextStyle(
                          color: isPast ? Colors.red : Colors.green,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Scheduled date and time
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: context.outlineColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat(
                        'MMM dd, yyyy • hh:mm a',
                      ).format(scheduledTime),
                      style: TextStyle(
                        color: context.outlineColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Type and viewers info
                Row(
                  children: [
                    _buildTypeBadge(stream['type'] as String),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _veryLightBackground,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people,
                            size: 14,
                            color: context.outlineColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Max ${stream['maxViewers']} viewers',
                            style: TextStyle(
                              color: context.outlineColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Tags
                if (stream['tags'] != null &&
                    (stream['tags'] as List).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (stream['tags'] as List)
                          .map(
                            (tag) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '#$tag',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),

                const SizedBox(height: 16),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _handleEdit(stream),
                      icon: Icon(
                        Icons.edit,
                        size: 18,
                        color: context.onSurfaceColor,
                      ),
                      label: Text(
                        'Edit',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: _lightBackgroundOpacity,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _handleCancel(stream['id'] as String),
                      icon: Icon(
                        Icons.cancel,
                        size: 18,
                        color: context.errorColor,
                      ),
                      label: Text(
                        'Cancel',
                        style: TextStyle(color: context.errorColor),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: _redBackground,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(String type) {
    IconData icon;
    Color color;

    switch (type.toLowerCase()) {
      case 'private':
        icon = Icons.lock;
        color = Colors.orange;
        break;
      case 'premium':
        icon = Icons.star;
        color = Colors.purple;
        break;
      default:
        icon = Icons.public;
        color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            type.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.schedule, size: 80, color: context.onSurfaceVariantColor),
          const SizedBox(height: 24),
          Text(
            'No Scheduled Streams',
            style: TextStyle(
              color: context.onSurfaceColor,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to schedule a stream',
            style: TextStyle(
              color: context.onSurfaceVariantColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: context.errorColor),
          const SizedBox(height: 24),
          Text(
            'Error Loading Streams',
            style: TextStyle(
              color: context.onSurfaceColor,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.outlineColor, fontSize: 14),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadScheduledStreams,
            icon: Icon(Icons.refresh),
            label: Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: context.onSurfaceColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
