// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;

/// A wrapper around TextField/TextFormField that provides automatic keyboard handling
/// including scroll-to-field on focus, especially optimized for iOS.
///
/// **Features:**
/// - Auto-scroll to field when focused (prevents keyboard covering)
/// - iOS-optimized keyboard animations
/// - Built-in validation error display
/// - Keyboard action buttons (next/done)
/// - Consistent styling across the app
///
/// **Usage:**
/// ```dart
/// KeyboardAwareTextField(
///   label: 'Email',
///   controller: _emailController,
///   focusNode: _emailFocusNode,
///   nextFocusNode: _passwordFocusNode,  // Auto-move to next field
///   keyboardType: TextInputType.emailAddress,
///   validator: (value) => value?.isEmpty == true ? 'Required' : null,
/// )
/// ```
class KeyboardAwareTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final int? maxLines;
  final int? minLines;
  final bool enabled;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final EdgeInsets? contentPadding;
  final InputDecoration? decoration;
  final List<TextInputFormatter>? inputFormatters;
  final bool autoScrollOnFocus;
  final ScrollController? scrollController;

  const KeyboardAwareTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.focusNode,
    this.nextFocusNode,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.maxLines = 1,
    this.minLines,
    this.enabled = true,
    this.prefixIcon,
    this.suffixIcon,
    this.contentPadding,
    this.decoration,
    this.inputFormatters,
    this.autoScrollOnFocus = true,
    this.scrollController,
  });

  @override
  State<KeyboardAwareTextField> createState() => _KeyboardAwareTextFieldState();
}

class _KeyboardAwareTextFieldState extends State<KeyboardAwareTextField> {
  late FocusNode _internalFocusNode;
  final GlobalKey _fieldKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _internalFocusNode = widget.focusNode ?? FocusNode();

    // Add focus listener for auto-scroll
    if (widget.autoScrollOnFocus) {
      _internalFocusNode.addListener(_handleFocusChange);
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _internalFocusNode.dispose();
    } else if (widget.autoScrollOnFocus) {
      _internalFocusNode.removeListener(_handleFocusChange);
    }
    super.dispose();
  }

  void _handleFocusChange() {
    if (_internalFocusNode.hasFocus) {
      _scrollToField();
    }
  }

  /// Scroll to make this field visible when keyboard appears
  /// Safe to use context here as we access it from GlobalKey and check mounted
  void _scrollToField() {
    if (widget.scrollController == null) return;

    // Wait for keyboard to appear
    final delayMs = Platform.isIOS ? 300 : 100;
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (!mounted) return;

      // Safe: accessing GlobalKey's context, not widget BuildContext
      final fieldContext = _fieldKey.currentContext;
      if (fieldContext == null || !mounted) return;

      final renderBox = fieldContext.findRenderObject() as RenderBox?;
      if (renderBox == null) return;

      final fieldOffset = renderBox.localToGlobal(Offset.zero).dy;
      final scrollOffset = widget.scrollController!.offset;
      final viewportHeight =
          widget.scrollController!.position.viewportDimension;
      if (!mounted) return;
      final keyboardHeight = MediaQuery.of(fieldContext).viewInsets.bottom;

      // Calculate visible area (viewport minus keyboard)
      final visibleHeight = viewportHeight - keyboardHeight;

      // Position field at 25% from top of visible area
      final targetPosition = visibleHeight * 0.25;

      // Calculate new scroll position
      final newScrollOffset = scrollOffset + fieldOffset - targetPosition;

      // Ensure we don't scroll beyond bounds
      final maxScroll = widget.scrollController!.position.maxScrollExtent;
      final clampedOffset = newScrollOffset.clamp(0.0, maxScroll);

      // Animate to new position
      widget.scrollController!.animateTo(
        clampedOffset,
        duration: Duration(milliseconds: Platform.isIOS ? 400 : 300),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine text input action
    final inputAction =
        widget.textInputAction ??
        (widget.nextFocusNode != null
            ? TextInputAction.next
            : TextInputAction.done);

    return Container(
      key: _fieldKey,
      child: TextFormField(
        controller: widget.controller,
        focusNode: _internalFocusNode,
        keyboardType: widget.keyboardType,
        textInputAction: inputAction,
        obscureText: widget.obscureText,
        validator: widget.validator,
        onChanged: widget.onChanged,
        maxLines: widget.maxLines,
        minLines: widget.minLines,
        enabled: widget.enabled,
        inputFormatters: widget.inputFormatters,
        decoration:
            widget.decoration ??
            InputDecoration(
              labelText: widget.label,
              hintText: widget.hint,
              prefixIcon: widget.prefixIcon,
              suffixIcon: widget.suffixIcon,
              contentPadding:
                  widget.contentPadding ??
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF6E3BFF), // PulseColors.primary
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
            ),
        onFieldSubmitted: (value) {
          if (widget.nextFocusNode != null) {
            // Move to next field
            widget.nextFocusNode!.requestFocus();
          } else {
            // Dismiss keyboard
            _internalFocusNode.unfocus();
          }
          widget.onSubmitted?.call(value);
        },
      ),
    );
  }
}

/// A complete form wrapper that handles keyboard and scrolling automatically
///
/// **Usage:**
/// ```dart
/// KeyboardAwareForm(
///   formKey: _formKey,
///   children: [
///     KeyboardAwareTextField(
///       label: 'Name',
///       controller: _nameController,
///       focusNode: _nameFocus,
///       nextFocusNode: _emailFocus,
///     ),
///     SizedBox(height: 16),
///     KeyboardAwareTextField(
///       label: 'Email',
///       controller: _emailController,
///       focusNode: _emailFocus,
///       nextFocusNode: _passwordFocus,
///     ),
///     SizedBox(height: 24),
///     ElevatedButton(
///       onPressed: _submit,
///       child: Text('Submit'),
///     ),
///   ],
/// )
/// ```
class KeyboardAwareForm extends StatefulWidget {
  final GlobalKey<FormState>? formKey;
  final List<Widget> children;
  final EdgeInsets? padding;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;

  const KeyboardAwareForm({
    super.key,
    this.formKey,
    required this.children,
    this.padding,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
    this.mainAxisSize = MainAxisSize.min,
  });

  @override
  State<KeyboardAwareForm> createState() => _KeyboardAwareFormState();
}

class _KeyboardAwareFormState extends State<KeyboardAwareForm> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final form = Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: widget.crossAxisAlignment,
        mainAxisSize: widget.mainAxisSize,
        children: widget.children,
      ),
    );

    return SingleChildScrollView(
      controller: _scrollController,
      padding:
          widget.padding ??
          EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
      child: form,
    );
  }
}
