import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Reusable verification badge widget to display verified status
/// Can be used on profile cards, detail screens, chat headers, etc.
/// 
/// Usage:
/// ```dart
/// VerificationBadge(
///   isVerified: user.verified,
///   size: VerificationBadgeSize.medium,
/// )
/// ```
class VerificationBadge extends StatelessWidget {
  final bool isVerified;
  final VerificationBadgeSize size;
  final bool showLabel;
  final String? customLabel;
  final Color? backgroundColor;
  final Color? iconColor;

  const VerificationBadge({
    Key? key,
    required this.isVerified,
    this.size = VerificationBadgeSize.medium,
    this.showLabel = false,
    this.customLabel,
    this.backgroundColor,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isVerified) {
      return const SizedBox.shrink();
    }

    final sizeConfig = _getSizeConfig();

    if (showLabel) {
      return _buildWithLabel(sizeConfig);
    } else {
      return _buildIconOnly(sizeConfig);
    }
  }

  Widget _buildIconOnly(_BadgeSizeConfig config) {
    return Container(
      width: config.iconSize,
      height: config.iconSize,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.primary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (backgroundColor ?? AppColors.primary).withOpacity(0.3),
            blurRadius: config.shadowBlur,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        Icons.verified,
        color: iconColor ?? Colors.white,
        size: config.checkmarkSize,
      ),
    );
  }

  Widget _buildWithLabel(_BadgeSizeConfig config) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: config.paddingHorizontal,
        vertical: config.paddingVertical,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(config.borderRadius),
        border: Border.all(
          color: backgroundColor ?? AppColors.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified,
            color: iconColor ?? AppColors.primary,
            size: config.checkmarkSize,
          ),
          SizedBox(width: config.spacing),
          Text(
            customLabel ?? 'Verified',
            style: TextStyle(
              color: iconColor ?? AppColors.primary,
              fontSize: config.fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeSizeConfig _getSizeConfig() {
    switch (size) {
      case VerificationBadgeSize.small:
        return const _BadgeSizeConfig(
          iconSize: 16,
          checkmarkSize: 12,
          fontSize: 10,
          paddingHorizontal: 6,
          paddingVertical: 2,
          spacing: 3,
          borderRadius: 8,
          shadowBlur: 4,
        );
      case VerificationBadgeSize.medium:
        return const _BadgeSizeConfig(
          iconSize: 20,
          checkmarkSize: 14,
          fontSize: 12,
          paddingHorizontal: 8,
          paddingVertical: 4,
          spacing: 4,
          borderRadius: 10,
          shadowBlur: 6,
        );
      case VerificationBadgeSize.large:
        return const _BadgeSizeConfig(
          iconSize: 24,
          checkmarkSize: 18,
          fontSize: 14,
          paddingHorizontal: 10,
          paddingVertical: 6,
          spacing: 6,
          borderRadius: 12,
          shadowBlur: 8,
        );
    }
  }
}

enum VerificationBadgeSize {
  small,
  medium,
  large,
}

class _BadgeSizeConfig {
  final double iconSize;
  final double checkmarkSize;
  final double fontSize;
  final double paddingHorizontal;
  final double paddingVertical;
  final double spacing;
  final double borderRadius;
  final double shadowBlur;

  const _BadgeSizeConfig({
    required this.iconSize,
    required this.checkmarkSize,
    required this.fontSize,
    required this.paddingHorizontal,
    required this.paddingVertical,
    required this.spacing,
    required this.borderRadius,
    required this.shadowBlur,
  });
}
