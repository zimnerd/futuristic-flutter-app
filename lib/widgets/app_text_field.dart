import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

/// Text field variants
enum AppTextFieldVariant {
  standard,
  outlined,
  filled,
}

/// Custom app text field widget following PulseLink design system
class AppTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? placeholder;
  final String? helperText;
  final String? errorText;
  final String? Function(String?)? validator;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final VoidCallback? onTap;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final AppTextFieldVariant variant;
  final bool isRequired;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;

  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.placeholder,
    this.helperText,
    this.errorText,
    this.validator,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.prefixIcon,
    this.suffixIcon,
    this.variant = AppTextFieldVariant.outlined,
    this.isRequired = false,
    this.inputFormatters,
    this.focusNode,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _isFocused = false;
  bool _obscureText = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
    _errorText = widget.errorText;
  }

  @override
  void didUpdateWidget(AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.errorText != oldWidget.errorText) {
      setState(() {
        _errorText = widget.errorText;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          _buildLabel(),
          const SizedBox(height: 8),
        ],
        _buildTextField(),
        if (_errorText != null || widget.helperText != null) ...[
          const SizedBox(height: 4),
          _buildHelperText(),
        ],
      ],
    );
  }

  Widget _buildLabel() {
    return RichText(
      text: TextSpan(
        text: widget.label!,
        style: AppTextStyles.labelMedium.copyWith(
          color: _isFocused ? AppColors.primary : AppColors.textPrimary,
        ),
        children: [
          if (widget.isRequired)
            TextSpan(
              text: ' *',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.error,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField() {
    return Focus(
      onFocusChange: (hasFocus) {
        setState(() {
          _isFocused = hasFocus;
        });
      },
      child: TextFormField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        obscureText: _obscureText,
        enabled: widget.enabled,
        readOnly: widget.readOnly,
        maxLines: widget.maxLines,
        maxLength: widget.maxLength,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        inputFormatters: widget.inputFormatters,
        onTap: widget.onTap,
        onChanged: (value) {
          // Clear error when user starts typing
          if (_errorText != null && value.isNotEmpty) {
            setState(() {
              _errorText = null;
            });
          }
          
          widget.onChanged?.call(value);
        },
        onFieldSubmitted: widget.onSubmitted,
        validator: (value) {
          final validationResult = widget.validator?.call(value);
          if (validationResult != null) {
            setState(() {
              _errorText = validationResult;
            });
          } else {
            setState(() {
              _errorText = null;
            });
          }
          return validationResult;
        },
        style: AppTextStyles.bodyMedium.copyWith(
          color: widget.enabled ? AppColors.textPrimary : AppColors.disabledText,
        ),
        decoration: _buildInputDecoration(),
      ),
    );
  }

  InputDecoration _buildInputDecoration() {
    final hasError = _errorText != null;
    
    return InputDecoration(
      hintText: widget.placeholder,
      hintStyle: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.textSecondary,
      ),
      prefixIcon: widget.prefixIcon,
      suffixIcon: _buildSuffixIcon(),
      filled: widget.variant == AppTextFieldVariant.filled,
      fillColor: widget.variant == AppTextFieldVariant.filled
          ? AppColors.surface
          : AppColors.transparent,
      border: _buildBorder(false, hasError),
      enabledBorder: _buildBorder(false, hasError),
      focusedBorder: _buildBorder(true, hasError),
      errorBorder: _buildBorder(false, true),
      focusedErrorBorder: _buildBorder(true, true),
      disabledBorder: _buildBorder(false, hasError),
      contentPadding: _getContentPadding(),
      counterText: '', // Hide character counter
      errorStyle: const TextStyle(height: 0), // Hide default error text
    );
  }

  Widget? _buildSuffixIcon() {
    if (widget.obscureText) {
      return IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off : Icons.visibility,
          color: AppColors.textSecondary,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      );
    }
    return widget.suffixIcon;
  }

  InputBorder _buildBorder(bool isFocused, bool hasError) {
    Color borderColor;
    double borderWidth;
    
    if (!widget.enabled) {
      borderColor = AppColors.disabled;
      borderWidth = 1;
    } else if (hasError) {
      borderColor = AppColors.error;
      borderWidth = isFocused ? 2 : 1;
    } else if (isFocused) {
      borderColor = AppColors.primary;
      borderWidth = 2;
    } else {
      borderColor = AppColors.border;
      borderWidth = 1;
    }

    switch (widget.variant) {
      case AppTextFieldVariant.standard:
        return UnderlineInputBorder(
          borderSide: BorderSide(color: borderColor, width: borderWidth),
        );
      case AppTextFieldVariant.outlined:
        return OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor, width: borderWidth),
        );
      case AppTextFieldVariant.filled:
        return OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor, width: borderWidth),
        );
    }
  }

  EdgeInsets _getContentPadding() {
    switch (widget.variant) {
      case AppTextFieldVariant.standard:
        return const EdgeInsets.symmetric(vertical: 12, horizontal: 0);
      case AppTextFieldVariant.outlined:
      case AppTextFieldVariant.filled:
        return const EdgeInsets.symmetric(vertical: 12, horizontal: 16);
    }
  }

  Widget _buildHelperText() {
    final text = _errorText ?? widget.helperText;
    final color = _errorText != null ? AppColors.error : AppColors.textSecondary;
    
    if (text == null) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(color: color),
      ),
    );
  }
}

/// Specialized text field variants for common use cases
class AppPasswordField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? placeholder;
  final String? helperText;
  final String? errorText;
  final String? Function(String?)? validator;
  final bool enabled;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final bool isRequired;

  const AppPasswordField({
    super.key,
    this.controller,
    this.label,
    this.placeholder,
    this.helperText,
    this.errorText,
    this.validator,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: label ?? 'Password',
      placeholder: placeholder ?? 'Enter your password',
      helperText: helperText,
      errorText: errorText,
      validator: validator,
      enabled: enabled,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      isRequired: isRequired,
      obscureText: true,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: TextInputAction.done,
    );
  }
}

class AppEmailField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? placeholder;
  final String? helperText;
  final String? errorText;
  final String? Function(String?)? validator;
  final bool enabled;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final bool isRequired;

  const AppEmailField({
    super.key,
    this.controller,
    this.label,
    this.placeholder,
    this.helperText,
    this.errorText,
    this.validator,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: label ?? 'Email',
      placeholder: placeholder ?? 'Enter your email',
      helperText: helperText,
      errorText: errorText,
      validator: validator ?? _defaultEmailValidator,
      enabled: enabled,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      isRequired: isRequired,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
    );
  }

  String? _defaultEmailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return isRequired ? 'Email is required' : null;
    }
    
    const pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
    final regex = RegExp(pattern);
    
    if (!regex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }
}

class AppSearchField extends StatelessWidget {
  final TextEditingController? controller;
  final String? placeholder;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final VoidCallback? onClear;
  final bool enabled;

  const AppSearchField({
    super.key,
    this.controller,
    this.placeholder,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      placeholder: placeholder ?? 'Search...',
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      enabled: enabled,
      prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
      suffixIcon: (controller?.text.isNotEmpty ?? false)
          ? IconButton(
              icon: const Icon(Icons.clear, color: AppColors.textSecondary),
              onPressed: () {
                controller?.clear();
                onClear?.call();
              },
            )
          : null,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.search,
      variant: AppTextFieldVariant.filled,
    );
  }
}
