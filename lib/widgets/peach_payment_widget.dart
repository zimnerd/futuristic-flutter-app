import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/services/payment_service.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';

/// PeachPayments integration widget for processing payments
class PeachPaymentWidget extends StatefulWidget {
  final String checkoutId;
  final double amount;
  final String currency;
  final Function(Map<String, dynamic>) onPaymentResult;
  final VoidCallback? onCancel;

  const PeachPaymentWidget({
    super.key,
    required this.checkoutId,
    required this.amount,
    required this.currency,
    required this.onPaymentResult,
    this.onCancel,
  });

  @override
  State<PeachPaymentWidget> createState() => _PeachPaymentWidgetState();
}

class _PeachPaymentWidgetState extends State<PeachPaymentWidget> {
  bool _isProcessing = false;
  String? _error;
  String _selectedPaymentMethod = 'card';

  // Card form controllers
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardHolderController = TextEditingController();

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardHolderController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (_selectedPaymentMethod == 'card' && !_validateCardForm()) return;

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      // For now, simulate payment processing by checking status
      // In a real implementation, you would submit the payment data to PeachPayments
      final result = await PaymentService.instance.checkPeachPaymentStatus(
        widget.checkoutId,
      );
      widget.onPaymentResult(result);
    } catch (e) {
      setState(() {
        _error = 'Payment failed: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  bool _validateCardForm() {
    if (_cardNumberController.text.replaceAll(' ', '').length < 13) {
      setState(() {
        _error = 'Please enter a valid card number';
      });
      return false;
    }

    if (_expiryController.text.length != 5 ||
        !_expiryController.text.contains('/')) {
      setState(() {
        _error = 'Please enter a valid expiry date (MM/YY)';
      });
      return false;
    }

    if (_cvvController.text.length < 3) {
      setState(() {
        _error = 'Please enter a valid CVV';
      });
      return false;
    }

    if (_cardHolderController.text.trim().isEmpty) {
      setState(() {
        _error = 'Please enter the cardholder name';
      });
      return false;
    }

    return true;
  }

  String _formatCardNumber(String value) {
    value = value.replaceAll(' ', '');
    String formatted = '';
    for (int i = 0; i < value.length; i++) {
      if (i > 0 && i % 4 == 0) {
        formatted += ' ';
      }
      formatted += value[i];
    }
    return formatted;
  }

  String _formatExpiry(String value) {
    value = value.replaceAll('/', '');
    if (value.length >= 2) {
      return '${value.substring(0, 2)}/${value.substring(2)}';
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Secure Payment', style: AppTextStyles.headlineSmall),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: widget.onCancel ?? () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: _isProcessing ? _buildLoadingState() : _buildPaymentForm(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }

  Widget _buildPaymentForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Payment summary
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.textSecondary.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Text('Payment Summary', style: AppTextStyles.titleMedium),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Amount:',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${widget.currency} ${widget.amount.toStringAsFixed(2)}',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Payment method selection
          Text('Payment Method', style: AppTextStyles.titleMedium),
          const SizedBox(height: 16),

          _buildPaymentMethodSelector(),

          const SizedBox(height: 32),

          // Payment form based on selected method
          if (_selectedPaymentMethod == 'card') _buildCardForm(),
          if (_selectedPaymentMethod != 'card') _buildExternalPaymentInfo(),

          if (_error != null) ...[
            const SizedBox(height: 16),
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
          ],

          const SizedBox(height: 32),

          AppButton(
            text: _isProcessing ? 'Processing...' : 'Pay Now',
            onPressed: _isProcessing ? null : _processPayment,
            isLoading: _isProcessing,
          ),

          const SizedBox(height: 16),

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
                    'Your payment is secured by PeachPayments with 256-bit SSL encryption',
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
    );
  }

  Widget _buildPaymentMethodSelector() {
    final methods = [
      {'key': 'card', 'label': 'Credit/Debit Card', 'icon': Icons.credit_card},
      {
        'key': 'paypal',
        'label': 'PayPal',
        'icon': Icons.account_balance_wallet,
      },
      {'key': 'applepay', 'label': 'Apple Pay', 'icon': Icons.phone_iphone},
      {
        'key': 'googlepay',
        'label': 'Google Pay',
        'icon': Icons.account_balance_wallet,
      },
    ];

    return Column(
      children: methods.map((method) {
        final isSelected = _selectedPaymentMethod == method['key'];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedPaymentMethod = method['key'] as String;
                _error = null;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary.withValues(alpha: 0.3),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    method['icon'] as IconData,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      method['label'] as String,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle, color: AppColors.primary),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCardForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Card Details', style: AppTextStyles.titleMedium),
        const SizedBox(height: 16),

        AppTextField(
          label: 'Card Number',
          controller: _cardNumberController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(19),
            TextInputFormatter.withFunction((oldValue, newValue) {
              return TextEditingValue(
                text: _formatCardNumber(newValue.text),
                selection: TextSelection.collapsed(
                  offset: _formatCardNumber(newValue.text).length,
                ),
              );
            }),
          ],
        ),

        const SizedBox(height: 16),

        AppTextField(
          label: 'Cardholder Name',
          controller: _cardHolderController,
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: 'MM/YY',
                controller: _expiryController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    return TextEditingValue(
                      text: _formatExpiry(newValue.text),
                      selection: TextSelection.collapsed(
                        offset: _formatExpiry(newValue.text).length,
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: AppTextField(
                label: 'CVV',
                controller: _cvvController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                obscureText: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExternalPaymentInfo() {
    String description = '';
    IconData icon = Icons.payment;

    switch (_selectedPaymentMethod) {
      case 'paypal':
        description =
            'You will be redirected to PayPal to complete your payment securely.';
        icon = Icons.account_balance_wallet;
        break;
      case 'applepay':
        description = 'Use Touch ID or Face ID to pay with Apple Pay.';
        icon = Icons.phone_iphone;
        break;
      case 'googlepay':
        description = 'Pay quickly and securely with Google Pay.';
        icon = Icons.account_balance_wallet;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            description,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Helper function to show PeachPayments widget
void showPeachPaymentWidget({
  required BuildContext context,
  required String checkoutId,
  required double amount,
  required String currency,
  required Function(Map<String, dynamic>) onPaymentResult,
  VoidCallback? onCancel,
}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => PeachPaymentWidget(
        checkoutId: checkoutId,
        amount: amount,
        currency: currency,
        onPaymentResult: onPaymentResult,
        onCancel: onCancel,
      ),
      fullscreenDialog: true,
    ),
  );
}
