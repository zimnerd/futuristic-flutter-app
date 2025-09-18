import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../business_logic/blocs/ai_preferences_bloc.dart';
import '../../../core/services/service_locator.dart';
import '../settings/ai_settings_screen.dart';

/// Example of how to integrate AI preferences throughout the app
class AiIntegrationExample extends StatelessWidget {
  const AiIntegrationExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Preferences Demo',
      theme: ThemeData.dark(),
      home: BlocProvider(
        create: (context) => AiPreferencesBloc(
          preferencesService: ServiceLocator.instance.aiPreferences,
        )..add(LoadAiPreferences()),
        child: const HomeScreen(),
      ),
      routes: {
        '/ai-settings': (context) => BlocProvider.value(
              value: context.read<AiPreferencesBloc>(),
              child: const AiSettingsScreen(),
            ),
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Features Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).pushNamed('/ai-settings');
            },
          ),
        ],
      ),
      body: BlocBuilder<AiPreferencesBloc, AiPreferencesState>(
        builder: (context, state) {
          if (state is AiPreferencesLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AiPreferencesLoaded) {
            return _buildFeatureList(context, state);
          }

          return const Center(
            child: Text('Failed to load AI preferences'),
          );
        },
      ),
    );
  }

  Widget _buildFeatureList(BuildContext context, AiPreferencesLoaded state) {
    final preferences = state.preferences;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // AI Status Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  preferences.isAiEnabled ? Icons.psychology : Icons.psychology_outlined,
                  color: preferences.isAiEnabled ? Colors.green : Colors.grey,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Assistant',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        preferences.isAiEnabled ? 'Active' : 'Disabled',
                        style: TextStyle(
                          color: preferences.isAiEnabled ? Colors.green : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: preferences.isAiEnabled,
                  onChanged: (value) {
                    context.read<AiPreferencesBloc>().add(SetAiEnabled(value));
                  },
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Feature Cards
        if (preferences.isAiEnabled) ...[
          _buildFeatureCard(
            context,
            'Smart Conversations',
            'AI-powered reply suggestions',
            Icons.chat_bubble_outline,
            preferences.conversations.smartRepliesEnabled,
            () => _toggleFeature(context, 'smart_replies'),
          ),
          
          _buildFeatureCard(
            context,
            'AI Companion',
            'Personal dating assistant',
            Icons.psychology,
            preferences.companion.companionChatEnabled,
            () => _toggleFeature(context, 'companion_chat'),
          ),
          
          _buildFeatureCard(
            context,
            'Profile Optimization',
            'AI-enhanced profile suggestions',
            Icons.person_outline,
            preferences.profile.profileOptimizationEnabled,
            () => _toggleFeature(context, 'profile_optimization'),
          ),
          
          _buildFeatureCard(
            context,
            'Smart Matching',
            'Intelligent compatibility analysis',
            Icons.favorite_outline,
            preferences.matching.smartMatchingEnabled,
            () => _toggleFeature(context, 'smart_matching'),
          ),
          
          _buildFeatureCard(
            context,
            'Icebreaker Suggestions',
            'Personalized conversation starters',
            Icons.lightbulb_outline,
            preferences.icebreakers.icebreakerSuggestionsEnabled,
            () => _toggleFeature(context, 'icebreaker_suggestions'),
          ),
        ] else ...[
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.psychology_outlined,
                    size: 48,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Enable AI Assistant to unlock intelligent features',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 32),

        // Settings Button
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pushNamed('/ai-settings');
          },
          icon: const Icon(Icons.tune),
          label: const Text('AI Settings'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    bool enabled,
    VoidCallback onToggle,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          icon,
          color: enabled ? Colors.blue : Colors.grey,
        ),
        title: Text(title),
        subtitle: Text(description),
        trailing: Switch(
          value: enabled,
          onChanged: (_) => onToggle(),
        ),
        onTap: onToggle,
      ),
    );
  }

  void _toggleFeature(BuildContext context, String feature) {
    // This is a simplified toggle - in a real app, you'd update specific settings
    final bloc = context.read<AiPreferencesBloc>();
    final currentState = bloc.state;
    
    if (currentState is AiPreferencesLoaded) {
      final preferences = currentState.preferences;
      
      // Example: Toggle smart replies
      if (feature == 'smart_replies') {
        final newSettings = preferences.conversations.copyWith(
          smartRepliesEnabled: !preferences.conversations.smartRepliesEnabled,
        );
        bloc.add(UpdateConversationSettings(newSettings));
      }
      
      // Add other feature toggles as needed...
    }
  }
}

/// Helper widget to check if a feature is enabled before showing UI
class AiFeatureWrapper extends StatelessWidget {
  final String feature;
  final Widget child;
  final Widget? fallback;

  const AiFeatureWrapper({
    super.key,
    required this.feature,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AiPreferencesBloc, AiPreferencesState>(
      builder: (context, state) {
        if (state is AiPreferencesLoaded) {
          final bloc = context.read<AiPreferencesBloc>();
          final isEnabled = bloc.isFeatureEnabled(feature);
          
          if (isEnabled) {
            return child;
          }
        }
        
        return fallback ?? const SizedBox.shrink();
      },
    );
  }
}

/// Example of using AiFeatureWrapper in chat
class ExampleChatScreen extends StatelessWidget {
  const ExampleChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          const Expanded(
            child: Center(child: Text('Chat messages here...')),
          ),
          
          // AI features only show when enabled
          AiFeatureWrapper(
            feature: 'smart_replies',
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.blue.withOpacity(0.1),
              child: const Text('AI Suggestions: "How are you?", "Tell me more!"'),
            ),
          ),
          
          // Regular message input
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                
                // AI button only shows when any AI feature is enabled
                AiFeatureWrapper(
                  feature: 'smart_replies',
                  child: IconButton(
                    icon: const Icon(Icons.psychology),
                    onPressed: () {
                      // Show AI modal or suggestions
                    },
                  ),
                ),
                
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    // Send message
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}