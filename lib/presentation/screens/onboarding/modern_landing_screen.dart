import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../navigation/app_router.dart';
import '../../theme/pulse_colors.dart';

/// Modern landing page with stunning visuals and smooth onboarding
class ModernLandingScreen extends StatefulWidget {
  const ModernLandingScreen({super.key});

  @override
  State<ModernLandingScreen> createState() => _ModernLandingScreenState();
}

class _ModernLandingScreenState extends State<ModernLandingScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimationSequence();
    _checkFirstLaunch();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
  }

  void _startAnimationSequence() {
    Future.delayed(const Duration(milliseconds: 300), () {
      _fadeController.forward();
    });
    
    Future.delayed(const Duration(milliseconds: 500), () {
      _slideController.forward();
    });
    
    Future.delayed(const Duration(milliseconds: 700), () {
      _scaleController.forward();
    });
  }

  void _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
    
    if (!hasSeenOnboarding) {
      // Show onboarding after a delay
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          _showOnboarding();
        }
      });
    }
  }

  void _showOnboarding() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, _) => const ModernOnboardingFlow(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
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
          child: Stack(
            children: [
              // Background particles/shapes
              _buildBackgroundElements(),
              
              // Main content with skip button
              SingleChildScrollView(
                padding: const EdgeInsets.all(PulseSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Skip button at the top
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 60), // Balance for centering
                        const Spacer(),
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: TextButton(
                            onPressed: () => context.go('/login'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white70,
                              padding: const EdgeInsets.symmetric(
                                horizontal: PulseSpacing.md,
                                vertical: PulseSpacing.sm,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Skip'),
                                SizedBox(width: 4),
                                Icon(Icons.favorite_outline, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: PulseSpacing.lg),

                    // Top section with logo and branding
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: _buildBrandingSection(),
                      ),
                    ),

                    const SizedBox(height: PulseSpacing.xl),

                    // Features showcase
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildFeaturesSection(),
                    ),

                    const SizedBox(height: PulseSpacing.xxl),

                    // Action buttons
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: _buildActionButtons(),
                    ),

                    const SizedBox(height: PulseSpacing.lg),

                    // Terms and privacy
                    _buildTermsSection(),

                    // Extra padding at bottom to ensure content doesn't get cut off
                    const SizedBox(height: PulseSpacing.xl),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundElements() {
    return Stack(
      children: [
        // Floating hearts
        Positioned(
          top: 100,
          right: 50,
          child: AnimatedBuilder(
            animation: _scaleController,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              );
            },
          ),
        ),
        
        // More decorative elements
        Positioned(
          bottom: 200,
          left: 30,
          child: AnimatedBuilder(
            animation: _slideController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - _slideAnimation.value.dy)),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(PulseRadii.lg),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBrandingSection() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Modern logo container
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.2),
                Colors.white.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(35),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.favorite,
            size: 70,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(height: PulseSpacing.xl),
        
        // App name with modern typography
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
              fontSize: 48,
              letterSpacing: -1,
            ),
          ),
        ),
        
        const SizedBox(height: PulseSpacing.sm),
        
        // Enhanced tagline
        Text(
          'Where Hearts Connect In Perfect Harmony',
          style: PulseTextStyles.headlineSmall.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
            fontWeight: FontWeight.w300,
            height: 1.3,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFeaturesSection() {
    return Column(
      children: [
        // Animated feature cards
        AnimatedBuilder(
          animation: _slideController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, 30 * (1 - _slideAnimation.value.dy)),
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: _buildFeatureItem(
                  icon: Icons.psychology,
                  title: 'AI-Powered Matching',
                  subtitle: 'Find your perfect match with smart algorithms',
                ),
              ),
            );
          },
        ),
        
        const SizedBox(height: PulseSpacing.md),
        
        AnimatedBuilder(
          animation: _slideController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, 40 * (1 - _slideAnimation.value.dy)),
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: _buildFeatureItem(
                  icon: Icons.video_call,
                  title: 'Video Calls & AR',
                  subtitle: 'Connect face-to-face with immersive experiences',
                ),
              ),
            );
          },
        ),
        
        const SizedBox(height: PulseSpacing.md),
        
        AnimatedBuilder(
          animation: _slideController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, 50 * (1 - _slideAnimation.value.dy)),
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: _buildFeatureItem(
                  icon: Icons.security,
                  title: 'Safe & Secure',
                  subtitle: 'Your privacy and safety are our top priority',
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(PulseSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(PulseRadii.lg),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(PulseRadii.md),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: PulseSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: PulseTextStyles.titleSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: PulseTextStyles.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Primary CTA
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.white, Color(0xFFF0F8FF)],
            ),
            borderRadius: BorderRadius.circular(PulseRadii.lg),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () => context.go(AppRoutes.register),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(PulseRadii.lg),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Start Your Journey',
                  style: PulseTextStyles.titleMedium.copyWith(
                    color: PulseColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: PulseSpacing.sm),
                Icon(
                  Icons.arrow_forward,
                  color: PulseColors.primary,
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: PulseSpacing.lg),
        
        // Secondary CTA
        TextButton(
          onPressed: () => context.go(AppRoutes.login),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: PulseSpacing.md),
          ),
          child: Text(
            'I already have an account',
            style: PulseTextStyles.titleSmall.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              decoration: TextDecoration.underline,
              decorationColor: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTermsSection() {
    return Text(
      'By continuing, you agree to our Terms of Service and Privacy Policy',
      style: PulseTextStyles.labelSmall.copyWith(
        color: Colors.white.withValues(alpha: 0.6),
        height: 1.4,
      ),
      textAlign: TextAlign.center,
    );
  }
}

/// Modern onboarding flow with interactive screens
class ModernOnboardingFlow extends StatefulWidget {
  const ModernOnboardingFlow({super.key});

  @override
  State<ModernOnboardingFlow> createState() => _ModernOnboardingFlowState();
}

class _ModernOnboardingFlowState extends State<ModernOnboardingFlow> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 3;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    
    if (mounted) {
      Navigator.of(context).pop();
      context.go(AppRoutes.register);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PulseColors.surface,
      body: SafeArea(
        child: Stack(
          children: [
            PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentPage = index),
              children: [
                _buildOnboardingPage(
                  title: 'Discover Your\\nPerfect Match',
                  subtitle: 'Our AI-powered algorithm learns your preferences to find your ideal partner',
                  asset: 'assets/onboarding/match.json', // Lottie animation
                  color: PulseColors.primary,
                ),
                _buildOnboardingPage(
                  title: 'Connect Through\\nVideo & AR',
                  subtitle: 'Experience immersive dates with video calls and augmented reality features',
                  asset: 'assets/onboarding/video.json',
                  color: PulseColors.secondary,
                ),
                _buildOnboardingPage(
                  title: 'Safe & Secure\\nDating',
                  subtitle: 'Your privacy matters. Date with confidence using our verified profiles and safety features',
                  asset: 'assets/onboarding/safety.json',
                  color: PulseColors.success,
                ),
              ],
            ),
            
            // Page indicators
            Positioned(
              bottom: 120,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_totalPages, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? PulseColors.primary
                          : PulseColors.onSurfaceVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
            
            // Navigation buttons
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: () => _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                      child: Text(
                        'Back',
                        style: TextStyle(color: PulseColors.onSurfaceVariant),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  
                  ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PulseColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    child: Text(
                      _currentPage == _totalPages - 1 ? 'Get Started' : 'Next',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            
            // Skip button
            Positioned(
              top: 20,
              right: 20,
              child: TextButton(
                onPressed: _completeOnboarding,
                child: Text(
                  'Skip',
                  style: TextStyle(color: PulseColors.onSurfaceVariant),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingPage({
    required String title,
    required String subtitle,
    required String asset,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.all(PulseSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animation placeholder (would use Lottie in real implementation)
          Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(PulseRadii.xl),
            ),
            child: Icon(
              Icons.favorite,
              size: 120,
              color: color,
            ),
          ),
          
          const SizedBox(height: PulseSpacing.xxl),
          
          Text(
            title,
            style: PulseTextStyles.displaySmall.copyWith(
              fontWeight: FontWeight.bold,
              color: PulseColors.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: PulseSpacing.lg),
          
          Text(
            subtitle,
            style: PulseTextStyles.bodyLarge.copyWith(
              color: PulseColors.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}