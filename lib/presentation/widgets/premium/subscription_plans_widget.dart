import 'package:flutter/material.dart';

import '../../../data/models/premium.dart';
import '../../theme/pulse_colors.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';

/// Widget for displaying available subscription plans
class SubscriptionPlansWidget extends StatelessWidget {
  final List<PremiumPlan> plans;
  final UserSubscription? currentSubscription;
  final Function(PremiumPlan) onPlanSelected;

  const SubscriptionPlansWidget({
    super.key,
    required this.plans,
    this.currentSubscription,
    required this.onPlanSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (plans.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      children: plans.map((plan) => _buildPlanCard(context, plan)).toList(),
    );
  }

  Widget _buildPlanCard(BuildContext context, PremiumPlan plan) {
    final isCurrentPlan = currentSubscription?.planId == plan.id;
    final isPopular = plan.isPopular;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentPlan
              ? Colors.green
              : isPopular
              ? PulseColors.primary
              : context.outlineColor.withValues(alpha: 0.3),
          width: isCurrentPlan || isPopular ? 2 : 1,
        ),
        gradient: isPopular
            ? LinearGradient(
                colors: [
                  PulseColors.primary.withValues(alpha: 0.1),
                  PulseColors.primary.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
      ),
      child: Stack(
        children: [
          // Popular badge
          if (isPopular)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: PulseColors.primary,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
                child: Text(
                  plan.promoText ?? 'POPULAR',
                  style: TextStyle(
                    color: context.onSurfaceColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          // Current plan badge
          if (isCurrentPlan)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'CURRENT',
                  style: TextStyle(
                    color: context.onSurfaceColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.name,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isPopular ? PulseColors.primary : null,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                _formatPrice(plan.priceInCents),
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isPopular
                                          ? PulseColors.primary
                                          : Colors.grey[800],
                                    ),
                              ),
                              Text(
                                '/${plan.interval}',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: context.onSurfaceVariantColor,
                                    ),
                              ),
                            ],
                          ),
                          if (plan.discountPercent != null)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: context.errorColor.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${plan.discountPercent}% OFF',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: context.errorColor.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      _getPlanIcon(plan.name),
                      size: 32,
                      color: isPopular
                          ? PulseColors.primary
                          : context.onSurfaceVariantColor,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                if (plan.description.isNotEmpty) ...[
                  Text(
                    plan.description,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(
                      color: context.onSurfaceVariantColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Features list
                ...plan.features.map(
                  (feature) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 18,
                          color: isPopular
                              ? PulseColors.primary
                              : Colors.green[600],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            feature,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Action button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isCurrentPlan
                        ? null
                        : () => onPlanSelected(plan),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCurrentPlan
                          ? context.outlineColor.withValues(alpha: 0.2)
                          : isPopular
                          ? PulseColors.primary
                          : Colors.grey[800],
                      foregroundColor: context.onSurfaceColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isCurrentPlan
                          ? 'Current Plan'
                          : plan.priceInCents == 0
                          ? 'Downgrade'
                          : 'Upgrade',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.star_outline,
            size: 64,
            color: context.outlineColor.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'No plans available',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(
              color: context.onSurfaceVariantColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Premium plans are currently unavailable',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(
              color: context.onSurfaceVariantColor.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(int priceInCents) {
    if (priceInCents == 0) return 'FREE';
    return '\$${(priceInCents / 100).toStringAsFixed(2)}';
  }

  IconData _getPlanIcon(String planName) {
    final lowerName = planName.toLowerCase();
    if (lowerName.contains('premium') || lowerName.contains('pro')) {
      return Icons.workspace_premium;
    } else if (lowerName.contains('basic') || lowerName.contains('starter')) {
      return Icons.star;
    } else if (lowerName.contains('free')) {
      return Icons.person;
    }
    return Icons.diamond;
  }
}
