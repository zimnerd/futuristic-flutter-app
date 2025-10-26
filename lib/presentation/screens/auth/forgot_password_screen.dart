import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../navigation/app_router.dart';
import '../../theme/pulse_colors.dart';
import '../../widgets/common/common_widgets.dart';
import '../../widgets/common/keyboard_dismissible_scaffold.dart';
import '../../widgets/common/pulse_toast.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';

/// Enhanced forgot password screen
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleResetPassword() async {
    if (_formKey.currentState?.validate() == true) {
      final email = _emailController.text.trim();
      context.read<AuthBloc>().add(AuthPasswordResetRequested(email: email));
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardDismissibleScaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          setState(() {
            _isLoading = state is AuthLoading;
          });

          if (state is AuthPasswordResetEmailSent) {
            setState(() {
              _emailSent = true;
            });
            PulseToast.success(context, message: state.message);
          } else if (state is AuthFailure) {
            PulseToast.error(context, message: state.error);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Theme.of(context).colorScheme.surface, Theme.of(context).colorScheme.surfaceContainerHighest],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: PulseSpacing.xl,
                right: PulseSpacing.xl,
                top: PulseSpacing.xl,
                bottom:
                    MediaQuery.of(context).viewInsets.bottom + PulseSpacing.xl,
              ),
              child: _emailSent ? _buildSuccessView() : _buildFormView(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          IconButton(
            onPressed: () => context.go(AppRoutes.login),
            icon: Icon(Icons.arrow_back),
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
          ),
          const SizedBox(height: PulseSpacing.xl),

          // Header
          Text(
            'Reset Password',
            style: PulseTextStyles.displayMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: PulseSpacing.sm),
          Text(
            'Enter your email address and we\'ll send you a link to reset your password',
            style: PulseTextStyles.bodyLarge.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: PulseSpacing.xxl),

          // Email input
          PulseTextField(
            controller: _emailController,
            hintText: 'Email Address',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icon(Icons.email),
            validator: (value) {
              if (value?.isEmpty == true) {
                return 'Email is required';
              }
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value!)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: PulseSpacing.xl),

          // Extra space for keyboard
          const SizedBox(height: 80),

          // Reset button
          PulseButton(
            text: 'Send Reset Link',
            onPressed: _isLoading ? null : _handleResetPassword,
            fullWidth: true,
            isLoading: _isLoading,
          ),
          const Spacer(),

          // Sign in prompt
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Remember your password? ',
                style: PulseTextStyles.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              TextButton(
                onPressed: () => context.go(AppRoutes.login),
                child: Text(
                  'Sign in',
                  style: PulseTextStyles.bodyMedium.copyWith(
                    color: PulseColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: PulseColors.success,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check, color: context.onSurfaceColor, size: 40),
        ),
        const SizedBox(height: PulseSpacing.xl),

        Text(
          'Check your email',
          style: PulseTextStyles.headlineLarge.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: PulseSpacing.md),
        Text(
          'We\'ve sent a password reset link to\n${_emailController.text}',
          style: PulseTextStyles.bodyLarge.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: PulseSpacing.xxl),

        PulseButton(
          text: 'Back to Sign In',
          onPressed: () => context.go(AppRoutes.login),
          fullWidth: true,
        ),
        const SizedBox(height: PulseSpacing.lg),

        TextButton(
          onPressed: () {
            setState(() {
              _emailSent = false;
            });
          },
          child: Text(
            'Didn\'t receive the email? Try again',
            style: PulseTextStyles.bodyMedium.copyWith(
              color: PulseColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}
