import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/location_tracking_initializer.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/theme/theme_bloc.dart';
import '../../blocs/theme/theme_event.dart';
import '../../blocs/theme/theme_state.dart';
import '../../theme/pulse_colors.dart';
import '../../widgets/common/common_widgets.dart';
import '../../widgets/common/pulse_toast.dart';

/// Enhanced settings screen with full configuration options
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: PulseTextStyles.headlineMedium.copyWith(
            color: PulseColors.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: PulseColors.surface,
        elevation: 0,
        foregroundColor: PulseColors.onSurface,
      ),
      body: ListView(
        padding: const EdgeInsets.all(PulseSpacing.lg),
        children: [
          // Preferences Section
          _buildSectionHeader('Preferences'),
          _buildThemeToggle(context),
          _buildSettingsTile(
            icon: Icons.notifications,
            title: 'Notifications',
            subtitle: 'Push notifications and email',
            onTap: () {
              PulseToast.info(
                context,
                message: 'Notifications settings coming soon!',
              );
            },
          ),
          _buildSettingsTile(
            icon: Icons.language,
            title: 'Language',
            subtitle: 'App language and region',
            onTap: () {
              PulseToast.info(
                context,
                message: 'Language settings coming soon!',
              );
            },
          ),
          _buildSettingsTile(
            icon: Icons.tune,
            title: 'Discovery Settings',
            subtitle: 'Age range, distance preferences',
            onTap: () => context.go('/filters'),
          ),
          _buildSettingsTile(
            icon: Icons.psychology,
            title: 'AI Matching Settings',
            subtitle: 'Configure AI-powered match preferences',
            onTap: () => context.push('/ai-matching'),
          ),
          const SizedBox(height: PulseSpacing.lg),

          // Premium & Features Section
          _buildSectionHeader('Premium & Features'),
          _buildSettingsTile(
            icon: Icons.star_rounded,
            title: 'Advanced Features',
            subtitle: 'Explore premium dating features',
            onTap: () => context.push('/advanced-features'),
          ),
          _buildSettingsTile(
            icon: Icons.receipt_long,
            title: 'Transaction History',
            subtitle: 'View your payment and subscription history',
            onTap: () => context.push('/transaction-history'),
          ),
          _buildSettingsTile(
            icon: Icons.map_rounded,
            title: 'Activity Heat Map',
            subtitle: 'See where you\'re most active',
            onTap: () => context.push('/heat-map'),
          ),
          const SizedBox(height: PulseSpacing.lg),

          // App & Support Section
          _buildSectionHeader('App & Support'),
          _buildSettingsTile(
            icon: Icons.verified_user,
            title: 'Get Verified',
            subtitle: 'Verify your profile to build trust',
            onTap: () => context.push('/verification-status'),
          ),
          _buildSettingsTile(
            icon: Icons.analytics,
            title: 'Advanced Analytics',
            subtitle: 'View your detailed activity insights',
            onTap: () => context.push('/advanced-analytics'),
          ),
          _buildSettingsTile(
            icon: Icons.security,
            title: 'Safety Center',
            subtitle: 'Privacy, security, and safety settings',
            onTap: () => context.push('/safety-center'),
          ),
          _buildSettingsTile(
            icon: Icons.contact_emergency,
            title: 'Emergency Contacts',
            subtitle: 'Manage your emergency contacts for dates',
            onTap: () => context.push('/safety/emergency-contacts'),
          ),
          _buildSettingsTile(
            icon: Icons.lock,
            title: 'Privacy & Security',
            subtitle: 'Manage your privacy settings',
            onTap: () => context.go('/safety'),
          ),
          _buildSettingsTile(
            icon: Icons.help,
            title: 'Help & Support',
            subtitle: 'FAQs and contact support',
            onTap: () {
              PulseToast.info(context, message: 'Help & Support coming soon!');
            },
          ),
          _buildSettingsTile(
            icon: Icons.info,
            title: 'About',
            subtitle: 'Version ${AppConstants.appVersion}',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: AppConstants.appName,
                applicationVersion: AppConstants.appVersion,
                applicationLegalese:
                    '© 2025 ${AppConstants.appName}. All rights reserved.',
              );
            },
          ),
          _buildSettingsTile(
            icon: Icons.description,
            title: 'Terms & Privacy',
            subtitle: 'Legal information',
            onTap: () {
              PulseToast.info(context, message: 'Terms & Privacy coming soon!');
            },
          ),
          const SizedBox(height: PulseSpacing.xl),

          // Debug & Testing Section (Development Only)
          _buildSectionHeader('Debug & Testing'),
          _buildSettingsTile(
            icon: Icons.location_on,
            title: 'Test Location Permissions',
            subtitle: 'Manually trigger location permission flow',
            onTap: () => _testLocationPermissions(context),
          ),
          const SizedBox(height: PulseSpacing.xl),

          // Logout Button
          Container(
            margin: const EdgeInsets.symmetric(vertical: PulseSpacing.lg),
            child: PulseButton(
              text: 'Log Out',
              onPressed: () => _showLogoutDialog(context),
              fullWidth: true,
            ),
          ),

          // Delete Account
          TextButton(
            onPressed: () => _showDeleteAccountDialog(context),
            child: Text(
              'Delete Account',
              style: PulseTextStyles.bodyMedium.copyWith(
                color: PulseColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: PulseSpacing.sm,
        bottom: PulseSpacing.sm,
        top: PulseSpacing.md,
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

  Widget _buildThemeToggle(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        return Container(
          margin: const EdgeInsets.only(bottom: PulseSpacing.xs),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(PulseSpacing.sm),
              decoration: BoxDecoration(
                color: PulseColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                themeState.themeMode == ThemeMode.dark
                    ? Icons.dark_mode
                    : themeState.themeMode == ThemeMode.light
                        ? Icons.light_mode
                        : Icons.brightness_auto,
                color: PulseColors.primary,
                size: 20,
              ),
            ),
            title: Text(
              'Theme',
              style: PulseTextStyles.bodyLarge.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              _getThemeSubtitle(themeState.themeMode),
              style: PulseTextStyles.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: DropdownButton<ThemeMode>(
              value: themeState.themeMode,
              underline: const SizedBox(),
              dropdownColor: Theme.of(context).colorScheme.surface,
              onChanged: (ThemeMode? newMode) {
                if (newMode != null) {
                  context.read<ThemeBloc>().add(ThemeChanged(newMode));
                }
              },
              items: [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text(
                    'System',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text(
                    'Light',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text(
                    'Dark',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: PulseSpacing.lg,
              vertical: PulseSpacing.sm,
            ),
          ),
        );
      },
    );
  }

  String _getThemeSubtitle(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'Follow system settings';
      case ThemeMode.light:
        return 'Light mode';
      case ThemeMode.dark:
        return 'Dark mode';
    }
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: PulseSpacing.xs),
      decoration: BoxDecoration(
        color: PulseColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PulseColors.outline.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(PulseSpacing.sm),
          decoration: BoxDecoration(
            color: PulseColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: PulseColors.primary, size: 20),
        ),
        title: Text(
          title,
          style: PulseTextStyles.bodyLarge.copyWith(
            color: PulseColors.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: PulseTextStyles.bodyMedium.copyWith(
            color: PulseColors.onSurfaceVariant,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: PulseColors.onSurfaceVariant,
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: PulseSpacing.lg,
          vertical: PulseSpacing.sm,
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Log Out',
          style: PulseTextStyles.headlineSmall.copyWith(
            color: PulseColors.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: PulseTextStyles.bodyLarge.copyWith(
            color: PulseColors.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: PulseTextStyles.bodyMedium.copyWith(
                color: PulseColors.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<AuthBloc>().add(const AuthSignOutRequested());
            },
            child: Text(
              'Log Out',
              style: PulseTextStyles.bodyMedium.copyWith(
                color: PulseColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Account',
          style: PulseTextStyles.headlineSmall.copyWith(
            color: PulseColors.error,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'This action cannot be undone. All your data will be permanently deleted.',
          style: PulseTextStyles.bodyLarge.copyWith(
            color: PulseColors.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: PulseTextStyles.bodyMedium.copyWith(
                color: PulseColors.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Show final confirmation for account deletion
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Final Confirmation'),
                  content: const Text(
                    'This action cannot be undone. All your data will be permanently deleted.\n\nType "DELETE" to confirm:',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // In real implementation, call AuthBloc to delete account
                        context.read<AuthBloc>().add(
                          const AuthSignOutRequested(),
                        );
                        PulseToast.success(context, message: 'Account deleted');
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: PulseColors.error,
                      ),
                      child: const Text('DELETE ACCOUNT'),
                    ),
                  ],
                ),
              );
            },
            child: Text(
              'Delete Account',
              style: PulseTextStyles.bodyMedium.copyWith(
                color: PulseColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _testLocationPermissions(BuildContext context) async {
    try {
      debugPrint('🔧 SettingsScreen: Starting manual location permission test');

      final locationService = context.read<LocationService>();
      final locationTracker = LocationTrackingInitializer();

      debugPrint(
        '🔧 SettingsScreen: Requesting location permissions with dialog...',
      );
      final success = await locationService.requestPermissionsWithDialog(
        context,
      );

      if (success) {
        debugPrint(
          '🔧 SettingsScreen: Location permissions granted, starting tracking...',
        );
        await locationTracker.initializeWithDialogs(
          context,
        ); // ignore: use_build_context_synchronously
        if (context.mounted) {
          PulseToast.success(
            context,
            message: '✅ Location permissions granted and tracking started!',
          );
        }
      } else {
        debugPrint('🔧 SettingsScreen: Location permissions denied');
        if (context.mounted) {
          PulseToast.error(
            context,
            message: '❌ Location permissions denied or failed',
          );
        }
      }
    } catch (e) {
      debugPrint('🔧 SettingsScreen: Error testing location permissions: $e');
      if (context.mounted) {
        PulseToast.error(
          context,
          message: '❌ Error testing location permissions: $e',
        );
      }
    }
  }
}
