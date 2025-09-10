import 'package:flutter/material.dart';

import '../../../data/models/safety.dart';
import '../../theme/pulse_colors.dart';

/// Safety dashboard widget showing overview of safety features
class SafetyDashboardWidget extends StatelessWidget {
  final List<BlockedUser> blockedUsers;
  final List<SafetyTip> safetyTips;
  final List<SafetyReport> recentReports;
  final SafetySettings? settings;

  const SafetyDashboardWidget({
    super.key,
    required this.blockedUsers,
    required this.safetyTips,
    required this.recentReports,
    this.settings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Safety Overview',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  icon: Icons.block,
                  title: 'Blocked Users',
                  count: blockedUsers.length,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  icon: Icons.report,
                  title: 'Reports Made',
                  count: recentReports.length,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  icon: Icons.lightbulb,
                  title: 'Safety Tips',
                  count: safetyTips.length,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  icon: Icons.settings,
                  title: 'Settings',
                  count: _getActiveSettingsCount(),
                  color: Colors.green,
                ),
              ),
            ],
          ),
          if (settings != null) ...[
            const SizedBox(height: 16),
            _buildSettingsPreview(context),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Text(
                count.toString(),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsPreview(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PulseColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Active Settings',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildSettingIndicator(
                'Location Sharing',
                settings!.locationSharingEnabled,
              ),
              const SizedBox(width: 16),
              _buildSettingIndicator(
                'Emergency Contacts',
                settings!.emergencyContactsEnabled,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _buildSettingIndicator(
                'Check-in Reminders',
                settings!.checkInRemindersEnabled,
              ),
              const SizedBox(width: 16),
              _buildSettingIndicator(
                'Panic Button',
                settings!.panicButtonEnabled,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingIndicator(String label, bool isActive) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isActive ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isActive ? Colors.green : Colors.grey,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? Colors.green : Colors.grey,
          ),
        ),
      ],
    );
  }

  int _getActiveSettingsCount() {
    if (settings == null) return 0;
    
    int count = 0;
    if (settings!.locationSharingEnabled) count++;
    if (settings!.emergencyContactsEnabled) count++;
    if (settings!.checkInRemindersEnabled) count++;
    if (settings!.panicButtonEnabled) count++;
    
    return count;
  }
}
