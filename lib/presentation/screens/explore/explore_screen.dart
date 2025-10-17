import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:line_icons/line_icons.dart';

import '../../theme/pulse_colors.dart';

/// Explore/Feature Hub Screen - Centralized access to all app features
/// FIXES: Feature discovery crisis - makes hidden features discoverable
class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PulseColors.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Simulate refresh - in real app would reload feature states
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: CustomScrollView(
            slivers: [
            // App Bar
            SliverAppBar(
              floating: true,
              backgroundColor: PulseColors.surface,
              elevation: 0,
              title: Text(
                'Explore',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: PulseColors.onSurface,
                    ),
              ),
            ),

            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(context, 'Premium Features',
                        'Unlock exclusive experiences'),
                    const SizedBox(height: 16),
                    _buildFeatureGrid(context, _premiumFeatures),

                    const SizedBox(height: 32),
                    _buildSectionHeader(context, 'Communication',
                        'Connect in different ways'),
                    const SizedBox(height: 16),
                    _buildFeatureGrid(context, _communicationFeatures),

                    const SizedBox(height: 32),
                    _buildSectionHeader(context, 'Social & Events',
                        'Meet people IRL'),
                    const SizedBox(height: 16),
                    _buildFeatureGrid(context, _socialFeatures),

                    const SizedBox(height: 32),
                    _buildSectionHeader(context, 'Tools & Insights',
                        'Enhance your experience'),
                    const SizedBox(height: 16),
                    _buildFeatureGrid(context, _toolsFeatures),
                  ],
                ),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: PulseColors.onSurface,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: PulseColors.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildFeatureGrid(BuildContext context, List<FeatureItem> features) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        return _buildFeatureCard(context, feature);
      },
    );
  }

  Widget _buildFeatureCard(BuildContext context, FeatureItem feature) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(feature.route),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: feature.color.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: feature.color.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon with gradient background
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        feature.color,
                        feature.color.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: feature.color.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    feature.icon,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),

                // Title
                Text(
                  feature.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: PulseColors.onSurface,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Description
                Text(
                  feature.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: PulseColors.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                // Premium badge if applicable
                if (feature.isPremium) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.workspace_premium,
                          size: 12,
                          color: Colors.amber[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Premium',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Premium Features
  static final List<FeatureItem> _premiumFeatures = [
    FeatureItem(
      icon: LineIcons.rocket,
      title: 'Speed Dating',
      description: 'Quick video dates',
      route: '/speed-dating',
      color: const Color(0xFFFF6B6B),
      isPremium: true,
    ),
    FeatureItem(
      icon: LineIcons.video,
      title: 'Live Streaming',
      description: 'Go live or watch streams',
      route: '/live-streaming',
      color: const Color(0xFF4ECDC4),
      isPremium: true,
    ),
    FeatureItem(
      icon: LineIcons.calendarPlus,
      title: 'Date Planning',
      description: 'Plan perfect dates',
      route: '/date-planning',
      color: const Color(0xFFFF6B9D),
      isPremium: true,
    ),
    FeatureItem(
      icon: LineIcons.gift,
      title: 'Virtual Gifts',
      description: 'Send special gifts',
      route: '/virtual-gifts',
      color: const Color(0xFFFFD93D),
      isPremium: true,
    ),
    FeatureItem(
      icon: LineIcons.heart,
      title: 'Who Liked You',
      description: 'See who likes you',
      route: '/who-liked-you',
      color: const Color(0xFFE63946),
      isPremium: true,
    ),
    FeatureItem(
      icon: LineIcons.crown,
      title: 'Premium',
      description: 'Upgrade your account',
      route: '/premium',
      color: const Color(0xFFFFD700),
      isPremium: false,
    ),
  ];

  // Communication Features
  static final List<FeatureItem> _communicationFeatures = [
    FeatureItem(
      icon: LineIcons.robot,
      title: 'AI Companion',
      description: 'Your dating coach',
      route: '/ai-companion',
      color: const Color(0xFF6E3BFF),
      isPremium: false,
    ),
    FeatureItem(
      icon: LineIcons.microphone,
      title: 'Voice Messages',
      description: 'Send voice notes',
      route: '/voice-messages',
      color: const Color(0xFF00C2FF),
      isPremium: false,
    ),
    FeatureItem(
      icon: LineIcons.users,
      title: 'Group Chat',
      description: 'Chat with groups',
      route: '/group-list',
      color: const Color(0xFF00D95F),
      isPremium: false,
    ),
    FeatureItem(
      icon: LineIcons.phone,
      title: 'Call History',
      description: 'View past calls',
      route: '/call-history',
      color: const Color(0xFF3D5AFE),
      isPremium: false,
    ),
  ];

  // Social & Events Features
  static final List<FeatureItem> _socialFeatures = [
    FeatureItem(
      icon: LineIcons.calendarCheck,
      title: 'Events',
      description: 'Join local events',
      route: '/events',
      color: const Color(0xFFFF6B6B),
      isPremium: false,
    ),
    FeatureItem(
      icon: LineIcons.compass,
      title: 'Discovery',
      description: 'Find new people',
      route: '/discovery',
      color: const Color(0xFF4ECDC4),
      isPremium: false,
    ),
  ];

  // Tools & Insights Features
  static final List<FeatureItem> _toolsFeatures = [
    FeatureItem(
      icon: LineIcons.filter,
      title: 'Filters',
      description: 'Refine your matches',
      route: '/filters',
      color: const Color(0xFF6E3BFF),
      isPremium: false,
    ),
    FeatureItem(
      icon: LineIcons.barChart,
      title: 'Statistics',
      description: 'Your dating insights',
      route: '/statistics',
      color: const Color(0xFF00C2FF),
      isPremium: false,
    ),
    FeatureItem(
      icon: LineIcons.userShield,
      title: 'Safety Center',
      description: 'Privacy & safety',
      route: '/safety',
      color: const Color(0xFFFF6B9D),
      isPremium: false,
    ),
    FeatureItem(
      icon: LineIcons.cog,
      title: 'Settings',
      description: 'App preferences',
      route: '/settings',
      color: const Color(0xFF95A5A6),
      isPremium: false,
    ),
  ];
}

class FeatureItem {
  final IconData icon;
  final String title;
  final String description;
  final String route;
  final Color color;
  final bool isPremium;

  FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.route,
    required this.color,
    this.isPremium = false,
  });
}
