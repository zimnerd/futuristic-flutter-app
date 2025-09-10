import 'package:flutter/material.dart';
import '../../theme/pulse_colors.dart';

/// Widget to display speed dating event information
class SpeedDatingEventCard extends StatelessWidget {
  final Map<String, dynamic> event;
  final VoidCallback onJoin;
  final VoidCallback onViewDetails;

  const SpeedDatingEventCard({
    super.key,
    required this.event,
    required this.onJoin,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final String title = event['title'] ?? 'Speed Dating Event';
    final String location = event['location'] ?? 'Virtual';
    final String date = event['date'] ?? 'TBD';
    final String time = event['time'] ?? 'TBD';
    final int participantCount = event['participantCount'] ?? 0;
    final int maxParticipants = event['maxParticipants'] ?? 20;
    final String ageRange = event['ageRange'] ?? '18-35';
    final bool isJoined = event['isJoined'] ?? false;
    final bool isFull = participantCount >= maxParticipants;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              PulseColors.primary.withValues(alpha: 0.1),
              PulseColors.secondary.withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and status
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(event['status']).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(event['status']),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(event['status']),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Event details
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    icon: Icons.location_on,
                    label: 'Location',
                    value: location,
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    icon: Icons.calendar_today,
                    label: 'Date',
                    value: date,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    icon: Icons.access_time,
                    label: 'Time',
                    value: time,
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    icon: Icons.people,
                    label: 'Age Range',
                    value: ageRange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Participants progress
            Row(
              children: [
                Icon(
                  Icons.group,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  'Participants: $participantCount/$maxParticipants',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                Text(
                  '${((participantCount / maxParticipants) * 100).round()}% Full',
                  style: TextStyle(
                    fontSize: 12,
                    color: isFull ? Colors.red : Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Progress bar
            LinearProgressIndicator(
              value: participantCount / maxParticipants,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                isFull ? Colors.red : PulseColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onViewDetails,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: PulseColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('View Details'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: (isFull && !isJoined) ? null : onJoin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isJoined 
                        ? Colors.green 
                        : PulseColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      isJoined 
                        ? 'Joined' 
                        : isFull 
                          ? 'Full' 
                          : 'Join Event',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: PulseColors.primary,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'upcoming':
        return Colors.blue;
      case 'live':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return PulseColors.primary;
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'upcoming':
        return 'Upcoming';
      case 'live':
        return 'Live';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Open';
    }
  }
}
