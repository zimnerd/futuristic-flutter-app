import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';

import '../../../domain/entities/event.dart';
import '../../../core/network/api_client.dart';
import '../../blocs/event/event_bloc.dart';
import '../../blocs/event/event_event.dart';
import '../../blocs/event/event_state.dart';
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

          // Check for EventDetailsLoaded state (correct state for single event)
          if (state is EventDetailsLoaded) {
            return _buildEventDetails(context, state.event);
          }

          // Fallback: Also check EventsLoaded in case navigation came from events list
          if (state is EventsLoaded) {
            try {
              final event = state.events.firstWhere(
                (e) => e.id == widget.eventId,
              );
              return _buildEventDetails(context, event);
            } catch (e) {
              // Event not in the loaded list, trigger load
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
          }

          return const Center(
            child: Text('Event not found'),
          );
        },
      ),
    );
  }

  Widget _buildEventDetails(BuildContext context, Event event) {
    // Only show image if available
    final bool hasImage = event.image != null && event.image!.isNotEmpty;
    
    return CustomScrollView(
      slivers: [
        // App bar with event image (only if image exists)
        if (hasImage)
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  RobustNetworkImage(
                    imageUrl: event.image,
                    width: double.infinity,
                    height: 300,
                    fit: BoxFit.cover,
                  ),
                  // Gradient overlay for better text readability
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          // Simple app bar without image
          SliverAppBar(pinned: true, title: const Text('Event Details')),
        
        // Event content
        SliverPadding(
          padding: const EdgeInsets.all(20),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor.withValues(alpha: 0.1),
            Theme.of(context).primaryColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category badge with icon and color
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: event.categoryDetails?.color != null
                  ? _parseColor(event.categoryDetails!.color!)
                  : Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (event.categoryDetails?.icon != null)
                  Text(
                    event.categoryDetails!.icon!,
                    style: const TextStyle(fontSize: 14),
                  )
                else
                  const Icon(
                    Icons.category_outlined,
                    size: 14,
                    color: Colors.white,
                  ),
                const SizedBox(width: 6),
                Text(
                  event.categoryDetails?.name.toUpperCase() ?? 
                  event.category.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Event title
          Text(
            event.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          
          // Attendance badge
          if (event.isAttending)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[300]!, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[700], size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'You\'re going!',
                      style: TextStyle(
                        color: Colors.green[800],
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Helper to parse hex color strings
  Color _parseColor(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return Theme.of(context).primaryColor;
    }
  }

  Widget _buildDescription(BuildContext context, Event event) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description_outlined,
                size: 20,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'About',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            event.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventInfo(BuildContext context, Event event) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Event Details',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Date & Time
          _buildInfoRow(
            context,
            Icons.schedule,
            'Date & Time',
            '${event.date.day}/${event.date.month}/${event.date.year} at ${event.date.hour}:${event.date.minute.toString().padLeft(2, '0')}',
            Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Location with map link
          _buildInfoRow(
            context,
            Icons.location_on,
            'Location',
            event.location,
            Colors.red[400]!,
            showAction: true,
            actionIcon: Icons.map_outlined,
            onActionTap: () => _openMap(event),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Attendee count
          _buildInfoRow(
            context,
            Icons.people,
            'Attendees',
            '${event.attendeeCount} going${event.maxAttendees != null ? ' / ${event.maxAttendees} max' : ''}',
            Colors.green[400]!,
          ),
          
          // Category description if available
          if (event.categoryDetails?.description != null) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            _buildInfoRow(
              context,
              Icons.info_outline,
              'Category Info',
              event.categoryDetails!.description!,
              Colors.blue[400]!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color iconColor, {
    bool showAction = false,
    IconData? actionIcon,
    VoidCallback? onActionTap,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon,
            size: 22, color: iconColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  letterSpacing: 0.5,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        if (showAction && actionIcon != null && onActionTap != null)
          IconButton(
            icon: Icon(actionIcon, size: 20),
            onPressed: onActionTap,
            color: iconColor,
            tooltip: 'Open in Maps',
          ),
      ],
    );
  }

  void _openMap(Event event) {
    final lat = event.coordinates.lat;
    final lng = event.coordinates.lng;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📍 Location: $lat, $lng\nTap to open in maps (coming soon)'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Close',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, Event event) {
    return Column(
      children: [
        // Primary action button
        SizedBox(
          width: double.infinity,
          height: 56,
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: event.isAttending ? 0 : 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  event.isAttending ? Icons.check_circle : Icons.add_circle,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  event.isAttending ? 'Leave Event' : 'Join Event',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // Secondary action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _shareEvent(context, event),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  side: BorderSide(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                  ),
                ),
                icon: Icon(
                  Icons.share,
                  size: 18,
                  color: Theme.of(context).primaryColor,
                ),
                label: Text(
                  'Share',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _reportEvent(context, event),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
                ),
                icon: const Icon(Icons.flag, size: 18, color: Colors.red),
                label: const Text(
                  'Report',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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

}

class AttendeeAvatar extends StatelessWidget {
  final EventAttendance attendance;
  final double size;

  const AttendeeAvatar({required this.attendance, this.size = 50, super.key});

  @override
  Widget build(BuildContext context) {
    final userInfo = attendance.user;
    final displayName = userInfo?['displayName'] ?? userInfo?['name'] ?? 'User';
    final profilePictureUrl = userInfo?['profilePictureUrl'] as String?;

    return Column(
      children: [
        CircleAvatar(
          radius: size / 2,
          backgroundImage: profilePictureUrl != null
              ? NetworkImage(profilePictureUrl)
              : null,
          child: profilePictureUrl == null
              ? Text(
                  displayName.toString()[0].toUpperCase(),
                  style: TextStyle(fontSize: size / 2.5),
                )
              : null,
        ),
      ],
    );
  }
}
