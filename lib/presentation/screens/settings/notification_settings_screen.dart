import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/notification_preferences.dart';
import '../../blocs/notification/notification_bloc.dart';
import '../../widgets/common/pulse_toast.dart';
import '../../theme/pulse_colors.dart';

/// Screen for managing notification preferences
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationBloc>().add(LoadNotificationPreferences());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<NotificationBloc, NotificationState>(
      listener: (context, state) {
        if (state is NotificationError) {
          PulseToast.error(context, message: state.message);
        } else if (state is NotificationPreferencesUpdated) {
          PulseToast.success(
            context,
            message: 'Notification preferences updated',
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notification Settings'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: BlocBuilder<NotificationBloc, NotificationState>(
          builder: (context, state) {
            if (state is NotificationLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is NotificationError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: PulseColors.error,
                    ),
                    const SizedBox(height: 16),
                    Text(state.message),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<NotificationBloc>().add(
                        LoadNotificationPreferences(),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final preferences = state is NotificationPreferencesLoaded
                ? state.preferences
                : NotificationPreferences.defaults();

            return _buildPreferencesList(preferences);
          },
        ),
      ),
    );
  }

  Widget _buildPreferencesList(NotificationPreferences preferences) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('Match & Discovery'),
        _buildSwitchTile(
          title: 'New Matches',
          subtitle: 'Get notified when you have a new match',
          value: preferences.matchNotifications,
          onChanged: (value) => _updatePreference(
            preferences.copyWith({'matchNotifications': value}),
          ),
        ),
        _buildSwitchTile(
          title: 'New Messages',
          subtitle: 'Get notified when you receive a message',
          value: preferences.messageNotifications,
          onChanged: (value) => _updatePreference(
            preferences.copyWith({'messageNotifications': value}),
          ),
        ),
        _buildSwitchTile(
          title: 'Likes',
          subtitle: 'Get notified when someone likes you',
          value: preferences.likeNotifications,
          onChanged: (value) => _updatePreference(
            preferences.copyWith({'likeNotifications': value}),
          ),
        ),
        _buildSwitchTile(
          title: 'Super Likes',
          subtitle: 'Get notified when someone super likes you',
          value: preferences.superLikeNotifications,
          onChanged: (value) => _updatePreference(
            preferences.copyWith({'superLikeNotifications': value}),
          ),
        ),
        const Divider(height: 32),
        _buildSectionHeader('Events'),
        _buildSwitchTile(
          title: 'Event Updates',
          subtitle: 'Get notified about events you might like',
          value: preferences.eventNotifications,
          onChanged: (value) => _updatePreference(
            preferences.copyWith({'eventNotifications': value}),
          ),
        ),
        _buildSwitchTile(
          title: 'Event Reminders',
          subtitle: 'Get reminders for events you joined',
          value: preferences.eventReminders,
          onChanged: (value) => _updatePreference(
            preferences.copyWith({'eventReminders': value}),
          ),
        ),
        _buildSwitchTile(
          title: 'Speed Dating',
          subtitle: 'Get notified about speed dating sessions',
          value: preferences.speedDatingNotifications,
          onChanged: (value) => _updatePreference(
            preferences.copyWith({'speedDatingNotifications': value}),
          ),
        ),
        const Divider(height: 32),
        _buildSectionHeader('Premium & Promotions'),
        _buildSwitchTile(
          title: 'Premium Features',
          subtitle: 'Get notified about premium features',
          value: preferences.premiumNotifications,
          onChanged: (value) => _updatePreference(
            preferences.copyWith({'premiumNotifications': value}),
          ),
        ),
        _buildSwitchTile(
          title: 'Promotional Offers',
          subtitle: 'Receive special offers and promotions',
          value: preferences.promotionalNotifications,
          onChanged: (value) => _updatePreference(
            preferences.copyWith({'promotionalNotifications': value}),
          ),
        ),
        const Divider(height: 32),
        _buildSectionHeader('System & Security'),
        _buildSwitchTile(
          title: 'Security Alerts',
          subtitle: 'Get notified about security-related activity',
          value: preferences.securityAlerts,
          onChanged: (value) => _updatePreference(
            preferences.copyWith({'securityAlerts': value}),
          ),
        ),
        _buildSwitchTile(
          title: 'Account Activity',
          subtitle: 'Get notified about important account changes',
          value: preferences.accountActivity,
          onChanged: (value) => _updatePreference(
            preferences.copyWith({'accountActivity': value}),
          ),
        ),
        _buildSwitchTile(
          title: 'New Features',
          subtitle: 'Learn about new app features',
          value: preferences.newFeatures,
          onChanged: (value) =>
              _updatePreference(preferences.copyWith({'newFeatures': value})),
        ),
        _buildSwitchTile(
          title: 'Tips & Tricks',
          subtitle: 'Get helpful tips for using the app',
          value: preferences.tipsTricks,
          onChanged: (value) =>
              _updatePreference(preferences.copyWith({'tipsTricks': value})),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: PulseTextStyles.titleMedium.copyWith(
          fontWeight: FontWeight.bold,
          color: PulseColors.primary,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: PulseColors.surfaceVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: PulseTextStyles.titleSmall.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: PulseTextStyles.bodySmall.copyWith(
            color: PulseColors.onSurface.withValues(alpha: 0.7),
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeThumbColor: PulseColors.primary,
        activeTrackColor: PulseColors.primary.withValues(alpha: 0.5),
      ),
    );
  }

  void _updatePreference(NotificationPreferences preferences) {
    context.read<NotificationBloc>().add(
      UpdateNotificationPreferences(preferences),
    );
  }
}
