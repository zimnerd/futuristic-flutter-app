import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/phone_utils.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../navigation/app_router.dart';
import '../../theme/pulse_colors.dart';
import '../../widgets/common/common_widgets.dart';
import '../../widgets/common/keyboard_dismissible_scaffold.dart';
import '../../widgets/common/pulse_toast.dart';
import '../../widgets/error_widgets.dart';
import '../../widgets/phone_input.dart';

/// Enhanced registration screen for new users
class RegisterScreen extends StatefulWidget {
  final String? phoneNumber;

  const RegisterScreen({super.key, this.phoneNumber});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedCountryCode = PhoneUtils.defaultCountryCode;
  String _currentPhone = '';
  bool _isLoading = false;
  bool _acceptedTerms = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // Initialize with location-based country detection
    _initializeCountryCode();

    // Pre-fill phone number if provided (from OTP verification)
    if (widget.phoneNumber != null) {
      final phone = widget.phoneNumber!;
      // Extract country code and number
      if (phone.startsWith('+')) {
        // Parse the phone number
        final phoneWithoutPlus = phone.substring(1);
        // Common country codes
        if (phoneWithoutPlus.startsWith('27')) {
          _selectedCountryCode = '+27';
          _phoneController.text = phoneWithoutPlus.substring(2);
        } else if (phoneWithoutPlus.startsWith('1')) {
          _selectedCountryCode = '+1';
          _phoneController.text = phoneWithoutPlus.substring(1);
        } else {
          // Default: assume first 2-3 digits are country code
          _phoneController.text = phoneWithoutPlus;
        }
      } else {
        _phoneController.text = phone;
      }
      _currentPhone = phone;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Initialize country code based on user location
  Future<void> _initializeCountryCode() async {
    try {
      final detectedCountry = await PhoneUtils.getDefaultCountryCode();
      if (mounted) {
        setState(() {
          _selectedCountryCode = detectedCountry;
        });
      }
    } catch (e) {
      // Keep default if detection fails
    }
  }

  void _handleRegister() {
    if (_formKey.currentState?.validate() == true && _acceptedTerms) {
      // Clean phone number before submission using PhoneUtils
      final cleanedPhone = PhoneUtils.cleanPhoneForSubmission(
        _currentPhone.isNotEmpty ? _currentPhone : _phoneController.text,
        _selectedCountryCode,
      );

      if (cleanedPhone.isEmpty) {
        ErrorNotification.showSnackbar(
          context,
          'Please enter a valid phone number',
        );
        return;
      }

      // Validate phone number first
      context.read<AuthBloc>().add(
        AuthPhoneValidationRequested(
          phone: cleanedPhone,
          countryCode: _selectedCountryCode,
        ),
      );
    } else if (!_acceptedTerms) {
      ErrorNotification.showSnackbar(
        context,
        'Please accept the Terms of Service and Privacy Policy',
      );
    }
  }

  void _proceedWithRegistration() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final cleanedPhone = PhoneUtils.cleanPhoneForSubmission(
      _currentPhone.isNotEmpty ? _currentPhone : _phoneController.text,
      _selectedCountryCode,
    );

    context.read<AuthBloc>().add(
      AuthSignUpRequested(
        email: email,
        password: password,
        username: name,
        phone: cleanedPhone,
      ),
    );
  }

  void _onPhoneChanged(String formattedPhone) {
    setState(() {
      _currentPhone = formattedPhone;
    });
  }

  void _onCountryChanged(String countryCode) {
    setState(() {
      _selectedCountryCode = countryCode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardDismissibleScaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          setState(() {
            _isLoading = state is AuthLoading || state is AuthPhoneValidating;
          });

          if (state is AuthError) {
            PulseToast.error(context, message: state.message);
          } else if (state is AuthPhoneValidationSuccess && state.isValid) {
            // Phone validation successful, proceed with registration
            _proceedWithRegistration();
          } else if (state is AuthPhoneValidationError) {
            PulseToast.error(context, message: state.message);
          } else if (state is AuthRegistrationSuccess) {
            // Show success message
            PulseToast.success(
              context,
              message:
                  'Account created successfully! Please log in to continue.',
              duration: const Duration(seconds: 4),
            );
            // Navigate to login page
            context.go('/login');
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
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: PulseSpacing.xl,
                right: PulseSpacing.xl,
                top: PulseSpacing.xl,
                bottom:
                    MediaQuery.of(context).viewInsets.bottom + PulseSpacing.xl,
              ),
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
                    Column(
                      children: [
                        // Name input
                        PulseTextField(
                          controller: _nameController,
                          hintText: 'Username',
                          keyboardType: TextInputType.name,
                          prefixIcon: const Icon(Icons.person),
                          validator: ValidationHelpers.validateUsername,
                        ),
                        const SizedBox(height: PulseSpacing.lg),

                        // Email input
                        PulseTextField(
                          controller: _emailController,
                          hintText: 'Email Address',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(Icons.email),
                          validator: ValidationHelpers.validateEmail,
                        ),
                        const SizedBox(height: PulseSpacing.lg),

                        // Password input
                        PulseTextField(
                          controller: _passwordController,
                          hintText: 'Password',
                          obscureText: _obscurePassword,
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          validator: ValidationHelpers.validatePassword,
                        ),
                        const SizedBox(height: PulseSpacing.lg),

                        // Phone input with country selector
                        PhoneInput(
                          initialCountryCode: _selectedCountryCode,
                          onChanged: _onPhoneChanged,
                          onCountryChanged: _onCountryChanged,
                          validator: ValidationHelpers.validatePhone,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            hintText: 'Enter your phone number',
                          ),
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
                              fillColor: WidgetStateProperty.resolveWith((
                                states,
                              ) {
                                if (states.contains(WidgetState.selected)) {
                                  return PulseColors.primary;
                                }
                                return null;
                              }),
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
                                        style: PulseTextStyles.bodyMedium
                                            .copyWith(
                                              color: PulseColors.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const TextSpan(text: ' and '),
                                      TextSpan(
                                        text: 'Privacy Policy',
                                        style: PulseTextStyles.bodyMedium
                                            .copyWith(
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

                        // Extra space for keyboard
                        const SizedBox(height: 80),

                        // Register button
                        PulseButton(
                          text: 'Create Account',
                          onPressed: _isLoading ? null : _handleRegister,
                          fullWidth: true,
                          isLoading: _isLoading,
                        ),
                      ],
                    ),

                    const SizedBox(height: PulseSpacing.xl),

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
