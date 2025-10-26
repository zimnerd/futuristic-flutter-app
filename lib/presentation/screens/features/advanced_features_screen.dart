import 'package:flutter/material.dart';
import '../../navigation/navigation_helper.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';

/// Advanced Features Navigation Demo Screen
/// This screen showcases all the advanced features and their navigation
/// Useful for testing and demonstrating the app's capabilities
class AdvancedFeaturesScreen extends StatelessWidget {
  const AdvancedFeaturesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Advanced Features'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: context.onSurfaceColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Explore Advanced Features',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap any feature below to explore PulseLink\'s advanced capabilities',
              style: TextStyle(fontSize: 16, color: context.outlineColor),
            ),
            const SizedBox(height: 24),

            // Core Features Section
            _buildSectionHeader('Core Features'),
            const SizedBox(height: 12),
            _buildFeatureGrid(context, NavigationHelper.coreFeatures),

            const SizedBox(height: 32),

            // Premium Features Section
            _buildSectionHeader('Premium Features'),
            const SizedBox(height: 12),
            _buildFeatureGrid(context, NavigationHelper.premiumFeatures),

            const SizedBox(height: 32),

            // Quick Actions
            _buildSectionHeader('Quick Actions'),
            const SizedBox(height: 12),
            _buildQuickActions(context),

            const SizedBox(height: 32),

            // Navigation Test
            _buildSectionHeader('Navigation Test'),
            const SizedBox(height: 12),
            _buildNavigationTest(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.deepPurple,
      ),
    );
  }

  Widget _buildFeatureGrid(BuildContext context, List<String> features) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final featureKey = features[index];
        final feature = NavigationHelper.getDestination(featureKey);

        if (feature == null) return const SizedBox.shrink();

        final isPremium = NavigationHelper.isPremiumFeature(featureKey);

        return Card(
          elevation: 4,
          child: InkWell(
            onTap: () => context.navigateToFeature(featureKey),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    children: [
                      Icon(
                        feature['icon'],
                        size: 32,
                        color: isPremium ? Colors.amber : Colors.deepPurple,
                      ),
                      if (isPremium)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.amber[700],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    feature['title'],
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    feature['description'],
                    style: TextStyle(fontSize: 11, color: context.outlineColor),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.card_giftcard, color: Colors.pink),
          title: Text('Send Virtual Gift'),
          subtitle: Text('Send a gift to someone special'),
          trailing: Icon(Icons.arrow_forward_ios),
          onTap: () =>
              context.showVirtualGiftsBottomSheet(recipientName: 'Demo User'),
        ),
        ListTile(
          leading: Icon(Icons.videocam, color: Colors.blue),
          title: Text('Start Video Call'),
          subtitle: Text('Begin a video conversation'),
          trailing: Icon(Icons.arrow_forward_ios),
          onTap: () => context.goToVideoCall('demo_call_123'),
        ),
        ListTile(
          leading: Icon(Icons.psychology, color: Colors.purple),
          title: Text('AI Dating Assistant'),
          subtitle: Text('Get personalized dating advice'),
          trailing: Icon(Icons.arrow_forward_ios),
          onTap: () => context.goToAiCompanion(),
        ),
      ],
    );
  }

  Widget _buildNavigationTest(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test Navigation System',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              'This section tests our navigation system with various feature names:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  [
                        'discovery',
                        'gifts',
                        'premium',
                        'safety',
                        'ai',
                        'speed dating',
                        'live',
                        'dates',
                        'voice',
                        'settings',
                      ]
                      .map(
                        (feature) => ElevatedButton(
                          onPressed: () => context.navigateToFeature(feature),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple.withValues(
                              alpha: 0.1,
                            ),
                            foregroundColor: Colors.deepPurple,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                          ),
                          child: Text(
                            feature,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
