import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../business_logic/blocs/ai_preferences_bloc.dart';

/// AI onboarding dialog to introduce users to AI features
class AiOnboardingDialog extends StatefulWidget {
  const AiOnboardingDialog({super.key});

  @override
  State<AiOnboardingDialog> createState() => _AiOnboardingDialogState();
}

class _AiOnboardingDialogState extends State<AiOnboardingDialog>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  int _currentPage = 0;
  bool _dataConsent = false;
  bool _personalizedExperience = false;
  bool _aiLearning = false;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Meet Your AI Assistant',
      description: 'Enhance your dating experience with intelligent conversation helpers, smart matching, and personalized suggestions.',
      icon: Icons.psychology,
      gradient: LinearGradient(
        colors: [Colors.purple.shade400, Colors.cyan.shade400],
      ),
    ),
    OnboardingPage(
      title: 'Smart Conversations',
      description: 'Get AI-powered reply suggestions and conversation starters that match your personality and style.',
      icon: Icons.chat_bubble_outline,
      gradient: LinearGradient(
        colors: [Colors.blue.shade400, Colors.cyan.shade400],
      ),
    ),
    OnboardingPage(
      title: 'Intelligent Matching',
      description: 'Our AI analyzes compatibility factors to suggest better matches and improve your dating success.',
      icon: Icons.favorite_outline,
      gradient: LinearGradient(
        colors: [Colors.red.shade400, Colors.pink.shade400],
      ),
    ),
    OnboardingPage(
      title: 'Privacy First',
      description: 'Choose what data to share and how AI learns from your interactions. You\'re always in control.',
      icon: Icons.security,
      gradient: LinearGradient(
        colors: [Colors.green.shade400, Colors.teal.shade400],
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_animationController);
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'AI Setup',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              // Page content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _pages.length + 1, // +1 for consent page
                  itemBuilder: (context, index) {
                    if (index < _pages.length) {
                      return _buildOnboardingPage(_pages[index]);
                    } else {
                      return _buildConsentPage();
                    }
                  },
                ),
              ),

              // Page indicator
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Page dots
                    Row(
                      children: List.generate(_pages.length + 1, (index) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: index == _currentPage
                                ? Colors.purple
                                : Colors.grey.shade600,
                          ),
                        );
                      }),
                    ),

                    // Navigation buttons
                    Row(
                      children: [
                        if (_currentPage > 0)
                          TextButton(
                            onPressed: () {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: const Text(
                              'Back',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _currentPage == _pages.length
                              ? _completeOnboarding
                              : () {
                                  _pageController.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _currentPage == _pages.length ? 'Get Started' : 'Next',
                          ),
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
    );
  }

  Widget _buildOnboardingPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: page.gradient,
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon,
              size: 64,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white70,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsentPage() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.privacy_tip_outlined,
            size: 64,
            color: Colors.cyan,
          ),
          const SizedBox(height: 32),
          Text(
            'Your Privacy Choices',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Consent options
          _buildConsentOption(
            'Data Collection',
            'Allow AI to analyze your conversations and interactions to provide better suggestions.',
            _dataConsent,
            (value) => setState(() => _dataConsent = value),
          ),
          
          _buildConsentOption(
            'Personalized Experience',
            'Enable AI to learn your preferences and adapt recommendations over time.',
            _personalizedExperience,
            (value) => setState(() => _personalizedExperience = value),
          ),
          
          _buildConsentOption(
            'AI Learning',
            'Help improve AI for all users by sharing anonymous usage patterns.',
            _aiLearning,
            (value) => setState(() => _aiLearning = value),
          ),
        ],
      ),
    );
  }

  Widget _buildConsentOption(
    String title,
    String description,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.cyan,
            activeTrackColor: Colors.cyan.withValues(alpha: 0.3),
            inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  void _completeOnboarding() {
    // Update preferences based on user choices
    context.read<AiPreferencesBloc>().add(CompleteAiOnboarding());
    
    if (_dataConsent || _personalizedExperience || _aiLearning) {
      context.read<AiPreferencesBloc>().add(const SetAiEnabled(true));
    }

    Navigator.of(context).pop();
  }
}

/// Data class for onboarding pages
class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Gradient gradient;

  const OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
  });
}