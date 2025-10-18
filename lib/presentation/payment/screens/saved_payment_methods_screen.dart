import 'package:flutter/material.dart';
import '../../../data/models/saved_payment_method.dart';
import '../../../data/services/saved_payment_methods_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_text_field.dart';
import '../widgets/payment_method_card.dart';
import 'add_payment_method_screen.dart';
import '../../widgets/common/pulse_toast.dart';

/// Screen for managing saved payment methods
class SavedPaymentMethodsScreen extends StatefulWidget {
  const SavedPaymentMethodsScreen({super.key});

  @override
  State<SavedPaymentMethodsScreen> createState() => _SavedPaymentMethodsScreenState();
}

class _SavedPaymentMethodsScreenState extends State<SavedPaymentMethodsScreen> {
  final SavedPaymentMethodsService _service = SavedPaymentMethodsService.instance;
  List<SavedPaymentMethod> _savedMethods = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSavedMethods();
  }

  Future<void> _loadSavedMethods() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final methods = await _service.getSavedPaymentMethods();
      setState(() {
        _savedMethods = methods;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load payment methods: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deletePaymentMethod(SavedPaymentMethod method) async {
    final confirmed = await _showDeleteConfirmation(method);
    if (!confirmed) return;

    try {
      final success = await _service.deletePaymentMethod(method.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment method deleted'),
            backgroundColor: AppColors.success,
          ),
        );
        await _loadSavedMethods();
      } else {
        throw Exception('Failed to delete payment method');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting payment method: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<bool> _showDeleteConfirmation(SavedPaymentMethod method) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        title: Text(
          'Delete Payment Method',
          style: AppTextStyles.heading3,
        ),
        content: Text(
          'Are you sure you want to delete ${method.displayName}?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Delete',
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _setAsDefault(SavedPaymentMethod method) async {
    try {
      final success = await _service.setDefaultPaymentMethod(method.id);
      if (success && mounted) {
        PulseToast.success(context, message: 'Default payment method updated',
        );
        await _loadSavedMethods();
      } else {
        throw Exception('Failed to set default payment method');
      }
    } catch (e) {
      if (mounted) {
        PulseToast.error(context, message: 'Error updating default method: $e',
        );
      }
    }
  }

  Future<void> _editPaymentMethod(SavedPaymentMethod method) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _EditPaymentMethodDialog(method: method),
    );

    if (result != null) {
      try {
        final success = await _service.updatePaymentMethod(
          methodId: method.id,
          nickname: result,
        );
        if (success && mounted) {
          PulseToast.success(context, message: 'Payment method updated',
          );
          await _loadSavedMethods();
        } else {
          throw Exception('Failed to update payment method');
        }
      } catch (e) {
        if (mounted) {
          PulseToast.error(
            context,
            message: 'Error updating payment method: $e',
          );
        }
      }
    }
  }

  Future<void> _addNewPaymentMethod() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const AddPaymentMethodScreen(),
      ),
    );

    if (result == true) {
      await _loadSavedMethods();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Payment Methods',
          style: AppTextStyles.heading2,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: AppColors.primary),
            onPressed: _addNewPaymentMethod,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_savedMethods.isEmpty) {
      return _buildEmptyState();
    }

    return _buildPaymentMethodsList();
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Payment Methods',
              style: AppTextStyles.heading3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AppButton(
              text: 'Try Again',
              onPressed: _loadSavedMethods,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
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
              style: AppTextStyles.heading3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Add a payment method to make purchases faster and more convenient.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AppButton(
              text: 'Add Payment Method',
              onPressed: _addNewPaymentMethod,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodsList() {
    return RefreshIndicator(
      onRefresh: _loadSavedMethods,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _savedMethods.length,
        itemBuilder: (context, index) {
          final method = _savedMethods[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PaymentMethodCard(
              method: method,
              onTap: () => _editPaymentMethod(method),
              onSetDefault: () => _setAsDefault(method),
              onDelete: () => _deletePaymentMethod(method),
            ),
          );
        },
      ),
    );
  }
}

/// Dialog for editing payment method nickname
class _EditPaymentMethodDialog extends StatefulWidget {
  final SavedPaymentMethod method;

  const _EditPaymentMethodDialog({required this.method});

  @override
  State<_EditPaymentMethodDialog> createState() => _EditPaymentMethodDialogState();
}

class _EditPaymentMethodDialogState extends State<_EditPaymentMethodDialog> {
  late TextEditingController _nicknameController;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(text: widget.method.nickname);
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.background,
      title: Text(
        'Edit Payment Method',
        style: AppTextStyles.heading3,
      ),
      contentPadding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.method.maskedCardNumber,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _nicknameController,
            label: 'Nickname',
            placeholder: 'Enter a name for this payment method',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary),
          ),
        ),
        TextButton(
          onPressed: () {
            final nickname = _nicknameController.text.trim();
            if (nickname.isNotEmpty) {
              Navigator.of(context).pop(nickname);
            }
          },
          child: Text(
            'Save',
            style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}
