import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/logger.dart';
import '../widgets/app_button.dart';
import '../widgets/peach_payment_widget.dart';
import '../data/services/payment_service.dart';

/// Demo screen to show PeachPayments integration
class PaymentDemoScreen extends StatefulWidget {
  const PaymentDemoScreen({super.key});

  @override
  State<PaymentDemoScreen> createState() => _PaymentDemoScreenState();
}

class _PaymentDemoScreenState extends State<PaymentDemoScreen> {
  bool _isCreatingCheckout = false;
  String? _error;
  Map<String, dynamic>? _lastResult;

  Future<void> _startPayment() async {
    setState(() {
      _isCreatingCheckout = true;
      _error = null;
    });

    try {
      // Create a checkout session with PeachPayments
      final checkoutResult = await PaymentService.instance.createPeachCheckout(
        amount: 99.99,
        currency: 'USD',
        paymentType: 'DB',
      );

      if (checkoutResult['success'] == true &&
          checkoutResult['checkoutId'] != null) {
        // Show the payment widget
        if (mounted) {
          showPeachPaymentWidget(
            context: context,
            checkoutId: checkoutResult['checkoutId'],
            amount: 99.99,
            currency: 'USD',
            onPaymentResult: _handlePaymentResult,
            onCancel: () {
              Navigator.of(context).pop();
              AppLogger.info('Payment cancelled by user');
            },
          );
        }
      } else {
        setState(() {
          _error =
              checkoutResult['error'] ?? 'Failed to create checkout session';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to start payment: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isCreatingCheckout = false;
      });
    }
  }

  void _handlePaymentResult(Map<String, dynamic> result) {
    setState(() {
      _lastResult = result;
    });

    Navigator.of(context).pop(); // Close payment widget

    if (result['success'] == true) {
      _showSuccessDialog();
    } else {
      _showErrorDialog(result['error'] ?? 'Payment failed');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success, size: 28),
              const SizedBox(width: 12),
              Text(
                'Payment Successful',
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          content: Text(
            'Your payment has been processed successfully. You now have access to premium features!',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Go back to previous screen
              },
              child: Text(
                'Continue',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.error_outline, color: AppColors.error, size: 28),
              const SizedBox(width: 12),
              Text(
                'Payment Failed',
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          content: Text(
            error,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Try Again',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Payment Demo', style: AppTextStyles.headlineSmall),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Premium subscription card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          color: AppColors.textOnPrimary,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Premium Subscription',
                          style: AppTextStyles.titleLarge.copyWith(
                            color: AppColors.textOnPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Unlock all premium features including:',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textOnPrimary.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: [
                        _buildFeatureItem('✓ Unlimited matches'),
                        _buildFeatureItem('✓ Advanced filters'),
                        _buildFeatureItem('✓ Priority support'),
                        _buildFeatureItem('✓ Ad-free experience'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$99.99 USD',
                          style: AppTextStyles.headlineSmall.copyWith(
                            color: AppColors.textOnPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'per year',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textOnPrimary.withValues(
                              alpha: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Payment button
              AppButton(
                text: _isCreatingCheckout
                    ? 'Creating Checkout...'
                    : 'Purchase Premium',
                onPressed: _isCreatingCheckout ? null : _startPayment,
                isLoading: _isCreatingCheckout,
              ),

              const SizedBox(height: 16),

              // Error display
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: AppColors.error),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _error!,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Last result display (for debugging)
              if (_lastResult != null) ...[
                const Divider(color: AppColors.textSecondary),
                const SizedBox(height: 16),
                Text('Last Payment Result:', style: AppTextStyles.titleMedium),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.textSecondary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    _lastResult.toString(),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],

              const Spacer(),

              // Security notice
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.security, color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Payments are processed securely by PeachPayments with bank-level encryption',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
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

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Text(
            text,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textOnPrimary.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}
