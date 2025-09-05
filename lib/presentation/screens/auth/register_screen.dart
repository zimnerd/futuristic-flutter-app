import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../navigation/app_router.dart';
import '../../theme/pulse_colors.dart';
import '../../widgets/common/common_widgets.dart';

/// Enhanced registration screen for new users
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    if (_formKey.currentState?.validate() == true && _acceptedTerms) {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      
      context.read<AuthBloc>().add(AuthSignUpRequested(
        email: email,
        password: 'temp_password', // TODO: Add password field
        username: name,
      ));
    } else if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the Terms of Service and Privacy Policy'),
          backgroundColor: PulseColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          } else if (state is AuthRegistrationSuccess) {
            context.go(AppRoutes.home);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                PulseColors.surface,
                const Color(0xFFF8F9FA),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(PulseSpacing.xl),
              child: Form(
                key: _formKey,
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
                      'Create Account',
                      style: PulseTextStyles.displayMedium.copyWith(
                        color: PulseColors.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: PulseSpacing.sm),
                    Text(
                      'Join PulseLink and find your perfect match',
                      style: PulseTextStyles.bodyLarge.copyWith(
                        color: PulseColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: PulseSpacing.xxl),
                    
                    // Form fields
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // Name input
                            PulseTextField(
                              controller: _nameController,
                              hintText: 'Full Name',
                              keyboardType: TextInputType.name,
                              prefixIcon: const Icon(Icons.person),
                              validator: (value) {
                                if (value?.isEmpty == true) {
                                  return 'Name is required';
                                }
                                if (value!.length < 2) {
                                  return 'Name must be at least 2 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: PulseSpacing.lg),
                            
                            // Email input
                            PulseTextField(
                              controller: _emailController,
                              hintText: 'Email Address',
                              keyboardType: TextInputType.emailAddress,
                              prefixIcon: const Icon(Icons.email),
                              validator: (value) {
                                if (value?.isEmpty == true) {
                                  return 'Email is required';
                                }
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: PulseSpacing.lg),
                            
                            // Phone input
                            PulseTextField(
                              controller: _phoneController,
                              hintText: 'Phone Number',
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
                            
                            // Terms checkbox
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Checkbox(
                                  value: _acceptedTerms,
                                  onChanged: (value) {
                                    setState(() {
                                      _acceptedTerms = value ?? false;
                                    });
                                  },
                                  activeColor: PulseColors.primary,
                                ),
                                const SizedBox(width: PulseSpacing.sm),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _acceptedTerms = !_acceptedTerms;
                                      });
                                    },
                                    child: Text.rich(
                                      TextSpan(
                                        text: 'I agree to the ',
                                        style: PulseTextStyles.bodyMedium.copyWith(
                                          color: PulseColors.onSurfaceVariant,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: 'Terms of Service',
                                            style: PulseTextStyles.bodyMedium.copyWith(
                                              color: PulseColors.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const TextSpan(text: ' and '),
                                          TextSpan(
                                            text: 'Privacy Policy',
                                            style: PulseTextStyles.bodyMedium.copyWith(
                                              color: PulseColors.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: PulseSpacing.xl),
                            
                            // Register button
                            PulseButton(
                              text: 'Create Account',
                              onPressed: _isLoading ? null : _handleRegister,
                              fullWidth: true,
                              isLoading: _isLoading,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Sign in prompt
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: PulseTextStyles.bodyMedium.copyWith(
                            color: PulseColors.onSurfaceVariant,
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}
