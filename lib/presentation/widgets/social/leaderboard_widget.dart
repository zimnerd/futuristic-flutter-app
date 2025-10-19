import 'package:flutter/material.dart';
import '../../theme/pulse_colors.dart';

/// Social gaming leaderboard widget with animations and rankings
class LeaderboardWidget extends StatefulWidget {
  const LeaderboardWidget({
    super.key,
    required this.leaderboardType,
    this.onUserTapped,
    this.showCurrentUser = true,
  });

  final LeaderboardType leaderboardType;
  final Function(LeaderboardEntry)? onUserTapped;
  final bool showCurrentUser;

  @override
  State<LeaderboardWidget> createState() => _LeaderboardWidgetState();
}

class _LeaderboardWidgetState extends State<LeaderboardWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<double>> _entryAnimations;

  final List<LeaderboardEntry> _entries = [
    LeaderboardEntry(
      id: '1',
      name: 'Sarah Chen',
      score: 2845,
      rank: 1,
      avatar:
          'https://apilink.pulsetek.co.za/uploads/images-seeder/image-1761.jpg',
      badgeType: BadgeType.gold,
      isCurrentUser: false,
      streak: 12,
      level: 15,
    ),
    LeaderboardEntry(
      id: '2',
      name: 'Alex Rivera',
      score: 2720,
      rank: 2,
      avatar:
          'https://apilink.pulsetek.co.za/uploads/images-seeder/image-1763.jpg',
      badgeType: BadgeType.silver,
      isCurrentUser: false,
      streak: 8,
      level: 14,
    ),
    LeaderboardEntry(
      id: '3',
      name: 'Emma Johnson',
      score: 2650,
      rank: 3,
      avatar:
          'https://apilink.pulsetek.co.za/uploads/images-seeder/image-1766.jpg',
      badgeType: BadgeType.bronze,
      isCurrentUser: false,
      streak: 15,
      level: 13,
    ),
    LeaderboardEntry(
      id: '4',
      name: 'You',
      score: 2420,
      rank: 7,
      avatar:
          'https://apilink.pulsetek.co.za/uploads/images-seeder/image-1769.jpg',
      badgeType: BadgeType.none,
      isCurrentUser: true,
      streak: 5,
      level: 11,
    ),
  ];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _entryAnimations = List.generate(
      _entries.length,
      (index) => Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            index * 0.1,
            0.5 + (index * 0.1),
            curve: Curves.elasticOut,
          ),
        ),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildTopThree(),
          _buildLeaderboardList(),
          if (widget.showCurrentUser) _buildCurrentUserPosition(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            PulseColors.primary,
            PulseColors.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getLeaderboardTitle(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _getLeaderboardSubtitle(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Text(
              'Weekly',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopThree() {
    final topThree = _entries.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 2nd place
          if (topThree.length > 1) _buildPodiumPosition(topThree[1], 1),

          // 1st place
          if (topThree.isNotEmpty)
            _buildPodiumPosition(topThree[0], 0, isWinner: true),

          // 3rd place
          if (topThree.length > 2) _buildPodiumPosition(topThree[2], 2),
        ],
      ),
    );
  }

  Widget _buildPodiumPosition(
    LeaderboardEntry entry,
    int animationIndex, {
    bool isWinner = false,
  }) {
    return AnimatedBuilder(
      animation: _entryAnimations[animationIndex],
      builder: (context, child) {
        return Transform.scale(
          scale: _entryAnimations[animationIndex].value,
          child: Column(
            children: [
              // Avatar with crown for winner
              Stack(
                children: [
                  Container(
                    width: isWinner ? 80 : 60,
                    height: isWinner ? 80 : 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _getBadgeColor(entry.badgeType),
                        width: 3,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.network(
                        entry.avatar,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade300,
                            child: Icon(
                              Icons.person,
                              color: Colors.grey.shade600,
                              size: isWinner ? 40 : 30,
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Crown for winner
                  if (isWinner)
                    Positioned(
                      top: -10,
                      left: 0,
                      right: 0,
                      child: Container(
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 24,
                        ),
                      ),
                    ),

                  // Rank badge
                  Positioned(
                    bottom: -5,
                    right: -5,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _getBadgeColor(entry.badgeType),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          '${entry.rank}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Name
              SizedBox(
                width: isWinner ? 100 : 80,
                child: Text(
                  entry.name,
                  style: TextStyle(
                    fontSize: isWinner ? 14 : 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Score
              Text(
                '${entry.score}',
                style: TextStyle(
                  fontSize: isWinner ? 16 : 14,
                  fontWeight: FontWeight.bold,
                  color: PulseColors.primary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLeaderboardList() {
    final remainingEntries = _entries.skip(3).toList();

    if (remainingEntries.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        const Divider(),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: remainingEntries.length,
          itemBuilder: (context, index) {
            final entry = remainingEntries[index];
            final animationIndex = index + 3;

            return AnimatedBuilder(
              animation: _entryAnimations[animationIndex],
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    (1 - _entryAnimations[animationIndex].value) * 100,
                    0,
                  ),
                  child: Opacity(
                    opacity: _entryAnimations[animationIndex].value,
                    child: _buildLeaderboardItem(entry),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildLeaderboardItem(LeaderboardEntry entry) {
    return ListTile(
      onTap: () => widget.onUserTapped?.call(entry),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundImage: NetworkImage(entry.avatar),
            onBackgroundImageError: (error, stackTrace) {},
            child: entry.avatar.isEmpty ? const Icon(Icons.person) : null,
          ),

          // Rank indicator
          Positioned(
            bottom: -2,
            right: -2,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: entry.isCurrentUser ? PulseColors.primary : Colors.grey,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Text(
                  '${entry.rank}',
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      title: Row(
        children: [
          Text(
            entry.name,
            style: TextStyle(
              fontWeight: entry.isCurrentUser
                  ? FontWeight.bold
                  : FontWeight.w500,
              color: entry.isCurrentUser ? PulseColors.primary : null,
            ),
          ),
          if (entry.isCurrentUser) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: PulseColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'You',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Row(
        children: [
          Icon(Icons.local_fire_department, color: Colors.orange, size: 14),
          const SizedBox(width: 4),
          Text('${entry.streak} streak'),
          const SizedBox(width: 12),
          Icon(Icons.stars, color: Colors.amber, size: 14),
          const SizedBox(width: 4),
          Text('Level ${entry.level}'),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${entry.score}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            'points',
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentUserPosition() {
    final currentUser = _entries.firstWhere(
      (entry) => entry.isCurrentUser,
      orElse: () => _entries.last,
    );

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            PulseColors.primary.withValues(alpha: 0.1),
            PulseColors.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PulseColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage(currentUser.avatar),
            onBackgroundImageError: (error, stackTrace) {},
            child: currentUser.avatar.isEmpty ? const Icon(Icons.person) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Your Rank: #${currentUser.rank}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${currentUser.score} points',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: PulseColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Keep going to reach the top 3!',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getLeaderboardTitle() {
    switch (widget.leaderboardType) {
      case LeaderboardType.matches:
        return 'Match Masters';
      case LeaderboardType.conversations:
        return 'Chat Champions';
      case LeaderboardType.profileViews:
        return 'Most Viewed';
      case LeaderboardType.likesGiven:
        return 'Love Givers';
      case LeaderboardType.streak:
        return 'Streak Kings';
    }
  }

  String _getLeaderboardSubtitle() {
    switch (widget.leaderboardType) {
      case LeaderboardType.matches:
        return 'Most matches this week';
      case LeaderboardType.conversations:
        return 'Most active conversations';
      case LeaderboardType.profileViews:
        return 'Highest profile engagement';
      case LeaderboardType.likesGiven:
        return 'Spreading the most love';
      case LeaderboardType.streak:
        return 'Longest daily streaks';
    }
  }

  Color _getBadgeColor(BadgeType badgeType) {
    switch (badgeType) {
      case BadgeType.gold:
        return Colors.amber;
      case BadgeType.silver:
        return Colors.grey[400]!;
      case BadgeType.bronze:
        return Colors.brown;
      case BadgeType.none:
        return Colors.grey;
    }
  }
}

enum LeaderboardType {
  matches,
  conversations,
  profileViews,
  likesGiven,
  streak,
}

enum BadgeType { gold, silver, bronze, none }

class LeaderboardEntry {
  final String id;
  final String name;
  final int score;
  final int rank;
  final String avatar;
  final BadgeType badgeType;
  final bool isCurrentUser;
  final int streak;
  final int level;

  LeaderboardEntry({
    required this.id,
    required this.name,
    required this.score,
    required this.rank,
    required this.avatar,
    required this.badgeType,
    required this.isCurrentUser,
    required this.streak,
    required this.level,
  });
}
