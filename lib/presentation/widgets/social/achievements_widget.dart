import 'package:flutter/material.dart';
import '../../theme/pulse_colors.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';

/// Gamification achievements and badges widget
class AchievementsWidget extends StatefulWidget {
  const AchievementsWidget({
    super.key,
    this.onAchievementTapped,
    this.showProgress = true,
  });

  final Function(Achievement)? onAchievementTapped;
  final bool showProgress;

  @override
  State<AchievementsWidget> createState() => _AchievementsWidgetState();
}

class _AchievementsWidgetState extends State<AchievementsWidget>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;
  late List<Achievement> _achievements;

  void _initializeAchievements(BuildContext context) {
    _achievements = [
      Achievement(
        id: 'first_match',
        title: 'First Match',
        description: 'Made your first match',
        icon: Icons.favorite,
        color: context.errorColor,
        isUnlocked: true,
        unlockedAt: DateTime.now().subtract(const Duration(days: 5)),
        points: 100,
        category: AchievementCategory.dating,
      ),
      Achievement(
        id: 'social_butterfly',
        title: 'Social Butterfly',
        description: 'Started 10 conversations',
        icon: Icons.chat_bubble,
        color: context.successColor,
        isUnlocked: true,
        unlockedAt: DateTime.now().subtract(const Duration(days: 3)),
        points: 250,
        category: AchievementCategory.social,
        progress: 10,
        maxProgress: 10,
      ),
      Achievement(
        id: 'week_streak',
        title: 'Weekly Warrior',
        description: 'Used app 7 days in a row',
        icon: Icons.local_fire_department,
        color: Colors.orange,
        isUnlocked: true,
        unlockedAt: DateTime.now().subtract(const Duration(days: 1)),
        points: 500,
        category: AchievementCategory.engagement,
        rarity: AchievementRarity.rare,
      ),
      Achievement(
        id: 'profile_perfectionist',
        title: 'Profile Perfectionist',
        description: 'Complete your profile 100%',
        icon: Icons.star,
        color: Colors.amber,
        isUnlocked: false,
        points: 300,
        category: AchievementCategory.profile,
        progress: 8,
        maxProgress: 10,
      ),
      Achievement(
        id: 'super_liker',
        title: 'Super Liker',
        description: 'Send 50 Super Likes',
        icon: Icons.bolt,
        color: PulseColors.primary,
        isUnlocked: false,
        points: 750,
        category: AchievementCategory.premium,
        progress: 23,
        maxProgress: 50,
        rarity: AchievementRarity.epic,
      ),
      Achievement(
        id: 'matchmaker',
        title: 'Matchmaker',
        description: 'Get 100 matches',
        icon: Icons.emoji_events,
        color: Colors.green,
        isUnlocked: false,
        points: 1000,
        category: AchievementCategory.dating,
        progress: 67,
        maxProgress: 100,
        rarity: AchievementRarity.legendary,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _initializeAchievements(context);

    _shimmerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _shimmerController.repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.onSurfaceColor,
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
          _buildHeader(context),
          _buildCategoryTabs(context),
          _buildAchievementsList(context),
          _buildProgressSummary(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final totalPoints = _achievements
        .where((a) => a.isUnlocked)
        .fold<int>(0, (sum, a) => sum + a.points);

    final unlockedCount = _achievements.where((a) => a.isUnlocked).length;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  PulseColors.primary,
                  PulseColors.primary.withValues(alpha: 0.7),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.emoji_events,
              color: context.textOnPrimary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Achievements',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
                Text(
                  '$unlockedCount/${_achievements.length} unlocked • $totalPoints points',
                  style: TextStyle(fontSize: 14, color: context.textSecondary),
                ),
              ],
            ),
          ),
          _buildProgressRing(context, unlockedCount / _achievements.length),
        ],
      ),
    );
  }

  Widget _buildProgressRing(BuildContext context, double progress) {
    return SizedBox(
      width: 50,
      height: 50,
      child: Stack(
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 4,
            backgroundColor: context.borderColor.withValues(alpha: 0.3),
            valueColor: AlwaysStoppedAnimation<Color>(PulseColors.primary),
          ),
          Center(
            child: Text(
              '${(progress * 100).round()}%',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: AchievementCategory.values.map((category) {
          final count = _achievements
              .where((a) => a.category == category)
              .length;

          return Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: context.borderColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getCategoryIcon(category),
                  size: 16,
                  color: context.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  _getCategoryName(category),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: context.textSecondary,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: context.borderColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: context.textOnPrimary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAchievementsList(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: _achievements.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final achievement = _achievements[index];
        return _buildAchievementCard(context, achievement);
      },
    );
  }

  Widget _buildAchievementCard(BuildContext context, Achievement achievement) {
    return GestureDetector(
      onTap: () => widget.onAchievementTapped?.call(achievement),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: achievement.isUnlocked
              ? context.surfaceColor
              : context.surfaceColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: achievement.isUnlocked
                ? achievement.color.withValues(alpha: 0.3)
                : context.borderColor,
          ),
          boxShadow: achievement.isUnlocked
              ? [
                  BoxShadow(
                    color: achievement.color.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            _buildAchievementIcon(context, achievement),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          achievement.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: achievement.isUnlocked
                                ? context.textPrimary
                                : context.textSecondary,
                          ),
                        ),
                      ),
                      _buildRarityBadge(context, achievement.rarity),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    achievement.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.textSecondary,
                    ),
                  ),
                  if (widget.showProgress && achievement.maxProgress != null)
                    _buildProgressBar(context, achievement),
                  if (achievement.isUnlocked && achievement.unlockedAt != null)
                    _buildUnlockedDate(achievement.unlockedAt!),
                ],
              ),
            ),
            _buildPointsBadge(context, achievement),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementIcon(BuildContext context, Achievement achievement) {
    final iconWidget = Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: achievement.isUnlocked
            ? achievement.color.withValues(alpha: 0.1)
            : context.borderColor.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(
        achievement.icon,
        color: achievement.isUnlocked
            ? achievement.color
            : context.borderColor.withValues(alpha: 0.3),
        size: 24,
      ),
    );

    if (!achievement.isUnlocked) {
      return ColorFiltered(
        colorFilter: const ColorFilter.mode(
          Color.fromARGB(255, 200, 200, 200),
          BlendMode.saturation,
        ),
        child: iconWidget,
      );
    }

    // Add shimmer effect for rare achievements
    if (achievement.rarity != AchievementRarity.common) {
      return AnimatedBuilder(
        animation: _shimmerAnimation,
        builder: (context, child) {
          return Stack(
            children: [
              iconWidget,
              Positioned.fill(
                child: ClipOval(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          context.textOnPrimary.withValues(alpha: 0.3),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                        begin: Alignment(-1.0 + _shimmerAnimation.value, -1.0),
                        end: Alignment(1.0 + _shimmerAnimation.value, 1.0),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    }

    return iconWidget;
  }

  Widget _buildRarityBadge(BuildContext context, AchievementRarity rarity) {
    if (rarity == AchievementRarity.common) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _getRarityColor(rarity),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _getRarityName(rarity),
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: context.textOnPrimary,
        ),
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context, Achievement achievement) {
    if (achievement.maxProgress == null || achievement.isUnlocked) {
      return const SizedBox.shrink();
    }

    final progress = (achievement.progress ?? 0) / achievement.maxProgress!;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: TextStyle(fontSize: 10, color: context.textSecondary),
              ),
              Text(
                '${achievement.progress}/${achievement.maxProgress}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: context.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: context.borderColor.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(achievement.color),
            minHeight: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildUnlockedDate(DateTime unlockedAt) {
    final daysAgo = DateTime.now().difference(unlockedAt).inDays;
    final timeText = daysAgo == 0
        ? 'Today'
        : daysAgo == 1
        ? 'Yesterday'
        : '$daysAgo days ago';

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        'Unlocked $timeText',
        style: TextStyle(
          fontSize: 10,
          color: Colors.green,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPointsBadge(BuildContext context, Achievement achievement) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: achievement.isUnlocked
            ? PulseColors.primary
            : context.borderColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '+${achievement.points}',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: context.textOnPrimary,
        ),
      ),
    );
  }

  Widget _buildProgressSummary(BuildContext context) {
    final totalPoints = _achievements
        .where((a) => a.isUnlocked)
        .fold<int>(0, (sum, a) => sum + a.points);

    final availablePoints = _achievements
        .where((a) => !a.isUnlocked)
        .fold<int>(0, (sum, a) => sum + a.points);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              context: context,
              icon: Icons.star,
              label: 'Points Earned',
              value: totalPoints.toString(),
              color: Colors.amber,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: context.borderColor.withValues(alpha: 0.2),
          ),
          Expanded(
            child: _buildSummaryItem(
              context: context,
              icon: Icons.trending_up,
              label: 'Available',
              value: availablePoints.toString(),
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: context.textSecondary),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.dating:
        return Icons.favorite;
      case AchievementCategory.social:
        return Icons.chat;
      case AchievementCategory.profile:
        return Icons.person;
      case AchievementCategory.engagement:
        return Icons.local_fire_department;
      case AchievementCategory.premium:
        return Icons.star;
    }
  }

  String _getCategoryName(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.dating:
        return 'Dating';
      case AchievementCategory.social:
        return 'Social';
      case AchievementCategory.profile:
        return 'Profile';
      case AchievementCategory.engagement:
        return 'Engagement';
      case AchievementCategory.premium:
        return 'Premium';
    }
  }

  Color _getRarityColor(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return context.outlineColor;
      case AchievementRarity.rare:
        return Colors.blue;
      case AchievementRarity.epic:
        return Colors.purple;
      case AchievementRarity.legendary:
        return Colors.orange;
    }
  }

  String _getRarityName(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return 'COMMON';
      case AchievementRarity.rare:
        return 'RARE';
      case AchievementRarity.epic:
        return 'EPIC';
      case AchievementRarity.legendary:
        return 'LEGENDARY';
    }
  }
}

enum AchievementCategory { dating, social, profile, engagement, premium }

enum AchievementRarity { common, rare, epic, legendary }

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final int points;
  final AchievementCategory category;
  final AchievementRarity rarity;
  final int? progress;
  final int? maxProgress;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isUnlocked,
    this.unlockedAt,
    required this.points,
    required this.category,
    this.rarity = AchievementRarity.common,
    this.progress,
    this.maxProgress,
  });
}
