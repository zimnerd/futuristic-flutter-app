import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/payment/payment_bloc.dart';
import '../../../data/services/payment_service.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_text_field.dart';
import '../../widgets/common/keyboard_dismissible_scaffold.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../screens/payment_demo_screen.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  @override
  void initState() {
    super.initState();
    // Load payment methods when screen opens
    context.read<PaymentBloc>().add(LoadPaymentMethodsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardDismissibleScaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Payment Methods',
          style: AppTextStyles.heading2.copyWith(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      body: BlocConsumer<PaymentBloc, PaymentState>(
        listener: (context, state) {
          if (state is PaymentError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          } else if (state is PaymentSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is PaymentLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is PaymentMethodsLoaded) {
            return _buildPaymentMethodsList(state.paymentMethods);
          }

          return _buildEmptyState();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPaymentMethodDialog(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildPaymentMethodsList(List<Map<String, dynamic>> paymentMethods) {
    if (paymentMethods.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: paymentMethods.length + 1, // +1 for demo button
      itemBuilder: (context, index) {
        if (index == paymentMethods.length) {
          // Demo button at the end
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: AppButton(
              text: 'Try Payment Demo',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const PaymentDemoScreen(),
                  ),
                );
              },
              variant: AppButtonVariant.outline,
            ),
          );
        }
        
        final method = paymentMethods[index];
        return _buildPaymentMethodCard(method);
      },
    );
  }

  Widget _buildPaymentMethodCard(Map<String, dynamic> method) {
    final type = method['type'] as String? ?? 'Unknown';
    final last4 = method['last4'] as String? ?? '****';
    final brand = method['brand'] as String? ?? '';
    final isDefault = method['isDefault'] as bool? ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: isDefault
            ? Border.all(color: AppColors.primary, width: 2)
            : Border.all(color: AppColors.cardBorder),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: _getPaymentMethodIcon(type),
        title: Text(
          '$brand **** $last4',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          type.toUpperCase(),
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isDefault)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Default',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _showDeleteConfirmation(context, method),
              icon: Icon(Icons.delete_outline, color: AppColors.error),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getPaymentMethodIcon(String type) {
    IconData iconData;
    Color iconColor = AppColors.primary;

    switch (type.toLowerCase()) {
      case 'credit_card':
      case 'debit_card':
        iconData = Icons.credit_card;
        break;
      case 'apple_pay':
        iconData = Icons.apple;
        break;
      case 'google_pay':
        iconData = Icons.account_balance_wallet; // Using wallet icon for Google Pay
        break;
      case 'paypal':
        iconData = Icons.payment;
        break;
      default:
        iconData = Icons.payment;
    }

    return Icon(iconData, color: iconColor, size: 32);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.credit_card_off,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No Payment Methods',
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a payment method to purchase premium features',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          AppButton(
            text: 'Add Payment Method',
            onPressed: () => _showAddPaymentMethodDialog(context),
            variant: AppButtonVariant.primary,
          ),
          const SizedBox(height: 16),
          AppButton(
            text: 'Try Payment Demo',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PaymentDemoScreen(),
                ),
              );
            },
            variant: AppButtonVariant.outline,
          ),
        ],
      ),
    );
  }

  void _showAddPaymentMethodDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const AddPaymentMethodSheet(),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Map<String, dynamic> method) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Delete Payment Method',
          style: AppTextStyles.heading3.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this payment method?',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<PaymentBloc>().add(
                RemovePaymentMethodEvent(method['id'] as String),
              );
            },
            child: Text(
              'Delete',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AddPaymentMethodSheet extends StatefulWidget {
  const AddPaymentMethodSheet({super.key});

  @override
  State<AddPaymentMethodSheet> createState() => _AddPaymentMethodSheetState();
}

class _AddPaymentMethodSheetState extends State<AddPaymentMethodSheet> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();

  PaymentMethod _selectedType = PaymentMethod.creditCard;

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
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add Payment Method',
            style: AppTextStyles.heading2.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: Column(
              children: [
                _buildPaymentTypeSelector(),
                const SizedBox(height: 16),
                if (_selectedType == PaymentMethod.creditCard ||
                    _selectedType == PaymentMethod.debitCard) ...[
                  AppTextField(
                    controller: _cardNumberController,
                    label: 'Card Number',
                    placeholder: '1234 5678 9012 3456',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Card number is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _expiryController,
                          label: 'Expiry',
                          placeholder: 'MM/YY',
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Expiry is required';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AppTextField(
                          controller: _cvvController,
                          label: 'CVV',
                          placeholder: '123',
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'CVV is required';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _nameController,
                    label: 'Cardholder Name',
                    placeholder: 'John Doe',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Cardholder name is required';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 24),
                AppButton(
                  text: 'Add Payment Method',
                  onPressed: _addPaymentMethod,
                  variant: AppButtonVariant.primary,
                  isFullWidth: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Type',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: PaymentMethod.values.map((type) {
            final isSelected = _selectedType == type;
            return ChoiceChip(
              label: Text(_getPaymentMethodName(type)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedType = type;
                  });
                }
              },
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              backgroundColor: AppColors.background,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _getPaymentMethodName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.creditCard:
        return 'Credit Card';
      case PaymentMethod.debitCard:
        return 'Debit Card';
      case PaymentMethod.applePay:
        return 'Apple Pay';
      case PaymentMethod.googlePay:
        return 'Google Pay';
      case PaymentMethod.paypal:
        return 'PayPal';
      case PaymentMethod.stripe:
        return 'Stripe';
    }
  }

  void _addPaymentMethod() {
    if (_formKey.currentState?.validate() ?? false) {
      final paymentData = <String, dynamic>{};

      if (_selectedType == PaymentMethod.creditCard ||
          _selectedType == PaymentMethod.debitCard) {
        paymentData.addAll({
          'cardNumber': _cardNumberController.text,
          'expiryMonth': _expiryController.text.split('/')[0],
          'expiryYear': _expiryController.text.split('/')[1],
          'cvv': _cvvController.text,
          'cardholderName': _nameController.text,
        });
      }

      context.read<PaymentBloc>().add(
        AddPaymentMethodEvent(
          type: _selectedType,
          paymentData: paymentData,
        ),
      );

      Navigator.of(context).pop();
    }
  }
}
