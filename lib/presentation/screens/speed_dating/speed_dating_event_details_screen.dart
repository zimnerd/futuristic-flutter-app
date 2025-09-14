import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../theme/pulse_colors.dart';
import '../../blocs/speed_dating/speed_dating_bloc.dart';
import '../../blocs/speed_dating/speed_dating_event.dart';

/// Screen showing detailed view of a speed dating event
class SpeedDatingEventDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> event;

  const SpeedDatingEventDetailsScreen({
    super.key,
    required this.event,
  });

  @override
  State<SpeedDatingEventDetailsScreen> createState() => _SpeedDatingEventDetailsScreenState();
}

class _SpeedDatingEventDetailsScreenState extends State<SpeedDatingEventDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final startTime = DateTime.tryParse(event['startTime'] ?? '');
    final endTime = DateTime.tryParse(event['endTime'] ?? '');
    final maxParticipants = event['maxParticipants'] ?? 0;
    final currentParticipants = event['currentParticipants'] ?? 0;
    final isRegistered = event['isRegistered'] == true;
    final canJoin = currentParticipants < maxParticipants && !isRegistered;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(event['title'] ?? 'Speed Dating Event'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event['title'] ?? 'Speed Dating Event',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (event['description'] != null && event['description'].isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        event['description'],
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
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
                            isRegistered ? 'You are registered!' : 'Join this event',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
            if (startTime != null && endTime != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.schedule),
                  title: const Text('Event Time'),
                  subtitle: Text(
                    '${_formatDateTime(startTime)} - ${_formatTime(endTime)}',
                  ),
                ),
              ),
            const SizedBox(height: 16),
            
            // Location
            if (event['location'] != null && event['location'].isNotEmpty)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.location_on),
                  title: const Text('Location'),
                  subtitle: Text(event['location']),
                  trailing: IconButton(
                    icon: const Icon(Icons.map),
                    onPressed: () => _openLocation(event['location']),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            
            // Age Range
            if (event['ageRange'] != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.cake),
                  title: const Text('Age Range'),
                  subtitle: Text(event['ageRange']),
                ),
              ),
            const SizedBox(height: 16),
            
            // Round Duration
            if (event['roundDuration'] != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.timer),
                  title: const Text('Round Duration'),
                  subtitle: Text('${event['roundDuration']} minutes per conversation'),
                ),
              ),
            const SizedBox(height: 16),
            
            // Registration Fee
            if (event['fee'] != null && event['fee'] > 0)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.attach_money),
                  title: const Text('Registration Fee'),
                  subtitle: Text('\$${event['fee'].toStringAsFixed(2)}'),
                ),
              ),
            const SizedBox(height: 32),
            
            // Action Button
            SizedBox(
              width: double.infinity,
              child: isRegistered
                  ? ElevatedButton.icon(
                      onPressed: _leaveEvent,
                      icon: const Icon(Icons.exit_to_app),
                      label: const Text('Leave Event'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: canJoin ? _joinEvent : null,
                      icon: const Icon(Icons.join_full),
                      label: Text(canJoin ? 'Join Event' : 'Event Full'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PulseColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour == 0 ? 12 : dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  void _joinEvent() {
    final eventId = widget.event['id'] as String?;
    if (eventId != null) {
      context.read<SpeedDatingBloc>().add(JoinSpeedDatingEvent(eventId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Joining event...')),
      );
    }
  }

  void _leaveEvent() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Event'),
        content: const Text(
          'Are you sure you want to leave this speed dating event?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final eventId = widget.event['id'] as String?;
              if (eventId != null) {
                context.read<SpeedDatingBloc>().add(LeaveSpeedDatingEvent(eventId));
              }
              Navigator.pop(context); // Close dialog
              context.pop(); // Return to previous screen
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  void _openLocation(String location) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening location: $location')),
    );
  }
}