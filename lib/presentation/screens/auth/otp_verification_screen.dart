import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../theme/pulse_colors.dart';
import '../../widgets/common/keyboard_dismissible_scaffold.dart';
import '../../widgets/common/pulse_toast.dart';

/// Screen for verifying OTP code sent via WhatsApp/SMS
class OTPVerificationScreen extends StatefulWidget {
  final String sessionId;
  final String phoneNumber;
  final List<String>? deliveryMethods;

  const OTPVerificationScreen({
    super.key,
    required this.sessionId,
    required this.phoneNumber,
    this.deliveryMethods,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final Logger _logger = Logger();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _canResend = false;
  int _remainingSeconds = 30;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _canResend = false;
      _remainingSeconds = 30;
    });

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      
      setState(() {
        _remainingSeconds--;
      });

      if (_remainingSeconds <= 0) {
        setState(() {
          _canResend = true;
        });
        return false;
      }
      return true;
    });
  }

  void _handleVerify() {
    if (_formKey.currentState?.validate() == true) {
      final code = _otpController.text.trim();
      _logger.i('Verifying OTP code: $code');
      
      context.read<AuthBloc>().add(
        AuthOTPVerifyRequested(
          sessionId: widget.sessionId,
          code: code,
          email: widget.phoneNumber, // Using phone number as identifier
        ),
      );
    }
  }

  void _handleResend() {
    if (_canResend) {
      _logger.i('Resending OTP to: ${widget.phoneNumber}');
      context.read<AuthBloc>().add(
        AuthOTPResendRequested(sessionId: widget.sessionId),
      );
      _startResendTimer();
    }
  }

  String? _validateOTP(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter the OTP code';
    }
    if (value.length != 4) {
      return 'OTP code must be exactly 4 digits';
    }
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'OTP code must contain only numbers';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardDismissibleScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          setState(() {
            _isLoading = state is AuthLoading;
          });

          if (state is AuthAuthenticated) {
            _logger.i('✅ OTP verification successful, navigating to home');
            context.go('/home');
          } else if (state is AuthOTPVerifiedRequiresRegistration) {
            _logger.i(
              '✅ OTP verified, navigating to registration with phone: ${state.phoneNumber}',
            );
            // Navigate to registration screen with pre-filled phone number
            context.go('/register', extra: {'phoneNumber': state.phoneNumber});
          } else if (state is AuthOTPSent) {
            // OTP resent successfully
            PulseToast.success(
              context,
              message: 'OTP resent successfully',
            );
          } else if (state is AuthOTPVerificationFailed) {
            PulseToast.error(
              context,
              message: state.message,
            );
          } else if (state is AuthError) {
            PulseToast.error(
              context,
              message: state.message,
            );
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 24.0,
              right: 24.0,
              top: 24.0,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // Icon
                const Icon(
                  Icons.message,
                  size: 80,
                  color: PulseColors.primary,
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  'Verify Your Number',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: PulseColors.onSurface,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Subtitle
                Text(
                  'We sent a verification code to',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: PulseColors.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.phoneNumber,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: PulseColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                  textAlign: TextAlign.center,
                ),
                
                if (widget.deliveryMethods != null && widget.deliveryMethods!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'via ${widget.deliveryMethods!.join(", ").toUpperCase()}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: PulseColors.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],

                const SizedBox(height: 48),

                // OTP Input
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 8,
                        ),
                        maxLength: 4,
                        validator: _validateOTP,
                        decoration: InputDecoration(
                          hintText: '• • • •',
                          hintStyle: TextStyle(
                            color: PulseColors.onSurfaceVariant.withValues(alpha: 0.3),
                            letterSpacing: 16,
                          ),
                          counterText: '',
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Extra space for keyboard
                      const SizedBox(height: 80),

                      // Verify button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleVerify,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PulseColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Verify',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),

                      const SizedBox(height: 24),

                      // Resend button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Didn't receive the code? ",
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: PulseColors.onSurfaceVariant,
                                ),
                          ),
                          TextButton(
                            onPressed: _canResend ? _handleResend : null,
                            child: Text(
                              _canResend
                                  ? 'Resend'
                                  : 'Resend in ${_remainingSeconds}s',
                              style: TextStyle(
                                color: _canResend
                                    ? PulseColors.primary
                                    : PulseColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
