import 'package:flutter/material.dart';
import '../../../data/models/premium.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';

/// Showcase widget for premium features with interactive demonstrations
class PremiumFeaturesShowcase extends StatefulWidget {
  const PremiumFeaturesShowcase({
    super.key,
    this.features = const [],
    this.onFeatureSelected,
  });

  final List<PremiumFeature> features;
  final Function(PremiumFeature)? onFeatureSelected;

  @override
  State<PremiumFeaturesShowcase> createState() =>
      _PremiumFeaturesShowcaseState();
}

class _PremiumFeaturesShowcaseState extends State<PremiumFeaturesShowcase>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();

    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();

    // Auto-scroll through features
    _startAutoScroll();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    if (widget.features.isEmpty) return;

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        final nextIndex = (_currentIndex + 1) % widget.features.length;
        _pageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        _startAutoScroll();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.features.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 280,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [context.primaryColor, context.accentColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.star, color: context.onSurfaceColor, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Premium Features',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.onSurfaceColor,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      '${_currentIndex + 1}/${widget.features.length}',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.onSurfaceColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Feature showcase
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemCount: widget.features.length,
                itemBuilder: (context, index) {
                  final feature = widget.features[index];
                  return _buildFeatureCard(feature);
                },
              ),
            ),

            // Page indicator
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.features.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: index == _currentIndex ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: index == _currentIndex
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(PremiumFeature feature) {
    return GestureDetector(
      onTap: () => widget.onFeatureSelected?.call(feature),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Feature icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(feature.icon, style: TextStyle(fontSize: 40)),
              ),
            ),

            const SizedBox(height: 16),

            // Feature name
            Text(
              feature.displayName,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: context.onSurfaceColor,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Feature description
            Text(
              feature.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Grid layout for premium features
class PremiumFeaturesGrid extends StatelessWidget {
  const PremiumFeaturesGrid({
    super.key,
    required this.features,
    this.onFeatureSelected,
    this.crossAxisCount = 2,
  });

  final List<PremiumFeature> features;
  final Function(PremiumFeature)? onFeatureSelected;
  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        return _buildFeatureGridItem(context, feature);
      },
    );
  }

  Widget _buildFeatureGridItem(BuildContext context, PremiumFeature feature) {
    return GestureDetector(
      onTap: () => onFeatureSelected?.call(feature),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.onSurfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.outlineColor.shade200, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Feature icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(feature.icon, style: TextStyle(fontSize: 24)),
              ),
            ),

            const SizedBox(height: 12),

            // Feature name
            Text(
              feature.displayName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact list view for premium features
class PremiumFeaturesList extends StatelessWidget {
  const PremiumFeaturesList({
    super.key,
    required this.features,
    this.showDescriptions = true,
    this.onFeatureSelected,
  });

  final List<PremiumFeature> features;
  final bool showDescriptions;
  final Function(PremiumFeature)? onFeatureSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: features
          .map((feature) => _buildFeatureListItem(context, feature))
          .toList(),
    );
  }

  Widget _buildFeatureListItem(BuildContext context, PremiumFeature feature) {
    return GestureDetector(
      onTap: () => onFeatureSelected?.call(feature),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.onSurfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.outlineColor.shade200, width: 1),
        ),
        child: Row(
          children: [
            // Feature icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(feature.icon, style: TextStyle(fontSize: 20)),
              ),
            ),

            const SizedBox(width: 16),

            // Feature details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feature.displayName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  if (showDescriptions) ...[
                    const SizedBox(height: 4),
                    Text(
                      feature.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: context.onSurfaceVariantColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Arrow indicator
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: context.outlineColor.withValues(alpha: 0.2),
            ),
          ],
        ),
      ),
    );
  }
}
