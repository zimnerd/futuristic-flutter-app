import 'package:flutter/material.dart';
import '../../../domain/entities/user_profile.dart';
import '../../theme/pulse_colors.dart';

/// Displays profile analytics indicators for engagement level and quality
/// Used to show profile metrics like engagement level, profile strength, etc.
///
/// Usage:
/// ```dart
/// ProfileAnalyticsIndicators(
///   profile: userProfile,
///   showEngagementLevel: true,
///   showProfileQuality: true,
/// )
/// ```
class ProfileAnalyticsIndicators extends StatelessWidget {
  final UserProfile profile;
  final bool showEngagementLevel;
  final bool showProfileQuality;
  final bool compact;

  const ProfileAnalyticsIndicators({
    super.key,
    required this.profile,
    this.showEngagementLevel = true,
    this.showProfileQuality = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final indicators = <Widget>[];

    if (showEngagementLevel) {
      indicators.add(_buildEngagementLevelBadge());
    }

    if (showProfileQuality && profile.isHighQualityProfile) {
      indicators.add(_buildProfileQualityBadge());
    }

    if (indicators.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: compact ? 4 : 8,
      runSpacing: compact ? 4 : 8,
      children: indicators,
    );
  }

  Widget _buildEngagementLevelBadge() {
    final engagementLevel = profile.engagementLevel;
    final config = _getEngagementLevelConfig(engagementLevel);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: config.colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
        boxShadow: [
          BoxShadow(
            color: config.colors[0].withValues(alpha: 0.3),
            blurRadius: compact ? 4 : 6,
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
            size: compact ? 14 : 16,
          ),
          SizedBox(width: compact ? 4 : 6),
          Text(
            config.label,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 11 : 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileQualityBadge() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00D95F), Color(0xFF00B34D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D95F).withValues(alpha: 0.3),
            blurRadius: compact ? 4 : 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star,
            color: Colors.white,
            size: compact ? 14 : 16,
          ),
          SizedBox(width: compact ? 4 : 6),
          Text(
            'High Quality',
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 11 : 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  _EngagementLevelConfig _getEngagementLevelConfig(String level) {
    switch (level) {
      case 'influencer':
        return _EngagementLevelConfig(
          label: 'Influencer',
          icon: Icons.local_fire_department,
          colors: [const Color(0xFFFF6B6B), const Color(0xFFFF5252)],
        );
      case 'popular':
        return _EngagementLevelConfig(
          label: 'Popular',
          icon: Icons.trending_up,
          colors: [PulseColors.secondary, PulseColors.secondary.withValues(alpha: 0.8)],
        );
      case 'active':
        return _EngagementLevelConfig(
          label: 'Active',
          icon: Icons.bolt,
          colors: [PulseColors.primary, PulseColors.primary.withValues(alpha: 0.8)],
        );
      case 'growing':
        return _EngagementLevelConfig(
          label: 'Growing',
          icon: Icons.arrow_upward,
          colors: [const Color(0xFF00D95F), const Color(0xFF00B34D)],
        );
      case 'new':
      default:
        return _EngagementLevelConfig(
          label: 'New',
          icon: Icons.new_releases,
          colors: [const Color(0xFF9E9E9E), const Color(0xFF757575)],
        );
    }
  }
}

class _EngagementLevelConfig {
  final String label;
  final IconData icon;
  final List<Color> colors;

  _EngagementLevelConfig({
    required this.label,
    required this.icon,
    required this.colors,
  });
}
