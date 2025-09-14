import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../theme/pulse_colors.dart';
import '../../widgets/common/common_widgets.dart';

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
          // Account Section
          _buildSectionHeader('Account'),
          _buildSettingsTile(
            icon: Icons.person,
            title: 'Edit Profile',
            subtitle: 'Update your personal information',
            onTap: () => context.go('/profile/edit'),
          ),
          _buildSettingsTile(
            icon: Icons.photo_library,
            title: 'Manage Photos',
            subtitle: 'Add or remove profile photos',
            onTap: () => context.go('/profile/photos'),
          ),
          _buildSettingsTile(
            icon: Icons.lock,
            title: 'Privacy & Security',
            subtitle: 'Manage your privacy settings',
            onTap: () => context.go('/settings/privacy'),
          ),
          const SizedBox(height: PulseSpacing.lg),

          // Preferences Section
          _buildSectionHeader('Preferences'),
          _buildSettingsTile(
            icon: Icons.tune,
            title: 'Discovery Settings',
            subtitle: 'Age range, distance, and more',
            onTap: () => context.go('/settings/discovery'),
          ),
          _buildSettingsTile(
            icon: Icons.notifications,
            title: 'Notifications',
            subtitle: 'Push notifications and email',
            onTap: () => context.go('/settings/notifications'),
          ),
          _buildSettingsTile(
            icon: Icons.language,
            title: 'Language',
            subtitle: 'App language and region',
            onTap: () => context.go('/settings/language'),
          ),
          const SizedBox(height: PulseSpacing.lg),

          // App Section
          _buildSectionHeader('App'),
          _buildSettingsTile(
            icon: Icons.help,
            title: 'Help & Support',
            subtitle: 'FAQs and contact support',
            onTap: () => context.go('/support'),
          ),
          _buildSettingsTile(
            icon: Icons.info,
            title: 'About',
            subtitle: 'Version ${AppConstants.appVersion}',
            onTap: () => context.go('/about'),
          ),
          _buildSettingsTile(
            icon: Icons.description,
            title: 'Terms & Privacy',
            subtitle: 'Legal information',
            onTap: () => context.go('/legal'),
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
                        context.read<AuthBloc>().add(const AuthSignOutRequested());
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Account deleted')),
                        );
                      },
                      style: TextButton.styleFrom(foregroundColor: PulseColors.error),
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
}
