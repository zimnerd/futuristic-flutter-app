import 'package:flutter/material.dart';
import '../../theme/pulse_colors.dart';

/// Reusable card widget for displaying premium features
///
/// Shows a feature with icon, title, description, and premium badge.
/// Can be highlighted and tapped for more details.
class PremiumFeatureCard extends StatelessWidget {
  /// Icon representing the feature
  final IconData icon;

  /// Feature title
  final String title;

  /// Feature description
  final String description;

  /// Whether this is a premium-only feature
  final bool isPremium;

  /// Whether to highlight this feature (e.g., when navigated from a specific locked feature)
  final bool isHighlighted;

  /// Callback when card is tapped
  final VoidCallback? onTap;

  const PremiumFeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.isPremium = true,
    this.isHighlighted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: isHighlighted
              ? PulseColors.primary.withValues(alpha: 0.1)
              : PulseColors.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHighlighted
                ? PulseColors.primary
                : PulseColors.outline.withValues(alpha: 0.2),
            width: isHighlighted ? 2 : 1,
          ),
          boxShadow: isHighlighted
              ? [
                  BoxShadow(
                    color: PulseColors.primary.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isPremium
                        ? [
                            PulseColors.primary,
                            PulseColors.primaryLight,
                          ]
                        : [
                            PulseColors.onSurfaceVariant,
                            PulseColors.onSurfaceVariant,
                          ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),

              const SizedBox(width: 16),

              // Title and description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                          ),
                        ),
                        if (isPremium)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFFFD700),
                                  Color(0xFFFF9900),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.workspace_premium,
                                  size: 12,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'PRO',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: PulseColors.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow indicator if tappable
              if (onTap != null) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: PulseColors.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact version of premium feature card for lists
class CompactPremiumFeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isPremium;

  const CompactPremiumFeatureCard({
    super.key,
    required this.icon,
    required this.title,
    this.isPremium = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isPremium
            ? PulseColors.primary.withValues(alpha: 0.08)
            : PulseColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPremium
              ? PulseColors.primary.withValues(alpha: 0.2)
              : PulseColors.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isPremium ? PulseColors.primary : PulseColors.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isPremium ? PulseColors.primary : PulseColors.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Feature comparison row widget for free vs premium comparison
class FeatureComparisonRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String freeValue;
  final String premiumValue;
  final bool showCheckmark;

  const FeatureComparisonRow({
    super.key,
    required this.icon,
    required this.title,
    required this.freeValue,
    required this.premiumValue,
    this.showCheckmark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: PulseColors.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: _buildValue(freeValue, false),
          ),
          Expanded(
            child: _buildValue(premiumValue, true),
          ),
        ],
      ),
    );
  }

  Widget _buildValue(String value, bool isPremium) {
    if (showCheckmark) {
      final hasFeature = value.toLowerCase() == 'yes' || value == '✓';
      return Icon(
        hasFeature ? Icons.check_circle : Icons.cancel,
        color: hasFeature
            ? (isPremium ? PulseColors.success : PulseColors.onSurfaceVariant)
            : PulseColors.onSurfaceVariant.withValues(alpha: 0.3),
        size: 20,
      );
    }

    return Text(
      value,
      style: TextStyle(
        fontSize: 13,
        color: isPremium ? PulseColors.primary : PulseColors.onSurfaceVariant,
        fontWeight: isPremium ? FontWeight.w600 : FontWeight.normal,
      ),
      textAlign: TextAlign.center,
    );
  }
}
