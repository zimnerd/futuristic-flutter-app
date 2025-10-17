import 'package:flutter/material.dart';
import '../../theme/pulse_colors.dart';

/// Reusable empty state widget for consistent UX across the app
/// Displays icon, title, message, and optional action button
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;
  final double iconSize;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.iconColor,
    this.iconSize = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: iconSize + 40,
              height: iconSize + 40,
              decoration: BoxDecoration(
                color: (iconColor ?? PulseColors.primary).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: iconSize,
                color: iconColor ?? PulseColors.primary,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              title,
              style: PulseTextStyles.headlineSmall.copyWith(
                color: PulseColors.onSurface,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Message
            Text(
              message,
              style: PulseTextStyles.bodyLarge.copyWith(
                color: PulseColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            // Action Button
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: PulseColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(PulseRadii.lg),
                  ),
                ),
                child: Text(
                  actionLabel!,
                  style: PulseTextStyles.labelLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Predefined empty states for common scenarios
class EmptyStates {
  // Messages
  static Widget noMessages({VoidCallback? onExplore}) => EmptyStateWidget(
        icon: Icons.chat_bubble_outline,
        title: 'No Messages Yet',
        message:
            'Start a conversation with your matches.\nYour messages will appear here.',
        actionLabel: 'Explore Matches',
        onAction: onExplore,
      );

  // Matches
  static Widget noMatches({VoidCallback? onDiscover}) => EmptyStateWidget(
        icon: Icons.favorite_border,
        title: 'No Matches Yet',
        message:
            'Keep swiping to find your perfect match!\nYour mutual likes will appear here.',
        actionLabel: 'Start Swiping',
        onAction: onDiscover,
        iconColor: const Color(0xFFFF6B9D),
      );

  // Discovery
  static Widget noMoreProfiles({VoidCallback? onAdjustFilters}) =>
      EmptyStateWidget(
        icon: Icons.explore_off,
        title: 'No More Profiles',
        message:
            'You\'ve seen everyone nearby.\nTry adjusting your filters or check back later!',
        actionLabel: 'Adjust Filters',
        onAction: onAdjustFilters,
        iconColor: const Color(0xFF9C27B0),
      );

  // Events
  static Widget noEvents({VoidCallback? onCreate}) => EmptyStateWidget(
        icon: Icons.event_busy,
        title: 'No Events Found',
        message:
            'No events match your criteria.\nBe the first to create an event!',
        actionLabel: 'Create Event',
        onAction: onCreate,
        iconColor: const Color(0xFFFFA726),
      );

  // Search Results
  static Widget noSearchResults({required String query}) => EmptyStateWidget(
        icon: Icons.search_off,
        title: 'No Results Found',
        message: 'We couldn\'t find anything matching "$query".\nTry different keywords.',
        iconColor: Colors.grey,
      );

  // Blocked Users
  static Widget noBlockedUsers() => EmptyStateWidget(
        icon: Icons.block,
        title: 'No Blocked Users',
        message: 'You haven\'t blocked anyone yet.\nBlocked users will appear here.',
        iconColor: Colors.red,
      );

  // Statistics
  static Widget noStats() => EmptyStateWidget(
        icon: Icons.bar_chart,
        title: 'No Statistics Yet',
        message:
            'Start interacting with others to see your stats.\nYour activity will be tracked here.',
        iconColor: const Color(0xFF4ECDC4),
      );

  // Call History
  static Widget noCallHistory({VoidCallback? onStartCall}) => EmptyStateWidget(
        icon: Icons.phone_disabled,
        title: 'No Call History',
        message: 'You haven\'t made or received any calls yet.\nStart a call with your matches!',
        actionLabel: 'View Matches',
        onAction: onStartCall,
        iconColor: const Color(0xFF66BB6A),
      );

  // Notifications
  static Widget noNotifications() => EmptyStateWidget(
        icon: Icons.notifications_off,
        title: 'No Notifications',
        message: 'You\'re all caught up!\nNew notifications will appear here.',
        iconColor: const Color(0xFF7E57C2),
      );

  // Favorites/Likes
  static Widget noLikes() => EmptyStateWidget(
        icon: Icons.favorite_border,
        title: 'No Likes Yet',
        message: 'Keep swiping right on profiles you like!\nYour likes will be saved here.',
        iconColor: const Color(0xFFFF6B9D),
      );
}
