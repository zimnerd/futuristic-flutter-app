import 'package:flutter/material.dart';

import '../../theme/pulse_colors.dart';

/// Loading indicator with Pulse branding
class PulseLoadingIndicator extends StatelessWidget {
  const PulseLoadingIndicator({
    super.key,
    this.size = PulseLoadingSize.medium,
    this.color,
  });

  final PulseLoadingSize size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _getSize(),
      width: _getSize(),
      child: CircularProgressIndicator(
        strokeWidth: _getStrokeWidth(),
        valueColor: AlwaysStoppedAnimation<Color>(color ?? PulseColors.primary),
      ),
    );
  }

  double _getSize() {
    switch (size) {
      case PulseLoadingSize.small:
        return 20;
      case PulseLoadingSize.medium:
        return 32;
      case PulseLoadingSize.large:
        return 48;
    }
  }

  double _getStrokeWidth() {
    switch (size) {
      case PulseLoadingSize.small:
        return 2;
      case PulseLoadingSize.medium:
        return 3;
      case PulseLoadingSize.large:
        return 4;
    }
  }
}

/// Loading overlay that covers the entire screen
class PulseLoadingOverlay extends StatelessWidget {
  const PulseLoadingOverlay({super.key, this.message, this.isVisible = true});

  final String? message;
  final bool isVisible;

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(PulseSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const PulseLoadingIndicator(),
                if (message != null) ...[
                  const SizedBox(height: PulseSpacing.md),
                  Text(
                    message!,
                    style: PulseTextStyles.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Empty state widget for when no content is available
class PulseEmptyState extends StatelessWidget {
  const PulseEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PulseSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: PulseColors.onSurfaceVariant),
            const SizedBox(height: PulseSpacing.lg),
            Text(
              title,
              style: PulseTextStyles.headlineSmall.copyWith(
                color: PulseColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: PulseSpacing.sm),
              Text(
                subtitle!,
                style: PulseTextStyles.bodyMedium.copyWith(
                  color: PulseColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: PulseSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Error state widget for handling errors gracefully
class PulseErrorState extends StatelessWidget {
  const PulseErrorState({
    super.key,
    required this.title,
    this.subtitle,
    this.onRetry,
    this.retryText = 'Try Again',
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onRetry;
  final String retryText;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PulseSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: PulseColors.error),
            const SizedBox(height: PulseSpacing.lg),
            Text(
              title,
              style: PulseTextStyles.headlineSmall.copyWith(
                color: PulseColors.error,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: PulseSpacing.sm),
              Text(
                subtitle!,
                style: PulseTextStyles.bodyMedium.copyWith(
                  color: PulseColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: PulseSpacing.lg),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: PulseColors.error,
                  foregroundColor: Colors.white,
                ),
                child: Text(retryText),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Loading size options
enum PulseLoadingSize { small, medium, large }
