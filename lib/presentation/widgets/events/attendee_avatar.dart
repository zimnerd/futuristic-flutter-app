import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../domain/entities/event.dart';
import '../../../core/constants/app_constants.dart';
import '../../theme/pulse_colors.dart';

class AttendeeAvatar extends StatelessWidget {
  final EventAttendance attendance;
  final double size;
  final VoidCallback? onTap;

  const AttendeeAvatar({
    super.key,
    required this.attendance,
    this.size = 32,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final user = attendance.user;
    final profileImageUrl = user?['profileImages']?.isNotEmpty == true 
        ? user!['profileImages'][0]['url'] 
        : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: _getStatusColor(),
            width: 2,
          ),
        ),
        child: ClipOval(
          child: profileImageUrl != null
              ? CachedNetworkImage(
                  imageUrl: profileImageUrl.startsWith('http') 
                      ? profileImageUrl 
                      : '${AppConstants.baseUrl}/$profileImageUrl',
                  fit: BoxFit.cover,
                  placeholder: (context, url) => _buildPlaceholder(),
                  errorWidget: (context, url, error) => _buildPlaceholder(),
                )
              : _buildPlaceholder(),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    final user = attendance.user;
    final initials = _getInitials(user?['firstName'], user?['lastName']);
    
    return Container(
      color: PulseColors.primary.withOpacity(0.1),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: PulseColors.primary,
            fontSize: size * 0.4,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String _getInitials(String? firstName, String? lastName) {
    final first = firstName?.isNotEmpty == true ? firstName![0].toUpperCase() : '';
    final last = lastName?.isNotEmpty == true ? lastName![0].toUpperCase() : '';
    return first + last;
  }

  Color _getStatusColor() {
    switch (attendance.status) {
      case 'attending':
        return PulseColors.success;
      case 'interested':
        return PulseColors.secondary;
      default:
        return PulseColors.outline;
    }
  }
}

class AttendeeList extends StatelessWidget {
  final List<EventAttendance> attendees;
  final int maxVisible;
  final VoidCallback? onSeeAll;

  const AttendeeList({
    super.key,
    required this.attendees,
    this.maxVisible = 5,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final visibleAttendees = attendees.take(maxVisible).toList();
    final remainingCount = attendees.length - visibleAttendees.length;

    return Row(
      children: [
        // Avatar stack
        SizedBox(
          height: 32,
          child: Stack(
            children: [
              ...visibleAttendees.asMap().entries.map((entry) {
                final index = entry.key;
                final attendance = entry.value;
                
                return Positioned(
                  left: index * 24.0, // Overlap avatars
                  child: AttendeeAvatar(
                    attendance: attendance,
                    size: 32,
                  ),
                );
              }),
              // Show remaining count if there are more
              if (remainingCount > 0)
                Positioned(
                  left: visibleAttendees.length * 24.0,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: PulseColors.primary,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '+$remainingCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Attendee count and see all button
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${attendees.length} ${attendees.length == 1 ? 'person' : 'people'} attending',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: PulseColors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (onSeeAll != null && attendees.length > maxVisible)
                GestureDetector(
                  onTap: onSeeAll,
                  child: Text(
                    'See all',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: PulseColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class AttendeeGrid extends StatelessWidget {
  final List<EventAttendance> attendees;
  final Function(EventAttendance)? onAttendeeTap;

  const AttendeeGrid({
    super.key,
    required this.attendees,
    this.onAttendeeTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: attendees.length,
      itemBuilder: (context, index) {
        final attendance = attendees[index];
        final user = attendance.user;
        
        return GestureDetector(
          onTap: () => onAttendeeTap?.call(attendance),
          child: Column(
            children: [
              AttendeeAvatar(
                attendance: attendance,
                size: 48,
              ),
              const SizedBox(height: 8),
              Text(
                user?['firstName'] ?? 'Unknown',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                attendance.status == 'attending' ? 'Going' : 'Interested',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: attendance.status == 'attending' 
                      ? PulseColors.success 
                      : PulseColors.secondary,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}