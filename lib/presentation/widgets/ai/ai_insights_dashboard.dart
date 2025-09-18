import 'package:flutter/material.dart';

/// AI Insights Dashboard - displays AI-generated analytics, compatibility scores, 
/// and personalized recommendations
class AiInsightsDashboard extends StatefulWidget {
  final String userId;
  final VoidCallback? onRefresh;

  const AiInsightsDashboard({
    super.key,
    required this.userId,
    this.onRefresh,
  });

  @override
  State<AiInsightsDashboard> createState() => _AiInsightsDashboardState();
}

class _AiInsightsDashboardState extends State<AiInsightsDashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  // Mock data - replace with actual service calls
  final Map<String, dynamic> _mockInsights = {
    'compatibility': {
      'averageScore': 82,
      'trend': 'improving',
      'topMatches': 5,
      'recommendations': [
        'Update your interests section',
        'Add more photos',
        'Be more active in conversations',
      ],
    },
    'conversations': {
      'responseRate': 67,
      'averageEngagement': 4.2,
      'improvementAreas': [
        'Ask more questions',
        'Share personal experiences',
        'Use conversation starters',
      ],
    },
    'profile': {
      'optimizationScore': 78,
      'viewsThisWeek': 143,
      'improvements': [
        'Add professional photo',
        'Expand bio section',
        'Update activity status',
      ],
    },
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInsights();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInsights() async {
    setState(() => _isLoading = true);
    
    // TODO: Load actual insights from AI services
    // await Future.wait([
    //   _aiConversationService.getInsights(userId: widget.userId),
    //   _aiProfileAnalysisService.getAnalytics(userId: widget.userId),
    //   _aiFeedbackService.getFeedbackAnalytics(userId: widget.userId),
    // ]);

    await Future.delayed(const Duration(seconds: 2)); // Simulate API call
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF6E3BFF).withOpacity(0.1),
            Colors.black.withOpacity(0.9),
          ],
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: _isLoading 
                ? _buildLoadingState() 
                : _buildTabViews(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: const LinearGradient(
                colors: [Color(0xFF6E3BFF), Color(0xFF00C2FF)],
              ),
            ),
            child: const Icon(
              Icons.psychology_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Insights',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Personalized recommendations',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _isLoading ? null : _loadInsights,
            icon: Icon(
              Icons.refresh_rounded,
              color: _isLoading ? Colors.white38 : Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.1),
      ),
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Compatibility'),
          Tab(text: 'Conversations'),
          Tab(text: 'Profile'),
        ],
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Color(0xFF6E3BFF), Color(0xFF00C2FF)],
          ),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        dividerColor: Colors.transparent,
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6E3BFF)),
          ),
          SizedBox(height: 16),
          Text(
            'Analyzing your data...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabViews() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildCompatibilityTab(),
        _buildConversationsTab(),
        _buildProfileTab(),
      ],
    );
  }

  Widget _buildCompatibilityTab() {
    final data = _mockInsights['compatibility'] as Map<String, dynamic>;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildScoreCard(
            title: 'Average Compatibility',
            score: data['averageScore'],
            subtitle: 'Based on your matches',
            icon: Icons.favorite_rounded,
          ),
          const SizedBox(height: 16),
          _buildTrendCard(
            title: 'Compatibility Trend',
            trend: data['trend'],
            description: 'Your matches are getting better!',
          ),
          const SizedBox(height: 16),
          _buildRecommendationsCard(
            title: 'Improve Your Matches',
            recommendations: List<String>.from(data['recommendations']),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationsTab() {
    final data = _mockInsights['conversations'] as Map<String, dynamic>;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildScoreCard(
                  title: 'Response Rate',
                  score: data['responseRate'],
                  subtitle: 'People reply to you',
                  icon: Icons.chat_bubble_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildScoreCard(
                  title: 'Engagement',
                  score: (data['averageEngagement'] * 20).round(),
                  subtitle: 'Out of 5 stars',
                  icon: Icons.star_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRecommendationsCard(
            title: 'Conversation Tips',
            recommendations: List<String>.from(data['improvementAreas']),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    final data = _mockInsights['profile'] as Map<String, dynamic>;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildScoreCard(
                  title: 'Profile Score',
                  score: data['optimizationScore'],
                  subtitle: 'Optimization level',
                  icon: Icons.person_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'Profile Views',
                  value: data['viewsThisWeek'].toString(),
                  subtitle: 'This week',
                  icon: Icons.visibility_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRecommendationsCard(
            title: 'Profile Improvements',
            recommendations: List<String>.from(data['improvements']),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard({
    required String title,
    required int score,
    required String subtitle,
    required IconData icon,
  }) {
    final color = _getScoreColor(score);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.1),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$score%',
            style: TextStyle(
              color: color,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.1),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF00C2FF), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF00C2FF),
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendCard({
    required String title,
    required String trend,
    required String description,
  }) {
    final isImproving = trend == 'improving';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.1),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: (isImproving ? Colors.green : Colors.orange)
                  .withOpacity(0.2),
            ),
            child: Icon(
              isImproving ? Icons.trending_up_rounded : Icons.trending_flat_rounded,
              color: isImproving ? Colors.green : Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard({
    required String title,
    required List<String> recommendations,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.1),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_rounded,
                color: Color(0xFFFFD700),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...recommendations.map((recommendation) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Color(0xFF6E3BFF),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    recommendation,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return const Color(0xFF00C2FF);
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }
}