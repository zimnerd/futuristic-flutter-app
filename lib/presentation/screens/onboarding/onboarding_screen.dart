import 'package:flutter/material.dart';

/// Onboarding screen for user setup
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Your Profile'),
      ),
      body: const Center(
        child: Text('Onboarding Screen - TODO: Implement'),
      ),
    );
  }
}
