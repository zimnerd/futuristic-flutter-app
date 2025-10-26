import 'package:flutter/material.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';

import '../theme/pulse_colors.dart';

/// Enhanced animation utilities for Pulse Dating App
/// Provides smooth, modern animations that create an engaging user experience

/// Custom animation curves for modern feel
class PulseCurves {
  PulseCurves._();

  // Smooth easing curves
  static const Curve easeInOutQuint = Cubic(0.83, 0, 0.17, 1);
  static const Curve easeOutQuart = Cubic(0.25, 1, 0.5, 1);
  static const Curve easeInQuart = Cubic(0.5, 0, 0.75, 0);

  // Bouncy curves for playful interactions
  static const Curve bounceOut = Curves.bounceOut;
  static const Curve elasticOut = Curves.elasticOut;

  // Spring physics
  static const SpringDescription spring = SpringDescription(
    mass: 1,
    stiffness: 500,
    damping: 30,
  );

  static const SpringDescription gentleSpring = SpringDescription(
    mass: 1,
    stiffness: 300,
    damping: 25,
  );
}

/// Slide transition animations
class SlideTransitionAnimation extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;
  final Offset begin;
  final Offset end;
  final Curve curve;

  const SlideTransitionAnimation({
    super.key,
    required this.child,
    required this.animation,
    this.begin = const Offset(1.0, 0.0),
    this.end = Offset.zero,
    this.curve = PulseCurves.easeOutQuart,
  });

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: begin,
        end: end,
      ).animate(CurvedAnimation(parent: animation, curve: curve)),
      child: child,
    );
  }
}

/// Scale transition with bounce effect
class BounceScaleTransition extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;
  final double beginScale;
  final double endScale;
  final Curve curve;

  const BounceScaleTransition({
    super.key,
    required this.child,
    required this.animation,
    this.beginScale = 0.0,
    this.endScale = 1.0,
    this.curve = PulseCurves.bounceOut,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(
        begin: beginScale,
        end: endScale,
      ).animate(CurvedAnimation(parent: animation, curve: curve)),
      child: child,
    );
  }
}

/// Fade transition with custom curve
class FadeTransitionAnimation extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;
  final double beginOpacity;
  final double endOpacity;
  final Curve curve;

  const FadeTransitionAnimation({
    super.key,
    required this.child,
    required this.animation,
    this.beginOpacity = 0.0,
    this.endOpacity = 1.0,
    this.curve = PulseCurves.easeOutQuart,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(
        begin: beginOpacity,
        end: endOpacity,
      ).animate(CurvedAnimation(parent: animation, curve: curve)),
      child: child,
    );
  }
}

/// Combined slide and fade animation
class SlideFadeTransition extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;
  final Offset slideBegin;
  final Offset slideEnd;
  final double fadeBegin;
  final double fadeEnd;
  final Curve curve;

  const SlideFadeTransition({
    super.key,
    required this.child,
    required this.animation,
    this.slideBegin = const Offset(0.0, 0.5),
    this.slideEnd = Offset.zero,
    this.fadeBegin = 0.0,
    this.fadeEnd = 1.0,
    this.curve = PulseCurves.easeOutQuart,
  });

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: slideBegin,
        end: slideEnd,
      ).animate(CurvedAnimation(parent: animation, curve: curve)),
      child: FadeTransition(
        opacity: Tween<double>(
          begin: fadeBegin,
          end: fadeEnd,
        ).animate(CurvedAnimation(parent: animation, curve: curve)),
        child: child,
      ),
    );
  }
}

/// Staggered animation for lists
class StaggeredAnimation extends StatefulWidget {
  final List<Widget> children;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final Axis direction;

  const StaggeredAnimation({
    super.key,
    required this.children,
    this.duration = const Duration(milliseconds: 600),
    this.delay = const Duration(milliseconds: 100),
    this.curve = PulseCurves.easeOutQuart,
    this.direction = Axis.vertical,
  });

  @override
  State<StaggeredAnimation> createState() => _StaggeredAnimationState();
}

class _StaggeredAnimationState extends State<StaggeredAnimation>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = [];
    _animations = [];

    for (int i = 0; i < widget.children.length; i++) {
      final controller = AnimationController(
        duration: widget.duration,
        vsync: this,
      );
      _controllers.add(controller);

      final animation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(parent: controller, curve: widget.curve));
      _animations.add(animation);

      // Start animation with staggered delay
      Future.delayed(
        Duration(milliseconds: widget.delay.inMilliseconds * i),
        () {
          if (mounted) {
            controller.forward();
          }
        },
      );
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(widget.children.length, (index) {
        final slideOffset = widget.direction == Axis.vertical
            ? const Offset(0.0, 0.5)
            : const Offset(0.5, 0.0);

        return SlideFadeTransition(
          animation: _animations[index],
          slideBegin: slideOffset,
          child: widget.children[index],
        );
      }),
    );
  }
}

/// Shimmer loading effect
class ShimmerWidget extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;

  const ShimmerWidget({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFFE0E0E0),
    this.highlightColor = const Color(0xFFF5F5F5),
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// Pulse animation for attention-grabbing elements
class PulseAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;
  final Curve curve;

  const PulseAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1000),
    this.minScale = 1.0,
    this.maxScale = 1.1,
    this.curve = Curves.easeInOut,
  });

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _animation, child: widget.child);
  }
}

/// Hero-style page transition
class HeroPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final String heroTag;
  final Duration duration;

  HeroPageRoute({
    required this.child,
    required this.heroTag,
    this.duration = const Duration(milliseconds: 400),
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) => child,
         transitionDuration: duration,
         reverseTransitionDuration: duration,
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           return SlideTransition(
             position:
                 Tween<Offset>(
                   begin: const Offset(1.0, 0.0),
                   end: Offset.zero,
                 ).animate(
                   CurvedAnimation(
                     parent: animation,
                     curve: PulseCurves.easeOutQuart,
                   ),
                 ),
             child: FadeTransition(opacity: animation, child: child),
           );
         },
       );
}

/// Match celebration animation
class MatchCelebrationWidget extends StatefulWidget {
  final VoidCallback? onComplete;

  const MatchCelebrationWidget({super.key, this.onComplete});

  @override
  State<MatchCelebrationWidget> createState() => _MatchCelebrationWidgetState();
}

class _MatchCelebrationWidgetState extends State<MatchCelebrationWidget>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: PulseCurves.bounceOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startAnimation();
  }

  void _startAnimation() async {
    await _scaleController.forward();
    _pulseController.repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        widget.onComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: ScaleTransition(
          scale: _pulseAnimation,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: PulseColors.primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: PulseColors.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              Icons.favorite,
              color: context.onSurfaceColor,
              size: 60,
            ),
          ),
        ),
      ),
    );
  }
}
