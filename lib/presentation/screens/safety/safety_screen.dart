import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/safety.dart';
import '../../blocs/safety/safety_bloc.dart';
import '../../theme/pulse_colors.dart';
import '../../widgets/common/pulse_loading.dart';
import '../../widgets/safety/safety_dashboard_widget.dart';
import '../../widgets/safety/emergency_button_widget.dart';
import '../../widgets/safety/safety_score_widget.dart';
import '../../widgets/safety/safety_tips_widget.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';

/// Main safety screen with dashboard and controls
class SafetyScreen extends StatefulWidget {
  const SafetyScreen({super.key});

  @override
  State<SafetyScreen> createState() => _SafetyScreenState();
}

class _SafetyScreenState extends State<SafetyScreen> {
  @override
  void initState() {
    super.initState();
    // Load safety data when screen opens
    context.read<SafetyBloc>().add(const LoadSafetyData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Safety Center',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: PulseColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              context.push('/safety-settings');
            },
          ),
        ],
      ),
      body: BlocBuilder<SafetyBloc, SafetyState>(
        builder: (context, state) {
          if (state.isLoading && state.status == SafetyStatus.loading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PulseLoadingIndicator(),
                  SizedBox(height: 16),
                  Text('Loading safety data...'),
                ],
              ),
            );
          }

          if (state.status == SafetyStatus.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: context.errorColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load safety data',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<SafetyBloc>().add(const LoadSafetyData());
                    },
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [PulseColors.surface, PulseColors.surfaceVariant],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Emergency button - always accessible
                    const EmergencyButtonWidget(),
                    const SizedBox(height: 24),

                    // Safety score card
                    if (state.safetyScore != null)
                      SafetyScoreWidget(score: state.safetyScore!),
                    const SizedBox(height: 24),

                    // Main safety dashboard
                    SafetyDashboardWidget(
                      blockedUsers: state.blockedUsers,
                      safetyTips: state.safetyTips,
                      recentReports: state.userReports,
                      settings: state.safetySettings,
                    ),
                    const SizedBox(height: 24),

                    // Quick actions
                    _buildQuickActions(context),

                    // Safety tips section
                    if (state.safetyTips.isNotEmpty)
                      _buildSafetyTips(context, state.safetyTips),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.onSurfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  context,
                  icon: Icons.report,
                  title: 'Report User',
                  subtitle: 'Report inappropriate behavior',
                  onTap: () => context.push('/safety-center'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  context,
                  icon: Icons.block,
                  title: 'Block User',
                  subtitle: 'Block and hide from matches',
                  onTap: () => context.push('/blocked-users'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  context,
                  icon: Icons.verified_user,
                  title: 'Verification',
                  subtitle: 'Verify your identity',
                  onTap: () => context.push('/photo-verification'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  context,
                  icon: Icons.help,
                  title: 'Safety Tips',
                  subtitle: 'Learn safety best practices',
                  onTap: () => context.push('/safety-center'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: PulseColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: PulseColors.outline.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: PulseColors.primary, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: PulseColors.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyTips(BuildContext context, List<SafetyTip> tips) {
    return SafetyTipsWidget(
      tips: tips,
      onTipRead: () {
        // Handle tip read action
      },
    );
  }
}
