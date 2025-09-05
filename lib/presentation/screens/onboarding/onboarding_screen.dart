import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/pulse_colors.dart';
import '../../widgets/common/common_widgets.dart';

/// Enhanced onboarding screen with profile setup flow
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 4;

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
      // Complete onboarding
      context.go('/home');
    }
  }

  void _skipOnboarding() {
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              PulseColors.primary.withValues(alpha: 0.1),
              PulseColors.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(PulseSpacing.lg),
                  child: TextButton(
                    onPressed: _skipOnboarding,
                    child: Text(
                      'Skip',
                      style: PulseTextStyles.bodyLarge.copyWith(
                        color: PulseColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              // Page content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  children: [
                    _buildWelcomePage(),
                    _buildInterestsPage(),
                    _buildLocationPage(),
                    _buildNotificationsPage(),
                  ],
                ),
              ),

              // Page indicator and navigation
              Padding(
                padding: const EdgeInsets.all(PulseSpacing.xl),
                child: Column(
                  children: [
                    // Page indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _totalPages,
                        (index) => Container(
                          width: index == _currentPage ? 24 : 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: index == _currentPage
                                ? PulseColors.primary
                                : PulseColors.primary.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: PulseSpacing.xl),

                    // Next button
                    PulseButton(
                      text: _currentPage == _totalPages - 1
                          ? 'Get Started'
                          : 'Next',
                      onPressed: _nextPage,
                      fullWidth: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(PulseSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: PulseColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.favorite, size: 60, color: PulseColors.primary),
          ),
          const SizedBox(height: PulseSpacing.xxl),

          Text(
            'Welcome to Pulse',
            style: PulseTextStyles.displayMedium.copyWith(
              color: PulseColors.onSurface,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: PulseSpacing.lg),
          Text(
            'Find meaningful connections with people who share your interests and values.',
            style: PulseTextStyles.bodyLarge.copyWith(
              color: PulseColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsPage() {
    return Padding(
      padding: const EdgeInsets.all(PulseSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: PulseColors.secondary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.interests,
              size: 60,
              color: PulseColors.secondary,
            ),
          ),
          const SizedBox(height: PulseSpacing.xxl),

          Text(
            'Share Your Interests',
            style: PulseTextStyles.displayMedium.copyWith(
              color: PulseColors.onSurface,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: PulseSpacing.lg),
          Text(
            'Tell us what you love to do. This helps us find people with similar passions.',
            style: PulseTextStyles.bodyLarge.copyWith(
              color: PulseColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationPage() {
    return Padding(
      padding: const EdgeInsets.all(PulseSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: PulseColors.secondary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_on,
              size: 60,
              color: PulseColors.secondary,
            ),
          ),
          const SizedBox(height: PulseSpacing.xxl),

          Text(
            'Enable Location',
            style: PulseTextStyles.displayMedium.copyWith(
              color: PulseColors.onSurface,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: PulseSpacing.lg),
          Text(
            'We use your location to show you people nearby and improve your matching experience.',
            style: PulseTextStyles.bodyLarge.copyWith(
              color: PulseColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsPage() {
    return Padding(
      padding: const EdgeInsets.all(PulseSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: PulseColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications,
              size: 60,
              color: PulseColors.success,
            ),
          ),
          const SizedBox(height: PulseSpacing.xxl),

          Text(
            'Stay Connected',
            style: PulseTextStyles.displayMedium.copyWith(
              color: PulseColors.onSurface,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: PulseSpacing.lg),
          Text(
            'Get notified when you have new matches, messages, and activity updates.',
            style: PulseTextStyles.bodyLarge.copyWith(
              color: PulseColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
