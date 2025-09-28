import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/services/statistics_service.dart';

// BLoC Events
abstract class StatisticsEvent {}

class LoadStatistics extends StatisticsEvent {}

class RefreshStatistics extends StatisticsEvent {}

// BLoC States
abstract class StatisticsState {}

class StatisticsInitial extends StatisticsState {}

class StatisticsLoading extends StatisticsState {}

class StatisticsLoaded extends StatisticsState {
  final UserStatistics statistics;
  final Map<String, dynamic> formattedStats;

  StatisticsLoaded({
    required this.statistics,
    required this.formattedStats,
  });
}

class StatisticsError extends StatisticsState {
  final String message;
  StatisticsError(this.message);
}

// BLoC
class StatisticsBloc extends Bloc<StatisticsEvent, StatisticsState> {
  final StatisticsService _statisticsService;

  StatisticsBloc(this._statisticsService) : super(StatisticsInitial()) {
    on<LoadStatistics>(_onLoadStatistics);
    on<RefreshStatistics>(_onRefreshStatistics);
  }

  Future<void> _onLoadStatistics(LoadStatistics event, Emitter<StatisticsState> emit) async {
    emit(StatisticsLoading());
    
    try {
      final statistics = await _statisticsService.getUserStatistics();
      final formattedStats = _statisticsService.formatStatisticsForDisplay(statistics);
      
      emit(StatisticsLoaded(
        statistics: statistics,
        formattedStats: formattedStats,
      ));
    } catch (e) {
      emit(StatisticsError('Failed to load statistics: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshStatistics(RefreshStatistics event, Emitter<StatisticsState> emit) async {
    add(LoadStatistics());
  }
}

// Statistics Screen Widget
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => StatisticsBloc(
        context.read<StatisticsService>(),
      )..add(LoadStatistics()),
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        appBar: _buildAppBar(context),
        body: BlocConsumer<StatisticsBloc, StatisticsState>(
          listener: (context, state) {
            if (state is StatisticsLoaded) {
              _animationController.forward();
            }
          },
          builder: (context, state) {
            if (state is StatisticsLoading) {
              return _buildLoadingState();
            } else if (state is StatisticsLoaded) {
              return _buildLoadedState(context, state);
            } else if (state is StatisticsError) {
              return _buildErrorState(context, state);
            }
            return _buildInitialState(context);
          },
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF0A0A0A),
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      title: const Text(
        'Your Stats',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        BlocBuilder<StatisticsBloc, StatisticsState>(
          builder: (context, state) {
            return IconButton(
              onPressed: state is! StatisticsLoading 
                  ? () => context.read<StatisticsBloc>().add(RefreshStatistics())
                  : null,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6E3BFF).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.refresh, color: Color(0xFF6E3BFF)),
              ),
            );
          },
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A0A0A), Color(0xFF1A1A1A)],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6E3BFF)),
            ),
            SizedBox(height: 24),
            Text(
              'Loading your stats...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadedState(BuildContext context, StatisticsLoaded state) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0A0A), Color(0xFF1A1A1A)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryCard(context, state),
              const SizedBox(height: 24),
              _buildStatsGrid(context, state),
              const SizedBox(height: 24),
              _buildInsightsCard(context, state),
              const SizedBox(height: 24),
              _buildPerformanceCard(context, state),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, StatisticsLoaded state) {
    final stats = state.statistics;
    final matchRate = state.formattedStats['matchRate'] as String;
    final activityLevel = state.formattedStats['engagementLevel'] as String;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6E3BFF), Color(0xFF00C2FF)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6E3BFF).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '✨',
                style: TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Dating Journey',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activityLevel,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Matches',
                  stats.totalMatches.toString(),
                  '💕',
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Match Rate',
                  matchRate,
                  '📊',
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Profile Views',
                  stats.profileViews.toString(),
                  '👀',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, String emoji) {
    return Column(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context, StatisticsLoaded state) {
    final formattedStats = state.formattedStats;
    final statsToShow = [
      'likesReceived',
      'likesSent',
      'messagesCount',
      'superLikesReceived',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detailed Statistics',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
          ),
          itemCount: statsToShow.length,
          itemBuilder: (context, index) {
            final statKey = statsToShow[index];
            final statValue = formattedStats[statKey] ?? '0';
            final stat = _createStatObject(statKey, statValue);
            return _buildStatCard(stat);
          },
        ),
      ],
    );
  }

  Widget _buildStatCard(Map<String, dynamic> stat) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            stat['icon'],
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(height: 12),
          Text(
            stat['value'].toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            stat['label'],
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _createStatObject(String statKey, String statValue) {
    final statConfig = {
      'likesReceived': {'icon': '❤️', 'label': 'Likes Received'},
      'likesSent': {'icon': '👍', 'label': 'Likes Sent'},
      'totalLikes': {'icon': '👍', 'label': 'Likes Sent'},
      'messagesCount': {'icon': '💬', 'label': 'Messages'},
      'profileViews': {'icon': '👀', 'label': 'Profile Views'},
      'totalMatches': {'icon': '💕', 'label': 'Total Matches'},
      'matchRate': {'icon': '📊', 'label': 'Match Rate'},
      'responseRate': {'icon': '⚡', 'label': 'Response Rate'},
      'superLikesReceived': {'icon': '⭐', 'label': 'Super Likes Received'},
      'superLikesSent': {'icon': '🌟', 'label': 'Super Likes Sent'},
    };

    final config = statConfig[statKey] ?? {'icon': '📈', 'label': statKey};

    return {
      'icon': config['icon'],
      'value': statValue,
      'label': config['label'],
    };
  }

  Widget _buildInsightsCard(BuildContext context, StatisticsLoaded state) {
    final stats = state.statistics;
    final insights = _generateInsights(stats);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                '💡',
                style: TextStyle(fontSize: 24),
              ),
              SizedBox(width: 12),
              Text(
                'Insights & Tips',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...insights.map((insight) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 6, right: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFF6E3BFF),
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    insight,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.4,
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

  Widget _buildPerformanceCard(BuildContext context, StatisticsLoaded state) {
    final stats = state.statistics;
    final matchRate = _calculateMatchRate(stats);
    final likeBackRate = _calculateLikeBackRate(stats);
    final engagementScore = _calculateEngagementScore(stats);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                '📈',
                style: TextStyle(fontSize: 24),
              ),
              SizedBox(width: 12),
              Text(
                'Performance Metrics',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildProgressBar('Match Rate', matchRate, 100, '${matchRate.toStringAsFixed(1)}%'),
          const SizedBox(height: 16),
          _buildProgressBar('Like Back Rate', likeBackRate, 100, '${likeBackRate.toStringAsFixed(1)}%'),
          const SizedBox(height: 16),
          _buildProgressBar('Engagement Score', engagementScore, 1000, engagementScore.toInt().toString()),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, double value, double maxValue, String displayValue) {
    final progress = (value / maxValue).clamp(0.0, 1.0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            Text(
              displayValue,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6E3BFF), Color(0xFF00C2FF)],
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, StatisticsError state) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A0A0A), Color(0xFF1A1A1A)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 24),
            const Text(
              'Oops! Something went wrong',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                state.message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                context.read<StatisticsBloc>().add(LoadStatistics());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6E3BFF),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialState(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A0A0A), Color(0xFF1A1A1A)],
        ),
      ),
      child: Center(
        child: ElevatedButton(
          onPressed: () {
            context.read<StatisticsBloc>().add(LoadStatistics());
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6E3BFF),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Load Statistics',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }

  // Helper methods for calculations
  double _calculateMatchRate(UserStatistics stats) {
    if (stats.totalLikes == 0) return 0.0;
    return (stats.totalMatches / stats.totalLikes) * 100;
  }

  double _calculateLikeBackRate(UserStatistics stats) {
    if (stats.likesReceived == 0) return 0.0;
    return (stats.totalMatches / stats.likesReceived) * 100;
  }

  double _calculateEngagementScore(UserStatistics stats) {
    final profileScore = stats.profileViews * 0.1;
    final likesScore = stats.likesReceived * 2;
    final matchesScore = stats.totalMatches * 5;
    final messagesScore = stats.messagesCount * 3;
    final superLikesScore = stats.likesReceived * 10;
    
    return profileScore + likesScore + matchesScore + messagesScore + superLikesScore;
  }

  List<String> _generateInsights(UserStatistics stats) {
    final insights = <String>[];
    final matchRate = _calculateMatchRate(stats);
    
    if (stats.profileViews < 50) {
      insights.add('Add more photos to increase your profile visibility');
    }
    
    if (matchRate < 10) {
      insights.add('Try updating your bio or interests to improve your match rate');
    } else if (matchRate > 25) {
      insights.add('Great match rate! You\'re doing something right');
    }
    
    if (stats.likesReceived > 0) {
      insights.add(
        'People are really interested in you! ${stats.likesReceived} likes received',
      );
    }
    
    if (stats.messagesCount > stats.totalMatches * 2) {
      insights.add('You\'re great at starting conversations! Keep it up');
    }
    
    if (insights.isEmpty) {
      insights.add('Keep being active to see more insights about your dating journey');
    }
    
    return insights;
  }
}