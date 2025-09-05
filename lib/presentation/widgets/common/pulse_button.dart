import 'package:flutter/material.dart';

import '../../theme/pulse_colors.dart';

/// Reusable button widget with Pulse branding
/// Supports multiple variants and loading states
class PulseButton extends StatelessWidget {
  const PulseButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = PulseButtonVariant.primary,
    this.size = PulseButtonSize.medium,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.fullWidth = false,
  });

  final String text;
  final VoidCallback? onPressed;
  final PulseButtonVariant variant;
  final PulseButtonSize size;
  final bool isLoading;
  final bool isDisabled;
  final Widget? icon;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Widget child = isLoading
        ? SizedBox(
            height: _getIconSize(),
            width: _getIconSize(),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getTextColor(theme),
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                SizedBox(
                  height: _getIconSize(),
                  width: _getIconSize(),
                  child: icon,
                ),
                const SizedBox(width: PulseSpacing.sm),
              ],
              Flexible(
                child: Text(
                  text,
                  style: _getTextStyle(theme),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );

    if (fullWidth) {
      child = SizedBox(width: double.infinity, child: child);
    }

    switch (variant) {
      case PulseButtonVariant.primary:
        return ElevatedButton(
          onPressed: isDisabled || isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: PulseColors.primary,
            foregroundColor: Colors.white,
            padding: _getPadding(),
            minimumSize: _getMinimumSize(),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(PulseRadii.button),
            ),
          ),
          child: child,
        );
      
      case PulseButtonVariant.secondary:
        return OutlinedButton(
          onPressed: isDisabled || isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: PulseColors.primary,
            side: const BorderSide(color: PulseColors.primary),
            padding: _getPadding(),
            minimumSize: _getMinimumSize(),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(PulseRadii.button),
            ),
          ),
          child: child,
        );
      
      case PulseButtonVariant.tertiary:
        return TextButton(
          onPressed: isDisabled || isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: PulseColors.primary,
            padding: _getPadding(),
            minimumSize: _getMinimumSize(),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(PulseRadii.button),
            ),
          ),
          child: child,
        );
      
      case PulseButtonVariant.danger:
        return ElevatedButton(
          onPressed: isDisabled || isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: PulseColors.error,
            foregroundColor: Colors.white,
            padding: _getPadding(),
            minimumSize: _getMinimumSize(),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(PulseRadii.button),
            ),
          ),
          child: child,
        );
    }
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case PulseButtonSize.small:
        return const EdgeInsets.symmetric(
          horizontal: PulseSpacing.md,
          vertical: PulseSpacing.sm,
        );
      case PulseButtonSize.medium:
        return const EdgeInsets.symmetric(
          horizontal: PulseSpacing.lg,
          vertical: PulseSpacing.md,
        );
      case PulseButtonSize.large:
        return const EdgeInsets.symmetric(
          horizontal: PulseSpacing.xl,
          vertical: PulseSpacing.lg,
        );
    }
  }

  Size _getMinimumSize() {
    switch (size) {
      case PulseButtonSize.small:
        return const Size(80, 36);
      case PulseButtonSize.medium:
        return const Size(120, 48);
      case PulseButtonSize.large:
        return const Size(160, 56);
    }
  }

  double _getIconSize() {
    switch (size) {
      case PulseButtonSize.small:
        return 16;
      case PulseButtonSize.medium:
        return 20;
      case PulseButtonSize.large:
        return 24;
    }
  }

  TextStyle _getTextStyle(ThemeData theme) {
    switch (size) {
      case PulseButtonSize.small:
        return PulseTextStyles.labelSmall;
      case PulseButtonSize.medium:
        return PulseTextStyles.labelMedium;
      case PulseButtonSize.large:
        return PulseTextStyles.labelLarge;
    }
  }

  Color _getTextColor(ThemeData theme) {
    switch (variant) {
      case PulseButtonVariant.primary:
      case PulseButtonVariant.danger:
        return Colors.white;
      case PulseButtonVariant.secondary:
      case PulseButtonVariant.tertiary:
        return PulseColors.primary;
    }
  }
}

/// Button variant styles
enum PulseButtonVariant {
  primary,
  secondary,
  tertiary,
  danger,
}

/// Button size options
enum PulseButtonSize {
  small,
  medium,
  large,
}
