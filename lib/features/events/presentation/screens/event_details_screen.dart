import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../presentation/theme/pulse_colors.dart';

// Temporary event model for the screen
class TempEvent {
  final String id;
  final String title;
  final String description;
  final String category;
  final DateTime dateTime;
  final String location;
  final bool isPublic;
  final String organizerName;
  final int attendeeCount;
  final int? maxAttendees;
  final String? imageUrl;

  const TempEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.dateTime,
    required this.location,
    required this.isPublic,
    required this.organizerName,
    required this.attendeeCount,
    this.maxAttendees,
    this.imageUrl,
  });
}

class EventDetailsScreen extends StatefulWidget {
  final String eventId;

  const EventDetailsScreen({
    super.key,
    required this.eventId,
  });

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  bool isAttending = false;

  // Temporary mock event data
  TempEvent get mockEvent => TempEvent(
    id: widget.eventId,
    title: 'Sample Event',
    description: 'This is a sample event description. In the real app, this would come from the backend API.',
    category: 'Social',
    dateTime: DateTime.now().add(const Duration(days: 7)),
    location: 'Sample Location, City',
    isPublic: true,
    organizerName: 'Event Organizer',
    attendeeCount: 15,
    maxAttendees: 50,
    imageUrl: null,
  );

  @override
  Widget build(BuildContext context) {
    final event = mockEvent;

    return Scaffold(
      appBar: AppBar(
        title: Text(event.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit event - Coming soon')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Image
            if (event.imageUrl != null)
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: NetworkImage(event.imageUrl!),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      PulseColors.primary.withOpacity(0.3),
                      PulseColors.secondary.withOpacity(0.3),
                    ],
                  ),
                ),
                child: Icon(
                  _getEventCategoryIcon(event.category),
                  size: 64,
                  color: PulseColors.primary,
                ),
              ),

            const SizedBox(height: 16),

            // Event Title
            Text(
              event.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: PulseColors.onSurface,
              ),
            ),

            const SizedBox(height: 8),

            // Event Category and Privacy
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: PulseColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    event.category,
                    style: TextStyle(
                      color: PulseColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: event.isPublic
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        event.isPublic ? Icons.public : Icons.lock,
                        size: 16,
                        color: event.isPublic ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        event.isPublic ? 'Public' : 'Private',
                        style: TextStyle(
                          color: event.isPublic ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Event Details
            _buildDetailRow(
              icon: Icons.access_time,
              title: 'Date & Time',
              content: DateFormat('EEEE, MMMM d, y • h:mm a').format(event.dateTime),
            ),

            const SizedBox(height: 12),

            _buildDetailRow(
              icon: Icons.location_on,
              title: 'Location',
              content: event.location,
            ),

            const SizedBox(height: 12),

            _buildDetailRow(
              icon: Icons.person,
              title: 'Organizer',
              content: event.organizerName,
            ),

            const SizedBox(height: 12),

            _buildDetailRow(
              icon: Icons.group,
              title: 'Attendees',
              content: event.maxAttendees != null
                  ? '${event.attendeeCount}/${event.maxAttendees}'
                  : '${event.attendeeCount}',
            ),

            const SizedBox(height: 20),

            // Event Description
            if (event.description.isNotEmpty) ...[
              Text(
                'Description',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: PulseColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                event.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: PulseColors.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Attendees Section
            Text(
              'Attendees',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: PulseColors.onSurface,
              ),
            ),
            const SizedBox(height: 12),

            // Placeholder attendees list
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: PulseColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: PulseColors.onSurface.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Icon(Icons.people, color: PulseColors.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(
                    'Attendee list will be loaded here',
                    style: TextStyle(color: PulseColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons Section
            Text(
              'Event Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: PulseColors.onSurface,
              ),
            ),
            const SizedBox(height: 12),

            // Chat, Call, Video Buttons (Temporary placeholders)
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.chat_bubble_outline,
                    label: 'Chat',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Event chat - Coming soon')),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.call,
                    label: 'Call',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Event call - Coming soon')),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.videocam,
                    label: 'Video',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Event video - Coming soon')),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // RSVP Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    isAttending = !isAttending;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isAttending ? 'Attending event!' : 'Left event'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAttending ? Colors.orange : PulseColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(isAttending ? 'Leave Event' : 'Attend Event'),
              ),
            ),

            const SizedBox(height: 16),

            // Share Event Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Share event - Coming soon')),
                  );
                },
                icon: const Icon(Icons.share),
                label: const Text('Share Event'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: PulseColors.primary,
                  side: BorderSide(color: PulseColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: PulseColors.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: PulseColors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                content,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: PulseColors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: PulseColors.surface,
        foregroundColor: PulseColors.primary,
        elevation: 0,
        side: BorderSide(color: PulseColors.primary.withOpacity(0.3)),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  IconData _getEventCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'social':
        return Icons.people;
      case 'sports':
        return Icons.sports_soccer;
      case 'entertainment':
        return Icons.movie;
      case 'educational':
        return Icons.school;
      case 'networking':
        return Icons.business;
      case 'outdoor':
        return Icons.nature;
      case 'food':
        return Icons.restaurant;
      case 'arts':
        return Icons.palette;
      default:
        return Icons.event;
    }
  }
}