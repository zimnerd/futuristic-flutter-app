import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/coin_package.dart';
import '../../core/theme/app_colors.dart';
import '../blocs/coin_purchase/coin_purchase_bloc.dart';
import '../blocs/coin_purchase/coin_purchase_event.dart';
import '../blocs/coin_purchase/coin_purchase_state.dart';
import '../blocs/premium/premium_bloc.dart';
import '../blocs/premium/premium_event.dart';
import '../blocs/premium/premium_state.dart';
import '../widgets/premium/coin_package_card.dart';
import '../widgets/common/pulse_toast.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';

/// Bottom sheet for purchasing coin packages
///
/// Features:
/// - Display coin packages with pricing
/// - Show current coin balance
/// - Payment method selection
/// - Purchase button with loading states
/// - Success/error handling
class CoinPurchaseSheet extends StatefulWidget {
  final String?
  reason; // Optional reason for showing sheet (e.g., "boost", "super_like")

  const CoinPurchaseSheet({super.key, this.reason});

  @override
  State<CoinPurchaseSheet> createState() => _CoinPurchaseSheetState();
}

class _CoinPurchaseSheetState extends State<CoinPurchaseSheet>
    with SingleTickerProviderStateMixin {
  CoinPackage? _selectedPackage;
  late AnimationController _coinAnimationController;
  late Animation<double> _coinAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize coin animation
    _coinAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _coinAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _coinAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _coinAnimationController.repeat(reverse: true);

    // Load payment methods
    context.read<CoinPurchaseBloc>().add(const LoadPaymentMethods());
  }

  @override
  void dispose() {
    _coinAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CoinPurchaseBloc, CoinPurchaseState>(
      listener: (context, state) {
        if (state is CoinPurchaseSuccess) {
          // Haptic feedback on success
          HapticFeedback.heavyImpact();

          // Show success message
          PulseToast.success(
            context,
            message: 'Successfully purchased ${state.coinsAdded} coins!',
          );

          // Refresh coin balance
          context.read<PremiumBloc>().add(LoadCoinBalance());

          // Close sheet after delay
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) {
              Navigator.pop(context, true);
            }
          });
        } else if (state is CoinPurchaseError) {
          // Haptic feedback on error
          HapticFeedback.mediumImpact();

          // Show error message
          PulseToast.error(context, message: state.message);
        }
      },
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.outlineColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Header with coin animation
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  // Animated coin icon
                  AnimatedBuilder(
                    animation: _coinAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1.0 + (_coinAnimation.value * 0.1),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.amber.shade400,
                                Colors.amber.shade600,
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withValues(alpha: 0.4),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.monetization_on,
                            color: context.theme.colorScheme.onPrimary,
                            size: 28,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Buy Coins',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: context.onSurfaceColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        BlocBuilder<PremiumBloc, PremiumState>(
                          builder: (context, state) {
                            int balance = 0;
                            if (state is PremiumLoaded) {
                              balance = state.coinBalance.totalCoins;
                            }
                            return Row(
                              children: [
                                Icon(
                                  Icons.account_balance_wallet,
                                  size: 14,
                                  color: context.onSurfaceVariantColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Current Balance: $balance coins',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: context.onSurfaceVariantColor,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: context.onSurfaceColor),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Reason badge if provided
            if (widget.reason != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getReasonIcon(widget.reason!),
                      color: context.theme.colorScheme.onPrimary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getReasonText(widget.reason!),
                        style: TextStyle(
                          color: context.theme.colorScheme.onPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (widget.reason != null) const SizedBox(height: 16),

            // What can you do with coins section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.outlineColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.tips_and_updates,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'What can you do with coins?',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: context.onSurfaceColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildCoinUsageItem(
                    Icons.rocket_launch,
                    'Boost your profile',
                    '5 coins',
                    AppColors.primary,
                  ),
                  _buildCoinUsageItem(
                    Icons.star,
                    'Send Super Likes',
                    '1 coin',
                    Colors.amber,
                  ),
                  _buildCoinUsageItem(
                    Icons.visibility,
                    'See who viewed you',
                    '3 coins',
                    AppColors.accent,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Coin packages
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: CoinPackages.all.length,
                itemBuilder: (context, index) {
                  final package = CoinPackages.all[index];
                  final isSelected = _selectedPackage?.id == package.id;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedPackage = package;
                        });
                        HapticFeedback.selectionClick();
                      },
                      child: CoinPackageCard(
                        package: package,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            _selectedPackage = package;
                          });
                          HapticFeedback.selectionClick();
                        },
                        isLoading: false,
                      ),
                    ),
                  );
                },
              ),
            ),

            // Purchase button
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                border: Border(
                  top: BorderSide(color: context.outlineColor, width: 1),
                ),
              ),
              child: BlocBuilder<CoinPurchaseBloc, CoinPurchaseState>(
                builder: (context, state) {
                  final isLoading = state is CoinPurchaseLoading;
                  final canPurchase = _selectedPackage != null && !isLoading;

                  return Column(
                    children: [
                      if (state is CoinPurchaseError)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: context.errorColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: context.errorColor),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: context.errorColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  state.message,
                                  style: TextStyle(
                                    color: context.errorColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: canPurchase ? _handlePurchase : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            disabledBackgroundColor: AppColors.disabled,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: isLoading
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              context.theme.colorScheme.onPrimary,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      state.message ?? 'Processing...',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: context.theme.colorScheme.onPrimary,
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.lock,
                                      size: 18,
                                      color: context.theme.colorScheme.onPrimary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _selectedPackage != null
                                          ? 'Purchase ${_selectedPackage!.totalCoins} Coins for ${_selectedPackage!.priceDisplay}'
                                          : 'Select a Package',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: context.theme.colorScheme.onPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        'Secure payment • Coins never expire',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoinUsageItem(
    IconData icon,
    String text,
    String coins,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: context.onSurfaceColor,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(
              coins,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handlePurchase() {
    if (_selectedPackage == null) return;

    // Add haptic feedback
    HapticFeedback.mediumImpact();

    // Trigger purchase
    context.read<CoinPurchaseBloc>().add(
      PurchaseCoinsRequested(
        coinPackageId: _selectedPackage!.id,
        coins: _selectedPackage!.totalCoins,
        price: _selectedPackage!.price,
      ),
    );
  }

  IconData _getReasonIcon(String reason) {
    switch (reason.toLowerCase()) {
      case 'boost':
        return Icons.rocket_launch;
      case 'super_like':
        return Icons.star;
      case 'view_profile':
        return Icons.visibility;
      default:
        return Icons.info_outline;
    }
  }

  String _getReasonText(String reason) {
    switch (reason.toLowerCase()) {
      case 'boost':
        return 'You need 5 coins to boost your profile';
      case 'super_like':
        return 'You need 1 coin to send a Super Like';
      case 'view_profile':
        return 'You need 3 coins to see who viewed you';
      default:
        return 'Get coins to unlock premium features';
    }
  }
}
