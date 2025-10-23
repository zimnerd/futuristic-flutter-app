import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/error_service.dart';
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
  String? _emailError;
  String? _usernameError;
  String? _phoneError;
  String? _passwordError;

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
      // Automatically clear phone error when user edits the field
      if (_phoneError != null) {
        _phoneError = null;
      }
    });
  }

  void _onCountryChanged(String countryCode) {
    setState(() {
      _selectedCountryCode = countryCode;
      // Automatically clear phone error when user changes country
      if (_phoneError != null) {
        _phoneError = null;
      }
    });
  }

  void _onEmailChanged(String email) {
    setState(() {
      // Automatically clear email error when user edits the field
      if (_emailError != null) {
        _emailError = null;
      }
    });
  }

  void _onUsernameChanged(String username) {
    setState(() {
      // Automatically clear username error when user edits the field
      if (_usernameError != null) {
        _usernameError = null;
      }
    });
  }

  void _onPasswordChanged(String password) {
    setState(() {
      // Automatically clear password error when user edits the field
      if (_passwordError != null) {
        _passwordError = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardDismissibleScaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          setState(() {
            _isLoading = state is AuthLoading || state is AuthPhoneValidating;

            // Clear field errors when loading
            if (state is AuthLoading || state is AuthPhoneValidating) {
              _emailError = null;
              _usernameError = null;
              _phoneError = null;
              _passwordError = null;
            }
          });

          if (state is AuthError) {
            // Use centralized error service
            final errorDetails = ErrorService.instance.parseError(
              state.errorObject ?? state.message,
            );

            setState(() {
              // Clear all errors first
              _emailError = null;
              _usernameError = null;
              _phoneError = null;
              _passwordError = null;

              // Set field-specific errors from backend
              if (errorDetails.hasFieldErrors) {
                _emailError = errorDetails.getFieldError('email');
                _usernameError = errorDetails.getFieldError('username');
                _phoneError = errorDetails.getFieldError('phone');
                _passwordError = errorDetails.getFieldError('password');

                // Error banner will show automatically above the form
              } else {
                // Show general error using centralized service
                ErrorService.instance.showError(
                  context,
                  state.errorObject ?? state.message,
                  onRetry: _handleRegister,
                );
              }
            });
          } else if (state is AuthPhoneValidationSuccess && state.isValid) {
            // Check if phone is already registered
            if (state.isRegistered) {
              setState(() {
                _phoneError =
                    'This phone number is already registered. Please use a different number or sign in.';
              });
              return;
            }

            // Phone validation successful and not registered, proceed with registration
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

                    // Error banner - shows when there's a field error
                    if (_emailError != null ||
                        _usernameError != null ||
                        _phoneError != null ||
                        _passwordError != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: PulseSpacing.lg),
                        padding: const EdgeInsets.all(PulseSpacing.md),
                        decoration: BoxDecoration(
                          color: PulseColors.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: PulseColors.error,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: PulseColors.error,
                              size: 20,
                            ),
                            const SizedBox(width: PulseSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Please fix the following errors:',
                                    style: PulseTextStyles.labelMedium.copyWith(
                                      color: PulseColors.error,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: PulseSpacing.xs),
                                  if (_emailError != null)
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '• Email: $_emailError',
                                          style: PulseTextStyles.bodySmall
                                              .copyWith(
                                                color: PulseColors.error,
                                              ),
                                        ),
                                        // Recovery suggestion for email errors
                                        if (_emailError != null &&
                                            (_emailError!.contains('already') ||
                                                _emailError!.contains(
                                                  'registered',
                                                )))
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: PulseSpacing.xs,
                                            ),
                                            child: Text(
                                              '💡 Try a different email or sign in with your existing account',
                                              style: PulseTextStyles.labelSmall
                                                  .copyWith(
                                                    color: PulseColors.error,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                            ),
                                          ),
                                      ],
                                    )
                                  else
                                    const SizedBox.shrink(),
                                  if (_usernameError != null)
                                    Text(
                                      '• Username: $_usernameError',
                                      style: PulseTextStyles.bodySmall.copyWith(
                                        color: PulseColors.error,
                                      ),
                                    ),
                                  if (_phoneError != null)
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '• Phone: $_phoneError',
                                          style: PulseTextStyles.bodySmall
                                              .copyWith(
                                                color: PulseColors.error,
                                              ),
                                        ),
                                        // Recovery suggestion for phone errors
                                        if (_phoneError != null &&
                                            (_phoneError!.contains('already') ||
                                                _phoneError!.contains(
                                                  'registered',
                                                )))
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: PulseSpacing.xs,
                                            ),
                                            child: Text(
                                              '💡 Try a different phone number or sign in with your existing account',
                                              style: PulseTextStyles.labelSmall
                                                  .copyWith(
                                                    color: PulseColors.error,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                            ),
                                          ),
                                      ],
                                    )
                                  else
                                    const SizedBox.shrink(),
                                  if (_passwordError != null)
                                    Text(
                                      '• Password: $_passwordError',
                                      style: PulseTextStyles.bodySmall.copyWith(
                                        color: PulseColors.error,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Form fields
                    Column(
                      children: [
                        // Name input
                        PulseTextField(
                          controller: _nameController,
                          hintText: 'Username',
                          keyboardType: TextInputType.name,
                          prefixIcon: const Icon(Icons.person),
                          errorText: _usernameError != null ? ' ' : null,
                          onChanged: _onUsernameChanged,
                        ),
                        const SizedBox(height: PulseSpacing.lg),

                        // Email input
                        PulseTextField(
                          controller: _emailController,
                          hintText: 'Email Address',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(Icons.email),
                          errorText: _emailError != null ? ' ' : null,
                          onChanged: _onEmailChanged,
                        ),
                        const SizedBox(height: PulseSpacing.lg),

                        // Password input
                        PulseTextField(
                          controller: _passwordController,
                          hintText: 'Password',
                          obscureText: _obscurePassword,
                          prefixIcon: const Icon(Icons.lock),
                          errorText: _passwordError != null ? ' ' : null,
                          onChanged: _onPasswordChanged,
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
                        ),
                        const SizedBox(height: PulseSpacing.lg),

                        // Phone input with country selector
                        PhoneInput(
                          initialCountryCode: _selectedCountryCode,
                          onChanged: _onPhoneChanged,
                          onCountryChanged: _onCountryChanged,
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            hintText: 'Enter your phone number',
                            errorText: _phoneError != null ? ' ' : null,
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
