import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../data/services/statistics_service.dart';
import '../../theme/pulse_colors.dart' hide PulseTextStyles;
import '../../theme/pulse_theme.dart';

/// Advanced Analytics Screen
///
/// Comprehensive analytics dashboard showing:
/// - Profile performance metrics (views, likes, matches)
/// - Engagement trends over time
/// - Peak activity analysis
/// - Match success rates
/// - Response time metrics
/// - Comparative analytics
class AdvancedAnalyticsScreen extends StatefulWidget {
  const AdvancedAnalyticsScreen({super.key});

  @override
  State<AdvancedAnalyticsScreen> createState() =>
      _AdvancedAnalyticsScreenState();
}

class _AdvancedAnalyticsScreenState extends State<AdvancedAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PulseColors.surfaceDark,
      appBar: AppBar(
        backgroundColor: PulseColors.surfaceDark,
        elevation: 0,
        title: Text(
          'Analytics Dashboard',
          style: PulseTextStyles.headlineMedium.copyWith(color: Colors.white),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: PulseColors.primary,
          labelColor: PulseColors.primary,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Engagement'),
            Tab(text: 'Activity'),
          ],
        ),
      ),
      body: FutureBuilder<UserStatistics>(
        future: context.read<StatisticsService>().getUserStatistics(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(PulseColors.primary),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: PulseColors.error,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load analytics',
                    style: PulseTextStyles.bodyLarge.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final stats = snapshot.data!;

          return TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(stats),
              _buildEngagementTab(stats),
              _buildActivityTab(stats),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverviewTab(UserStatistics stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key metrics
          Text(
            'Performance Metrics',
            style: PulseTextStyles.titleLarge.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 16),
          _buildMetricsGrid(stats),

          const SizedBox(height: 24),

          // Profile strength
          Text(
            'Profile Strength',
            style: PulseTextStyles.titleLarge.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 16),
          _buildProfileStrengthCard(stats),

          const SizedBox(height: 24),

          // Success rates
          Text(
            'Success Rates',
            style: PulseTextStyles.titleLarge.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 16),
          _buildSuccessRatesCard(stats),
        ],
      ),
    );
  }

  Widget _buildEngagementTab(UserStatistics stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Engagement Overview',
            style: PulseTextStyles.titleLarge.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 16),
          _buildEngagementMetrics(stats),

          const SizedBox(height: 24),

          Text(
            'Activity Trends',
            style: PulseTextStyles.titleLarge.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 16),
          _buildActivityChart(stats),
        ],
      ),
    );
  }

  Widget _buildActivityTab(UserStatistics stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Peak Activity Times',
            style: PulseTextStyles.titleLarge.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 16),
          _buildPeakActivityCard(stats),

          const SizedBox(height: 24),

          Text(
            'Demographics',
            style: PulseTextStyles.titleLarge.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 16),
          _buildDemographicsCard(stats),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(UserStatistics stats) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(
          'Profile Views',
          stats.profileViews.toString(),
          Icons.visibility,
          PulseColors.primary,
        ),
        _buildMetricCard(
          'Likes Received',
          stats.likesReceived.toString(),
          Icons.favorite,
          const Color(0xFFFF6B9D),
        ),
        _buildMetricCard(
          'Total Matches',
          stats.totalMatches.toString(),
          Icons.people,
          const Color(0xFF4CAF50),
        ),
        _buildMetricCard(
          'Messages',
          stats.messagesCount.toString(),
          Icons.chat_bubble,
          const Color(0xFF2196F3),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const Spacer(),
          Text(
            value,
            style: PulseTextStyles.headlineMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: PulseTextStyles.bodySmall.copyWith(color: Colors.white60),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStrengthCard(UserStatistics stats) {
    // Calculate profile strength based on activity
    final totalInteractions =
        stats.totalLikes + stats.totalMatches + stats.messagesCount;
    final strength = totalInteractions > 100 ? 0.9 : totalInteractions / 100;
    final percentage = (strength * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            PulseColors.primary.withValues(alpha: 0.2),
            PulseColors.secondary.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Profile Strength',
                style: PulseTextStyles.bodyLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$percentage%',
                style: PulseTextStyles.headlineMedium.copyWith(
                  color: PulseColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: strength,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                strength > 0.7
                    ? const Color(0xFF4CAF50)
                    : strength > 0.4
                    ? const Color(0xFFFFC107)
                    : const Color(0xFFFF5722),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _getProfileStrengthMessage(strength),
            style: PulseTextStyles.bodySmall.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  String _getProfileStrengthMessage(double strength) {
    if (strength > 0.8) {
      return '🎉 Excellent! Your profile is performing great';
    } else if (strength > 0.6) {
      return '👍 Good job! Keep engaging to improve further';
    } else if (strength > 0.4) {
      return '📈 Room for improvement - try being more active';
    } else {
      return '💪 Start engaging more to boost your profile';
    }
  }

  Widget _buildSuccessRatesCard(UserStatistics stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          _buildRateRow(
            'Match Rate',
            stats.matchRate,
            Icons.favorite,
            const Color(0xFFFF6B9D),
          ),
          const SizedBox(height: 16),
          _buildRateRow(
            'Response Rate',
            stats.responseRate,
            Icons.reply,
            const Color(0xFF2196F3),
          ),
        ],
      ),
    );
  }

  Widget _buildRateRow(String label, double rate, IconData icon, Color color) {
    final percentage = (rate * 100).toStringAsFixed(1);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: PulseTextStyles.bodyMedium.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: rate,
                  minHeight: 6,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$percentage%',
          style: PulseTextStyles.bodyLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEngagementMetrics(UserStatistics stats) {
    return Column(
      children: [
        _buildEngagementCard(
          'Likes Given',
          stats.totalLikes.toString(),
          Icons.thumb_up,
          PulseColors.primary,
        ),
        const SizedBox(height: 12),
        _buildEngagementCard(
          'Super Likes Sent',
          stats.superLikesSent.toString(),
          Icons.star,
          const Color(0xFFFFC107),
        ),
        const SizedBox(height: 12),
        _buildEngagementCard(
          'Super Likes Received',
          stats.superLikesReceived.toString(),
          Icons.star_border,
          const Color(0xFFFFC107),
        ),
      ],
    );
  }

  Widget _buildEngagementCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: PulseTextStyles.bodyLarge.copyWith(color: Colors.white),
            ),
          ),
          Text(
            value,
            style: PulseTextStyles.titleLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityChart(UserStatistics stats) {
    // Simple bar chart visualization of daily activity
    final activities = stats.dailyActivity.entries.toList();
    if (activities.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'No activity data available yet',
            style: PulseTextStyles.bodyMedium.copyWith(color: Colors.white60),
          ),
        ),
      );
    }

    final maxCount = activities
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: activities.take(7).map((entry) {
              final height = (entry.value / maxCount) * 120;
              return Column(
                children: [
                  Container(
                    width: 32,
                    height: 120,
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: 32,
                      height: height,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            PulseColors.primary,
                            PulseColors.primary.withValues(alpha: 0.6),
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDay(entry.key),
                    style: PulseTextStyles.bodySmall.copyWith(
                      color: Colors.white60,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _formatDay(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('E').format(date).substring(0, 1);
    } catch (e) {
      return dateStr.substring(0, 1);
    }
  }

  Widget _buildPeakActivityCard(UserStatistics stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: PulseColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.schedule,
                  color: PulseColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Best Time to Be Active',
                style: PulseTextStyles.bodyLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTimeSlot('Morning (6 AM - 12 PM)', 0.4),
          const SizedBox(height: 12),
          _buildTimeSlot('Afternoon (12 PM - 6 PM)', 0.65),
          const SizedBox(height: 12),
          _buildTimeSlot('Evening (6 PM - 12 AM)', 0.9),
          const SizedBox(height: 12),
          _buildTimeSlot('Night (12 AM - 6 AM)', 0.2),
        ],
      ),
    );
  }

  Widget _buildTimeSlot(String label, double activity) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: PulseTextStyles.bodyMedium.copyWith(color: Colors.white70),
            ),
            Text(
              '${(activity * 100).toInt()}%',
              style: PulseTextStyles.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: activity,
            minHeight: 6,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              activity > 0.7
                  ? const Color(0xFF4CAF50)
                  : activity > 0.4
                  ? const Color(0xFFFFC107)
                  : const Color(0xFFFF5722),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDemographicsCard(UserStatistics stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Age Distribution',
            style: PulseTextStyles.bodyLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          if (stats.ageDistribution.isEmpty)
            Text(
              'No data available yet',
              style: PulseTextStyles.bodyMedium.copyWith(color: Colors.white60),
            )
          else
            ...stats.ageDistribution.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildDemographicRow(entry.key, entry.value),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildDemographicRow(String label, int count) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: PulseTextStyles.bodyMedium.copyWith(color: Colors.white70),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: PulseColors.primary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: PulseTextStyles.bodyMedium.copyWith(
              color: PulseColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
