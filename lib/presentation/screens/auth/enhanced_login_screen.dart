import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../theme/pulse_colors.dart';
import '../../../data/services/biometric_service.dart';

/// Enhanced login screen with comprehensive validation and biometric auth
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _twoFactorCodeController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _trustDevice = false;
  bool _requiresTwoFactor = false;
  String? _twoFactorSessionId;
  bool _biometricEnabled = false;
  final BiometricService _biometricService = BiometricService();

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _twoFactorCodeController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricAvailability() async {
    // Check if biometric auth is available and enabled
    final isAvailable = await _biometricService.isBiometricAvailable();
    final hasEnrolled = await _biometricService.hasEnrolledBiometrics();
    
    setState(() {
      _biometricEnabled = isAvailable && hasEnrolled;
    });
  }

  void _handleLogin() {
    if (_formKey.currentState?.validate() == true) {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      
      context.read<AuthBloc>().add(
        AuthSignInRequested(
          email: email,
          password: password,
          rememberMe: _rememberMe,
          trustDevice: _trustDevice,
        ),
      );
    }
  }

  void _handleTwoFactorSubmit() {
    if (_twoFactorCodeController.text.trim().isNotEmpty && _twoFactorSessionId != null) {
      context.read<AuthBloc>().add(
        AuthTwoFactorVerifyRequested(
          sessionId: _twoFactorSessionId!,
          code: _twoFactorCodeController.text.trim(),
        ),
      );
    }
  }

  void _handleBiometricLogin() async {
    // Trigger biometric authentication
    context.read<AuthBloc>().add(const AuthBiometricSignInRequested());
  }

  void _handleForgotPassword() {
    context.push('/auth/forgot-password');
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          setState(() {
            _isLoading = state is AuthLoading;
          });

          if (state is AuthTwoFactorRequired) {
            setState(() {
              _requiresTwoFactor = true;
              _twoFactorSessionId = state.sessionId;
            });
          } else if (state is AuthAuthenticated) {
            // Clear 2FA state and navigate to home
            setState(() {
              _requiresTwoFactor = false;
              _twoFactorSessionId = null;
            });
            context.go('/home');
          } else if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
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
                  'Sign in to continue your journey',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: PulseColors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                
                // Main form or 2FA form
                if (!_requiresTwoFactor) ...[
                  // Main login form
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Email field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: _validateEmail,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            hintText: 'Enter your email address',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Password field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          validator: _validatePassword,
                          onFieldSubmitted: (_) => _handleLogin(),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Enter your password',
                            prefixIcon: const Icon(Icons.lock_outlined),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Remember me and trust device checkboxes
                        Row(
                          children: [
                            Expanded(
                              child: CheckboxListTile(
                                title: const Text('Remember me'),
                                value: _rememberMe,
                                onChanged: (value) {
                                  setState(() {
                                    _rememberMe = value ?? false;
                                  });
                                },
                                controlAffinity: ListTileControlAffinity.leading,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                        
                        CheckboxListTile(
                          title: const Text('Trust this device'),
                          subtitle: const Text('Skip 2FA on this device in the future'),
                          value: _trustDevice,
                          onChanged: (value) {
                            setState(() {
                              _trustDevice = value ?? false;
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: 24),
                        
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
                              : const Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Biometric login button (if available)
                        if (_biometricEnabled)
                          OutlinedButton.icon(
                            onPressed: _isLoading ? null : _handleBiometricLogin,
                            icon: const Icon(Icons.fingerprint),
                            label: const Text('Sign in with biometrics'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        
                        const SizedBox(height: 16),
                        
                        // Forgot password link
                        TextButton(
                          onPressed: _handleForgotPassword,
                          child: const Text('Forgot your password?'),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Two-factor authentication form
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.security,
                        size: 64,
                        color: PulseColors.primary,
                      ),
                      const SizedBox(height: 24),
                      
                      Text(
                        'Two-Factor Authentication',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      
                      Text(
                        'Please enter the verification code sent to your email',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: PulseColors.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      
                      // 2FA code field
                      TextFormField(
                        controller: _twoFactorCodeController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 8,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Verification Code',
                          hintText: '000000',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onFieldSubmitted: (_) => _handleTwoFactorSubmit(),
                      ),
                      const SizedBox(height: 24),
                      
                      // Verify button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleTwoFactorSubmit,
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
                            : const Text(
                                'Verify',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Back to login
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _requiresTwoFactor = false;
                            _twoFactorSessionId = null;
                            _twoFactorCodeController.clear();
                          });
                        },
                        child: const Text('Back to login'),
                      ),
                    ],
                  ),
                ],
                
                const SizedBox(height: 48),
                
                // Sign up link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () => context.push('/auth/register'),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
