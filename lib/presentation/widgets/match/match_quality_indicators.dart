import 'package:flutter/material.dart';
import '../../../data/models/match_model.dart';
import '../../theme/pulse_colors.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';

/// Widget to display match quality indicators including:
/// - Conversation health badges
/// - Engagement scores
/// - Match quality tiers
/// - Match source indicators
/// - Favorite status
class MatchQualityIndicators extends StatelessWidget {
  final MatchModel match;
  final bool showEngagement;
  final bool showHealth;
  final bool showQuality;
  final bool showSource;
  final bool compact;
  final VoidCallback? onFavoriteToggle;

  const MatchQualityIndicators({
    super.key,
    required this.match,
    this.showEngagement = true,
    this.showHealth = true,
    this.showQuality = false,
    this.showSource = false,
    this.compact = false,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: compact ? 6 : 8,
      runSpacing: compact ? 6 : 8,
      children: [
        if (showHealth) _buildHealthBadge(context),
        if (showEngagement && match.engagementScore > 50)
          _buildEngagementBadge(context),
        if (showQuality && match.qualityScore > 60) _buildQualityBadge(context),
        if (showSource && match.matchSource != null) _buildSourceBadge(context),
        if (match.isPremiumMatch) _buildPremiumBadge(context),
        if (match.meetupScheduled) _buildMeetupBadge(context),
        if (onFavoriteToggle != null) _buildFavoriteButton(context),
      ],
    );
  }

  /// Build conversation health badge with color-coded indicators
  Widget _buildHealthBadge(BuildContext context) {
    final health = match.conversationHealth;
    final config = _getHealthConfig(health);

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
            color: context.onSurfaceColor,
            size: compact ? 12 : 14,
          ),
          SizedBox(width: compact ? 3 : 4),
          Text(
            config.label,
            style: TextStyle(
              color: context.onSurfaceColor,
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
    final score = match.engagementScore.round();
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
        ],
      ),
    );
  }

  /// Build quality tier badge
  Widget _buildQualityBadge(BuildContext context) {
    final quality = match.matchQualityDisplay;
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
            color: context.onSurfaceColor,
            size: compact ? 12 : 14,
          ),
          SizedBox(width: compact ? 3 : 4),
          Text(
            config.label,
            style: TextStyle(
              color: context.onSurfaceColor,
              fontSize: compact ? 10 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Build match source badge (swipe, AI, event, etc.)
  Widget _buildSourceBadge(BuildContext context) {
    final source = match.matchSource;
    final config = _getSourceConfig(context, source ?? '');

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

  /// Build premium match badge
  Widget _buildPremiumBadge(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: PulseColors.premiumGradient),
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.workspace_premium,
            color: context.onSurfaceColor,
            size: compact ? 12 : 14,
          ),
          if (!compact) ...[
            const SizedBox(width: 4),
            Text(
              'Premium',
              style: TextStyle(
                color: context.onSurfaceColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build meetup scheduled badge
  Widget _buildMeetupBadge(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B9D), Color(0xFFFFA4C4)],
        ),
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_today,
            color: context.onSurfaceColor,
            size: compact ? 12 : 14,
          ),
          if (!compact) ...[
            const SizedBox(width: 4),
            Text(
              'Meetup',
              style: TextStyle(
                color: context.onSurfaceColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build favorite toggle button
  Widget _buildFavoriteButton(BuildContext context) {
    return GestureDetector(
      onTap: onFavoriteToggle,
      child: Container(
        padding: EdgeInsets.all(compact ? 6 : 8),
        decoration: BoxDecoration(
          color: match.isFavorite
              ? PulseColors.secondary.withValues(alpha: 0.15)
              : context.outlineColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(compact ? 12 : 16),
          border: Border.all(
            color: match.isFavorite
                ? PulseColors.secondary
                : context.outlineColor,
            width: 1.5,
          ),
        ),
        child: Icon(
          match.isFavorite ? Icons.star : Icons.star_border,
          color: match.isFavorite
              ? PulseColors.secondary
              : context.outlineColor,
          size: compact ? 14 : 16,
        ),
      ),
    );
  }

  /// Get configuration for conversation health display
  _HealthConfig _getHealthConfig(String health) {
    switch (health) {
      case 'excellent':
        return _HealthConfig(
          label: 'Excellent',
          icon: Icons.auto_awesome,
          colors: [const Color(0xFF00D95F), const Color(0xFF00FF7F)],
        );
      case 'good':
        return _HealthConfig(
          label: 'Good',
          icon: Icons.thumb_up,
          colors: [const Color(0xFF4CAF50), const Color(0xFF81C784)],
        );
      case 'moderate':
        return _HealthConfig(
          label: 'Moderate',
          icon: Icons.trending_flat,
          colors: [const Color(0xFFFFA726), const Color(0xFFFFB74D)],
        );
      case 'poor':
        return _HealthConfig(
          label: 'Low',
          icon: Icons.trending_down,
          colors: [const Color(0xFFFF7043), const Color(0xFFFF8A65)],
        );
      case 'inactive':
        return _HealthConfig(
          label: 'Inactive',
          icon: Icons.notifications_paused,
          colors: [const Color(0xFF9E9E9E), const Color(0xFFBDBDBD)],
        );
      default:
        return _HealthConfig(
          label: 'Unknown',
          icon: Icons.help_outline,
          colors: [const Color(0xFF9E9E9E), const Color(0xFFBDBDBD)],
        );
    }
  }

  /// Get configuration for quality tier display
  _QualityConfig _getQualityConfig(String quality) {
    switch (quality) {
      case 'premium':
        return _QualityConfig(
          label: 'Premium',
          icon: Icons.diamond,
          colors: PulseColors.premiumGradient,
        );
      case 'great':
        return _QualityConfig(
          label: 'Great',
          icon: Icons.star,
          colors: [const Color(0xFF00D95F), const Color(0xFF00FF7F)],
        );
      case 'good':
        return _QualityConfig(
          label: 'Good',
          icon: Icons.thumb_up,
          colors: [const Color(0xFF2196F3), const Color(0xFF64B5F6)],
        );
      case 'standard':
        return _QualityConfig(
          label: 'Standard',
          icon: Icons.check_circle,
          colors: [const Color(0xFF757575), const Color(0xFF9E9E9E)],
        );
      default:
        return _QualityConfig(
          label: 'Unknown',
          icon: Icons.help_outline,
          colors: [const Color(0xFF9E9E9E), const Color(0xFFBDBDBD)],
        );
    }
  }

  /// Get configuration for match source display
  _SourceConfig _getSourceConfig(BuildContext context, String source) {
    switch (source.toUpperCase()) {
      case 'SUPER_LIKE':
        return _SourceConfig(
          label: 'Super Like',
          icon: Icons.favorite,
          color: const Color(0xFFFF6B9D),
        );
      case 'AI_SUGGESTED':
        return _SourceConfig(
          label: 'AI Match',
          icon: Icons.psychology,
          color: PulseColors.primary,
        );
      case 'EVENT_BASED':
        return _SourceConfig(
          label: 'Event',
          icon: Icons.event,
          color: const Color(0xFFFF9800),
        );
      case 'AR_PROXIMITY':
        return _SourceConfig(
          label: 'AR Nearby',
          icon: Icons.location_on,
          color: const Color(0xFF00BCD4),
        );
      case 'BOOST':
        return _SourceConfig(
          label: 'Boost',
          icon: Icons.rocket_launch,
          color: PulseColors.secondary,
        );
      case 'MUTUAL_INTEREST':
        return _SourceConfig(
          label: 'Interest',
          icon: Icons.favorite_border,
          color: const Color(0xFFE91E63),
        );
      default:
        return _SourceConfig(
          label: 'Swipe',
          icon: Icons.swipe,
          color: context.outlineColor,
        );
    }
  }

  /// Get color for engagement score
  Color _getEngagementColor(int score) {
    if (score >= 80) return const Color(0xFF00D95F);
    if (score >= 60) return const Color(0xFF4CAF50);
    if (score >= 40) return const Color(0xFFFFA726);
    return const Color(0xFFFF7043);
  }
}

/// Configuration for health badge display
class _HealthConfig {
  final String label;
  final IconData icon;
  final List<Color> colors;

  _HealthConfig({
    required this.label,
    required this.icon,
    required this.colors,
  });
}

/// Configuration for quality badge display
class _QualityConfig {
  final String label;
  final IconData icon;
  final List<Color> colors;

  _QualityConfig({
    required this.label,
    required this.icon,
    required this.colors,
  });
}

/// Configuration for source badge display
class _SourceConfig {
  final String label;
  final IconData icon;
  final Color color;

  _SourceConfig({required this.label, required this.icon, required this.color});
}
