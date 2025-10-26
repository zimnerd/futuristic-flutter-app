import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';

/// Skeleton loading widget for LiveStreamCard
/// Displays a shimmering placeholder while stream data is loading
class StreamCardSkeleton extends StatelessWidget {
  const StreamCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail skeleton
          Shimmer.fromColors(
            baseColor: context.outlineColor.withValues(alpha: 0.3),
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                color: context.onSurfaceColor,
              ),
            ),
          ),

          // Stream info skeleton
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title skeleton
                Shimmer.fromColors(
                  baseColor: context.outlineColor.withValues(alpha: 0.3),
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: context.onSurfaceColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Second line of title
                Shimmer.fromColors(
                  baseColor: context.outlineColor.withValues(alpha: 0.3),
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    height: 16,
                    width: MediaQuery.of(context).size.width * 0.6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: context.onSurfaceColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Bottom row (avatar + name + category)
                Row(
                  children: [
                    // Avatar skeleton
                    Shimmer.fromColors(
                      baseColor: context.outlineColor.withValues(alpha: 0.3),
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: context.onSurfaceColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Name skeleton
                    Expanded(
                      child: Shimmer.fromColors(
                        baseColor: context.outlineColor.withValues(alpha: 0.3),
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          height: 14,
                          width: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: context.onSurfaceColor,
                          ),
                        ),
                      ),
                    ),
                    // Category skeleton
                    Shimmer.fromColors(
                      baseColor: context.outlineColor.withValues(alpha: 0.3),
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        height: 24,
                        width: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: context.onSurfaceColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
