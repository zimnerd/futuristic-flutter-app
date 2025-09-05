import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../navigation/app_router.dart';
import '../../theme/pulse_colors.dart';
import '../../widgets/common/common_widgets.dart';

/// Enhanced welcome screen with actual functionality
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [PulseColors.primary, PulseColors.secondary],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(PulseSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo placeholder
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(PulseRadii.xl),
                  ),
                  child: const Icon(
                    Icons.favorite,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: PulseSpacing.xl),

                // App name
                Text(
                  'PulseLink',
                  style: PulseTextStyles.displayLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: PulseSpacing.md),

                // Tagline
                Text(
                  'Find your perfect match',
                  style: PulseTextStyles.headlineSmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: PulseSpacing.xxl),

                // Action buttons
                Column(
                  children: [
                    PulseButton(
                      text: 'Get Started',
                      onPressed: () => context.go(AppRoutes.register),
                      variant: PulseButtonVariant.secondary,
                      fullWidth: true,
                      icon: const Icon(Icons.arrow_forward),
                    ),
                    const SizedBox(height: PulseSpacing.md),
                    PulseButton(
                      text: 'I already have an account',
                      onPressed: () => context.go(AppRoutes.login),
                      variant: PulseButtonVariant.tertiary,
                      fullWidth: true,
                    ),
                  ],
                ),
                const Spacer(),

                // Terms and privacy
                Text(
                  'By continuing, you agree to our Terms of Service and Privacy Policy',
                  style: PulseTextStyles.labelSmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
