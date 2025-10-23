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

/// Enhanced registration screen with verification method selection
/// Supports both email and WhatsApp verification
class EnhancedRegisterScreen extends StatefulWidget {
  final String? phoneNumber;

  const EnhancedRegisterScreen({super.key, this.phoneNumber});

  @override
  State<EnhancedRegisterScreen> createState() => _EnhancedRegisterScreenState();
}

class _EnhancedRegisterScreenState extends State<EnhancedRegisterScreen> {
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

  // Verification method selection
  String _verificationMethod = 'whatsapp'; // 'whatsapp' or 'email'
  bool _phoneIsWhatsApp = false;
  bool _checkingWhatsApp = false;

  String? _emailError;
  String? _usernameError;
  String? _phoneError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _initializeCountryCode();

    // Pre-fill phone number if provided (from OTP verification)
    if (widget.phoneNumber != null) {
      final phone = widget.phoneNumber!;
      if (phone.startsWith('+')) {
        final phoneWithoutPlus = phone.substring(1);
        if (phoneWithoutPlus.startsWith('27')) {
          _selectedCountryCode = '+27';
          _phoneController.text = phoneWithoutPlus.substring(2);
        } else if (phoneWithoutPlus.startsWith('1')) {
          _selectedCountryCode = '+1';
          _phoneController.text = phoneWithoutPlus.substring(1);
        } else {
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

  void _onPhoneChanged(String formattedPhone) {
    setState(() {
      _currentPhone = formattedPhone;
      _phoneIsWhatsApp = false; // Reset WhatsApp status on change
    });
  }

  void _onCountryChanged(String countryCode) {
    setState(() {
      _selectedCountryCode = countryCode;
      _phoneIsWhatsApp = false; // Reset WhatsApp status on change
    });
  }

  Future<void> _checkWhatsAppAvailability() async {
    if (_currentPhone.isEmpty && _phoneController.text.isEmpty) {
      return;
    }

    setState(() {
      _checkingWhatsApp = true;
    });

    final cleanedPhone = PhoneUtils.cleanPhoneForSubmission(
      _currentPhone.isNotEmpty ? _currentPhone : _phoneController.text,
      _selectedCountryCode,
    );

    // Validate phone with backend
    context.read<AuthBloc>().add(
      AuthPhoneValidationRequested(
        phone: cleanedPhone,
        countryCode: _selectedCountryCode,
      ),
    );
  }

  void _handleRegister() {
    if (_formKey.currentState?.validate() == true && _acceptedTerms) {
      // Check if WhatsApp verification is selected but phone not on WhatsApp
      if (_verificationMethod == 'whatsapp' && !_phoneIsWhatsApp) {
        setState(() {
          _verificationMethod = 'email'; // Fall back to email
        });
        PulseToast.info(
          context,
          message: 'Phone not on WhatsApp. Using email verification instead.',
        );
      }

      // Proceed with registration
      _proceedWithRegistration();
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

  @override
  Widget build(BuildContext context) {
    return KeyboardDismissibleScaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          setState(() {
            _isLoading = state is AuthLoading || state is AuthPhoneValidating;
            _checkingWhatsApp = state is AuthPhoneValidating;

            // Clear field errors when loading
            if (state is AuthLoading || state is AuthPhoneValidating) {
              _emailError = null;
              _usernameError = null;
              _phoneError = null;
              _passwordError = null;
            }
          });

          if (state is AuthError) {
            final errorDetails = ErrorService.instance.parseError(
              state.errorObject ?? state.message,
            );

            setState(() {
              _emailError = null;
              _usernameError = null;
              _phoneError = null;
              _passwordError = null;

              if (errorDetails.hasFieldErrors) {
                _emailError = errorDetails.getFieldError('email');
                _usernameError = errorDetails.getFieldError('username');
                _phoneError = errorDetails.getFieldError('phone');
                _passwordError = errorDetails.getFieldError('password');

                Future.delayed(const Duration(milliseconds: 100), () {
                  _formKey.currentState?.validate();
                });
              } else {
                ErrorService.instance.showError(
                  context,
                  state.errorObject ?? state.message,
                  onRetry: _handleRegister,
                );
              }
            });
          } else if (state is AuthPhoneValidationSuccess) {
            setState(() {
              _phoneIsWhatsApp = state.isValid;
              if (!state.isValid) {
                // If phone is not on WhatsApp, default to email verification
                _verificationMethod = 'email';
              }
            });
          } else if (state is AuthPhoneValidationError) {
            setState(() {
              _phoneIsWhatsApp = false;
              _verificationMethod = 'email'; // Default to email on error
            });
            PulseToast.warning(
              context,
              message: 'Unable to verify WhatsApp. Using email verification.',
            );
          } else if (state is AuthRegistrationSuccess) {
            PulseToast.success(
              context,
              message: 'Account created successfully! Please log in to continue.',
              duration: const Duration(seconds: 4),
            );
            context.go('/login');
          }
        },
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [PulseColors.surface, Color(0xFFF8F9FA)],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: PulseSpacing.xl,
                right: PulseSpacing.xl,
                top: PulseSpacing.xl,
                bottom: MediaQuery.of(context).viewInsets.bottom + PulseSpacing.xl,
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
                    const SizedBox(height: PulseSpacing.lg),

                    // Header
                    Text(
                      'Join PulseLink',
                      style: PulseTextStyles.displaySmall.copyWith(
                        color: PulseColors.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                      ),
                    ),
                    const SizedBox(height: PulseSpacing.sm),
                    Text(
                      'Create your account and start connecting',
                      style: PulseTextStyles.bodyLarge.copyWith(
                        color: PulseColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: PulseSpacing.xxl),

                    // Form fields
                    _buildFormFields(),

                    const SizedBox(height: PulseSpacing.xl),

                    // Verification method selection
                    _buildVerificationMethodSelector(),

                    const SizedBox(height: PulseSpacing.xl),

                    // Terms checkbox
                    _buildTermsCheckbox(),

                    const SizedBox(height: PulseSpacing.xl),

                    // Register button
                    PulseButton(
                      text: 'Create Account',
                      onPressed: _isLoading ? null : _handleRegister,
                      fullWidth: true,
                      isLoading: _isLoading,
                    ),

                    const SizedBox(height: PulseSpacing.lg),

                    // Sign in prompt
                    _buildSignInPrompt(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        // Name input
        PulseTextField(
          controller: _nameController,
          hintText: 'Username',
          keyboardType: TextInputType.name,
          prefixIcon: const Icon(Icons.person_outline),
          validator: (value) {
            if (_usernameError != null) return _usernameError;
            return ValidationHelpers.validateUsername(value);
          },
        ),
        const SizedBox(height: PulseSpacing.lg),

        // Email input
        PulseTextField(
          controller: _emailController,
          hintText: 'Email Address',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: const Icon(Icons.email_outlined),
          validator: (value) {
            if (_emailError != null) return _emailError;
            return ValidationHelpers.validateEmail(value);
          },
        ),
        const SizedBox(height: PulseSpacing.lg),

        // Password input
        PulseTextField(
          controller: _passwordController,
          hintText: 'Password',
          obscureText: _obscurePassword,
          prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
          validator: (value) {
            if (_passwordError != null) return _passwordError;
            return ValidationHelpers.validatePassword(value);
          },
        ),
        const SizedBox(height: PulseSpacing.lg),

        // Phone input with WhatsApp check
        PhoneInput(
          initialCountryCode: _selectedCountryCode,
          onChanged: _onPhoneChanged,
          onCountryChanged: _onCountryChanged,
          validator: (value) {
            if (_phoneError != null) return _phoneError;
            return ValidationHelpers.validatePhone(value);
          },
          decoration: InputDecoration(
            labelText: 'Phone Number',
            hintText: 'Enter your phone number',
            suffixIcon: _checkingWhatsApp
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : _phoneIsWhatsApp
                    ? IconButton(
                        icon: const Icon(Icons.check_circle, color: PulseColors.success),
                        onPressed: null,
                        tooltip: 'WhatsApp verified',
                      )
                    : IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _checkWhatsAppAvailability,
                        tooltip: 'Check WhatsApp',
                      ),
          ),
        ),
        if (_phoneIsWhatsApp)
          Padding(
            padding: const EdgeInsets.only(top: PulseSpacing.xs, left: PulseSpacing.sm),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 14,
                  color: PulseColors.success,
                ),
                const SizedBox(width: 4),
                Text(
                  'WhatsApp verified',
                  style: PulseTextStyles.labelSmall.copyWith(
                    color: PulseColors.success,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildVerificationMethodSelector() {
    return Container(
      padding: const EdgeInsets.all(PulseSpacing.md),
      decoration: BoxDecoration(
        color: PulseColors.primaryContainer,
        borderRadius: BorderRadius.circular(PulseRadii.md),
        border: Border.all(
          color: PulseColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.verified_user,
                size: 18,
                color: PulseColors.primary,
              ),
              const SizedBox(width: PulseSpacing.sm),
              Text(
                'Verification Method',
                style: PulseTextStyles.titleSmall.copyWith(
                  color: PulseColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: PulseSpacing.sm),
          Text(
            'Choose how you\'d like to verify your account',
            style: PulseTextStyles.bodySmall.copyWith(
              color: PulseColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: PulseSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildVerificationOption(
                  value: 'whatsapp',
                  icon: Icons.phone_android,
                  title: 'WhatsApp',
                  subtitle: 'Quick code via WhatsApp',
                  enabled: _phoneIsWhatsApp,
                ),
              ),
              const SizedBox(width: PulseSpacing.sm),
              Expanded(
                child: _buildVerificationOption(
                  value: 'email',
                  icon: Icons.email_outlined,
                  title: 'Email',
                  subtitle: 'Code via email',
                  enabled: true,
                ),
              ),
            ],
          ),
          if (_verificationMethod == 'whatsapp' && !_phoneIsWhatsApp)
            Padding(
              padding: const EdgeInsets.only(top: PulseSpacing.sm),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: PulseColors.warning,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Tap the refresh icon to check if your number is on WhatsApp',
                      style: PulseTextStyles.labelSmall.copyWith(
                        color: PulseColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVerificationOption({
    required String value,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool enabled,
  }) {
    final isSelected = _verificationMethod == value;

    return GestureDetector(
      onTap: enabled
          ? () {
              setState(() {
                _verificationMethod = value;
              });
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(PulseSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? PulseColors.primary.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(PulseRadii.md),
          border: Border.all(
            color: isSelected
                ? PulseColors.primary
                : enabled
                    ? PulseColors.outline
                    : PulseColors.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: enabled
                  ? (isSelected ? PulseColors.primary : PulseColors.onSurface)
                  : PulseColors.onSurfaceVariant,
              size: 28,
            ),
            const SizedBox(height: PulseSpacing.xs),
            Text(
              title,
              style: PulseTextStyles.labelMedium.copyWith(
                color: enabled
                    ? (isSelected ? PulseColors.primary : PulseColors.onSurface)
                    : PulseColors.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: PulseTextStyles.labelSmall.copyWith(
                color: PulseColors.onSurfaceVariant,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _acceptedTerms,
          onChanged: (value) {
            setState(() {
              _acceptedTerms = value ?? false;
            });
          },
          fillColor: WidgetStateProperty.resolveWith((states) {
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
    );
  }

  Widget _buildSignInPrompt() {
    return Row(
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
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Sign In',
            style: PulseTextStyles.bodyMedium.copyWith(
              color: PulseColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
