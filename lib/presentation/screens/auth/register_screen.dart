import 'package:flutter/material.dart';

/// Registration screen for new users
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: const Center(
        child: Text('Register Screen - TODO: Implement'),
      ),
    );
  }
}
