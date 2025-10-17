import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../theme/pulse_colors.dart';
import '../../blocs/notification/notification_bloc.dart';
import '../../../domain/entities/notification_preferences.dart';

/// Simplified notification settings screen matching the entity structure
class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Load preferences when screen opens
    context.read<NotificationBloc>().add(const LoadNotificationPreferences());

    return BlocListener<NotificationBloc, NotificationState>(
      listener: (context, state) {
        if (state is NotificationError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: PulseColors.error,
              duration: const Duration(seconds: 3),
            ),
          );
        } else if (state is NotificationPreferencesUpdated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notification preferences updated'),
              backgroundColor: PulseColors.success,
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Notification Settings',
            style: PulseTextStyles.titleLarge.copyWith(
              color: PulseColors.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: PulseColors.onSurface),
            onPressed: () => context.pop(),
          ),
        ),
        body: BlocBuilder<NotificationBloc, NotificationState>(
          builder: (context, state) {
            if (state is NotificationLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final preferences = state is NotificationPreferencesLoaded
                ? state.preferences
                : NotificationPreferences.defaults();

            return ListView(
              padding: const EdgeInsets.all(PulseSpacing.lg),
              children: [
                _buildSectionHeader('Matches & Discovery'),
                _buildNotificationTile(
                  context,
                  title: 'New Matches',
                  subtitle: 'Get notified when you have a new match',
                  icon: Icons.favorite,
                  value: preferences.matchNotifications,
                  onChanged: (value) => _updatePreference(
                    context,
                    {'matchNotifications': value},
                  ),
                ),
                _buildNotificationTile(
                  context,
                  title: 'New Messages',
                  subtitle: 'Get notified when you receive a message',
                  icon: Icons.message,
                  value: preferences.messageNotifications,
                  onChanged: (value) => _updatePreference(
                    context,
                    {'messageNotifications': value},
                  ),
                ),
                _buildNotificationTile(
                  context,
                  title: 'Likes',
                  subtitle: 'Get notified when someone likes you',
                  icon: Icons.thumb_up,
                  value: preferences.likeNotifications,
                  onChanged: (value) => _updatePreference(
                    context,
                    {'likeNotifications': value},
                  ),
                ),
                _buildNotificationTile(
                  context,
                  title: 'Super Likes',
                  subtitle: 'Get notified when someone super likes you',
                  icon: Icons.star,
                  value: preferences.superLikeNotifications,
                  onChanged: (value) => _updatePreference(
                    context,
                    {'superLikeNotifications': value},
                  ),
                ),
                const SizedBox(height: PulseSpacing.xl),
                _buildSectionHeader('Events'),
                _buildNotificationTile(
                  context,
                  title: 'Event Updates',
                  subtitle: 'Get notified about new events',
                  icon: Icons.event,
                  value: preferences.eventNotifications,
                  onChanged: (value) => _updatePreference(
                    context,
                    {'eventNotifications': value},
                  ),
                ),
                _buildNotificationTile(
                  context,
                  title: 'Event Reminders',
                  subtitle: 'Get reminded about upcoming events',
                  icon: Icons.alarm,
                  value: preferences.eventReminders,
                  onChanged: (value) => _updatePreference(
                    context,
                    {'eventReminders': value},
                  ),
                ),
                _buildNotificationTile(
                  context,
                  title: 'Speed Dating',
                  subtitle: 'Get notified about speed dating sessions',
                  icon: Icons.speed,
                  value: preferences.speedDatingNotifications,
                  onChanged: (value) => _updatePreference(
                    context,
                    {'speedDatingNotifications': value},
                  ),
                ),
                const SizedBox(height: PulseSpacing.xl),
                _buildSectionHeader('Premium & Promotions'),
                _buildNotificationTile(
                  context,
                  title: 'Premium Features',
                  subtitle: 'Get notified about premium features',
                  icon: Icons.workspace_premium,
                  value: preferences.premiumNotifications,
                  onChanged: (value) => _updatePreference(
                    context,
                    {'premiumNotifications': value},
                  ),
                ),
                _buildNotificationTile(
                  context,
                  title: 'Promotional Offers',
                  subtitle: 'Get notified about special offers and deals',
                  icon: Icons.local_offer,
                  value: preferences.promotionalNotifications,
                  onChanged: (value) => _updatePreference(
                    context,
                    {'promotionalNotifications': value},
                  ),
                ),
                const SizedBox(height: PulseSpacing.xl),
                _buildSectionHeader('System & Security'),
                _buildNotificationTile(
                  context,
                  title: 'Security Alerts',
                  subtitle: 'Get notified about important security updates',
                  icon: Icons.security,
                  value: preferences.securityAlerts,
                  onChanged: (value) => _updatePreference(
                    context,
                    {'securityAlerts': value},
                  ),
                ),
                _buildNotificationTile(
                  context,
                  title: 'Account Activity',
                  subtitle: 'Get notified about account changes',
                  icon: Icons.person,
                  value: preferences.accountActivity,
                  onChanged: (value) => _updatePreference(
                    context,
                    {'accountActivity': value},
                  ),
                ),
                _buildNotificationTile(
                  context,
                  title: 'New Features',
                  subtitle: 'Get notified about new app features',
                  icon: Icons.new_releases,
                  value: preferences.newFeatures,
                  onChanged: (value) => _updatePreference(
                    context,
                    {'newFeatures': value},
                  ),
                ),
                _buildNotificationTile(
                  context,
                  title: 'Tips & Tricks',
                  subtitle: 'Get helpful tips to improve your experience',
                  icon: Icons.lightbulb,
                  value: preferences.tipsTricks,
                  onChanged: (value) => _updatePreference(
                    context,
                    {'tipsTricks': value},
                  ),
                ),
                const SizedBox(height: PulseSpacing.xxl),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: PulseSpacing.md,
        top: PulseSpacing.sm,
      ),
      child: Text(
        title,
        style: PulseTextStyles.titleMedium.copyWith(
          color: PulseColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildNotificationTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: PulseSpacing.sm),
      child: SwitchListTile(
        title: Text(
          title,
          style: PulseTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: PulseTextStyles.bodySmall.copyWith(
            color: PulseColors.onSurface.withValues(alpha: 0.7),
          ),
        ),
        secondary: Icon(
          icon,
          color: PulseColors.primary,
        ),
        value: value,
        onChanged: onChanged,
        activeColor: PulseColors.primary,
      ),
    );
  }

  void _updatePreference(BuildContext context, Map<String, dynamic> updates) {
    // Get current preferences from BLoC state
    final currentState = context.read<NotificationBloc>().state;
    final currentPrefs = currentState is NotificationPreferencesLoaded
        ? currentState.preferences
        : NotificationPreferences.defaults();
    
    // Create updated preferences
    final updatedPrefs = currentPrefs.copyWith(updates);
    
    context.read<NotificationBloc>().add(UpdateNotificationPreferences(updatedPrefs));
  }
}
