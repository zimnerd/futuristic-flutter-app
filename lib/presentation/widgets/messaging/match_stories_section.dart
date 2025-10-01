import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pulse_dating_app/core/utils/logger.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../data/models/match_model.dart';
import '../../theme/pulse_colors.dart';

/// Stories-like horizontal scrollable match thumbnails
/// Shows matches that haven't been chatted with yet
class MatchStoriesSection extends StatelessWidget {
  final List<MatchStoryData> matches;
  final Function(MatchStoryData match) onMatchTap;
  final bool hasMore;
  final VoidCallback? onLoadMore;

  const MatchStoriesSection({
    super.key,
    required this.matches,
    required this.onMatchTap,
    this.hasMore = false,
    this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) return const SizedBox.shrink();

    return Container(
      height:
          134, // Precise height to prevent overflow: 24 (title) + 8 (gap) + 102 (content)
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title section: exactly 24px
          SizedBox(
            height: 24,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'New Matches',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: PulseColors.onSurface,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8), // Gap
          // Stories section: exactly 102px
          SizedBox(
            height: 102,
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollEndNotification &&
                    hasMore &&
                    onLoadMore != null) {
                  // Check if we're near the end (80% through)
                  final pixels = notification.metrics.pixels;
                  final maxScrollExtent = notification.metrics.maxScrollExtent;

                  if (pixels >= maxScrollExtent * 0.8) {
                    onLoadMore!();
                  }
                }
                return false;
              },
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount:
                    matches.length +
                    (hasMore ? 1 : 0), // Add 1 for loading indicator
                itemBuilder: (context, index) {
                  // Show loading indicator at the end
                  if (index == matches.length && hasMore) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  }
                  
                  final match = matches[index];
                  return _MatchStoryAvatar(
                    match: match,
                    onTap: () => onMatchTap(match),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchStoryAvatar extends StatelessWidget {
  final MatchStoryData match;
  final VoidCallback onTap;

  const _MatchStoryAvatar({
    required this.match,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 76, // Fixed width to prevent horizontal overflow
          height: 102, // Fixed height: 68 (avatar) + 4 (gap) + 30 (text area)
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar with border styling: exactly 68px
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: match.isSuperLike
                      ? const LinearGradient(
                          colors: [
                            Color(0xFFFFD700), // Gold
                            Color(0xFFFFA500), // Orange
                            Color(0xFFFF4500), // Red-orange
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : const LinearGradient(
                          colors: [PulseColors.primary, Color(0xFF8B5FFF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (match.isSuperLike
                                  ? const Color(0xFFFFD700)
                                  : PulseColors.primary)
                              .withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Container(
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: match.avatarUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: PulseColors.surfaceVariant,
                        child: const Icon(
                          Icons.person,
                          color: PulseColors.onSurfaceVariant,
                          size: 30,
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: PulseColors.surfaceVariant,
                        child: const Icon(
                          Icons.person,
                          color: PulseColors.onSurfaceVariant,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4), // Fixed 4px gap
              // Text area: exactly 30px
              SizedBox(
                width: 68,
                height: 30,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      match.name,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: PulseColors.onSurface,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    if (match.matchedTime != null)
                      Text(
                        _formatMatchTime(match.matchedTime!),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          color: PulseColors.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatMatchTime(DateTime matchTime) {
    final now = DateTime.now();
    final difference = now.difference(matchTime);


    // Handle edge cases
    if (difference.isNegative) {
      // Future time - might be a timezone issue or bad data
      AppLogger.debug('⚠️ Match time is in the future! Using "now" instead.');
      return 'now';
    }

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w';
    } else {
      final months = (difference.inDays / 30).floor();
      return '${months}mo';
    }
  }
}

/// Data model for match stories
class MatchStoryData {
  final String id;
  final String userId;
  final String name;
  final String avatarUrl;
  final bool isSuperLike;
  final DateTime? matchedTime;
  final UserProfile? userProfile;
  final String? conversationId;

  const MatchStoryData({
    required this.id,
    required this.userId,
    required this.name,
    required this.avatarUrl,
    this.isSuperLike = false,
    this.matchedTime,
    this.userProfile,
    this.conversationId,
  });

  /// Create from MatchModel and UserProfile
  factory MatchStoryData.fromMatch({
    required MatchModel match,
    required UserProfile userProfile,
    bool isSuperLike = false,
  }) {
    return MatchStoryData(
      id: match.id,
      userId: userProfile.id,
      name: userProfile.name,
      avatarUrl: userProfile.photos.isNotEmpty 
          ? userProfile.photos.first.url 
          : '',
      isSuperLike: isSuperLike,
      matchedTime: match.matchedAt,
      userProfile: userProfile,
    );
  }
}