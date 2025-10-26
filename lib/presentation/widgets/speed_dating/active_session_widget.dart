import 'package:flutter/material.dart';
import '../../theme/pulse_colors.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';

/// Widget to display active speed dating session
class ActiveSessionWidget extends StatelessWidget {
  final Map<String, dynamic> session;
  final VoidCallback onEnterRoom;
  final VoidCallback onLeaveSession;

  const ActiveSessionWidget({
    super.key,
    required this.session,
    required this.onEnterRoom,
    required this.onLeaveSession,
  });

  @override
  Widget build(BuildContext context) {
    final String eventTitle = session['eventTitle'] ?? 'Speed Dating Event';
    final String currentRound = session['currentRound']?.toString() ?? '1';
    final String totalRounds = session['totalRounds']?.toString() ?? '5';
    final String timeRemaining = session['timeRemaining'] ?? '3:00';
    final String currentPartner =
        session['currentPartner'] ?? 'Finding partner...';
    final bool isActive = session['isActive'] ?? false;
    final String sessionStatus = session['status'] ?? 'waiting';

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [PulseColors.primary, PulseColors.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Icon(
                  isActive ? Icons.live_tv : Icons.schedule,
                  color: context.onSurfaceColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eventTitle,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: context.onSurfaceColor,
                        ),
                      ),
                      Text(
                        _getStatusText(sessionStatus),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isActive ? 'LIVE' : 'WAITING',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: context.onSurfaceColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Session info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Round info
                  Row(
                    children: [
                      Icon(
                        Icons.rotate_right,
                        color: Colors.white.withValues(alpha: 0.8),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Round $currentRound of $totalRounds',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: context.onSurfaceColor,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: context.onSurfaceColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          timeRemaining,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: PulseColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Current partner
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: context.surfaceColor.withValues(
                          alpha: 0.2,
                        ),
                        child: Icon(
                          Icons.person,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Partner',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                            Text(
                              currentPartner,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: context.onSurfaceColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onLeaveSession,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: context.onSurfaceColor, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Leave Session',
                      style: TextStyle(
                        color: context.onSurfaceColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isActive ? onEnterRoom : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.surfaceColor,
                      foregroundColor: PulseColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isActive ? Icons.videocam : Icons.schedule,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isActive ? 'Enter Room' : 'Waiting...',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
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

  String _getStatusText(String status) {
    switch (status) {
      case 'waiting':
        return 'Waiting for event to start';
      case 'active':
        return 'Speed dating in progress';
      case 'break':
        return 'Break between rounds';
      case 'completed':
        return 'Session completed';
      default:
        return 'Unknown status';
    }
  }
}
