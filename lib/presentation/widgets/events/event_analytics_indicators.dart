import 'package:flutter/material.dart';
import '../../../domain/entities/event.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';

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
          _buildAttendanceBadge(context),
        if (showEngagement && event.engagementScore > 20)
          _buildEngagementBadge(context),
        if (showQuality) _buildQualityBadge(context),
        if (showPopularity) _buildPopularityBadge(context),
        if (showSuccess && event.isSuccessfulEvent) _buildSuccessBadge(context),
        if (event.viewCount > 100) _buildPopularViewsBadge(context),
        if (event.satisfactionScore >= 4.0) _buildHighRatingBadge(context),
      ],
    );
  }

  /// Build attendance health badge with color-coded indicators
  /// Shows: excellent (≥90%), good (70-89%), moderate (50-69%), poor (<50%)
  Widget _buildAttendanceBadge(BuildContext context) {
    final health = event.attendanceHealth;
    final config = _getAttendanceConfig(context, health);

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
            color: Theme.of(context).colorScheme.onSurface,
            size: compact ? 12 : 14,
          ),
          SizedBox(width: compact ? 3 : 4),
          Text(
            config.label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: compact ? 10 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Build engagement score badge with percentage
  Widget _buildEngagementBadge(BuildContext context) {
    final score = event.engagementScore.round();
    final color = _getEngagementColor(context, score);

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
          Icon(Icons.trending_up, color: color, size: compact ? 12 : 14),
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
  Widget _buildQualityBadge(BuildContext context) {
    final quality = event.eventQualityDisplay;
    final config = _getQualityConfig(context, quality);

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
            color: Theme.of(context).colorScheme.onSurface,
            size: compact ? 12 : 14,
          ),
          SizedBox(width: compact ? 3 : 4),
          Text(
            config.label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
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
  Widget _buildPopularityBadge(BuildContext context) {
    final popularity = event.popularityLevel;
    final config = _getPopularityConfig(context, popularity);

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
          Icon(config.icon, color: config.color, size: compact ? 12 : 14),
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
  Widget _buildSuccessBadge(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [context.performanceExcellent, context.successColor],
        ),
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified,
            color: Theme.of(context).colorScheme.onSurface,
            size: compact ? 12 : 14,
          ),
          if (!compact) ...[
            const SizedBox(width: 4),
            Text(
              'Success',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
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
  Widget _buildPopularViewsBadge(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: context.primaryColor.withValues(alpha: 0.15),
        border: Border.all(color: context.primaryColor, width: 1.5),
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.visibility,
            color: context.primaryColor,
            size: compact ? 12 : 14,
          ),
          if (!compact) ...[
            const SizedBox(width: 4),
            Text(
              '${_formatCount(event.viewCount)} views',
              style: TextStyle(
                color: context.primaryColor,
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
  Widget _buildHighRatingBadge(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [context.statusWarning, context.premiumGold],
        ),
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star,
            color: Theme.of(context).colorScheme.onSurface,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            event.satisfactionScore.toStringAsFixed(1),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
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
  ({String label, IconData icon, List<Color> colors}) _getAttendanceConfig(
    BuildContext context,
    String health,
  ) {
    return switch (health) {
      'excellent' => (
        label: 'Excellent',
        icon: Icons.people,
        colors: [context.performanceExcellent, context.successColor],
      ),
      'good' => (
        label: 'Good',
        icon: Icons.people,
        colors: [context.performanceGood, context.successColor],
      ),
      'moderate' => (
        label: 'Moderate',
        icon: Icons.people_outline,
        colors: [context.performanceModerate, context.statusWarning],
      ),
      'poor' => (
        label: 'Poor',
        icon: Icons.people_outline,
        colors: [context.performancePoor, context.errorColor],
      ),
      _ => (
        label: 'N/A',
        icon: Icons.info_outline,
        colors: [context.performanceNeutral, context.disabledColor],
      ),
    };
  }

  /// Get engagement color based on score
  Color _getEngagementColor(BuildContext context, int score) {
    if (score >= 70) return context.performanceExcellent; // Excellent
    if (score >= 50) return context.performanceGood; // Good
    if (score >= 30) return context.performanceModerate; // Moderate
    return context.performancePoor; // Poor
  }

  /// Get quality configuration
  ({String label, IconData icon, List<Color> colors}) _getQualityConfig(
    BuildContext context,
    String quality,
  ) {
    return switch (quality) {
      'premium' => (
        label: 'Premium',
        icon: Icons.workspace_premium,
        colors: [context.premiumGradientStart, context.premiumGradientEnd],
      ),
      'great' => (
        label: 'Great',
        icon: Icons.star,
        colors: [context.primaryColor, context.accentColor],
      ),
      'good' => (
        label: 'Good',
        icon: Icons.check_circle,
        colors: [context.performanceGood, context.successColor],
      ),
      'standard' => (
        label: 'Standard',
        icon: Icons.event,
        colors: [context.performanceNeutral, context.disabledColor],
      ),
      _ => (
        label: 'N/A',
        icon: Icons.info_outline,
        colors: [context.performanceNeutral, context.disabledColor],
      ),
    };
  }

  /// Get popularity configuration
  ({String label, IconData icon, Color color}) _getPopularityConfig(
    BuildContext context,
    String popularity,
  ) {
    return switch (popularity) {
      'viral' => (
        label: 'Viral',
        icon: Icons.whatshot,
        color: context.errorColor,
      ),
      'trending' => (
        label: 'Trending',
        icon: Icons.trending_up,
        color: context.statusWarning,
      ),
      'popular' => (
        label: 'Popular',
        icon: Icons.thumb_up,
        color: context.primaryColor,
      ),
      'growing' => (
        label: 'Growing',
        icon: Icons.show_chart,
        color: context.accentColor,
      ),
      _ => (
        label: 'New',
        icon: Icons.fiber_new,
        color: context.performanceNeutral,
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

  const EventAnalyticsCard({super.key, required this.event});

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
                Icon(
                  Icons.analytics_outlined,
                  color: context.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Event Analytics',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: context.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    event.eventQualityDisplay.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: context.primaryColor,
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
              _getEngagementColorAlt(context, event.engagementScore.round()),
            ),
            const Divider(height: 20),

            // Attendance Metrics
            if (event.attendanceRate > 0) ...[
              _buildMetricRow(
                'Attendance Rate',
                '${(event.attendanceRate * 100).toStringAsFixed(1)}%',
                Icons.people,
                _getAttendanceColor(context, event.attendanceRate),
              ),
              const Divider(height: 20),
            ],

            // Satisfaction Score
            if (event.satisfactionScore > 0) ...[
              _buildMetricRow(
                'Satisfaction',
                '${event.satisfactionScore.toStringAsFixed(1)} / 5.0',
                Icons.star,
                context.statusWarning,
              ),
              const Divider(height: 20),
            ],

            // Popularity Score
            _buildMetricRow(
              'Popularity',
              '${event.popularityScore.round()} / 100',
              Icons.whatshot,
              context.accentColor,
            ),
            const SizedBox(height: 16),

            // Conversion Funnel Summary
            if (event.conversionRate != null) ...[
              Text(
                'Conversion Funnel',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              _buildFunnelVisual(context),
            ],

            // View Stats
            if (event.viewCount > 0) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatBox(
                    context,
                    'Views',
                    _formatCount(event.viewCount),
                    Icons.visibility,
                  ),
                  _buildStatBox(
                    context,
                    'Unique',
                    _formatCount(event.uniqueViewers),
                    Icons.person,
                  ),
                  _buildStatBox(
                    context,
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
        Expanded(child: Text(label, style: TextStyle(fontSize: 14))),
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

  Widget _buildFunnelVisual(BuildContext context) {
    final funnel = event.conversionFunnelSummary;
    final viewToClick = funnel['viewToClick'] ?? '0%';
    final clickToReg = funnel['clickToRegister'] ?? '0%';
    final regToAttend = funnel['registerToAttend'] ?? '0%';
    final health = funnel['health'] ?? 'n/a';

    return Column(
      children: [
        _buildFunnelStage(context, 'View → Click', viewToClick, 1.0),
        const SizedBox(height: 8),
        _buildFunnelStage(context, 'Click → Register', clickToReg, 0.8),
        const SizedBox(height: 8),
        _buildFunnelStage(context, 'Register → Attend', regToAttend, 0.6),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getFunnelHealthColor(context, health).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getFunnelHealthIcon(health),
                size: 16,
                color: _getFunnelHealthColor(context, health),
              ),
              const SizedBox(width: 6),
              Text(
                'Funnel Health: ${health.toUpperCase()}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _getFunnelHealthColor(context, health),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFunnelStage(
    BuildContext context,
    String label,
    String percentage,
    double widthFactor,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: TextStyle(fontSize: 12)),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 24,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor:
                    widthFactor *
                    (double.tryParse(percentage.replaceAll('%', '')) ?? 0) /
                    100,
                child: Container(
                  height: 24,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [context.primaryColor, context.accentColor],
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
                  style: TextStyle(
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

  Widget _buildStatBox(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: context.primaryColor, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.outline.shade600,
          ),
        ),
      ],
    );
  }

  Color _getEngagementColorAlt(BuildContext context, int score) {
    if (score >= 70) return context.performanceExcellent;
    if (score >= 50) return context.performanceGood;
    if (score >= 30) return context.performanceModerate;
    return context.performancePoor;
  }

  Color _getAttendanceColor(BuildContext context, double rate) {
    if (rate >= 0.9) return context.performanceExcellent;
    if (rate >= 0.7) return context.performanceGood;
    if (rate >= 0.5) return context.performanceModerate;
    return context.performancePoor;
  }

  Color _getFunnelHealthColor(BuildContext context, String health) {
    return switch (health) {
      'excellent' => context.performanceExcellent,
      'good' => context.performanceGood,
      'moderate' => context.performanceModerate,
      'poor' => context.performancePoor,
      _ => context.performanceNeutral,
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
