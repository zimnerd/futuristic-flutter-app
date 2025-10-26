import 'package:flutter/material.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';

/// Skeleton loading widget - shows placeholder while content loads
/// Token-efficient, simple UI improvement
class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
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
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((s) => s.clamp(0.0, 1.0)).toList(),
              colors: [
                Theme.of(context).colorScheme.surfaceContainerHighest,
                Theme.of(context).colorScheme.surfaceContainer,
                Theme.of(context).colorScheme.surfaceContainerHighest,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Profile Card Skeleton
class ProfileCardSkeleton extends StatelessWidget {
  const ProfileCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile image
            Center(
              child: SkeletonLoader(
                width: 120,
                height: 120,
                borderRadius: BorderRadius.circular(60),
              ),
            ),
            const SizedBox(height: 16),
            // Name
            SkeletonLoader(
              width: double.infinity,
              height: 24,
              borderRadius: BorderRadius.circular(12),
            ),
            const SizedBox(height: 8),
            // Age/Location
            SkeletonLoader(
              width: 150,
              height: 16,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 16),
            // Bio
            SkeletonLoader(
              width: double.infinity,
              height: 14,
              borderRadius: BorderRadius.circular(7),
            ),
            const SizedBox(height: 8),
            SkeletonLoader(
              width: double.infinity,
              height: 14,
              borderRadius: BorderRadius.circular(7),
            ),
            const SizedBox(height: 8),
            SkeletonLoader(
              width: 200,
              height: 14,
              borderRadius: BorderRadius.circular(7),
            ),
          ],
        ),
      ),
    );
  }
}

/// Match Card Skeleton
class MatchCardSkeleton extends StatelessWidget {
  const MatchCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Avatar
            SkeletonLoader(
              width: 60,
              height: 60,
              borderRadius: BorderRadius.circular(30),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoader(
                    width: double.infinity,
                    height: 18,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  const SizedBox(height: 8),
                  SkeletonLoader(
                    width: 120,
                    height: 14,
                    borderRadius: BorderRadius.circular(7),
                  ),
                ],
              ),
            ),
            // Actions
            SkeletonLoader(
              width: 40,
              height: 40,
              borderRadius: BorderRadius.circular(20),
            ),
          ],
        ),
      ),
    );
  }
}

/// Message Card Skeleton
class MessageCardSkeleton extends StatelessWidget {
  const MessageCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: SkeletonLoader(
        width: 50,
        height: 50,
        borderRadius: BorderRadius.circular(25),
      ),
      title: SkeletonLoader(
        width: double.infinity,
        height: 16,
        borderRadius: BorderRadius.circular(8),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: SkeletonLoader(
          width: 200,
          height: 14,
          borderRadius: BorderRadius.circular(7),
        ),
      ),
      trailing: SkeletonLoader(
        width: 40,
        height: 12,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

/// List of Skeleton Items
class SkeletonList extends StatelessWidget {
  final Widget skeletonItem;
  final int itemCount;

  const SkeletonList({
    super.key,
    required this.skeletonItem,
    this.itemCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemBuilder: (context, index) => skeletonItem,
    );
  }
}
