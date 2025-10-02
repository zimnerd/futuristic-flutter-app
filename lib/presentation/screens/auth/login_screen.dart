import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/phone_utils.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../theme/pulse_colors.dart';
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

  @override
  void initState() {
    super.initState();
    // Initialize with location-based country detection
    _initializeCountryCode();
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
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.phone_android,
                color: PulseColors.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Confirm Phone Number',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'We will send an OTP code to:',
                style: TextStyle(
                  fontSize: 14,
                  color: PulseColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: PulseColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: PulseColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.verified_user,
                      color: PulseColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        displayNumber,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: PulseColors.primary,
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
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: PulseColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'The OTP will be sent via WhatsApp',
                      style: TextStyle(
                        fontSize: 12,
                        color: PulseColors.onSurfaceVariant.withValues(
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
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Edit',
                style: TextStyle(
                  color: PulseColors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: PulseColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
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
    return Scaffold(
      floatingActionButton: const DeveloperAutoLoginFAB(),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          setState(() {
            _isLoading = state is AuthLoading;
          });

          if (state is AuthAuthenticated) {
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
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: PulseColors.error,
              ),
            );
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                
                // Logo and title
                const Icon(
                  Icons.favorite,
                  size: 80,
                  color: PulseColors.primary,
                ),
                const SizedBox(height: 24),
                
                Text(
                  'Welcome Back',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: PulseColors.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                
                Text(
                  'Sign in to continue',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: PulseColors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                
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
                          foregroundColor: _isPhoneMode ? PulseColors.primary : PulseColors.onSurfaceVariant,
                        ),
                        child: const Text('Phone'),
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
                          foregroundColor: !_isPhoneMode ? PulseColors.primary : PulseColors.onSurfaceVariant,
                        ),
                        child: const Text('Email'),
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
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'Enter your email address',
                            prefixIcon: Icon(Icons.email),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          validator: _validatePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Enter your password',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      
                      // Login button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
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
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                _isPhoneMode ? 'Send OTP' : 'Sign In',
                                style: const TextStyle(
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
                          child: const Text('Forgot Password?'),
                        ),
                      ],
                      
                      const SizedBox(height: 32),
                      
                      // Register link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: PulseColors.onSurfaceVariant,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.push('/register'),
                            child: const Text('Sign Up'),
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