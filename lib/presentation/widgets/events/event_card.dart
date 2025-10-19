import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/event.dart';
import '../../../core/constants/app_constants.dart';
import '../../theme/pulse_colors.dart';
import '../common/robust_network_image.dart';
import 'event_analytics_indicators.dart';

class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback? onTap;
  final VoidCallback? onAttend;
  final VoidCallback? onLeave;
  final bool showAttendButton;
  final bool isLoading;

  const EventCard({
    super.key,
    required this.event,
    this.onTap,
    this.onAttend,
    this.onLeave,
    this.showAttendButton = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    // Hide past events
    if (event.date.isBefore(DateTime.now())) {
      return const SizedBox.shrink();
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shadowColor: PulseColors.primary.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: event.isAttending
            ? BorderSide(color: PulseColors.success, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Image
            _buildEventImage(),
            
            // Event Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category and Date
                  Row(
                    children: [
                      _buildCategoryChip(),
                      const Spacer(),
                      _buildDateInfo(),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Title
                  Text(
                    event.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: PulseColors.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Description
                  Text(
                    event.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: PulseColors.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Location
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: PulseColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.location,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: PulseColors.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),

                  // Event Analytics Indicators
                  EventAnalyticsIndicators(
                    event: event,
                    showAttendance: true,
                    showEngagement: true,
                    showPopularity: false,
                    compact: true,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Bottom Row - Attendees and Action Button
                  Row(
                    children: [
                      _buildAttendeeInfo(),
                      const Spacer(),
                      if (showAttendButton) _buildActionButton(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventImage() {
    return Stack(
      children: [
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            gradient: LinearGradient(
              colors: [
                PulseColors.primary.withValues(alpha: 0.1),
                PulseColors.secondary.withValues(alpha: 0.1),
              ],
            ),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: EventNetworkImage(
              imageUrl: event.image != null
                  ? (event.image!.startsWith('http')
                        ? event.image!
                        : '${AppConstants.baseUrl}/${event.image}')
                  : null,
              width: double.infinity,
              height: 200,
              eventCategory: event.category,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
          ),
        ),
        if (event.isAttending)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: PulseColors.success,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: PulseColors.success.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.check, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'JOINED',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: PulseColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: PulseColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        event.categoryDetails?.name ??
            EventCategories.getDisplayName(event.category),
        style: TextStyle(
          color: PulseColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDateInfo() {
    final dateFormat = DateFormat('MMM dd');
    final timeFormat = DateFormat('HH:mm');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          dateFormat.format(event.date),
          style: TextStyle(
            color: PulseColors.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          timeFormat.format(event.date),
          style: TextStyle(
            color: PulseColors.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildAttendeeInfo() {
    return Row(
      children: [
        Icon(
          Icons.people_outline,
          size: 16,
          color: PulseColors.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          '${event.attendeeCount} attending',
          style: TextStyle(
            color: PulseColors.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    if (isLoading) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          color: PulseColors.primary,
          strokeWidth: 2,
        ),
      );
    }

    if (event.isAttending) {
      return TextButton.icon(
        onPressed: onLeave,
        icon: Icon(
          Icons.check_circle,
          size: 16,
          color: PulseColors.success,
        ),
        label: Text(
          'Going',
          style: TextStyle(
            color: PulseColors.success,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: TextButton.styleFrom(
          backgroundColor: PulseColors.success.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: onAttend,
      icon: const Icon(Icons.add, size: 16),
      label: const Text('Join'),
      style: ElevatedButton.styleFrom(
        backgroundColor: PulseColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 0,
      ),
    );
  }
}