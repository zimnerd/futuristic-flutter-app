import 'package:flutter/material.dart';
import '../../../data/models/premium.dart';
import '../../theme/pulse_colors.dart';

class PremiumFeaturesWidget extends StatelessWidget {
  final UserSubscription? subscription;

  const PremiumFeaturesWidget({super.key, this.subscription});

  @override
  Widget build(BuildContext context) {
    final isPremium = subscription?.status == SubscriptionStatus.active;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: PulseColors.primary, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Premium Features',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 16),

            ...PremiumFeatureType.values.map(
              (feature) => _buildFeatureItem(context, feature, isPremium),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context,
    PremiumFeatureType feature,
    bool isUnlocked,
  ) {
    final featureInfo = _getFeatureInfo(feature);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnlocked
              ? PulseColors.primary.withValues(alpha: 0.3)
              : Colors.grey[300]!,
        ),
        color: isUnlocked
            ? PulseColors.primary.withValues(alpha: 0.05)
            : Colors.grey[50],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isUnlocked
                  ? PulseColors.primary.withValues(alpha: 0.1)
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              featureInfo.icon,
              color: isUnlocked ? PulseColors.primary : Colors.grey[600],
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        featureInfo.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isUnlocked ? Colors.black87 : Colors.grey[600],
                        ),
                      ),
                    ),
                    if (isUnlocked)
                      Icon(
                        Icons.check_circle,
                        color: Colors.green[600],
                        size: 18,
                      )
                    else
                      Icon(Icons.lock, color: Colors.grey[500], size: 18),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  featureInfo.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isUnlocked ? Colors.grey[700] : Colors.grey[500],
                  ),
                ),
                if (featureInfo.coinCost > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.monetization_on,
                        size: 14,
                        color: Colors.amber[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${featureInfo.coinCost} coins per use',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.amber[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  _FeatureInfo _getFeatureInfo(PremiumFeatureType feature) {
    switch (feature) {
      case PremiumFeatureType.boost:
        return _FeatureInfo(
          title: 'Profile Boost',
          description: '10x more profile views for 30 minutes',
          icon: Icons.trending_up,
          coinCost: 10,
        );
      case PremiumFeatureType.superLike:
        return _FeatureInfo(
          title: 'Super Like',
          description: 'Stand out with a special like that gets noticed',
          icon: Icons.favorite,
          coinCost: 5,
        );
      case PremiumFeatureType.rewind:
        return _FeatureInfo(
          title: 'Rewind',
          description: 'Undo your last swipe and get a second chance',
          icon: Icons.undo,
          coinCost: 3,
        );
      case PremiumFeatureType.readReceipts:
        return _FeatureInfo(
          title: 'Read Receipts',
          description: 'See when your messages have been read',
          icon: Icons.mark_email_read,
          coinCost: 0,
        );
      case PremiumFeatureType.unlimitedLikes:
        return _FeatureInfo(
          title: 'Unlimited Likes',
          description: 'Like as many profiles as you want',
          icon: Icons.favorite_border,
          coinCost: 0,
        );
      case PremiumFeatureType.whoLikedYou:
        return _FeatureInfo(
          title: 'Who Liked You',
          description: 'See who already swiped right on you',
          icon: Icons.visibility,
          coinCost: 0,
        );
      case PremiumFeatureType.advancedFilters:
        return _FeatureInfo(
          title: 'Advanced Filters',
          description: 'Filter by education, lifestyle, and more',
          icon: Icons.filter_list,
          coinCost: 0,
        );
      case PremiumFeatureType.prioritySupport:
        return _FeatureInfo(
          title: 'Priority Support',
          description: 'Get faster response from our support team',
          icon: Icons.support_agent,
          coinCost: 0,
        );
      case PremiumFeatureType.customGifts:
        return _FeatureInfo(
          title: 'Custom Gifts',
          description: 'Send personalized virtual gifts',
          icon: Icons.card_giftcard,
          coinCost: 15,
        );
      case PremiumFeatureType.profileViewers:
        return _FeatureInfo(
          title: 'Profile Viewers',
          description: 'See who viewed your profile',
          icon: Icons.remove_red_eye,
          coinCost: 0,
        );
      case PremiumFeatureType.aiCompanion:
        return _FeatureInfo(
          title: 'AI Dating Coach',
          description: 'Get personalized dating advice and tips',
          icon: Icons.psychology,
          coinCost: 0,
        );
      case PremiumFeatureType.conciergeService:
        return _FeatureInfo(
          title: 'Concierge Service',
          description: 'Personal dating assistant for premium members',
          icon: Icons.person_pin,
          coinCost: 0,
        );
      case PremiumFeatureType.exclusiveEvents:
        return _FeatureInfo(
          title: 'Exclusive Events',
          description: 'Access to VIP dating events and meetups',
          icon: Icons.event,
          coinCost: 0,
        );
      case PremiumFeatureType.aiSmartMatching:
        return _FeatureInfo(
          title: 'AI Smart Matching',
          description: 'Advanced AI algorithms find your perfect matches',
          icon: Icons.psychology,
          coinCost: 0,
        );
      case PremiumFeatureType.aiCompatibilityAnalysis:
        return _FeatureInfo(
          title: 'AI Compatibility Analysis',
          description: 'Deep compatibility insights powered by AI',
          icon: Icons.analytics,
          coinCost: 0,
        );
      case PremiumFeatureType.aiConversationStarters:
        return _FeatureInfo(
          title: 'AI Conversation Starters',
          description: 'Personalized icebreakers for every match',
          icon: Icons.chat_bubble,
          coinCost: 0,
        );
      case PremiumFeatureType.aiProfileOptimization:
        return _FeatureInfo(
          title: 'AI Profile Optimization',
          description: 'AI-powered profile improvement suggestions',
          icon: Icons.tune,
          coinCost: 0,
        );
      case PremiumFeatureType.aiBehavioralInsights:
        return _FeatureInfo(
          title: 'AI Behavioral Insights',
          description: 'Understand your dating patterns with AI analysis',
          icon: Icons.insights,
          coinCost: 0,
        );
    }
  }
}

class _FeatureInfo {
  final String title;
  final String description;
  final IconData icon;
  final int coinCost;

  const _FeatureInfo({
    required this.title,
    required this.description,
    required this.icon,
    required this.coinCost,
  });
}
