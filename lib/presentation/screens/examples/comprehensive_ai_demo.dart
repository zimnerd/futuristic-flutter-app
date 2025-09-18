import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../business_logic/blocs/ai_preferences_bloc.dart';
import '../../../core/services/service_locator.dart';
import '../../../data/models/ai_preferences.dart';

/// Complete integration example showing AI preferences in action
class ComprehensiveAiDemo extends StatelessWidget {
  const ComprehensiveAiDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AiPreferencesBloc(
        preferencesService: ServiceLocator.instance.aiPreferences,
      )..add(LoadAiPreferences()),
      child: const _AiDemoContent(),
    );
  }
}

class _AiDemoContent extends StatefulWidget {
  const _AiDemoContent();

  @override
  State<_AiDemoContent> createState() => _AiDemoContentState();
}

class _AiDemoContentState extends State<_AiDemoContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Features Complete Demo'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.chat), text: 'Chat'),
            Tab(icon: Icon(Icons.person), text: 'Profile'),
            Tab(icon: Icon(Icons.settings), text: 'Settings'),
          ],
        ),
      ),
      body: BlocBuilder<AiPreferencesBloc, AiPreferencesState>(
        builder: (context, state) {
          if (state is AiPreferencesLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is AiPreferencesError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${state.message}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<AiPreferencesBloc>().add(LoadAiPreferences());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is AiPreferencesLoaded) {
            return TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(context, state.preferences),
                _buildChatTab(context, state.preferences),
                _buildProfileTab(context, state.preferences),
                _buildSettingsTab(context, state.preferences),
              ],
            );
          }

          return const Center(child: Text('Unknown state'));
        },
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context, AiPreferences preferences) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // AI Status Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      preferences.isAiEnabled
                          ? Icons.psychology
                          : Icons.psychology_outlined,
                      color: preferences.isAiEnabled
                          ? Colors.green
                          : Colors.grey,
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
                            preferences.isAiEnabled
                                ? 'Active • ${_getActiveFeatureCount(preferences)} features enabled'
                                : 'Disabled',
                            style: TextStyle(
                              color: preferences.isAiEnabled
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: preferences.isAiEnabled,
                      onChanged: (value) {
                        context
                            .read<AiPreferencesBloc>()
                            .add(SetAiEnabled(value));
                      },
                    ),
                  ],
                ),
                if (preferences.isAiEnabled) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildFeatureGrid(context, preferences),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Quick Stats
        if (preferences.isAiEnabled) ...[
          Text(
            'Features Overview',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _buildQuickStats(context, preferences),
        ],
      ],
    );
  }

  Widget _buildFeatureGrid(BuildContext context, AiPreferences preferences) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        _buildMiniFeatureCard(
          'Smart Replies',
          preferences.conversations.smartRepliesEnabled,
          Icons.chat_bubble,
        ),
        _buildMiniFeatureCard(
          'AI Companion',
          preferences.companion.companionChatEnabled,
          Icons.psychology,
        ),
        _buildMiniFeatureCard(
          'Profile Help',
          preferences.profile.profileOptimizationEnabled,
          Icons.person,
        ),
        _buildMiniFeatureCard(
          'Smart Matching',
          preferences.matching.smartMatchingEnabled,
          Icons.favorite,
        ),
      ],
    );
  }

  Widget _buildMiniFeatureCard(String title, bool enabled, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: enabled ? Colors.blue : Colors.grey,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Icon(
            icon,
            size: 16,
            color: enabled ? Colors.blue : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: enabled ? Colors.blue : Colors.grey,
                fontWeight: enabled ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, AiPreferences preferences) {
    final stats = [
      {
        'title': 'Smart Conversations',
        'value': preferences.conversations.smartRepliesEnabled ? 'On' : 'Off',
        'enabled': preferences.conversations.smartRepliesEnabled,
      },
      {
        'title': 'AI Companion',
        'value': preferences.companion.companionChatEnabled ? 'Active' : 'Inactive',
        'enabled': preferences.companion.companionChatEnabled,
      },
      {
        'title': 'Profile Optimization',
        'value': preferences.profile.profileOptimizationEnabled ? 'Enabled' : 'Disabled',
        'enabled': preferences.profile.profileOptimizationEnabled,
      },
    ];

    return Column(
      children: stats.map((stat) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(stat['title'] as String),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: (stat['enabled'] as bool) ? Colors.green : Colors.grey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                stat['value'] as String,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChatTab(BuildContext context, AiPreferences preferences) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chat AI Features',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          
          // Smart Replies Demo
          Card(
            child: ListTile(
              leading: Icon(
                Icons.chat_bubble_outline,
                color: preferences.conversations.smartRepliesEnabled ? Colors.blue : Colors.grey,
              ),
              title: const Text('Smart Replies'),
              subtitle: const Text('AI suggests contextual responses to messages'),
              trailing: Switch(
                value: preferences.conversations.smartRepliesEnabled,
                onChanged: (enabled) {
                  final newSettings = preferences.conversations.copyWith(
                    smartRepliesEnabled: enabled,
                  );
                  context.read<AiPreferencesBloc>().add(
                    UpdateConversationSettings(newSettings),
                  );
                },
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Demo chat interface
          if (preferences.conversations.smartRepliesEnabled) ...[
            Container(
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.chat, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Demo Chat (AI Features Active)',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text('Hey! How was your day?'),
                          ),
                          SizedBox(height: 8),
                          Text('It was great! Went hiking today.'),
                          SizedBox(height: 16),
                          Text(
                            'AI Suggestions:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text('• "That sounds amazing! Where did you go?"'),
                          Text('• "I love hiking! What was the trail like?"'),
                          Text('• "Any beautiful views?"'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'Enable Smart Replies to see AI suggestions demo',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileTab(BuildContext context, AiPreferences preferences) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile AI Features',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          
          Card(
            child: ListTile(
              leading: Icon(
                Icons.person_outline,
                color: preferences.profile.profileOptimizationEnabled ? Colors.blue : Colors.grey,
              ),
              title: const Text('Profile Optimization'),
              subtitle: const Text('AI analyzes and suggests improvements to your profile'),
              trailing: Switch(
                value: preferences.profile.profileOptimizationEnabled,
                onChanged: (enabled) {
                  final newSettings = preferences.profile.copyWith(
                    profileOptimizationEnabled: enabled,
                  );
                  context.read<AiPreferencesBloc>().add(
                    UpdateProfileSettings(newSettings),
                  );
                },
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Card(
            child: ListTile(
              leading: Icon(
                Icons.favorite_outline,
                color: preferences.matching.smartMatchingEnabled ? Colors.blue : Colors.grey,
              ),
              title: const Text('Smart Matching'),
              subtitle: const Text('AI improves match quality based on compatibility'),
              trailing: Switch(
                value: preferences.matching.smartMatchingEnabled,
                onChanged: (enabled) {
                  final newSettings = preferences.matching.copyWith(
                    smartMatchingEnabled: enabled,
                  );
                  context.read<AiPreferencesBloc>().add(
                    UpdateMatchingSettings(newSettings),
                  );
                },
              ),
            ),
          ),
          
          if (preferences.profile.profileOptimizationEnabled ||
              preferences.matching.smartMatchingEnabled) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'AI Profile Insights',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text('• Consider adding more photos'),
                  Text('• Your bio could mention your hobbies'),
                  Text('• Active profiles get 3x more matches'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSettingsTab(BuildContext context, AiPreferences preferences) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Settings Management',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Privacy & Control',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You have complete control over AI features. Each can be enabled or disabled independently.',
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/ai-settings');
                    },
                    icon: const Icon(Icons.settings),
                    label: const Text('Open Full AI Settings'),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Data Usage',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'AI Features Active: ${_getActiveFeatureCount(preferences)}',
                  ),
                  Text(
                    'General Settings: ${preferences.general.personalizedExperienceEnabled ? 'Personalized' : 'Standard'}',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _getActiveFeatureCount(AiPreferences preferences) {
    if (!preferences.isAiEnabled) return 0;
    
    int count = 0;
    if (preferences.conversations.smartRepliesEnabled) count++;
    if (preferences.conversations.autoSuggestionsEnabled) count++;
    if (preferences.conversations.customReplyEnabled) count++;
    if (preferences.companion.companionChatEnabled) count++;
    if (preferences.profile.profileOptimizationEnabled) count++;
    if (preferences.matching.smartMatchingEnabled) count++;
    if (preferences.icebreakers.icebreakerSuggestionsEnabled) count++;
    
    return count;
  }
}

/// Helper widget to conditionally show features based on AI preferences
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
          final preferences = state.preferences;
          
          if (!preferences.isAiEnabled) {
            return fallback ?? const SizedBox.shrink();
          }
          
          final isEnabled = _isFeatureEnabled(preferences, feature);
          if (isEnabled) {
            return child;
          }
        }
        
        return fallback ?? const SizedBox.shrink();
      },
    );
  }

  bool _isFeatureEnabled(AiPreferences preferences, String feature) {
    switch (feature) {
      case 'smart_replies':
        return preferences.conversations.smartRepliesEnabled;
      case 'auto_suggestions':
        return preferences.conversations.autoSuggestionsEnabled;
      case 'custom_replies':
        return preferences.conversations.customReplyEnabled;
      case 'companion_chat':
        return preferences.companion.companionChatEnabled;
      case 'profile_optimization':
        return preferences.profile.profileOptimizationEnabled;
      case 'smart_matching':
        return preferences.matching.smartMatchingEnabled;
      case 'icebreaker_suggestions':
        return preferences.icebreakers.icebreakerSuggestionsEnabled;
      default:
        return false;
    }
  }
}