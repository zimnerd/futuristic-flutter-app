import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/premium.dart';
import '../../blocs/premium/premium_bloc.dart';
import '../../blocs/premium/premium_event.dart';
import '../../theme/pulse_colors.dart';
import '../common/pulse_button.dart';

/// Premium subscription card with features and pricing
class PremiumSubscriptionCard extends StatefulWidget {
  const PremiumSubscriptionCard({
    super.key,
    required this.plan,
    this.isSelected = false,
    this.onSelect,
    this.showDiscount = false,
  });

  final PremiumPlan plan;
  final bool isSelected;
  final VoidCallback? onSelect;
  final bool showDiscount;

  @override
  State<PremiumSubscriptionCard> createState() => _PremiumSubscriptionCardState();
}

class _PremiumSubscriptionCardState extends State<PremiumSubscriptionCard>
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
    
    if (widget.plan.isPopular) {
      _shimmerController.repeat();
    }
  }

  @override
  void didUpdateWidget(PremiumSubscriptionCard oldWidget) {
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
                    ? const LinearGradient(
                        colors: [PulseColors.primary, PulseColors.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: widget.isSelected ? null : Colors.white,
                border: Border.all(
                  color: widget.isSelected 
                      ? Colors.transparent 
                      : widget.plan.isPopular
                          ? PulseColors.primary
                          : Colors.grey.shade300,
                  width: widget.plan.isPopular ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.isSelected 
                        ? PulseColors.primary.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.1),
                    blurRadius: widget.isSelected ? 20 : 10,
                    offset: const Offset(0, 5),
                    spreadRadius: widget.isSelected ? 2 : 0,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Shimmer effect for popular plans
                  if (widget.plan.isPopular && !widget.isSelected)
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
                                    widget.plan.name,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: widget.isSelected 
                                          ? Colors.white 
                                          : Colors.black87,
                                    ),
                                  ),
                                  if (widget.plan.description.isNotEmpty)
                                    Text(
                                      widget.plan.description,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: widget.isSelected 
                                            ? Colors.white70 
                                            : Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (widget.plan.isPopular)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: widget.isSelected 
                                      ? Colors.white 
                                      : PulseColors.primary,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'POPULAR',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: widget.isSelected 
                                        ? PulseColors.primary 
                                        : Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Pricing
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${(widget.plan.priceInCents / 100).toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: widget.isSelected 
                                    ? Colors.white 
                                    : Colors.black87,
                              ),
                            ),
                            Text(
                              '/${widget.plan.interval}',
                              style: TextStyle(
                                fontSize: 16,
                                color: widget.isSelected 
                                    ? Colors.white70 
                                    : Colors.grey[600],
                              ),
                            ),
                            if (widget.showDiscount && (widget.plan.discountPercent ?? 0) > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '-${widget.plan.discountPercent}%',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        
                        if (widget.plan.promoText?.isNotEmpty == true)
                          Text(
                            widget.plan.promoText!,
                            style: TextStyle(
                              fontSize: 14,
                              color: widget.isSelected 
                                  ? Colors.white60 
                                  : Colors.grey[500],
                            ),
                          ),
                        
                        const SizedBox(height: 20),
                        
                        // Features list
                        ...widget.plan.features.map((feature) =>
                          _buildFeatureItem(feature),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // CTA Button
                        if (widget.isSelected)
                          PulseButton(
                            text: 'Get ${widget.plan.name}',
                            onPressed: () {
                              context.read<PremiumBloc>().add(
                                SubscribeToPlan(
                                  planId: widget.plan.id,
                                  paymentMethodId: 'default', // TODO: Implement payment method selection
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
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.check,
                          color: PulseColors.primary,
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
                    PulseColors.primary.withValues(alpha: 0.1),
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

  Widget _buildFeatureItem(String feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            size: 20,
            color: widget.isSelected 
                ? Colors.white 
                : PulseColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              feature,
              style: TextStyle(
                fontSize: 14,
                color: widget.isSelected 
                    ? Colors.white 
                    : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
