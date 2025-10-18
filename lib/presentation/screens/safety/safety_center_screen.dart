import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/pulse_colors.dart' hide PulseTextStyles;
import '../../theme/pulse_theme.dart';
import '../../widgets/common/pulse_toast.dart';

/// Main Safety Center screen with links to all safety features
class SafetyCenterScreen extends StatelessWidget {
  const SafetyCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Safety Center'),
        backgroundColor: PulseColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header section
          _buildHeaderCard(),
          const SizedBox(height: 24),

          // Safety sections
          _buildSectionTitle('Privacy & Security'),
          const SizedBox(height: 12),
          _buildOptionCard(
            context,
            icon: Icons.lock_outline,
            title: 'Privacy Settings',
            subtitle: 'Control who can see your profile and contact you',
            onTap: () => context.push('/privacy-settings'),
            color: PulseColors.primary,
          ),
          const SizedBox(height: 12),
          _buildOptionCard(
            context,
            icon: Icons.shield_outlined,
            title: 'Account Security',
            subtitle: 'Manage your password and security options',
            onTap: () {
              // Navigate to account security (can be implemented later)
              PulseToast.info(
                context,
                message: 'Account Security coming soon',
              );
            },
            color: Colors.blue,
          ),
          const SizedBox(height: 24),

          _buildSectionTitle('Safety Tools'),
          const SizedBox(height: 12),
          _buildOptionCard(
            context,
            icon: Icons.block,
            title: 'Blocked Users',
            subtitle: 'Manage your blocked users list',
            onTap: () => context.push('/blocked-users'),
            color: Colors.red,
          ),
          const SizedBox(height: 12),
          _buildOptionCard(
            context,
            icon: Icons.history,
            title: 'Report History',
            subtitle: 'View your submitted reports',
            onTap: () => context.push('/report-history'),
            color: Colors.orange,
          ),
          const SizedBox(height: 24),

          _buildSectionTitle('Resources'),
          const SizedBox(height: 12),
          _buildOptionCard(
            context,
            icon: Icons.tips_and_updates_outlined,
            title: 'Safety Tips',
            subtitle: 'Learn how to stay safe on PulseLink',
            onTap: () => context.push('/safety-tips'),
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _buildOptionCard(
            context,
            icon: Icons.help_outline,
            title: 'Safety Guidelines',
            subtitle: 'Read our community guidelines',
            onTap: () {
              // Navigate to guidelines (can be implemented later)
              PulseToast.info(
                context,
                message: 'Safety Guidelines coming soon',
              );
            },
            color: PulseColors.secondary,
          ),
          const SizedBox(height: 24),

          // Emergency contact
          _buildEmergencyCard(context),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 0,
      color: PulseColors.primary.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: PulseColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: PulseColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.verified_user,
                size: 32,
                color: PulseColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Safety Matters',
                    style: PulseTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: PulseColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'We\'re committed to keeping you safe',
                    style: PulseTextStyles.bodyMedium.copyWith(
                      color: PulseColors.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: PulseTextStyles.titleSmall.copyWith(
        fontWeight: FontWeight.bold,
        color: PulseColors.onSurface,
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: PulseColors.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: PulseTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: PulseTextStyles.bodySmall.copyWith(
                        color: PulseColors.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: PulseColors.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyCard(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.red.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.red.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.emergency,
              size: 32,
              color: Colors.red.shade700,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Emergency?',
                    style: PulseTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'If you\'re in immediate danger, contact local emergency services',
                    style: PulseTextStyles.bodySmall.copyWith(
                      color: Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
