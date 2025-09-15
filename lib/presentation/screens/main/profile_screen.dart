import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../navigation/app_router.dart';
import '../../theme/pulse_colors.dart';
import '../../widgets/common/common_widgets.dart';

/// Enhanced profile screen with user settings
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              _buildHeader(context),

              // Profile info
              _buildProfileInfo(),

              // Settings sections
              _buildSettingsSection(),

              // Support section
              _buildSupportSection(),

              // Logout
              _buildLogoutSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(PulseSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, PulseColors.primary.withValues(alpha: 0.02)],
        ),
      ),
      child: Row(
        children: [
          Text(
            'Profile',
            style: PulseTextStyles.headlineLarge.copyWith(
              color: PulseColors.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          // Quick signout button
          Container(
            margin: const EdgeInsets.only(right: PulseSpacing.sm),
            child: IconButton(
              onPressed: () => _showLogoutDialog(context),
              icon: const Icon(Icons.logout, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: PulseColors.error.withValues(alpha: 0.1),
                foregroundColor: PulseColors.error,
                padding: const EdgeInsets.all(8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(PulseRadii.sm),
                ),
              ),
              tooltip: 'Quick Sign Out',
            ),
          ),
          // Edit profile button
          IconButton(
            onPressed: () {
              context.go('/profile-creation');
            },
            icon: const Icon(Icons.edit),
            style: IconButton.styleFrom(
              backgroundColor: PulseColors.primary.withValues(alpha: 0.1),
              foregroundColor: PulseColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(PulseRadii.sm),
              ),
            ),
            tooltip: 'Edit Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo() {
    return Container(
      margin: const EdgeInsets.all(PulseSpacing.lg),
      padding: const EdgeInsets.all(PulseSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, PulseColors.primary.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(PulseRadii.xl),
        boxShadow: [
          BoxShadow(
            color: PulseColors.primary.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar with improved design
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [PulseColors.primary, PulseColors.secondary],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: PulseColors.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.person, size: 64, color: Colors.white),
          ),
          const SizedBox(height: PulseSpacing.lg),

          // Name and info with better colors
          Text(
            'John Doe',
            style: PulseTextStyles.headlineMedium.copyWith(
              color: PulseColors.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: PulseSpacing.sm),
          Text(
            '25 years old • 2.5 km away',
            style: PulseTextStyles.bodyLarge.copyWith(
              color: PulseColors.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: PulseSpacing.xl),

          // Enhanced stats with better visual hierarchy
          Container(
            padding: const EdgeInsets.all(PulseSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(PulseRadii.lg),
              border: Border.all(
                color: PulseColors.primary.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatItem(
                  value: '127',
                  label: 'Matches',
                  color: PulseColors.primary,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: PulseColors.primary.withValues(alpha: 0.1),
                ),
                _StatItem(
                  value: '89',
                  label: 'Likes',
                  color: PulseColors.success,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: PulseColors.primary.withValues(alpha: 0.1),
                ),
                _StatItem(
                  value: '23',
                  label: 'Visits',
                  color: PulseColors.secondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Padding(
      padding: const EdgeInsets.all(PulseSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: PulseTextStyles.headlineSmall.copyWith(
              color: PulseColors.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: PulseSpacing.md),

          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.person_outline,
                title: 'Edit Profile',
                subtitle: 'Update your photos and info',
                onTap: (context) {
                  context.go('/profile-creation');
                },
              ),
              _SettingsTile(
                icon: Icons.notifications,
                title: 'Notifications',
                subtitle: 'Manage your notification preferences',
                onTap: (context) {
                  context.go('/settings');
                },
              ),
              _SettingsTile(
                icon: Icons.location_on,
                title: 'Location',
                subtitle: 'Update your location settings',
                onTap: (context) {
                  context.go('/settings');
                },
              ),
              _SettingsTile(
                icon: Icons.security,
                title: 'Privacy & Security',
                subtitle: 'Control your privacy settings',
                onTap: (context) {
                  context.go('/safety');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection() {
    return Padding(
      padding: const EdgeInsets.all(PulseSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Support',
            style: PulseTextStyles.headlineSmall.copyWith(
              color: PulseColors.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: PulseSpacing.md),

          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.help_outline,
                title: 'Help Center',
                subtitle: 'Get help and support',
                onTap: (context) {
                  // Navigate to help center - placeholder for now
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Help Center coming soon!')),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.feedback_outlined,
                title: 'Feedback',
                subtitle: 'Share your thoughts with us',
                onTap: (context) {
                  // Navigate to feedback - placeholder for now
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Feedback form coming soon!')),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.info_outline,
                title: 'About',
                subtitle: 'App version and info',
                onTap: (context) {
                  showAboutDialog(
                    context: context,
                    applicationName: 'PulseLink',
                    applicationVersion: '1.0.0',
                    applicationIcon: const FlutterLogo(size: 64),
                    children: const [
                      Text('A modern dating app connecting hearts worldwide.'),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(PulseSpacing.lg),
      child: _SettingsCard(
        children: [
          _SettingsTile(
            icon: Icons.logout,
            title: 'Sign Out',
            subtitle: 'Sign out of your account',
            textColor: PulseColors.error,
            onTap: (context) => _showLogoutDialog(context),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          PulseButton(
            text: 'Sign Out',
            onPressed: () {
              Navigator.of(context).pop();
              context.read<AuthBloc>().add(const AuthSignOutRequested());
              context.go(AppRoutes.welcome);
            },
            variant: PulseButtonVariant.secondary,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: PulseTextStyles.headlineMedium.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: PulseSpacing.xs),
        Text(
          label,
          style: PulseTextStyles.bodyMedium.copyWith(
            color: PulseColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PulseColors.surface,
        borderRadius: BorderRadius.circular(PulseRadii.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.textColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final void Function(BuildContext) onTap;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap(context),
        borderRadius: BorderRadius.circular(PulseRadii.lg),
        child: Padding(
          padding: const EdgeInsets.all(PulseSpacing.lg),
          child: Row(
            children: [
              Icon(icon, color: textColor ?? PulseColors.primary, size: 24),
              const SizedBox(width: PulseSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: PulseTextStyles.bodyLarge.copyWith(
                        color: textColor ?? PulseColors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: PulseSpacing.xs),
                    Text(
                      subtitle,
                      style: PulseTextStyles.bodyMedium.copyWith(
                        color: PulseColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: PulseColors.onSurfaceVariant,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
