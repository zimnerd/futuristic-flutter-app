import 'package:flutter/material.dart';

import 'package:pulse_dating_app/core/theme/theme_extensions.dart';
import '../../theme/pulse_colors.dart'; // For PulseRadii, PulseTextStyles

/// Reusable text input widget with Pulse branding
/// Supports various input types and validation states
class PulseTextField extends StatefulWidget {
  const PulseTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.focusNode,
    this.autofocus = false,
    this.onTap,
  });

  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final FocusNode? focusNode;
  final bool autofocus;
  final VoidCallback? onTap;

  @override
  State<PulseTextField> createState() => _PulseTextFieldState();
}

class _PulseTextFieldState extends State<PulseTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          obscureText: widget.obscureText,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          maxLines: widget.maxLines,
          maxLength: widget.maxLength,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          validator: widget.validator,
          autofocus: widget.autofocus,
          onTap: widget.onTap,
          style: PulseTextStyles.bodyMedium.copyWith(
            color: widget.enabled
                ? context.onSurfaceColor
                : context.onSurfaceVariantColor,
          ),
          decoration: InputDecoration(
            // Use Material Design's OutlineInputBorder for proper rounded corners
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(PulseRadii.input),
              borderSide: BorderSide(color: context.outlineColor, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(PulseRadii.input),
              borderSide: BorderSide(color: _getBorderColor(context), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(PulseRadii.input),
              borderSide: BorderSide(color: context.primaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(PulseRadii.input),
              borderSide: BorderSide(color: context.errorColor, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(PulseRadii.input),
              borderSide: BorderSide(color: context.errorColor, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(PulseRadii.input),
              borderSide: BorderSide(
                color: context.borderLight,
                width: 1,
              ),
            ),
            // Material Design labels that float on top
            labelText: widget.labelText ?? widget.hintText,
            hintText: widget.hintText,
            prefixIcon: widget.prefixIcon,
            suffixIcon: widget.suffixIcon,
            counterText: '',
            // Proper padding for Material Design
            contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            labelStyle: PulseTextStyles.bodyMedium.copyWith(
              color: _getLabelColor(context),
            ),
            hintStyle: PulseTextStyles.bodyMedium.copyWith(
              color: context.onSurfaceVariantColor,
            ),
            // Material Design floating label behavior
            floatingLabelBehavior: FloatingLabelBehavior.auto,
            filled: true,
            fillColor: widget.enabled
                ? context.surfaceVariantColor
                : context.borderLight.withValues(alpha: 0.1),
          ),
        ),
        if (widget.helperText != null || widget.errorText != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              widget.errorText ?? widget.helperText!,
              style: PulseTextStyles.labelSmall.copyWith(
                color: widget.errorText != null
                    ? context.errorColor
                    : context.onSurfaceVariantColor,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Color _getBorderColor(BuildContext context) {
    if (widget.errorText != null) {
      return context.errorColor;
    }
    if (_isFocused) {
      return context.primaryColor;
    }
    return context.outlineColor;
  }

  Color _getLabelColor(BuildContext context) {
    if (widget.errorText != null) {
      return context.errorColor;
    }
    if (_isFocused) {
      return context.primaryColor;
    }
    return context.onSurfaceVariantColor;
  }
}

/// Specialized password field with show/hide functionality
class PulsePasswordField extends StatefulWidget {
  const PulsePasswordField({
    super.key,
    this.controller,
    this.labelText = 'Password',
    this.hintText,
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.focusNode,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final String labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  State<PulsePasswordField> createState() => _PulsePasswordFieldState();
}

class _PulsePasswordFieldState extends State<PulsePasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return PulseTextField(
      controller: widget.controller,
      labelText: widget.labelText,
      hintText: widget.hintText,
      helperText: widget.helperText,
      errorText: widget.errorText,
      enabled: widget.enabled,
      obscureText: _obscureText,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      validator: widget.validator,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      textInputAction: TextInputAction.done,
      suffixIcon: IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility : Icons.visibility_off,
          color: context.onSurfaceVariantColor,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      ),
    );
  }
}
