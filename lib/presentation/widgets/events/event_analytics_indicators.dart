import 'package:flutter/material.dart';
import '../../../domain/entities/event.dart';
import '../../theme/pulse_colors.dart';

/// Widget to display event analytics indicators including:
/// - Attendance health badges
/// - Engagement scores
/// - Event quality tiers
/// - Popularity level indicators
/// - Success status badges
/// - Conversion funnel summaries
class EventAnalyticsIndicators extends StatelessWidget {
  final Event event;
  final bool showAttendance;
  final bool showEngagement;
  final bool showQuality;
  final bool showPopularity;
  final bool showSuccess;
  final bool compact;

  const EventAnalyticsIndicators({
    super.key,
    required this.event,
    this.showAttendance = true,
    this.showEngagement = true,
    this.showQuality = false,
    this.showPopularity = false,
    this.showSuccess = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: compact ? 6 : 8,
      runSpacing: compact ? 6 : 8,
      children: [
        if (showAttendance && event.attendanceRate > 0)
          _buildAttendanceBadge(),
        if (showEngagement && event.engagementScore > 20)
          _buildEngagementBadge(),
        if (showQuality) _buildQualityBadge(),
        if (showPopularity) _buildPopularityBadge(),
        if (showSuccess && event.isSuccessfulEvent) _buildSuccessBadge(),
        if (event.viewCount > 100) _buildPopularViewsBadge(),
        if (event.satisfactionScore >= 4.0) _buildHighRatingBadge(),
      ],
    );
  }

  /// Build attendance health badge with color-coded indicators
  /// Shows: excellent (≥90%), good (70-89%), moderate (50-69%), poor (<50%)
  Widget _buildAttendanceBadge() {
    final health = event.attendanceHealth;
    final config = _getAttendanceConfig(health);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: config.colors),
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
        boxShadow: [
          BoxShadow(
            color: config.colors.first.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            config.icon,
            color: Colors.white,
            size: compact ? 12 : 14,
          ),
          SizedBox(width: compact ? 3 : 4),
          Text(
            config.label,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 10 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Build engagement score badge with percentage
  Widget _buildEngagementBadge() {
    final score = event.engagementScore.round();
    final color = _getEngagementColor(score);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.trending_up,
            color: color,
            size: compact ? 12 : 14,
          ),
          SizedBox(width: compact ? 3 : 4),
          Text(
            '$score%',
            style: TextStyle(
              color: color,
              fontSize: compact ? 10 : 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (!compact) ...[
            const SizedBox(width: 2),
            Text(
              'engagement',
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build event quality tier badge
  /// Shows: premium (≥80), great (60-79), good (40-59), standard (<40)
  Widget _buildQualityBadge() {
    final quality = event.eventQualityDisplay;
    final config = _getQualityConfig(quality);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: config.colors),
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            config.icon,
            color: Colors.white,
            size: compact ? 12 : 14,
          ),
          SizedBox(width: compact ? 3 : 4),
          Text(
            config.label,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 10 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Build popularity level badge
  /// Shows: viral (≥90), trending (70-89), popular (50-69), growing (<50)
  Widget _buildPopularityBadge() {
    final popularity = event.popularityLevel;
    final config = _getPopularityConfig(popularity);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.15),
        border: Border.all(color: config.color, width: 1.5),
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            config.icon,
            color: config.color,
            size: compact ? 12 : 14,
          ),
          if (!compact) ...[
            SizedBox(width: 4),
            Text(
              config.label,
              style: TextStyle(
                color: config.color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build successful event badge (green checkmark)
  Widget _buildSuccessBadge() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00D95F), Color(0xFF00E676)],
        ),
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified,
            color: Colors.white,
            size: compact ? 12 : 14,
          ),
          if (!compact) ...[
            const SizedBox(width: 4),
            const Text(
              'Success',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build popular views badge (100+ views)
  Widget _buildPopularViewsBadge() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: PulseColors.primary.withValues(alpha: 0.15),
        border: Border.all(color: PulseColors.primary, width: 1.5),
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.visibility,
            color: PulseColors.primary,
            size: compact ? 12 : 14,
          ),
          if (!compact) ...[
            const SizedBox(width: 4),
            Text(
              '${_formatCount(event.viewCount)} views',
              style: const TextStyle(
                color: PulseColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build high rating badge (4+ stars)
  Widget _buildHighRatingBadge() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFB800), Color(0xFFFFC94D)],
        ),
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            event.satisfactionScore.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Configuration Helpers ====================

  /// Get attendance health configuration
  ({
    String label,
    IconData icon,
    List<Color> colors,
  }) _getAttendanceConfig(String health) {
    return switch (health) {
      'excellent' => (
          label: 'Excellent',
          icon: Icons.people,
          colors: const [Color(0xFF00D95F), Color(0xFF00E676)],
        ),
      'good' => (
          label: 'Good',
          icon: Icons.people,
          colors: const [Color(0xFF4CAF50), Color(0xFF66BB6A)],
        ),
      'moderate' => (
          label: 'Moderate',
          icon: Icons.people_outline,
          colors: const [Color(0xFFFFA726), Color(0xFFFFB74D)],
        ),
      'poor' => (
          label: 'Poor',
          icon: Icons.people_outline,
          colors: const [Color(0xFFEF5350), Color(0xFFE57373)],
        ),
      _ => (
          label: 'N/A',
          icon: Icons.info_outline,
          colors: const [Color(0xFF9E9E9E), Color(0xFFBDBDBD)],
        ),
    };
  }

  /// Get engagement color based on score
  Color _getEngagementColor(int score) {
    if (score >= 70) return const Color(0xFF00D95F); // Excellent
    if (score >= 50) return const Color(0xFF4CAF50); // Good
    if (score >= 30) return const Color(0xFFFFA726); // Moderate
    return const Color(0xFFEF5350); // Poor
  }

  /// Get quality configuration
  ({
    String label,
    IconData icon,
    List<Color> colors,
  }) _getQualityConfig(String quality) {
    return switch (quality) {
      'premium' => (
          label: 'Premium',
          icon: Icons.workspace_premium,
          colors: PulseColors.premiumGradient,
        ),
      'great' => (
          label: 'Great',
          icon: Icons.star,
          colors: const [Color(0xFF6E3BFF), Color(0xFF9D5CFF)],
        ),
      'good' => (
          label: 'Good',
          icon: Icons.check_circle,
          colors: const [Color(0xFF4CAF50), Color(0xFF66BB6A)],
        ),
      'standard' => (
          label: 'Standard',
          icon: Icons.event,
          colors: const [Color(0xFF9E9E9E), Color(0xFFBDBDBD)],
        ),
      _ => (
          label: 'N/A',
          icon: Icons.info_outline,
          colors: const [Color(0xFF9E9E9E), Color(0xFFBDBDBD)],
        ),
    };
  }

  /// Get popularity configuration
  ({
    String label,
    IconData icon,
    Color color,
  }) _getPopularityConfig(String popularity) {
    return switch (popularity) {
      'viral' => (
          label: 'Viral',
          icon: Icons.whatshot,
          color: const Color(0xFFFF3D00),
        ),
      'trending' => (
          label: 'Trending',
          icon: Icons.trending_up,
          color: const Color(0xFFFF6B00),
        ),
      'popular' => (
          label: 'Popular',
          icon: Icons.thumb_up,
          color: const Color(0xFF6E3BFF),
        ),
      'growing' => (
          label: 'Growing',
          icon: Icons.show_chart,
          color: const Color(0xFF00C2FF),
        ),
      _ => (
          label: 'New',
          icon: Icons.fiber_new,
          color: const Color(0xFF9E9E9E),
        ),
    };
  }

  /// Format large numbers (1000 -> 1K, 1000000 -> 1M)
  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

/// Detailed event analytics card for event details screen
/// Shows comprehensive analytics including conversion funnel
class EventAnalyticsCard extends StatelessWidget {
  final Event event;

  const EventAnalyticsCard({
    super.key,
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(
                  Icons.analytics_outlined,
                  color: PulseColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Event Analytics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: PulseColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    event.eventQualityDisplay.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: PulseColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Engagement Metrics
            _buildMetricRow(
              'Engagement Score',
              '${event.engagementScore.round()}%',
              Icons.trending_up,
              _getEngagementColor(event.engagementScore.round()),
            ),
            const Divider(height: 20),

            // Attendance Metrics
            if (event.attendanceRate > 0) ...[
              _buildMetricRow(
                'Attendance Rate',
                '${(event.attendanceRate * 100).toStringAsFixed(1)}%',
                Icons.people,
                _getAttendanceColor(event.attendanceRate),
              ),
              const Divider(height: 20),
            ],

            // Satisfaction Score
            if (event.satisfactionScore > 0) ...[
              _buildMetricRow(
                'Satisfaction',
                '${event.satisfactionScore.toStringAsFixed(1)} / 5.0',
                Icons.star,
                const Color(0xFFFFB800),
              ),
              const Divider(height: 20),
            ],

            // Popularity Score
            _buildMetricRow(
              'Popularity',
              '${event.popularityScore.round()} / 100',
              Icons.whatshot,
              PulseColors.secondary,
            ),
            const SizedBox(height: 16),

            // Conversion Funnel Summary
            if (event.conversionRate != null) ...[
              const Text(
                'Conversion Funnel',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _buildFunnelVisual(),
            ],

            // View Stats
            if (event.viewCount > 0) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatBox(
                    'Views',
                    _formatCount(event.viewCount),
                    Icons.visibility,
                  ),
                  _buildStatBox(
                    'Unique',
                    _formatCount(event.uniqueViewers),
                    Icons.person,
                  ),
                  _buildStatBox(
                    'Shares',
                    _formatCount(event.shareCount),
                    Icons.share,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildFunnelVisual() {
    final funnel = event.conversionFunnelSummary;
    final viewToClick = funnel['viewToClick'] ?? '0%';
    final clickToReg = funnel['clickToRegister'] ?? '0%';
    final regToAttend = funnel['registerToAttend'] ?? '0%';
    final health = funnel['health'] ?? 'n/a';

    return Column(
      children: [
        _buildFunnelStage('View → Click', viewToClick, 1.0),
        const SizedBox(height: 8),
        _buildFunnelStage('Click → Register', clickToReg, 0.8),
        const SizedBox(height: 8),
        _buildFunnelStage('Register → Attend', regToAttend, 0.6),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getFunnelHealthColor(health).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getFunnelHealthIcon(health),
                size: 16,
                color: _getFunnelHealthColor(health),
              ),
              const SizedBox(width: 6),
              Text(
                'Funnel Health: ${health.toUpperCase()}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _getFunnelHealthColor(health),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFunnelStage(String label, String percentage, double widthFactor) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: widthFactor *
                    (double.tryParse(
                            percentage.replaceAll('%', '')) ??
                        0) /
                    100,
                child: Container(
                  height: 24,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [PulseColors.primary, PulseColors.secondary],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Container(
                height: 24,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  percentage,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatBox(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: PulseColors.primary, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Color _getEngagementColor(int score) {
    if (score >= 70) return const Color(0xFF00D95F);
    if (score >= 50) return const Color(0xFF4CAF50);
    if (score >= 30) return const Color(0xFFFFA726);
    return const Color(0xFFEF5350);
  }

  Color _getAttendanceColor(double rate) {
    if (rate >= 0.9) return const Color(0xFF00D95F);
    if (rate >= 0.7) return const Color(0xFF4CAF50);
    if (rate >= 0.5) return const Color(0xFFFFA726);
    return const Color(0xFFEF5350);
  }

  Color _getFunnelHealthColor(String health) {
    return switch (health) {
      'excellent' => const Color(0xFF00D95F),
      'good' => const Color(0xFF4CAF50),
      'moderate' => const Color(0xFFFFA726),
      'poor' => const Color(0xFFEF5350),
      _ => const Color(0xFF9E9E9E),
    };
  }

  IconData _getFunnelHealthIcon(String health) {
    return switch (health) {
      'excellent' => Icons.check_circle,
      'good' => Icons.check,
      'moderate' => Icons.warning,
      'poor' => Icons.error,
      _ => Icons.info,
    };
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
