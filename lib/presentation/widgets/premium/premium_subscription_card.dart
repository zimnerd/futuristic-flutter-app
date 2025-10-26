import 'package:flutter/material.dart';
import '../../../data/models/premium.dart';
import '../common/pulse_button.dart';
import '../common/pulse_toast.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';

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
  State<PremiumSubscriptionCard> createState() =>
      _PremiumSubscriptionCardState();
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
                      : widget.plan.isPopular
                      ? context.primaryColor
                      : context.outlineColor.shade300,
                  width: widget.plan.isPopular ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.isSelected
                        ? context.primaryColor.withValues(alpha: 0.3)
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
                                            : context.onSurfaceVariantColor,
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
                                    : context.onSurfaceVariantColor,
                              ),
                            ),
                            if (widget.showDiscount &&
                                (widget.plan.discountPercent ?? 0) > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: context.errorColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '-${widget.plan.discountPercent}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: context.onSurfaceColor,
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
                                  : context.onSurfaceVariantColor.withValues(alpha: 0.6),
                            ),
                          ),

                        const SizedBox(height: 20),

                        // Features list
                        ...widget.plan.features.map(
                          (feature) => _buildFeatureItem(feature),
                        ),

                        const SizedBox(height: 20),

                        // CTA Button
                        if (widget.isSelected)
                          PulseButton(
                            text: 'Get ${widget.plan.name}',
                            onPressed: () {
                              _showPaymentMethodSelection();
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

  Widget _buildFeatureItem(String feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            size: 20,
            color: widget.isSelected ? Colors.white : context.primaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              feature,
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

  void _showPaymentMethodSelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.8,
        minChildSize: 0.4,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Payment Method',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Payment methods list
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildPaymentMethodTile(
                      icon: Icons.credit_card,
                      title: 'Credit/Debit Card',
                      subtitle: 'Visa, Mastercard, American Express',
                      onTap: () => _selectPaymentMethod('card'),
                    ),
                    const SizedBox(height: 12),
                    _buildPaymentMethodTile(
                      icon: Icons.account_balance,
                      title: 'Bank Transfer',
                      subtitle: 'Direct bank transfer',
                      onTap: () => _selectPaymentMethod('bank'),
                    ),
                    const SizedBox(height: 12),
                    _buildPaymentMethodTile(
                      icon: Icons.account_balance_wallet,
                      title: 'Digital Wallet',
                      subtitle: 'PayPal, Apple Pay, Google Pay',
                      onTap: () => _selectPaymentMethod('wallet'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 32, color: Colors.blue),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  void _selectPaymentMethod(String paymentType) {
    Navigator.of(context).pop();

    // Show payment method selected feedback
    if (mounted) {
      PulseToast.info(
        context,
        message: 'Selected payment method: $paymentType',
      );
    }

    // In a real implementation, this would proceed with the subscription process
    // using the selected payment method
    _proceedWithSubscription(paymentType);
  }

  void _proceedWithSubscription(String paymentMethodType) {
    // Add back the removed import and bloc call
    // For now, just show a placeholder
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Subscription'),
        content: Text(
          'Proceeding with ${widget.plan.name} subscription using $paymentMethodType',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
