import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../theme/pulse_colors.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';
import '../../widgets/common/pulse_toast.dart';
import '../../widgets/speed_dating/event_countdown_timer.dart';
import '../../blocs/speed_dating/speed_dating_bloc.dart';
import '../../blocs/speed_dating/speed_dating_event.dart';
import '../../blocs/speed_dating/speed_dating_state.dart';

/// Screen showing detailed view of a speed dating event
class SpeedDatingEventDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> event;

  const SpeedDatingEventDetailsScreen({super.key, required this.event});

  @override
  State<SpeedDatingEventDetailsScreen> createState() =>
      _SpeedDatingEventDetailsScreenState();
}

class _SpeedDatingEventDetailsScreenState
    extends State<SpeedDatingEventDetailsScreen> {
  bool _isWaitingToNavigateAfterLeave = false;

  @override
  Widget build(BuildContext context) {
    final startTime = DateTime.tryParse(widget.event['startTime'] ?? '');
    final durationMinutes = widget.event['durationMinutes'] ?? 0;
    final maxParticipants = widget.event['maxParticipants'] ?? 0;
    final currentParticipants = widget.event['currentParticipants'] ?? 0;
    final minAge = widget.event['minAge'];
    final maxAge = widget.event['maxAge'];
    final imageUrl = widget.event['imageUrl'];
    final location = widget.event['location'];
    final isVirtual = widget.event['isVirtual'] ?? true;
    final category = widget.event['category'];
    final tags = (widget.event['tags'] as List?)?.cast<String>() ?? [];
    final isRegistered = widget.event['isRegistered'] == true;
    final canJoin = widget.event['canJoin'] == true && !isRegistered;

    return BlocListener<SpeedDatingBloc, SpeedDatingState>(
      listener: (context, state) {
        if (state is SpeedDatingJoined) {
          PulseToast.success(
            context,
            message: 'Successfully joined the event!',
          );
          // Navigate back to speed dating list explicitly
          Future.delayed(const Duration(milliseconds: 800), () {
            if (context.mounted) {
              context.goNamed('speedDating');
            }
          });
        } else if (state is SpeedDatingLeft) {
          PulseToast.success(context, message: 'You have left the event');
          // Set flag to wait for event list refresh
          setState(() {
            _isWaitingToNavigateAfterLeave = true;
          });
          // BLoC will emit SpeedDatingLoaded after refreshing events
        } else if (state is SpeedDatingLoaded) {
          // Only navigate back if we're waiting for post-leave navigation
          if (_isWaitingToNavigateAfterLeave) {
            setState(() {
              _isWaitingToNavigateAfterLeave = false;
            });
            Future.delayed(const Duration(milliseconds: 300), () {
              if (context.mounted) {
                context.goNamed('speedDating');
              }
            });
          }
        } else if (state is SpeedDatingError) {
          PulseToast.error(context, message: state.message);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.event['title'] ?? 'Speed Dating Event',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: context.surfaceColor,
          iconTheme: const IconThemeData(color: Colors.black87),
          elevation: 1,
        ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              // Event Image
              if (imageUrl != null && imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: context.outlineColor.shade200,
                        child: Center(
                          child: Icon(
                            Icons.event,
                            size: 64,
                            color: context.outlineColor,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              if (imageUrl != null && imageUrl.isNotEmpty)
                const SizedBox(height: 16),

            // Event Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.event['title'] ?? 'Speed Dating Event',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (category != null && category.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: PulseColors.primary.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                category.toUpperCase(),
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: PulseColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                        ],
                    ),
                      if (widget.event['description'] != null &&
                          widget.event['description'].isNotEmpty) ...[
                        const SizedBox(height: 12),
                      Text(
                          widget.event['description'],
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                      if (tags.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: tags
                              .map(
                                (tag) => Chip(
                                  label: Text(tag),
                                  backgroundColor:
                                      context.outlineColor.shade200,
                                  labelStyle: Theme.of(
                                    context,
                                  ).textTheme.labelSmall,
                                ),
                              )
                              .toList(),
                        ),
                      ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

              // Countdown Timer (if event is upcoming)
              if (startTime != null && startTime.isAfter(DateTime.now()))
                Column(
                  children: [
                    EventCountdownTimer(eventStartTime: startTime),
                    const SizedBox(height: 16),
                  ],
                ),

            // Event Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      isRegistered ? Icons.check_circle : Icons.people,
                      color: isRegistered ? Colors.green : PulseColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isRegistered
                                ? 'You are registered!'
                                : 'Join this event',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isRegistered ? Colors.green : null,
                                ),
                          ),
                          Text(
                            '$currentParticipants/$maxParticipants participants',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Date & Time
              if (startTime != null)
              Card(
                child: ListTile(
                    leading:  Icon(
                      Icons.schedule,
                      color: PulseColors.primary,
                    ),
                    title: Text(
                      'Event Time',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  subtitle: Text(
                      '${_formatDateTime(startTime)} at ${_formatTime(startTime)}\nDuration: $durationMinutes minutes',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.black87),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Location
              Card(
                child: ListTile(
                  leading: Icon(
                    isVirtual ? Icons.video_call : Icons.location_on,
                    color: PulseColors.primary,
                  ),
                  title: Text(
                    isVirtual ? 'Virtual Event' : 'Location',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: location != null && location.isNotEmpty
                      ? Text(
                          location,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.black87),
                        )
                      : Text(
                          isVirtual
                              ? 'Join online via video call'
                              : 'No location specified',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.black87),
                        ),
                ),
              ),
              const SizedBox(height: 12),

            // Age Range
              if (minAge != null || maxAge != null)
              Card(
                child: ListTile(
                    leading: Icon(Icons.cake, color: PulseColors.primary),
                    title: Text(
                      'Age Range',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  subtitle: Text(
                      minAge != null && maxAge != null
                          ? '$minAge - $maxAge years'
                          : minAge != null
                          ? '$minAge+ years'
                          : 'Up to $maxAge years',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.black87),
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Registration Fee
              if (widget.event['fee'] != null && widget.event['fee'] > 0)
              Card(
                child: ListTile(
                    leading: Icon(Icons.attach_money),
                    title: Text('Registration Fee'),
                    subtitle: Text(
                      '\$${widget.event['fee'].toStringAsFixed(2)}',
                    ),
                ),
              ),
            const SizedBox(height: 32),

            // Action Button
            SizedBox(
              width: double.infinity,
              child: isRegistered
                  ? ElevatedButton.icon(
                        onPressed: () => _leaveEvent(context),
                        icon: Icon(Icons.exit_to_app),
                        label: Text('Leave Event'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                          foregroundColor: context.onSurfaceColor,
                      ),
                    )
                  : ElevatedButton.icon(
                        onPressed: canJoin ? () => _joinEvent(context) : null,
                        icon: Icon(Icons.join_full),
                      label: Text(canJoin ? 'Join Event' : 'Event Full'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PulseColors.primary,
                          foregroundColor: context.onSurfaceColor,
                      ),
                    ),
            ),
          ],
        ),
      ),
      ), // Close Scaffold and BlocListener
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour == 0
        ? 12
        : dateTime.hour > 12
        ? dateTime.hour - 12
        : dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  void _joinEvent(BuildContext context) {
    final eventId = widget.event['id'] as String?;
    if (eventId != null) {
      context.read<SpeedDatingBloc>().add(JoinSpeedDatingEvent(eventId));
    }
  }

  void _leaveEvent(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.surfaceColor,
        title: Text(
          'Leave Event',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to leave this speed dating event?',
          style: TextStyle(color: Colors.black87, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: PulseColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              final eventId = widget.event['id'] as String?;
              if (eventId != null) {
                context.read<SpeedDatingBloc>().add(
                  LeaveSpeedDatingEvent(eventId),
                );
              }
              Navigator.pop(dialogContext); // Close dialog
            },
            child: Text(
              'Leave',
              style: TextStyle(
                color: context.errorColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
