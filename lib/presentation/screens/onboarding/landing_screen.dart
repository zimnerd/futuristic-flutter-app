import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../navigation/app_router.dart';
import '../../theme/pulse_colors.dart';

/// Clean, modern landing page for first-time users
/// Focuses on clear value proposition and simple CTAs
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimationSequence();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
  }

  void _startAnimationSequence() {
    Future.delayed(const Duration(milliseconds: 200), () {
      _fadeController.forward();
    });

    Future.delayed(const Duration(milliseconds: 400), () {
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              PulseColors.primary,
              PulseColors.secondary,
              Color(0xFF1A1B5C),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: PulseSpacing.xl,
                vertical: PulseSpacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: PulseSpacing.xxl),

                  // Hero Section
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: _buildHeroSection(),
                    ),
                  ),

                  const SizedBox(height: PulseSpacing.xxl),

                  // Feature Highlights
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildFeatureHighlights(),
                  ),

                  const SizedBox(height: PulseSpacing.xxl),

                  // Social Proof
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildSocialProof(),
                  ),

                  const SizedBox(height: PulseSpacing.xxl * 1.5),

                  // CTAs
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildCTASection(),
                  ),

                  const SizedBox(height: PulseSpacing.xl),

                  // Terms
                  _buildTermsSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Column(
      children: [
        // App Icon with modern glassmorphism
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.25),
                Colors.white.withValues(alpha: 0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.4),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.favorite,
            size: 50,
            color: Colors.white,
          ),
        ),

        const SizedBox(height: PulseSpacing.xl),

        // App Name
        ShaderMask(
          shaderCallback: (Rect bounds) {
            return const LinearGradient(
              colors: [Colors.white, Color(0xFFE8F4FF)],
            ).createShader(bounds);
          },
          child: Text(
            'PulseLink',
            style: PulseTextStyles.displayLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 42,
              letterSpacing: -1,
            ),
          ),
        ),

        const SizedBox(height: PulseSpacing.md),

        // Tagline
        Text(
          'Find Your Vibe',
          style: PulseTextStyles.headlineMedium.copyWith(
            color: Colors.white.withValues(alpha: 0.95),
            fontWeight: FontWeight.w400,
            fontSize: 22,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: PulseSpacing.sm),

        Text(
          'Connect. Date. Discover.',
          style: PulseTextStyles.bodyLarge.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFeatureHighlights() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildFeatureBadge(
          icon: Icons.psychology,
          label: 'Smart\nMatch',
        ),
        _buildFeatureBadge(
          icon: Icons.video_call,
          label: 'Video\nDates',
        ),
        _buildFeatureBadge(
          icon: Icons.verified_user,
          label: 'Safe &\nSecure',
        ),
      ],
    );
  }

  Widget _buildFeatureBadge({
    required IconData icon,
    required String label,
  }) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(
        vertical: PulseSpacing.lg,
        horizontal: PulseSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(PulseRadii.lg),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(height: PulseSpacing.sm),
          Text(
            label,
            style: PulseTextStyles.labelMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSocialProof() {
    return Container(
      padding: const EdgeInsets.all(PulseSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(PulseRadii.lg),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.star,
          color: Colors.amber.shade300,
                size: 20,
        ),
        const SizedBox(width: 4),
        Text(
          '4.8',
                style: PulseTextStyles.titleMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: PulseSpacing.sm),
        Text(
          '•',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(width: PulseSpacing.sm),
        Text(
                '100K+ Matches Made',
                style: PulseTextStyles.bodyMedium.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
          ),
          const SizedBox(height: PulseSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle,
                color: PulseColors.success,
                size: 16,
              ),
              const SizedBox(width: PulseSpacing.xs),
              Text(
                'Verified & Trusted Community',
                style: PulseTextStyles.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCTASection() {
    return Column(
      children: [
        // Social media buttons FIRST (top priority)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSocialButton(
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
            const SizedBox(width: PulseSpacing.md),
            _buildSocialButton(
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
            const SizedBox(width: PulseSpacing.md),
            _buildSocialButton(
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
          ],
        ),

        const SizedBox(height: PulseSpacing.xl),

        // Divider with "or"
        Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: PulseSpacing.md),
              child: Text(
                'or',
                style: PulseTextStyles.labelMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),

        const SizedBox(height: PulseSpacing.xl),

        // Primary CTA (now secondary option)
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => context.go(AppRoutes.register),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: PulseColors.primary,
              elevation: 8,
              shadowColor: Colors.black.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(PulseRadii.lg),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Sign up with Email',
                  style: PulseTextStyles.titleMedium.copyWith(
                    color: PulseColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(width: PulseSpacing.sm),
                Icon(
                  Icons.email_outlined,
                  color: PulseColors.primary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: PulseSpacing.xl),

        // Secondary CTA
        TextButton(
          onPressed: () => context.go(AppRoutes.login),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: PulseSpacing.lg,
              vertical: PulseSpacing.md,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Already a member? ',
                style: PulseTextStyles.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              Text(
                'Sign In',
                style: PulseTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(PulseRadii.md),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(PulseRadii.md),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: PulseTextStyles.labelSmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTermsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: PulseSpacing.md),
      child: Text(
        'By continuing, you agree to our Terms of Service and Privacy Policy',
        style: PulseTextStyles.labelSmall.copyWith(
          color: Colors.white.withValues(alpha: 0.6),
          height: 1.4,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
