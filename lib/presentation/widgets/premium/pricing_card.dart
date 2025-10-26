import 'package:flutter/material.dart';
import '../../../data/models/premium.dart';
import '../../theme/pulse_colors.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';

/// Pricing card widget for displaying subscription plans
///
/// Features:
/// - Plan name and pricing
/// - "Most Popular" or "Best Value" ribbon
/// - Feature list with checkmarks
/// - Selected state highlighting
/// - Monthly cost breakdown for multi-month plans
/// - Discount badges
class PricingCard extends StatelessWidget {
  /// The premium plan to display
  final PremiumPlan plan;

  /// Whether this plan is currently selected
  final bool isSelected;

  /// Whether to show "Most Popular" badge
  final bool isMostPopular;

  /// Whether to show "Best Value" badge
  final bool isBestValue;

  /// Callback when plan is selected
  final VoidCallback onSelect;

  const PricingCard({
    super.key,
    required this.plan,
    this.isSelected = false,
    this.isMostPopular = false,
    this.isBestValue = false,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final showRibbon = isMostPopular || isBestValue;
    final ribbonText = isBestValue ? 'BEST VALUE' : 'MOST POPULAR';
    final ribbonColor = isBestValue
        ? const Color(0xFF00D95F) // Success green
        : PulseColors.primary;

    return GestureDetector(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: isSelected
              ? PulseColors.primary.withValues(alpha: 0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? PulseColors.primary
                : isMostPopular
                ? PulseColors.primary.withValues(alpha: 0.3)
                : PulseColors.outline.withValues(alpha: 0.3),
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: [
            if (isSelected || isMostPopular)
              BoxShadow(
                color: (isSelected ? PulseColors.primary : PulseColors.primary)
                    .withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Ribbon badge
            if (showRibbon)
              Positioned(
                top: -1,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: ribbonColor,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(8),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: ribbonColor.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, color: context.onSurfaceColor, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        ribbonText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: context.onSurfaceColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Main content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Plan header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Plan name
                            Text(
                              plan.name,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? PulseColors.primary
                                    : PulseColors.onSurface,
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Price
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _formatPrice(plan.priceInCents),
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? PulseColors.primary
                                        : PulseColors.onSurface,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    '/${plan.interval}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: PulseColors.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // Monthly breakdown for multi-month plans
                            if (_shouldShowMonthlyBreakdown(plan)) ...[
                              const SizedBox(height: 4),
                              Text(
                                _getMonthlyBreakdown(plan),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: PulseColors.onSurfaceVariant,
                                ),
                              ),
                            ],

                            // Discount badge
                            if (plan.discountPercent != null &&
                                plan.discountPercent! > 0) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFFF3B5C,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(
                                      0xFFFF3B5C,
                                    ).withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  'SAVE ${plan.discountPercent}%',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFFF3B5C),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Selection indicator
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? PulseColors.primary
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? PulseColors.primary
                                : PulseColors.outline,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? Icon(
                                Icons.check,
                                color: context.onSurfaceColor,
                                size: 18,
                              )
                            : null,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Divider
                  Divider(
                    height: 1,
                    color: PulseColors.outline.withValues(alpha: 0.3),
                  ),

                  const SizedBox(height: 16),

                  // Description if available
                  if (plan.description.isNotEmpty) ...[
                    Text(
                      plan.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: PulseColors.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Features list
                  Text(
                    'Includes:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: PulseColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ...plan.features
                      .take(5)
                      .map(
                        (feature) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? PulseColors.primary
                                      : PulseColors.success,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.check,
                                  color: context.onSurfaceColor,
                                  size: 14,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  feature,
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                  // Show more features indicator
                  if (plan.features.length > 5) ...[
                    const SizedBox(height: 4),
                    Text(
                      '+ ${plan.features.length - 5} more features',
                      style: TextStyle(
                        fontSize: 13,
                        color: PulseColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Select button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onSelect,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected
                            ? PulseColors.primary
                            : Colors.white,
                        foregroundColor: isSelected
                            ? Colors.white
                            : PulseColors.primary,
                        side: BorderSide(
                          color: PulseColors.primary,
                          width: isSelected ? 0 : 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: isSelected ? 2 : 0,
                      ),
                      child: Text(
                        isSelected ? 'Selected' : 'Select Plan',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : PulseColors.primary,
                        ),
                      ),
                    ),
                  ),

                  // Trial info
                  if (plan.metadata?['hasTrial'] == true) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        '7-day free trial included',
                        style: TextStyle(
                          fontSize: 12,
                          color: PulseColors.success,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(int priceInCents) {
    if (priceInCents == 0) return 'FREE';
    final dollars = priceInCents / 100;
    return '\$${dollars.toStringAsFixed(0)}';
  }

  bool _shouldShowMonthlyBreakdown(PremiumPlan plan) {
    final interval = plan.interval.toLowerCase();
    return interval.contains('quarter') ||
        interval.contains('year') ||
        interval == '3-month' ||
        interval == '6-month' ||
        interval.contains('3') ||
        interval.contains('6');
  }

  String _getMonthlyBreakdown(PremiumPlan plan) {
    final interval = plan.interval.toLowerCase();
    int months = 1;

    if (interval.contains('year')) {
      months = 12;
    } else if (interval.contains('quarter') ||
        interval == '3-month' ||
        interval.contains('3')) {
      months = 3;
    } else if (interval == '6-month' || interval.contains('6')) {
      months = 6;
    }

    if (months <= 1) return '';

    final monthlyPrice = plan.priceInCents / months / 100;
    return '\$${monthlyPrice.toStringAsFixed(2)}/month';
  }
}

/// Compact pricing card for smaller displays or comparison views
class CompactPricingCard extends StatelessWidget {
  final PremiumPlan plan;
  final bool isSelected;
  final VoidCallback onSelect;

  const CompactPricingCard({
    super.key,
    required this.plan,
    this.isSelected = false,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? PulseColors.primary.withValues(alpha: 0.1)
              : PulseColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? PulseColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatPrice(plan.priceInCents)}/${plan.interval}',
                    style: TextStyle(
                      fontSize: 14,
                      color: PulseColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? PulseColors.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? PulseColors.primary : PulseColors.outline,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Icon(Icons.check, color: context.onSurfaceColor, size: 16)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(int priceInCents) {
    if (priceInCents == 0) return 'FREE';
    final dollars = priceInCents / 100;
    return '\$${dollars.toStringAsFixed(0)}';
  }
}
