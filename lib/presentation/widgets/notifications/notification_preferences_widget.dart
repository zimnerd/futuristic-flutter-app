import 'package:flutter/material.dart';
import '../../theme/pulse_colors.dart';
import '../common/pulse_toast.dart';

/// Notification preferences and settings widget
class NotificationPreferencesWidget extends StatefulWidget {
  const NotificationPreferencesWidget({super.key, this.onPreferencesChanged});

  final Function(Map<String, bool>)? onPreferencesChanged;

  @override
  State<NotificationPreferencesWidget> createState() =>
      _NotificationPreferencesWidgetState();
}

class _NotificationPreferencesWidgetState
    extends State<NotificationPreferencesWidget> {
  Map<String, bool> _preferences = {
    'new_matches': true,
    'new_messages': true,
    'super_likes': true,
    'profile_views': false,
    'promotions': false,
    'push_notifications': true,
    'email_notifications': true,
    'quiet_hours': false,
  };

  final Map<String, NotificationCategory> _categories = {
    'Dating Activity': NotificationCategory(
      title: 'Dating Activity',
      description: 'Get notified about your dating activity',
      icon: Icons.favorite,
      color: Colors.red,
      items: [
        NotificationItem(
          key: 'new_matches',
          title: 'New Matches',
          description: 'When someone matches with you',
        ),
        NotificationItem(
          key: 'new_messages',
          title: 'New Messages',
          description: 'When you receive a new message',
        ),
        NotificationItem(
          key: 'super_likes',
          title: 'Super Likes',
          description: 'When someone super likes you',
        ),
        NotificationItem(
          key: 'profile_views',
          title: 'Profile Views',
          description: 'When someone views your profile',
        ),
      ],
    ),
    'App Updates': NotificationCategory(
      title: 'App Updates',
      description: 'Stay updated with app features and promotions',
      icon: Icons.notifications,
      color: Colors.blue,
      items: [
        NotificationItem(
          key: 'promotions',
          title: 'Promotions & Offers',
          description: 'Special deals and premium offers',
        ),
      ],
    ),
    'Delivery Methods': NotificationCategory(
      title: 'Delivery Methods',
      description: 'How you receive notifications',
      icon: Icons.settings,
      color: Colors.grey,
      items: [
        NotificationItem(
          key: 'push_notifications',
          title: 'Push Notifications',
          description: 'Receive notifications on your device',
        ),
        NotificationItem(
          key: 'email_notifications',
          title: 'Email Notifications',
          description: 'Receive notifications via email',
        ),
      ],
    ),
    'Advanced': NotificationCategory(
      title: 'Advanced Settings',
      description: 'Fine-tune your notification experience',
      icon: Icons.tune,
      color: PulseColors.primary,
      items: [
        NotificationItem(
          key: 'quiet_hours',
          title: 'Quiet Hours (10 PM - 8 AM)',
          description: 'Disable notifications during quiet hours',
        ),
      ],
    ),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: PulseColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications,
                    color: PulseColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notification Preferences',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Customize how you stay connected',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Notification categories
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _categories.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final categoryName = _categories.keys.elementAt(index);
              final category = _categories[categoryName]!;
              return _buildNotificationCategory(category);
            },
          ),

          // Quick actions
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildQuickAction(
                    icon: Icons.volume_off,
                    label: 'Mute All',
                    onTap: _muteAll,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildQuickAction(
                    icon: Icons.volume_up,
                    label: 'Enable All',
                    onTap: _enableAll,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildQuickAction(
                    icon: Icons.refresh,
                    label: 'Reset',
                    onTap: _resetToDefaults,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCategory(NotificationCategory category) {
    return ExpansionTile(
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: category.color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(category.icon, color: category.color, size: 16),
      ),
      title: Text(
        category.title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        category.description,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      children: category.items
          .map((item) => _buildNotificationItem(item))
          .toList(),
    );
  }

  Widget _buildNotificationItem(NotificationItem item) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
      child: Row(
        children: [
          const SizedBox(width: 48), // Align with category icon
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  item.description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _preferences[item.key] ?? false,
            onChanged: (value) => _updatePreference(item.key, value),
            activeTrackColor: PulseColors.primary,
            activeThumbColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.grey[600], size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updatePreference(String key, bool value) {
    setState(() {
      _preferences[key] = value;
    });

    widget.onPreferencesChanged?.call(_preferences);

    // Show feedback
    if (mounted) {
      PulseToast.info(
        context,
        message: value ? 'Notifications enabled' : 'Notifications disabled',
      );
    }
  }

  void _muteAll() {
    setState(() {
      _preferences = _preferences.map((key, value) => MapEntry(key, false));
    });
    widget.onPreferencesChanged?.call(_preferences);

    if (mounted) {
      PulseToast.info(context, message: 'All notifications muted');
    }
  }

  void _enableAll() {
    setState(() {
      _preferences = _preferences.map((key, value) => MapEntry(key, true));
    });
    widget.onPreferencesChanged?.call(_preferences);

    if (mounted) {
      PulseToast.success(context, message: 'All notifications enabled');
    }
  }

  void _resetToDefaults() {
    setState(() {
      _preferences = {
        'new_matches': true,
        'new_messages': true,
        'super_likes': true,
        'profile_views': false,
        'promotions': false,
        'push_notifications': true,
        'email_notifications': true,
        'quiet_hours': false,
      };
    });
    widget.onPreferencesChanged?.call(_preferences);

    if (mounted) {
      PulseToast.success(context, message: 'Preferences reset to defaults');
    }
  }
}

class NotificationCategory {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<NotificationItem> items;

  NotificationCategory({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.items,
  });
}

class NotificationItem {
  final String key;
  final String title;
  final String description;

  NotificationItem({
    required this.key,
    required this.title,
    required this.description,
  });
}
