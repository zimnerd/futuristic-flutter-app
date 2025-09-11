import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../presentation/blocs/payment/payment_bloc.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../domain/entities/payment_entities.dart';

/// Payment processing screen for handling different payment types
class PaymentProcessingScreen extends StatefulWidget {
  final PaymentType paymentType;
  final String? productId;
  final double? amount;
  final String? description;

  const PaymentProcessingScreen({
    super.key,
    required this.paymentType,
    this.productId,
    this.amount,
    this.description,
  });

  @override
  State<PaymentProcessingScreen> createState() => _PaymentProcessingScreenState();
}

class _PaymentProcessingScreenState extends State<PaymentProcessingScreen> {
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  PaymentMethod? _selectedPaymentMethod;
  bool _saveCard = false;

  @override
  void initState() {
    super.initState();
    // Load user's saved payment methods
    context.read<PaymentBloc>().add(LoadPaymentMethodsEvent());
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _getAppBarTitle(),
          style: AppTextStyles.headlineSmall,
        ),
      ),
      body: BlocConsumer<PaymentBloc, PaymentState>(
        listener: (context, state) {
          if (state is PaymentSuccess) {
            _showSuccessDialog();
          } else if (state is PaymentError) {
            _showErrorDialog(state.message);
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildOrderSummary(),
                            const SizedBox(height: 24),
                            _buildPaymentMethodSelection(state),
                            const SizedBox(height: 24),
                            if (_selectedPaymentMethod == null) ...[
                              _buildNewCardForm(),
                              const SizedBox(height: 16),
                              _buildSaveCardOption(),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  _buildPaymentButton(state),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getAppBarTitle() {
    switch (widget.paymentType) {
      case PaymentType.boost:
        return 'Boost Purchase';
      case PaymentType.premium:
        return 'Premium Subscription';
      case PaymentType.gift:
        return 'Send Gift';
      case PaymentType.credit:
        return 'Buy Credits';
    }
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.description ?? _getDefaultDescription(),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '\$${widget.amount?.toStringAsFixed(2) ?? _getDefaultAmount()}',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          if (widget.paymentType == PaymentType.premium) ...[
            const SizedBox(height: 8),
            Text(
              'Billed monthly, cancel anytime',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSelection(PaymentState state) {
    if (state is PaymentMethodsLoaded && state.paymentMethods.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Method',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...state.paymentMethods.map((methodData) => 
            _buildPaymentMethodTile(PaymentMethod.fromJson(methodData))),
          _buildAddNewCardTile(),
        ],
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method',
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Add a payment method to continue',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodTile(PaymentMethod method) {
    final isSelected = _selectedPaymentMethod?.id == method.id;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = isSelected ? null : method;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _getCardIcon(method.cardType),
              size: 24,
              color: AppColors.textPrimary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '**** **** **** ${method.lastFourDigits}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${method.cardType.toUpperCase()} • Expires ${method.expiryDate}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddNewCardTile() {
    final isSelected = _selectedPaymentMethod == null;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = null;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.add_circle_outline,
              size: 24,
              color: AppColors.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Add new payment method',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewCardForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Card Information',
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: _cardNumberController,
          label: 'Card Number',
          placeholder: '1234 5678 9012 3456',
          keyboardType: TextInputType.number,
          validator: _validateCardNumber,
          isRequired: true,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: _expiryController,
                label: 'Expiry Date',
                placeholder: 'MM/YY',
                keyboardType: TextInputType.number,
                validator: _validateExpiryDate,
                isRequired: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AppTextField(
                controller: _cvvController,
                label: 'CVV',
                placeholder: '123',
                keyboardType: TextInputType.number,
                validator: _validateCVV,
                isRequired: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: _nameController,
          label: 'Cardholder Name',
          placeholder: 'John Doe',
          keyboardType: TextInputType.name,
          validator: _validateCardholderName,
          isRequired: true,
        ),
      ],
    );
  }

  Widget _buildSaveCardOption() {
    return Row(
      children: [
        Checkbox(
          value: _saveCard,
          onChanged: (value) {
            setState(() {
              _saveCard = value ?? false;
            });
          },
          activeColor: AppColors.primary,
        ),
        Expanded(
          child: Text(
            'Save this card for future purchases',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentButton(PaymentState state) {
    final isLoading = state is PaymentLoading;
    final canProceed = _selectedPaymentMethod != null || _isNewCardFormValid();
    
    return AppButton(
      text: isLoading ? 'Processing...' : 'Complete Payment',
      onPressed: canProceed ? _processPayment : null,
      isLoading: isLoading,
      variant: AppButtonVariant.primary,
    );
  }

  bool _isNewCardFormValid() {
    return _cardNumberController.text.isNotEmpty &&
           _expiryController.text.isNotEmpty &&
           _cvvController.text.isNotEmpty &&
           _nameController.text.isNotEmpty;
  }

  void _processPayment() {
    if (_selectedPaymentMethod != null) {
      // Use existing payment method
      _processWithExistingMethod();
    } else {
      // Validate new card form
      if (_formKey.currentState?.validate() ?? false) {
        _processWithNewCard();
      }
    }
  }

  void _processWithExistingMethod() {
    switch (widget.paymentType) {
      case PaymentType.boost:
      case PaymentType.gift:
      case PaymentType.credit:
        context.read<PaymentBloc>().add(
          ProcessBoostPaymentEvent(
            boostType: widget.paymentType.name,
            paymentMethodId: _selectedPaymentMethod!.id,
          ),
        );
        break;
      case PaymentType.premium:
        context.read<PaymentBloc>().add(
          ProcessSubscriptionPaymentEvent(
            planId: widget.productId ?? 'premium_monthly',
            paymentMethodId: _selectedPaymentMethod!.id,
          ),
        );
        break;
    }
  }

  void _processWithNewCard() {
    final newPaymentMethod = PaymentMethod(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: 'current_user', // This should come from auth state
      cardType: _detectCardType(_cardNumberController.text),
      lastFourDigits: _cardNumberController.text.substring(_cardNumberController.text.length - 4),
      expiryDate: _expiryController.text,
      cardholderName: _nameController.text,
      isDefault: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    switch (widget.paymentType) {
      case PaymentType.boost:
      case PaymentType.gift:
      case PaymentType.credit:
        context.read<PaymentBloc>().add(
          ProcessBoostPaymentEvent(
            boostType: widget.paymentType.name,
            paymentMethodId: newPaymentMethod.id,
          ),
        );
        break;
      case PaymentType.premium:
        context.read<PaymentBloc>().add(
          ProcessSubscriptionPaymentEvent(
            planId: widget.productId ?? 'premium_monthly',
            paymentMethodId: newPaymentMethod.id,
          ),
        );
        break;
    }
  }

  String _getDefaultDescription() {
    switch (widget.paymentType) {
      case PaymentType.boost:
        return 'Profile Boost - 24 hours';
      case PaymentType.premium:
        return 'Premium Subscription - Monthly';
      case PaymentType.gift:
        return 'Virtual Gift';
      case PaymentType.credit:
        return 'App Credits';
    }
  }

  String _getDefaultAmount() {
    switch (widget.paymentType) {
      case PaymentType.boost:
        return '9.99';
      case PaymentType.premium:
        return '19.99';
      case PaymentType.gift:
        return '4.99';
      case PaymentType.credit:
        return '14.99';
    }
  }

  IconData _getCardIcon(String cardType) {
    switch (cardType.toLowerCase()) {
      case 'visa':
        return Icons.credit_card;
      case 'mastercard':
        return Icons.credit_card;
      case 'amex':
        return Icons.credit_card;
      default:
        return Icons.credit_card;
    }
  }

  String _detectCardType(String cardNumber) {
    final cleaned = cardNumber.replaceAll(RegExp(r'\D'), '');
    
    if (cleaned.startsWith('4')) {
      return 'visa';
    } else if (cleaned.startsWith(RegExp(r'5[1-5]')) || cleaned.startsWith(RegExp(r'2[2-7]'))) {
      return 'mastercard';
    } else if (cleaned.startsWith(RegExp(r'3[47]'))) {
      return 'amex';
    }
    
    return 'unknown';
  }

  String? _validateCardNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Card number is required';
    }
    
    final cleaned = value.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length < 13 || cleaned.length > 19) {
      return 'Please enter a valid card number';
    }
    
    return null;
  }

  String? _validateExpiryDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Expiry date is required';
    }
    
    final parts = value.split('/');
    if (parts.length != 2) {
      return 'Use MM/YY format';
    }
    
    final month = int.tryParse(parts[0]);
    final year = int.tryParse(parts[1]);
    
    if (month == null || year == null || month < 1 || month > 12) {
      return 'Please enter a valid expiry date';
    }
    
    final now = DateTime.now();
    final expiry = DateTime(2000 + year, month);
    
    if (expiry.isBefore(now)) {
      return 'Card has expired';
    }
    
    return null;
  }

  String? _validateCVV(String? value) {
    if (value == null || value.isEmpty) {
      return 'CVV is required';
    }
    
    if (value.length < 3 || value.length > 4) {
      return 'Please enter a valid CVV';
    }
    
    return null;
  }

  String? _validateCardholderName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Cardholder name is required';
    }
    
    if (value.length < 2) {
      return 'Please enter a valid name';
    }
    
    return null;
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            'Payment Successful!',
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.success,
            ),
          ),
          content: Text(
            'Your payment has been processed successfully.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            AppButton(
              text: 'Continue',
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to previous screen
              },
              variant: AppButtonVariant.primary,
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            'Payment Failed',
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.error,
            ),
          ),
          content: Text(
            message,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            AppButton(
              text: 'Try Again',
              onPressed: () => Navigator.of(context).pop(),
              variant: AppButtonVariant.secondary,
            ),
          ],
        );
      },
    );
  }
}
