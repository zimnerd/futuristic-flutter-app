import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/subscription_usage.dart';

/// Widget to display feature usage with progress indicators
class UsageIndicator extends StatelessWidget {
  final SubscriptionUsage usage;

  const UsageIndicator({super.key, required this.usage});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUsageItem(
            'Matches',
            usage.getFeatureUsage('matches'),
            Icons.favorite,
            AppColors.primary,
          ),
          const SizedBox(height: 16),
          _buildUsageItem(
            'Super Likes',
            usage.getFeatureUsage('super_likes'),
            Icons.star,
            AppColors.warning,
          ),
          const SizedBox(height: 16),
          _buildUsageItem(
            'Boosts',
            usage.getFeatureUsage('boosts'),
            Icons.trending_up,
            AppColors.success,
          ),
          const SizedBox(height: 16),
          _buildUsageItem(
            'Messages',
            usage.getFeatureUsage('messages'),
            Icons.message,
            AppColors.accent,
          ),
        ],
      ),
    );
  }

  Widget _buildUsageItem(
    String label,
    UsageCounter counter,
    IconData icon,
    Color color,
  ) {
    final isUnlimited = counter.limit == null;
    final percentage = isUnlimited
        ? 0.0
        : (counter.count / counter.limit!).clamp(0.0, 1.0);
    final isNearLimit = !isUnlimited && percentage > 0.8;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isUnlimited
                        ? '${counter.count} used (Unlimited)'
                        : '${counter.count} of ${counter.limit} used',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isNearLimit
                          ? AppColors.warning
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (!isUnlimited)
              Text(
                '${(percentage * 100).toInt()}%',
                style: AppTextStyles.labelSmall.copyWith(
                  color: isNearLimit
                      ? AppColors.warning
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        if (!isUnlimited) ...[
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(
              isNearLimit ? AppColors.warning : color,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ],
    );
  }
}
