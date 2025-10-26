import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/app_button.dart';
import '../../data/models/subscription_plan.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';


/// Widget to display subscription plan information and actions
class SubscriptionPlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool isCurrentPlan;
  final bool isPopular;
  final VoidCallback? onSelect;

  const SubscriptionPlanCard({
    super.key,
    required this.plan,
    this.isCurrentPlan = false,
    this.isPopular = false,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentPlan
              ? AppColors.primary
              : isPopular
              ? AppColors.warning
              : context.outlineColor,
          width: isCurrentPlan || isPopular ? 2 : 1,
        ),
        boxShadow: isPopular
            ? [
                BoxShadow(
                  color: AppColors.warning.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPopular) _buildPopularBadge(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 16),
                _buildPricing(context),
                const SizedBox(height: 20),
                _buildFeatures(context),
                const SizedBox(height: 20),
                _buildActionButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularBadge() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.warning,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Text(
        'MOST POPULAR',
        textAlign: TextAlign.center,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textOnPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                plan.name,
                style: AppTextStyles.heading4.copyWith(
                  color: context.onSurfaceColor,
                ),
              ),
            ),
            if (isCurrentPlan)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'CURRENT',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          plan.description,
          style: AppTextStyles.bodyMedium.copyWith(
            color: context.onSurfaceVariantColor,
          ),
        ),
      ],
    );
  }

  Widget _buildPricing(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '\$${plan.amount.toStringAsFixed(0)}',
          style: AppTextStyles.heading2.copyWith(
            color: context.onSurfaceColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 4),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            '/${_getBillingPeriodText()}',
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.onSurfaceVariantColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatures(BuildContext context) {
    return Column(
      children: plan.features
          .map((feature) => _buildFeatureItem(context, feature.name))
          .toList(),
    );
  }

  Widget _buildFeatureItem(BuildContext context, String feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.check, color: AppColors.success, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              feature,
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.onSurfaceColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    if (isCurrentPlan) {
      return AppButton(
        text: 'Current Plan',
        onPressed: null,
        variant: AppButtonVariant.outline,
        isFullWidth: true,
      );
    }

    return AppButton(
      text: 'Select Plan',
      onPressed: onSelect,
      variant: isPopular ? AppButtonVariant.primary : AppButtonVariant.outline,
      isFullWidth: true,
    );
  }

  String _getBillingPeriodText() {
    switch (plan.billingCycle) {
      case BillingCycle.weekly:
        return 'week';
      case BillingCycle.monthly:
        return 'month';
      case BillingCycle.quarterly:
        return 'quarter';
      case BillingCycle.yearly:
        return 'year';
    }
  }
}
