import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../animations/pulse_animations.dart';
import '../theme/pulse_colors.dart';

/// Enhanced animated button with smooth interactions
class AnimatedPulseButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final double? elevation;
  final Widget? icon;
  final bool isLoading;
  final bool isEnabled;
  final double? width;
  final double? height;
  final TextStyle? textStyle;
  final List<Color>? gradientColors;

  const AnimatedPulseButton({
    super.key,
    required this.text,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
    this.borderRadius,
    this.elevation,
    this.icon,
    this.isLoading = false,
    this.isEnabled = true,
    this.width,
    this.height,
    this.textStyle,
    this.gradientColors,
  });

  @override
  State<AnimatedPulseButton> createState() => _AnimatedPulseButtonState();
}

class _AnimatedPulseButtonState extends State<AnimatedPulseButton>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _loadingController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _loadingAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: PulseAnimations.buttonPress,
      vsync: this,
    );

    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: PulseCurves.easeOutQuart,
      ),
    );

    _loadingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.linear),
    );

    if (widget.isLoading) {
      _loadingController.repeat();
    }
  }

  @override
  void didUpdateWidget(AnimatedPulseButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !oldWidget.isLoading) {
      _loadingController.repeat();
    } else if (!widget.isLoading && oldWidget.isLoading) {
      _loadingController.stop();
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.isEnabled && !widget.isLoading) {
      _scaleController.forward();
      HapticFeedback.lightImpact();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.isEnabled && !widget.isLoading) {
      _scaleController.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.isEnabled && !widget.isLoading) {
      _scaleController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = widget.isEnabled && !widget.isLoading;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: isEnabled ? widget.onPressed : null,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: PulseAnimations.normal,
          curve: PulseCurves.easeOutQuart,
          width: widget.width,
          height: widget.height ?? 48,
          padding:
              widget.padding ??
              const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            gradient: widget.gradientColors != null
                ? LinearGradient(
                    colors: widget.gradientColors!,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: widget.gradientColors == null
                ? (widget.backgroundColor ?? PulseColors.primary)
                : null,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
            boxShadow: isEnabled
                ? [
                    BoxShadow(
                      color: (widget.backgroundColor ?? PulseColors.primary)
                          .withValues(alpha: 0.3),
                      blurRadius: widget.elevation ?? 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: AnimatedOpacity(
            duration: PulseAnimations.quick,
            opacity: isEnabled ? 1.0 : 0.6,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null && !widget.isLoading) ...[
                  widget.icon!,
                  const SizedBox(width: 8),
                ],
                if (widget.isLoading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: RotationTransition(
                      turns: _loadingAnimation,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          widget.foregroundColor ?? Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  )
                else
                  AnimatedDefaultTextStyle(
                    duration: PulseAnimations.quick,
                    style: (widget.textStyle ?? theme.textTheme.labelLarge!)
                        .copyWith(
                          color: widget.foregroundColor ?? Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                    child: Text(widget.text),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Floating Action Button with enhanced animations
class AnimatedFAB extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final String? tooltip;
  final String? heroTag;

  const AnimatedFAB({
    super.key,
    this.onPressed,
    required this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.tooltip,
    this.heroTag,
  });

  @override
  State<AnimatedFAB> createState() => _AnimatedFABState();
}

class _AnimatedFABState extends State<AnimatedFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: PulseCurves.easeOutQuart),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.1).animate(
      CurvedAnimation(parent: _controller, curve: PulseCurves.easeOutQuart),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() {
    if (widget.onPressed != null) {
      _controller.forward().then((_) => _controller.reverse());
      HapticFeedback.mediumImpact();
      widget.onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: RotationTransition(
        turns: _rotationAnimation,
        child: FloatingActionButton(
          onPressed: _onTap,
          backgroundColor: widget.backgroundColor ?? PulseColors.primary,
          foregroundColor: widget.foregroundColor ?? Theme.of(context).colorScheme.onPrimary,
          elevation: widget.elevation ?? 6,
          tooltip: widget.tooltip,
          heroTag: widget.heroTag,
          child: widget.icon,
        ),
      ),
    );
  }
}

/// Icon button with ripple and scale animation
class AnimatedIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? backgroundColor;
  final double size;
  final EdgeInsetsGeometry? padding;
  final String? tooltip;
  final BorderRadius? borderRadius;

  const AnimatedIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.backgroundColor,
    this.size = 24,
    this.padding,
    this.tooltip,
    this.borderRadius,
  });

  @override
  State<AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<AnimatedIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: PulseAnimations.buttonPress,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: PulseCurves.easeOutQuart),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() {
    if (widget.onPressed != null) {
      _controller.forward().then((_) => _controller.reverse());
      HapticFeedback.lightImpact();
      widget.onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip ?? '',
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Material(
          color: widget.backgroundColor ?? Colors.transparent,
          borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
          child: InkWell(
            onTap: _onTap,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
            child: Padding(
              padding: widget.padding ?? const EdgeInsets.all(8),
              child: Icon(
                widget.icon,
                color: widget.color ?? PulseColors.onSurface,
                size: widget.size,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
