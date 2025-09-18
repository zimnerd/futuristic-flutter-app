import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';

import '../../../domain/entities/event.dart';
import '../../../core/network/api_client.dart';
import '../../blocs/event/event_bloc.dart';
import '../../blocs/event/event_event.dart';
import '../../blocs/event/event_state.dart';
import '../../widgets/events/attendee_avatar.dart';
import '../../widgets/common/robust_network_image.dart';

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
  @override
  void initState() {
    super.initState();
    // Load event details when screen initializes
    context.read<EventBloc>().add(LoadEventDetails(widget.eventId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<EventBloc, EventState>(
        builder: (context, state) {
          if (state is EventLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is EventError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load event details',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.red[300],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.read<EventBloc>().add(
                          LoadEventDetails(widget.eventId),
                        ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is EventsLoaded) {
            final event = state.events.firstWhere(
              (e) => e.id == widget.eventId,
              orElse: () => throw StateError('Event not found'),
            );

            return _buildEventDetails(context, event);
          }

          return const Center(
            child: Text('Event not found'),
          );
        },
      ),
    );
  }

  Widget _buildEventDetails(BuildContext context, Event event) {
    return CustomScrollView(
      slivers: [
        // App bar with event image
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: RobustNetworkImage(
              imageUrl: event.image,
              width: double.infinity,
              height: 300,
              fit: BoxFit.cover,
            ),
          ),
        ),
        
        // Event content
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Event title and basic info
              _buildEventHeader(context, event),
              const SizedBox(height: 24),
              
              // Event description
              _buildDescription(context, event),
              const SizedBox(height: 24),
              
              // Event details
              _buildEventInfo(context, event),
              const SizedBox(height: 24),
              
              // Attendees section
              _buildAttendeesSection(context, event),
              const SizedBox(height: 24),
              
              // Action buttons
              _buildActionButtons(context, event),
              const SizedBox(height: 40),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildEventHeader(BuildContext context, Event event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          event.title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.category_outlined,
              size: 16,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              event.category,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDescription(BuildContext context, Event event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          event.description,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildEventInfo(BuildContext context, Event event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Event Details',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        
        // Date & Time
        _buildInfoRow(
          context,
          Icons.schedule,
          'Date & Time',
          '${event.date.day}/${event.date.month}/${event.date.year} at ${event.date.hour}:${event.date.minute.toString().padLeft(2, '0')}',
        ),
        const SizedBox(height: 12),
        
        // Location
        _buildInfoRow(
          context,
          Icons.location_on,
          'Location',
          event.location,
        ),
        const SizedBox(height: 12),
        
        // Attendee count
        _buildInfoRow(
          context,
          Icons.people,
          'Attendees',
          '${event.attendeeCount} going',
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttendeesSection(BuildContext context, Event event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Going (${event.attendeeCount})',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (event.attendees.length > 5)
              TextButton(
                onPressed: () {
                  _showAllAttendees(context, event);
                },
                child: const Text('See all'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        
        if (event.attendees.isEmpty)
          Text(
            'No attendees yet. Be the first to join!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          )
        else
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: event.attendees.take(10).length,
              itemBuilder: (context, index) {
                final attendee = event.attendees[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: AttendeeAvatar(
                    attendance: attendee,
                    size: 50,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, Event event) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: event.isAttending
                ? () => _leaveEvent(context, event)
                : () => _joinEvent(context, event),
            style: ElevatedButton.styleFrom(
              backgroundColor: event.isAttending
                  ? Colors.grey[300]
                  : Theme.of(context).primaryColor,
              foregroundColor: event.isAttending
                  ? Colors.grey[700]
                  : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              event.isAttending ? 'Leave Event' : 'Join Event',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _shareEvent(context, event),
                icon: const Icon(Icons.share),
                label: const Text('Share'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _reportEvent(context, event),
                icon: const Icon(Icons.flag),
                label: const Text('Report'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _joinEvent(BuildContext context, Event event) {
    context.read<EventBloc>().add(AttendEvent(event.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Joined "${event.title}"'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _leaveEvent(BuildContext context, Event event) {
    context.read<EventBloc>().add(LeaveEvent(event.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Left "${event.title}"'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _shareEvent(BuildContext context, Event event) {
    // Use clipboard as fallback since share_plus might not be available
    final shareText =
        '${event.title}\n\n${event.description}\n\nJoin me at this event!';
    Clipboard.setData(ClipboardData(text: shareText)).then((_) {
      if (mounted) {
        ScaffoldMessenger.of(this.context).showSnackBar(
          const SnackBar(
            content: Text('Event details copied to clipboard'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  void _reportEvent(BuildContext context, Event event) async {
    try {
      await ApiClient.instance.reportEvent(
        eventId: event.id,
        reason: 'inappropriate_content',
        description: 'Event reported by user',
      );

      if (mounted) {
        ScaffoldMessenger.of(this.context).showSnackBar(
          const SnackBar(
            content: Text('Event reported successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(
            content: Text('Failed to report event: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAllAttendees(BuildContext context, Event event) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Attendees (${event.attendeeCount})'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: event.attendees.isEmpty
                ? const Center(child: Text('No attendees yet'))
                : ListView.builder(
                    itemCount: event.attendees.length,
                    itemBuilder: (context, index) {
                      final attendee = event.attendees[index];
                      final userInfo = attendee.user;
                      final displayName =
                          userInfo?['displayName'] ??
                          userInfo?['name'] ??
                          'Unknown User';
                      final profilePictureUrl =
                          userInfo?['profilePictureUrl'] as String?;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: profilePictureUrl != null
                              ? NetworkImage(profilePictureUrl)
                              : null,
                          child: profilePictureUrl == null
                              ? Text(displayName.toString()[0].toUpperCase())
                              : null,
                        ),
                        title: Text(displayName.toString()),
                        subtitle: Text(
                          'Joined ${attendee.timestamp.toString().split(' ')[0]}',
                        ),
                        trailing: Icon(
                          attendee.status == 'confirmed'
                              ? Icons.check_circle
                              : Icons.help_outline,
                          color: attendee.status == 'confirmed'
                              ? Colors.green
                              : Colors.orange,
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}