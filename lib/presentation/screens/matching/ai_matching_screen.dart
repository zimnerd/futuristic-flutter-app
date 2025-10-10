import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/logger.dart';
import '../../../core/network/api_client.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/match_model.dart';
import '../../../data/services/ai_matching_service.dart';
import '../../../domain/entities/discovery_types.dart';
import '../../blocs/matching/matching_bloc.dart';
import '../../widgets/matching/smart_match_widget.dart';
import '../../widgets/matching/compatibility_score_widget.dart';
import '../../theme/pulse_colors.dart';
import '../../navigation/app_router.dart';

/// Main AI-powered matching screen
class AiMatchingScreen extends StatefulWidget {
  final UserModel currentUser;

  const AiMatchingScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<AiMatchingScreen> createState() => _AiMatchingScreenState();
}

class _AiMatchingScreenState extends State<AiMatchingScreen>
    with TickerProviderStateMixin {
  
  final AiMatchingService _aiService = AiMatchingService(
    ApiClient.instance,
  );

  late TabController _tabController;
  bool _isLoading = false;
  
  Map<String, dynamic> _aiInsights = {};
  List<MatchModel> _topMatches = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load AI insights and top matches in parallel
      await Future.wait([
        _loadAiInsights(),
        _loadTopMatches(),
      ]);
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorMessage('Failed to load matching data');
    }
  }

  Future<void> _loadAiInsights() async {
    try {
      // Simulate AI insights data - in real app, this would come from backend
      await Future.delayed(const Duration(milliseconds: 500));
      _aiInsights = {
        'total_potential_matches': 156,
        'high_compatibility_matches': 23,
        'new_matches_today': 5,
        'profile_completion': 85,
        'recommendation_accuracy': 0.87,
      };
    } catch (e) {
      AppLogger.debug('Error loading AI insights: $e');
    }
  }

  Future<void> _loadTopMatches() async {
    try {
      final matches = await _aiService.getRecommendations(
        userId: widget.currentUser.id,
        limit: 5,
        minCompatibility: 0.7,
      );
      
      _topMatches = matches;
    } catch (e) {
      AppLogger.debug('Error loading top matches: $e');
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Matching'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [PulseColors.primary, PulseColors.secondary],
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Discover', icon: Icon(Icons.explore, size: 20)),
            Tab(text: 'Analytics', icon: Icon(Icons.analytics, size: 20)),
            Tab(text: 'Preferences', icon: Icon(Icons.tune, size: 20)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDiscoverTab(),
                _buildAnalyticsTab(),
                _buildPreferencesTab(),
              ],
            ),
    );
  }

  Widget _buildDiscoverTab() {
    return Column(
      children: [
        // Quick Stats Header
        Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Today\'s Matches',
                  '${_aiInsights['new_matches_today'] ?? 0}',
                  Icons.favorite,
                  Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'High Quality',
                  '${_aiInsights['high_compatibility_matches'] ?? 0}',
                  Icons.star,
                  Colors.amber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Accuracy',
                  '${((_aiInsights['recommendation_accuracy'] ?? 0.0) * 100).round()}%',
                  Icons.psychology,
                  PulseColors.primary,
                ),
              ),
            ],
          ),
        ),
        
        // Smart Match Widget
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SmartMatchWidget(
              currentUser: widget.currentUser,
              onMatchTap: (match) {
                // Navigate to user profile
                _navigateToProfile(match);
              },
              onMatchAction: (match, action) {
                // Handle match actions
                _handleMatchAction(match, action);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Insights Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [PulseColors.primary.withValues(alpha: 0.1), Colors.transparent],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.psychology, color: PulseColors.primary),
                    const SizedBox(width: 12),
                    Text(
                      'AI Matching Analytics',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: PulseColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Your personalized matching insights powered by advanced AI algorithms',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Profile Completion
          _buildAnalyticsCard(
            'Profile Optimization',
            'Complete your profile to improve match quality',
            child: Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: (_aiInsights['profile_completion'] ?? 0) / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      (_aiInsights['profile_completion'] ?? 0) >= 80 
                          ? Colors.green 
                          : Colors.orange,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${_aiInsights['profile_completion'] ?? 0}%',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Top Matches Preview
          _buildAnalyticsCard(
            'Your Best Matches',
            'AI-selected profiles with highest compatibility',
            child: Column(
              children: _topMatches.take(3).map((match) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: match.userProfile?.photos.isNotEmpty == true
                            ? NetworkImage(match.userProfile!.photos.first.url)
                            : null,
                        child: match.userProfile?.photos.isEmpty != false
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              match.userProfile?.name ?? 'Unknown',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '${(match.compatibilityScore * 100).round()}% compatibility',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      CompatibilityScoreWidget(
                        score: match.compatibilityScore,
                        size: 40,
                        showPercentage: false,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Matching Stats
          _buildAnalyticsCard(
            'Matching Statistics',
            'Your AI-powered matching performance',
            child: Column(
              children: [
                _buildStatRow('Total Potential Matches', '${_aiInsights['total_potential_matches'] ?? 0}'),
                const SizedBox(height: 12),
                _buildStatRow('High Compatibility (80%+)', '${_aiInsights['high_compatibility_matches'] ?? 0}'),
                const SizedBox(height: 12),
                _buildStatRow('Algorithm Accuracy', '${((_aiInsights['recommendation_accuracy'] ?? 0.0) * 100).round()}%'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Matching Preferences',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Customize your AI matching algorithm',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Preference Cards
          _buildPreferenceCard(
            'Compatibility Threshold',
            'Minimum compatibility score for recommendations',
            child: Slider(
              value: 0.6,
              min: 0.0,
              max: 1.0,
              divisions: 10,
              label: '60%',
              onChanged: (value) {
                // Handle threshold change
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          _buildPreferenceCard(
            'Discovery Range',
            'How far to look for matches',
            child: DropdownButtonFormField<String>(
              initialValue: '25km',
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: const [
                DropdownMenuItem(value: '10km', child: Text('10km')),
                DropdownMenuItem(value: '25km', child: Text('25km')),
                DropdownMenuItem(value: '50km', child: Text('50km')),
                DropdownMenuItem(value: '100km', child: Text('100km')),
              ],
              onChanged: (value) {
                // Handle range change
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          _buildPreferenceCard(
            'Age Range',
            'Preferred age range for matches',
            child: RangeSlider(
              values: const RangeValues(25, 35),
              min: 18,
              max: 60,
              divisions: 42,
              labels: const RangeLabels('25', '35'),
              onChanged: (values) {
                // Handle age range change
              },
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Save preferences
                _savePreferences();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: PulseColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Save Preferences',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, String subtitle, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildPreferenceCard(String title, String subtitle, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _navigateToProfile(MatchModel match) {
    if (match.userProfile == null) return;

    context.push(
      AppRoutes.profileDetails.replaceFirst(
        ':profileId',
        match.userProfile!.id,
      ),
      extra: match.userProfile,
    );
  }

  void _handleMatchAction(MatchModel match, String action) {
    final matchingBloc = context.read<MatchingBloc>();

    switch (action) {
      case 'like':
        matchingBloc.add(
          SwipeProfile(
            profileId: match.userProfile!.id,
            direction: SwipeAction.right,
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Liked ${match.userProfile?.name ?? "profile"}'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        break;
      case 'pass':
        matchingBloc.add(
          SwipeProfile(
            profileId: match.userProfile!.id,
            direction: SwipeAction.left,
          ),
        );
        break;
      case 'super_like':
        matchingBloc.add(SuperLikeProfile(profileId: match.userProfile!.id));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Super Like sent! 💫'),
            backgroundColor: PulseColors.primary,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
        break;
    }
  }

  void _savePreferences() async {
    try {
      // Get current filter state
      final matchingBloc = context.read<MatchingBloc>();

      // Create updated filters from current UI state
      const updatedFilters = MatchingFilters(
        minAge: 18, // Use actual values from your UI state
        maxAge: 35,
        maxDistance: 50,
        showMeGender: null,
        verifiedOnly: false,
        hasPhotos: true,
      );

      // Update filters in BLoC
      matchingBloc.add(UpdateFilters(filters: updatedFilters));

      // Refresh matches with new preferences
      matchingBloc.add(RefreshMatches());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI matching preferences saved successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save preferences: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}