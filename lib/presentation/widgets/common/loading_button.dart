import 'package:flutter/material.dart';
import '../../../core/theme/pulse_design_system.dart';
import '../../../core/utils/haptic_feedback_utils.dart';

/// Loading Button with automatic state management
///
/// Stateful button that shows loading, success, and error states automatically.
/// Perfect for async operations like login, sending messages, saving data.
///
/// Features:
/// - Loading state with spinner
/// - Success state with checkmark + green color
/// - Error state with shake animation + red color
/// - Automatic state reset
/// - Haptic feedback
/// - Disabled during loading
///
/// Usage:
/// ```dart
/// LoadingButton(
///   onPressed: () async {
///     await login();
///     return true; // Success
///   },
///   child: Text('Login'),
/// )
///
/// // With explicit success/error handling
/// LoadingButton(
///   onPressed: () async {
///     try {
///       await sendMessage();
///       return true;
///     } catch (e) {
///       return false;
///     }
///   },
///   child: Text('Send'),
///   successMessage: 'Sent!',
///   errorMessage: 'Failed',
/// )
/// ```
class LoadingButton extends StatefulWidget {
  final Future<bool> Function() onPressed;
  final Widget child;
  final ButtonStyle? style;
  final bool isElevated;
  final String? successMessage;
  final String? errorMessage;
  final Duration successDuration;
  final Duration errorDuration;

  const LoadingButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
    this.isElevated = true,
    this.successMessage,
    this.errorMessage,
    this.successDuration = const Duration(seconds: 2),
    this.errorDuration = const Duration(seconds: 2),
  });

  @override
  State<LoadingButton> createState() => _LoadingButtonState();
}

class _LoadingButtonState extends State<LoadingButton>
    with SingleTickerProviderStateMixin {
  LoadingButtonState _state = LoadingButtonState.idle;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _handlePress() async {
    if (_state == LoadingButtonState.loading) return;

    setState(() => _state = LoadingButtonState.loading);
    PulseHaptics.medium();

    try {
      final success = await widget.onPressed();

      if (!mounted) return;

      if (success) {
        setState(() => _state = LoadingButtonState.success);
        PulseHaptics.success();

        await Future.delayed(widget.successDuration);
        if (mounted) {
          setState(() => _state = LoadingButtonState.idle);
        }
      } else {
        setState(() => _state = LoadingButtonState.error);
        PulseHaptics.error();
        _shakeController.forward().then((_) => _shakeController.reverse());

        await Future.delayed(widget.errorDuration);
        if (mounted) {
          setState(() => _state = LoadingButtonState.idle);
        }
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _state = LoadingButtonState.error);
      PulseHaptics.error();
      _shakeController.forward().then((_) => _shakeController.reverse());

      await Future.delayed(widget.errorDuration);
      if (mounted) {
        setState(() => _state = LoadingButtonState.idle);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: child,
        );
      },
      child: widget.isElevated
          ? ElevatedButton(
              onPressed: _state == LoadingButtonState.loading
                  ? null
                  : _handlePress,
              style: _getButtonStyle(context),
              child: _buildButtonChild(),
            )
          : OutlinedButton(
              onPressed: _state == LoadingButtonState.loading
                  ? null
                  : _handlePress,
              style: _getButtonStyle(context),
              child: _buildButtonChild(),
            ),
    );
  }

  ButtonStyle? _getButtonStyle(BuildContext context) {
    ButtonStyle? baseStyle = widget.style;

    switch (_state) {
      case LoadingButtonState.success:
        return baseStyle?.copyWith(
              backgroundColor: WidgetStateProperty.all(PulseColors.success),
            ) ??
            ElevatedButton.styleFrom(backgroundColor: PulseColors.success);
      case LoadingButtonState.error:
        return baseStyle?.copyWith(
              backgroundColor: WidgetStateProperty.all(PulseColors.reject),
            ) ??
            ElevatedButton.styleFrom(backgroundColor: PulseColors.reject);
      default:
        return baseStyle;
    }
  }

  Widget _buildButtonChild() {
    switch (_state) {
      case LoadingButtonState.loading:
        return const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        );

      case LoadingButtonState.success:
        if (widget.successMessage != null) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, size: 20),
              const SizedBox(width: 8),
              Text(widget.successMessage!),
            ],
          );
        }
        return Icon(Icons.check_circle, size: 20);

      case LoadingButtonState.error:
        if (widget.errorMessage != null) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error, size: 20),
              const SizedBox(width: 8),
              Text(widget.errorMessage!),
            ],
          );
        }
        return Icon(Icons.error, size: 20);

      case LoadingButtonState.idle:
        return widget.child;
    }
  }
}

enum LoadingButtonState { idle, loading, success, error }
