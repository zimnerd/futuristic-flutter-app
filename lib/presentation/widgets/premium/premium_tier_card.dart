import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/premium.dart';
import '../../blocs/premium/premium_bloc.dart';
import '../../blocs/premium/premium_event.dart';
import '../common/pulse_button.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';

/// Premium tier card with features and pricing
class PremiumTierCard extends StatefulWidget {
  const PremiumTierCard({
    super.key,
    required this.tier,
    this.isSelected = false,
    this.onSelect,
    this.showMonthlyPrice = true,
  });

  final PremiumTier tier;
  final bool isSelected;
  final VoidCallback? onSelect;
  final bool showMonthlyPrice;

  @override
  State<PremiumTierCard> createState() => _PremiumTierCardState();
}

class _PremiumTierCardState extends State<PremiumTierCard>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late AnimationController _selectionController;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _selectionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _selectionController, curve: Curves.easeOut),
    );

    if (widget.tier == PremiumTier.premium) {
      _shimmerController.repeat();
    }
  }

  @override
  void didUpdateWidget(PremiumTierCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _selectionController.forward();
      } else {
        _selectionController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _selectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTap: widget.onSelect,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: widget.isSelected
                    ? LinearGradient(
                        colors: [context.primaryColor, context.accentColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: widget.isSelected ? null : Colors.white,
                border: Border.all(
                  color: widget.isSelected
                      ? Colors.transparent
                      : widget.tier == PremiumTier.premium
                      ? context.primaryColor
                      : context.outlineColor.shade300,
                  width: widget.tier == PremiumTier.premium ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.isSelected
                        ? context.primaryColor.withValues(alpha: 0.3)
                        : context.outlineColor.withValues(alpha: 0.2),
                    blurRadius: widget.isSelected ? 20 : 10,
                    offset: const Offset(0, 5),
                    spreadRadius: widget.isSelected ? 2 : 0,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Shimmer effect for premium plans
                  if (widget.tier == PremiumTier.premium && !widget.isSelected)
                    _buildShimmerEffect(),

                  // Main content
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with badge
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.tier.displayName,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: widget.isSelected
                                          ? Colors.white
                                          : context.onSurfaceColor,
                                    ),
                                  ),
                                  Text(
                                    _getDescription(),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: widget.isSelected
                                          ? Colors.white70
                                          : context.onSurfaceVariantColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (widget.tier == PremiumTier.premium)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: widget.isSelected
                                      ? Colors.white
                                      : context.primaryColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'POPULAR',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: widget.isSelected
                                        ? context.primaryColor
                                        : Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Pricing
                        if (widget.tier != PremiumTier.free)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                widget.tier.formattedPrice,
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: widget.isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            'Free',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: widget.isSelected
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),

                        const SizedBox(height: 20),

                        // Features list
                        ...widget.tier.features.map(
                          (feature) => _buildFeatureItem(feature),
                        ),

                        const SizedBox(height: 20),

                        // CTA Button
                        if (widget.isSelected &&
                            widget.tier != PremiumTier.free)
                          PulseButton(
                            text: 'Get ${widget.tier.displayName}',
                            onPressed: () {
                              context.read<PremiumBloc>().add(
                                SubscribeToPlan(
                                  planId: widget.tier.name,
                                  paymentMethodId:
                                      'default', // This would come from payment selection
                                ),
                              );
                            },
                            variant: PulseButtonVariant.secondary,
                          ),
                      ],
                    ),
                  ),

                  // Selection indicator
                  if (widget.isSelected)
                    Positioned(
                      top: 15,
                      right: 15,
                      child: Container(
                        decoration: BoxDecoration(
                          color: context.onSurfaceColor,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.check,
                          color: context.primaryColor,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerEffect() {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    context.primaryColor.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                  stops: [
                    (_shimmerAnimation.value - 0.3).clamp(0.0, 1.0),
                    _shimmerAnimation.value.clamp(0.0, 1.0),
                    (_shimmerAnimation.value + 0.3).clamp(0.0, 1.0),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureItem(PremiumFeature feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(feature.icon, style: TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              feature.displayName,
              style: TextStyle(
                fontSize: 14,
                color: widget.isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDescription() {
    switch (widget.tier) {
      case PremiumTier.free:
        return 'Basic features to get started';
      case PremiumTier.basic:
        return 'Enhanced matching with premium features';
      case PremiumTier.premium:
        return 'Complete dating experience with all features';
      case PremiumTier.elite:
        return 'Exclusive VIP experience with concierge service';
    }
  }
}
