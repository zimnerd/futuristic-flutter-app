import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../theme/pulse_colors.dart';
import '../../widgets/developer_auto_login_fab.dart';

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

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState?.validate() == true) {
      if (_isPhoneMode) {
        final phone = _phoneController.text.trim();
        context.read<AuthBloc>().add(
          AuthSignInRequested(email: phone, password: 'temp'),
        );
      } else {
        final email = _emailController.text.trim();
        final password = _passwordController.text.trim();
        context.read<AuthBloc>().add(
          AuthSignInRequested(email: email, password: password),
        );
      }
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
                          backgroundColor: _isPhoneMode ? PulseColors.primary.withOpacity(0.1) : null,
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
                          backgroundColor: !_isPhoneMode ? PulseColors.primary.withOpacity(0.1) : null,
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
                        // Phone login
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          validator: _validatePhone,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            hintText: 'Enter your phone number',
                            prefixIcon: Icon(Icons.phone),
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