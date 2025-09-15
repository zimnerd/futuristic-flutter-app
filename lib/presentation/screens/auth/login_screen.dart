import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../navigation/app_router.dart';
import '../../theme/pulse_colors.dart';
import '../../widgets/common/pulse_text_field.dart';
import '../../widgets/common/pulse_button.dart';
import '../../widgets/developer_auto_login_fab.dart';

/// Enhanced login screen with auth integration
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState?.validate() == true) {
      final phone = _phoneController.text.trim();
      // Use our existing auth event for now (we'll create phone auth later)
      context.read<AuthBloc>().add(
        AuthSignInRequested(email: phone, password: 'temp'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: const DeveloperAutoLoginFAB(),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          setState(() {
            _isLoading = state is AuthLoading;
          });

          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: PulseColors.error,
              ),
            );
          } else if (state is AuthAuthenticated) {
            context.go(AppRoutes.home);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [PulseColors.surface, const Color(0xFFF8F9FA)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(PulseSpacing.xl),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight:
                          MediaQuery.of(context).size.height -
                          MediaQuery.of(context).padding.top -
                          MediaQuery.of(context).padding.bottom -
                          (PulseSpacing.xl * 2),
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                    // Back button
                    IconButton(
                      onPressed: () => context.go(AppRoutes.welcome),
                      icon: const Icon(Icons.arrow_back),
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                    ),
                    const SizedBox(height: PulseSpacing.xl),

                    // Header
                    Text(
                      'Welcome back',
                      style: PulseTextStyles.displayMedium.copyWith(
                        color: PulseColors.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: PulseSpacing.sm),
                    Text(
                      'Enter your phone number to continue',
                      style: PulseTextStyles.bodyLarge.copyWith(
                        color: PulseColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: PulseSpacing.xxl),

                    // Phone input
                    PulseTextField(
                      controller: _phoneController,
                      hintText: '+1 (555) 123-4567',
                      keyboardType: TextInputType.phone,
                      prefixIcon: const Icon(Icons.phone),
                      validator: (value) {
                        if (value?.isEmpty == true) {
                          return 'Phone number is required';
                        }
                        if (value!.length < 10) {
                          return 'Please enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: PulseSpacing.xl),

                    // Login button
                    PulseButton(
                      text: 'Send Verification Code',
                      onPressed: _isLoading ? null : _handleLogin,
                      fullWidth: true,
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: PulseSpacing.lg),

                    // Forgot password
                    Center(
                      child: TextButton(
                        onPressed: () => context.go(AppRoutes.forgotPassword),
                        child: Text(
                          'Having trouble signing in?',
                          style: PulseTextStyles.bodyMedium.copyWith(
                            color: PulseColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),

                    // Sign up prompt
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: PulseTextStyles.bodyMedium.copyWith(
                            color: PulseColors.onSurfaceVariant,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go(AppRoutes.register),
                          child: Text(
                            'Sign up',
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
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
