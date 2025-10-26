import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';

import '../../../core/utils/phone_utils.dart';
import '../../../core/utils/haptic_feedback_utils.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../theme/pulse_colors.dart';
import '../../widgets/common/keyboard_dismissible_scaffold.dart';
import '../../widgets/common/pulse_toast.dart';
import '../../widgets/developer_auto_login_fab.dart';
import '../../widgets/phone_input.dart';

/// Simple login screen with phone and email/password options
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPhoneMode = true;
  bool _obscurePassword = true;
  String _selectedCountryCode = PhoneUtils.defaultCountryCode;
  String _formattedPhoneNumber = '';
  String? _registrationSuccessMessage;

  @override
  void initState() {
    super.initState();
    // Initialize with location-based country detection
    _initializeCountryCode();
    // Check if user just registered
    _checkRegistrationSuccess();
  }

  /// Check if user just registered successfully
  void _checkRegistrationSuccess() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthRegistrationSuccess) {
      setState(() {
        _registrationSuccessMessage = authState.message;
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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

  void _handleLogin() {
    if (_formKey.currentState?.validate() == true) {
      // Haptic feedback for button press
      PulseHaptics.medium();

      if (_isPhoneMode) {
        // Show confirmation dialog before sending OTP
        _showPhoneConfirmationDialog();
      } else {
        // Use regular email/password login
        final email = _emailController.text.trim();
        final password = _passwordController.text.trim();
        context.read<AuthBloc>().add(
          AuthSignInRequested(email: email, password: password),
        );
      }
    }
  }

  /// Show confirmation dialog for phone number before sending OTP
  Future<void> _showPhoneConfirmationDialog() async {
    final phone = _formattedPhoneNumber.isNotEmpty
        ? _formattedPhoneNumber
        : _phoneController.text.trim();

    // Format the display number with country code
    String displayNumber = phone;
    if (!phone.startsWith('+')) {
      // Add + prefix if missing
      displayNumber = '+$phone';
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.phone_android,
                color: dialogContext.primaryColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Confirm Phone Number',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'We will send an OTP code to:',
                style: TextStyle(
                  fontSize: 14,
                  color: dialogContext.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: dialogContext.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: dialogContext.primaryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.verified_user,
                      color: dialogContext.primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        displayNumber,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: dialogContext.primaryColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: dialogContext.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'The OTP will be sent via WhatsApp',
                      style: TextStyle(
                        fontSize: 12,
                        color: dialogContext.textSecondary.withValues(
                          alpha: 0.8,
                        ),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Edit',
                style: TextStyle(
                  color: dialogContext.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: dialogContext.primaryColor,
                foregroundColor: dialogContext.theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Send OTP',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );

    // If user confirmed, send the OTP
    if (confirmed == true && mounted) {
      // Remove '+' prefix from phone number for backend
      final cleanPhone = phone.replaceAll('+', '');

      context.read<AuthBloc>().add(
        AuthOTPSendRequested(
          email: null, // No email for phone-only login
          phoneNumber: cleanPhone,
          countryCode: _selectedCountryCode,
          type: 'login',
          preferredMethod: 'whatsapp', // Use WhatsApp as preferred method
        ),
      );
    }
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }
    if (value.length < 10) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardDismissibleScaffold(
      floatingActionButton: const DeveloperAutoLoginFAB(),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          setState(() {
            _isLoading = state is AuthLoading;
          });

          if (state is AuthAuthenticated) {
            // Clear registration success message
            setState(() {
              _registrationSuccessMessage = null;
            });
            context.go('/home');
          } else if (state is AuthOTPSent) {
            // Navigate to OTP verification screen
            context.push(
              '/otp-verify',
              extra: {
                'sessionId': state.sessionId,
                'phoneNumber': _formattedPhoneNumber.isNotEmpty
                    ? _formattedPhoneNumber
                    : _phoneController.text.trim(),
                'deliveryMethods': state.deliveryMethods,
              },
            );
          } else if (state is AuthRegistrationSuccess) {
            // Update message if state changes
            setState(() {
              _registrationSuccessMessage = state.message;
            });
          } else if (state is AuthError) {
            PulseToast.error(context, message: state.message);
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
                const SizedBox(height: 60),

                // Logo and title
                Icon(
                  Icons.favorite,
                  size: 80,
                  color: PulseColors.primary,
                ),
                const SizedBox(height: 24),

                Text(
                  'Welcome Back',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.onSurfaceColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                Text(
                  'Sign in to continue',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: context.onSurfaceVariantColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Registration success banner
                if (_registrationSuccessMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.successColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: context.successColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: context.successColor,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '🎉 Account Created!',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: context.successColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _registrationSuccessMessage!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: context.onSurfaceColor.withValues(
                                    alpha: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Social media login buttons FIRST (top priority)
                Row(
                  children: [
                    Expanded(
                      child: _buildSocialLoginButton(
                        icon: Icons.g_mobiledata,
                        label: 'Google',
                        onPressed: () {
                          // TODO: Implement Google Sign In
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Google Sign In - Coming Soon'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSocialLoginButton(
                        icon: Icons.apple,
                        label: 'Apple',
                        onPressed: () {
                          // TODO: Implement Apple Sign In
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Apple Sign In - Coming Soon'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSocialLoginButton(
                        icon: Icons.facebook,
                        label: 'Facebook',
                        onPressed: () {
                          // TODO: Implement Facebook Sign In
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Facebook Sign In - Coming Soon'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Divider with "or sign in with"
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'or sign in with',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),

                const SizedBox(height: 24),

                // Toggle between phone and email login
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => setState(() => _isPhoneMode = true),
                        style: TextButton.styleFrom(
                          backgroundColor: _isPhoneMode
                              ? PulseColors.primary.withValues(alpha: 0.1)
                              : null,
                          foregroundColor: _isPhoneMode
                              ? PulseColors.primary
                              : PulseColors.onSurfaceVariant,
                        ),
                        child: Text('Phone'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextButton(
                        onPressed: () => setState(() => _isPhoneMode = false),
                        style: TextButton.styleFrom(
                          backgroundColor: !_isPhoneMode
                              ? PulseColors.primary.withValues(alpha: 0.1)
                              : null,
                          foregroundColor: !_isPhoneMode
                              ? PulseColors.primary
                              : PulseColors.onSurfaceVariant,
                        ),
                        child: Text('Email'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Login form
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_isPhoneMode) ...[
                        // Phone login with country picker
                        PhoneInput(
                          initialCountryCode: _selectedCountryCode,
                          onChanged: (formattedPhone) {
                            setState(() {
                              _formattedPhoneNumber = formattedPhone;
                            });
                          },
                          onCountryChanged: (countryCode) {
                            setState(() {
                              _selectedCountryCode = countryCode;
                            });
                          },
                          validator: _validatePhone,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            hintText: 'Enter your phone number',
                          ),
                        ),
                      ] else ...[
                        // Email login
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: _validateEmail,
                          style: TextStyle(color: context.onSurfaceColor),
                          decoration: InputDecoration(
                            labelText: 'Email',
                            hintText: 'Enter your email address',
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: context.formFieldBorder,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: context.formFieldBorder,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: context.formFieldBorderFocused,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: context.formFieldBackground,
                            floatingLabelBehavior: FloatingLabelBehavior.auto,
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          validator: _validatePassword,
                          style: TextStyle(color: context.onSurfaceColor),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Enter your password',
                            prefixIcon: Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: context.formFieldBorder,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: context.formFieldBorder,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: context.formFieldBorderFocused,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: context.formFieldBackground,
                            floatingLabelBehavior: FloatingLabelBehavior.auto,
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),

                      // Extra space for keyboard
                      const SizedBox(height: 80),

                      // Login button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PulseColors.primary,
                          foregroundColor: context.theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    context.theme.colorScheme.onPrimary,
                                  ),
                                ),
                              )
                            : Text(
                                _isPhoneMode ? 'Send OTP' : 'Sign In',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),

                      if (!_isPhoneMode) ...[
                        const SizedBox(height: 16),

                        // Forgot password
                        TextButton(
                          onPressed: () => context.push('/forgot-password'),
                          child: Text('Forgot Password?'),
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Register link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: PulseColors.onSurfaceVariant),
                          ),
                          TextButton(
                            onPressed: () => context.push('/register'),
                            child: Text('Sign Up'),
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

  Widget _buildSocialLoginButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: BorderSide(color: PulseColors.outline, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24, color: Theme.of(context).colorScheme.onSurface),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface),
          ),
        ],
      ),
    );
  }
}
