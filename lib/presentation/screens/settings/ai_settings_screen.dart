import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../business_logic/blocs/ai_preferences_bloc.dart';
import '../../../data/models/ai_preferences.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/common/pulse_toast.dart';
import '../../widgets/ai/ai_feature_card.dart';
import '../../widgets/ai/ai_onboarding_dialog.dart';

/// Main AI settings and preferences screen
class AiSettingsScreen extends StatefulWidget {
  const AiSettingsScreen({super.key});

  @override
  State<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends State<AiSettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    // Start animations
    _fadeController.forward();
    _slideController.forward();
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black,
              Colors.purple.shade900.withValues(alpha: 0.3),
              Colors.black,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: BlocConsumer<AiPreferencesBloc, AiPreferencesState>(
            listener: (context, state) {
              if (state is AiPreferencesError) {
                PulseToast.error(context, message: state.message);
              }
            },
            builder: (context, state) {
              if (state is AiPreferencesLoading) {
                return const LoadingOverlay();
              }

              if (state is AiPreferencesLoaded) {
                // Show onboarding if not completed
                if (!state.hasCompletedOnboarding) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _showOnboardingDialog(context);
                  });
                }

                return _buildSettingsContent(context, state.preferences);
              }

              return _buildInitialState(context);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInitialState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading AI Settings...',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsContent(
    BuildContext context,
    AiPreferences preferences,
  ) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          children: [
            // Custom app bar with AI branding
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.purple.shade400, Colors.cyan.shade400],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.psychology,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Assistant',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          'Personalize your AI experience',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: preferences.isAiEnabled,
                    onChanged: (value) {
                      context.read<AiPreferencesBloc>().add(
                        SetAiEnabled(value),
                      );
                    },
                    activeThumbColor: Colors.cyan,
                    activeTrackColor: Colors.cyan.withValues(alpha: 0.3),
                    inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
                  ),
                ],
              ),
            ),

            // Settings content
            Expanded(
              child: preferences.isAiEnabled
                  ? _buildEnabledSettings(context, preferences)
                  : _buildDisabledState(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisabledState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade800.withValues(alpha: 0.3),
              border: Border.all(
                color: Colors.grey.shade600.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.psychology_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'AI Assistant Disabled',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Enable AI assistance to unlock smart replies, personalized matching, and intelligent conversation features.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              context.read<AiPreferencesBloc>().add(const SetAiEnabled(true));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome),
                const SizedBox(width: 8),
                Text(
                  'Enable AI Assistant',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnabledSettings(
    BuildContext context,
    AiPreferences preferences,
  ) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Conversation AI
        AiFeatureCard(
          title: 'Smart Conversations',
          description: 'AI-powered reply suggestions and conversation helpers',
          icon: Icons.chat_bubble_outline,
          iconGradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.cyan.shade400],
          ),
          enabled:
              preferences.conversations.smartRepliesEnabled ||
              preferences.conversations.customReplyEnabled ||
              preferences.conversations.autoSuggestionsEnabled,
          onTap: () => _navigateToConversationSettings(context, preferences),
          features: [
            if (preferences.conversations.smartRepliesEnabled) 'Smart Replies',
            if (preferences.conversations.customReplyEnabled)
              'Custom AI Replies',
            if (preferences.conversations.autoSuggestionsEnabled)
              'Auto Suggestions',
          ],
        ),

        const SizedBox(height: 16),

        // AI Companion
        AiFeatureCard(
          title: 'AI Companion',
          description: 'Your personal dating coach and conversation partner',
          icon: Icons.psychology,
          iconGradient: LinearGradient(
            colors: [Colors.purple.shade400, Colors.pink.shade400],
          ),
          enabled:
              preferences.companion.companionChatEnabled ||
              preferences.companion.companionAdviceEnabled,
          onTap: () => _navigateToCompanionSettings(context, preferences),
          features: [
            if (preferences.companion.companionChatEnabled) 'Companion Chat',
            if (preferences.companion.companionAdviceEnabled) 'Dating Advice',
            if (preferences.companion.relationshipAnalysisEnabled)
              'Relationship Analysis',
          ],
        ),

        const SizedBox(height: 16),

        // Profile Optimization
        AiFeatureCard(
          title: 'Profile Assistant',
          description: 'AI-powered profile optimization and suggestions',
          icon: Icons.person_outline,
          iconGradient: LinearGradient(
            colors: [Colors.green.shade400, Colors.teal.shade400],
          ),
          enabled:
              preferences.profile.profileOptimizationEnabled ||
              preferences.profile.bioSuggestionsEnabled,
          onTap: () => _navigateToProfileSettings(context, preferences),
          features: [
            if (preferences.profile.profileOptimizationEnabled)
              'Profile Optimization',
            if (preferences.profile.bioSuggestionsEnabled) 'Bio Suggestions',
            if (preferences.profile.photoAnalysisEnabled) 'Photo Analysis',
          ],
        ),

        const SizedBox(height: 16),

        // Smart Matching
        AiFeatureCard(
          title: 'Smart Matching',
          description: 'AI-enhanced compatibility analysis and matching',
          icon: Icons.favorite_outline,
          iconGradient: LinearGradient(
            colors: [Colors.red.shade400, Colors.pink.shade400],
          ),
          enabled: preferences.matching.smartMatchingEnabled,
          onTap: () => _navigateToMatchingSettings(context, preferences),
          features: [
            if (preferences.matching.smartMatchingEnabled) 'Smart Matching',
            if (preferences.matching.compatibilityAnalysisEnabled)
              'Compatibility Analysis',
            if (preferences.matching.personalityInsightsEnabled)
              'Personality Insights',
          ],
        ),

        const SizedBox(height: 16),

        // Icebreakers
        AiFeatureCard(
          title: 'Smart Icebreakers',
          description: 'Personalized conversation starters and icebreakers',
          icon: Icons.lightbulb_outline,
          iconGradient: LinearGradient(
            colors: [Colors.orange.shade400, Colors.yellow.shade400],
          ),
          enabled: preferences.icebreakers.icebreakerSuggestionsEnabled,
          onTap: () => _navigateToIcebreakerSettings(context, preferences),
          features: [
            if (preferences.icebreakers.icebreakerSuggestionsEnabled)
              'Smart Suggestions',
            if (preferences.icebreakers.personalizedIcebreakersEnabled)
              'Personalized',
            if (preferences.icebreakers.contextualIcebreakersEnabled)
              'Contextual',
          ],
        ),

        const SizedBox(height: 16),

        // Privacy & General Settings
        AiFeatureCard(
          title: 'Privacy & Settings',
          description: 'Control your AI data and privacy preferences',
          icon: Icons.security,
          iconGradient: LinearGradient(
            colors: [Colors.grey.shade600, Colors.grey.shade400],
          ),
          enabled: true,
          onTap: () => _navigateToGeneralSettings(context, preferences),
          features: [
            'Privacy Level: ${preferences.general.privacyLevel.toUpperCase()}',
            if (preferences.general.aiLearningEnabled) 'AI Learning',
            if (preferences.general.analyticsEnabled) 'Analytics',
          ],
        ),

        const SizedBox(height: 32),

        // Reset button
        Center(
          child: TextButton.icon(
            onPressed: () => _showResetDialog(context),
            icon: const Icon(Icons.refresh, color: Colors.grey),
            label: Text(
              'Reset All AI Settings',
              style: TextStyle(color: Colors.grey.shade400),
            ),
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  void _showOnboardingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AiOnboardingDialog(),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text(
          'Reset AI Settings',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will reset all AI preferences to default values. This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<AiPreferencesBloc>().add(ResetAiPreferences());
            },
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _navigateToConversationSettings(
    BuildContext context,
    AiPreferences preferences,
  ) {
    // Navigate to conversation settings page
    Navigator.of(context).pushNamed('/ai-conversation-settings');
  }

  void _navigateToCompanionSettings(
    BuildContext context,
    AiPreferences preferences,
  ) {
    // Navigate to companion settings page
    Navigator.of(context).pushNamed('/ai-companion-settings');
  }

  void _navigateToProfileSettings(
    BuildContext context,
    AiPreferences preferences,
  ) {
    // Navigate to profile settings page
    Navigator.of(context).pushNamed('/ai-profile-settings');
  }

  void _navigateToMatchingSettings(
    BuildContext context,
    AiPreferences preferences,
  ) {
    // Navigate to matching settings page
    Navigator.of(context).pushNamed('/ai-matching-settings');
  }

  void _navigateToIcebreakerSettings(
    BuildContext context,
    AiPreferences preferences,
  ) {
    // Navigate to icebreaker settings page
    Navigator.of(context).pushNamed('/ai-icebreaker-settings');
  }

  void _navigateToGeneralSettings(
    BuildContext context,
    AiPreferences preferences,
  ) {
    // Navigate to general settings page
    Navigator.of(context).pushNamed('/ai-general-settings');
  }
}
