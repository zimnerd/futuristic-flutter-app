import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/user_profile.dart';
import '../../../core/utils/haptic_feedback_utils.dart';
import '../../animations/pulse_animations.dart';
import '../../navigation/app_router.dart';
import '../../screens/common/photo_preview_screen.dart';
import '../../screens/profile/profile_details_screen.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';
import '../common/robust_network_image.dart';
import '../verification/verification_badge.dart';
import '../dialogs/report_user_dialog.dart';

// Animation durations for consistent timing
class _SwipeCardConstants {
  static const Duration photoAnimationDuration = Duration(milliseconds: 800);
  static const Duration overlayAnimationDuration = Duration(milliseconds: 600);
  static const Duration actionAnimationDuration = Duration(milliseconds: 400);
  static const Duration shimmerAnimationDuration = Duration(milliseconds: 1500);
  static const Duration enterDelayDuration = Duration(milliseconds: 100);
  static const Duration overlayDelayDuration = Duration(milliseconds: 200);
  static const Duration photoSwitchDuration = Duration(milliseconds: 300);

  // Scale animation values
  static const double scaleBegin = 0.8;
  static const double scaleEnd = 1.0;

  // Swipe progress threshold
  static const double swipeProgressThreshold = 0.1;

  // UI dimensions
  static const double cardBorderRadius = 20.0;
  static const double photoIndicatorHeight = 3.0;
  static const double photoIndicatorSpacing = 4.0;
  static const double photoIndicatorRadius = 1.5;
  static const double userInfoHorizontalPadding = 20.0;
  static const double userInfoVerticalPadding = 16.0;
  static const double swipeOverlayHorizontalPadding = 24.0;
  static const double swipeOverlayVerticalPadding = 16.0;
  static const double swipeOverlayBorderRadius = 12.0;
  static const double swipeIconSize = 28.0;
  static const double swipeIconSpacing = 12.0;

  // Colors with opacity
  static const double overlayMaxOpacity = 0.2;
  static const double indicatorActiveOpacity = 1.0;
  static const double indicatorInactiveOpacity = 0.3;

  // Swipe colors
  static const Color likeColor = Color(0xFF4CAF50);
  static const Color nopeColor = Color(0xFFFF5722);
  static const Color superLikeColor = Color(0xFF2196F3);
}

/// Swipe direction configuration
class _SwipeConfig {
  const _SwipeConfig({
    required this.color,
    required this.icon,
    required this.label,
  });

  final Color color;
  final IconData icon;
  final String label;

  static const Map<SwipeDirection, _SwipeConfig> configs = {
    SwipeDirection.right: _SwipeConfig(
      color: _SwipeCardConstants.likeColor,
      icon: Icons.favorite,
      label: 'LIKE',
    ),
    SwipeDirection.left: _SwipeConfig(
      color: _SwipeCardConstants.nopeColor,
      icon: Icons.close,
      label: 'NOPE',
    ),
    SwipeDirection.up: _SwipeConfig(
      color: _SwipeCardConstants.superLikeColor,
      icon: Icons.star,
      label: 'SUPER LIKE',
    ),
  };

  static const _SwipeConfig? Function(SwipeDirection?) getConfig =
      _getConfigImpl;

  static _SwipeConfig? _getConfigImpl(SwipeDirection? direction) {
    return direction != null ? configs[direction] : null;
  }
}

/// Enhanced swipeable card widget with optimized performance
///
/// Performance optimizations:
/// - RepaintBoundary for isolated repaints
/// - Optimized transform operations
/// - Reduced unnecessary rebuilds
/// - Efficient animation listeners
/// - Pre-calculated shadows and decorations
///
/// Features:
/// - Beautiful photo display with modern animations
/// - User information overlay with glassmorphism
/// - Enhanced swipe gestures with haptic feedback
/// - Loading and error states with shimmer
/// - Premium features indicators with glow effects
/// - Smooth transitions and micro-interactions
class SwipeCard extends StatefulWidget {
  const SwipeCard({
    super.key,
    required this.user,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onSwipeUp,
    this.onTap,
    this.isAnimating = false,
    this.swipeProgress = 0.0,
    this.swipeDirection,
    this.showDetails = true,
    this.isSuperLike = false,
    this.compatibilityScore,
  });

  final UserProfile user;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onSwipeUp;
  final VoidCallback? onTap;
  final bool isAnimating;
  final double swipeProgress; // -1.0 to 1.0 (left to right)
  final SwipeDirection? swipeDirection;
  final bool showDetails;
  final bool isSuperLike; // Indicates if this is a super like action
  final double? compatibilityScore; // Compatibility percentage (0-100)

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard> with TickerProviderStateMixin {
  late AnimationController _photoController;
  late AnimationController _overlayController;
  late AnimationController _actionController;
  late AnimationController _shimmerController;
  late Animation<double> _scaleAnimation;

  final int _currentPhotoIndex = 0;

  @override
  void initState() {
    super.initState();

    // Enhanced animation controllers for smooth micro-interactions
    _photoController = AnimationController(
      duration: _SwipeCardConstants.photoAnimationDuration,
      vsync: this,
    );

    _overlayController = AnimationController(
      duration: _SwipeCardConstants.overlayAnimationDuration,
      vsync: this,
    );

    _actionController = AnimationController(
      duration: _SwipeCardConstants.actionAnimationDuration,
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: _SwipeCardConstants.shimmerAnimationDuration,
      vsync: this,
    )..repeat();

    // Create smooth animations with enhanced curves
    _scaleAnimation =
        Tween<double>(
          begin: _SwipeCardConstants.scaleBegin,
          end: _SwipeCardConstants.scaleEnd,
        ).animate(
          CurvedAnimation(
            parent: _photoController,
            curve: PulseCurves.easeOutQuart,
          ),
        );

    // Start enter animations
    _startEnterAnimation();
  }

  void _startEnterAnimation() {
    Future.delayed(_SwipeCardConstants.enterDelayDuration, () {
      if (mounted) {
        _photoController.forward();
        Future.delayed(_SwipeCardConstants.overlayDelayDuration, () {
          if (mounted) {
            _overlayController.forward();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _photoController.dispose();
    _overlayController.dispose();
    _actionController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  /// Show full profile details using GoRouter navigation
  void _showProfileDetails() {
    context.push(
      AppRoutes.profileDetails.replaceFirst(':profileId', widget.user.id),
      extra: {
        'profile': widget.user,
        'context': ProfileContext.discovery,
        'onLike': widget.onSwipeRight,
        'onDislike': widget.onSwipeLeft,
        'onSuperLike': widget.onSwipeUp,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentPhoto = widget.user.photos.isNotEmpty
        ? widget.user.photos[_currentPhotoIndex]
        : null;

    // Performance optimization: Use RepaintBoundary to isolate repaints
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_photoController, _overlayController]),
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: _PerformanceOptimizedCard(
              currentPhoto: currentPhoto,
              user: widget.user,
              actionController: _actionController,
              onTap: () {
                HapticFeedback.lightImpact();
                if (widget.onTap != null) {
                  widget.onTap!();
                } else {
                  _showProfileDetails();
                }
              },
              buildEnhancedPhotoSection: () =>
                  _buildEnhancedPhotoSection(currentPhoto),
              photoIndicators: _PhotoIndicators(
                photoCount: widget.user.photos.length,
                currentIndex: _currentPhotoIndex,
              ),
              userInfoOverlay: _UserInfoOverlay(
                user: widget.user,
                compatibilityScore: widget.compatibilityScore,
              ),
              swipeOverlay: _SwipeOverlay(
                swipeProgress: widget.swipeProgress,
                swipeDirection: widget.swipeDirection,
              ),
              showDetails: widget.showDetails,
            ),
          );
        },
      ),
    );
  }

  /// Enhanced photo section with shimmer loading and smooth transitions
  Widget _buildEnhancedPhotoSection(ProfilePhoto? currentPhoto) {
    return GestureDetector(
      onTap: () {
        if (currentPhoto != null) {
          PulseHaptics.light();
          final allPhotoUrls = widget.user.photos.map((p) => p.url).toList();
          final currentIndex = widget.user.photos.indexOf(currentPhoto);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PhotoPreviewScreen(
                images: allPhotoUrls,
                initialIndex: currentIndex,
                showReport: true,
                onReport: () {
                  final dialogContext = context;
                  Navigator.pop(dialogContext);
                  // Show report dialog
                  showDialog(
                    context: dialogContext,
                    builder: (_) => ReportUserDialog(
                      userId: widget.user.id,
                      userName: widget.user.name,
                    ),
                  );
                },
              ),
            ),
          );
        }
      },
      child: AnimatedSwitcher(
        duration: _SwipeCardConstants.photoSwitchDuration,
        child: currentPhoto != null
            ? RobustNetworkImage(
                key: ValueKey(currentPhoto.url),
                imageUrl: currentPhoto.url,
                blurhash:
                    currentPhoto.blurhash, // ✅ Pass blurhash for smooth loading
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              )
            : _buildErrorPlaceholder(),
      ),
    );
  }

  /// Error placeholder with modern design
  Widget _buildErrorPlaceholder() {
    return Container(
      color: context.surfaceVariantColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image_outlined, size: 80, color: context.onSurfaceVariantColor),
            const SizedBox(height: 8),
            Text(
              'Photo unavailable',
              style: TextStyle(color: context.onSurfaceVariantColor, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

/// User information overlay widget with glassmorphism effect
class _UserInfoOverlay extends StatelessWidget {
  const _UserInfoOverlay({required this.user, this.compatibilityScore});

  final UserProfile user;
  final double? compatibilityScore;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: _SwipeCardConstants.userInfoHorizontalPadding,
          vertical: _SwipeCardConstants.userInfoVerticalPadding,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.fromRGBO(0, 0, 0, 0), Color.fromRGBO(0, 0, 0, 0.8)],
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(_SwipeCardConstants.cardBorderRadius),
            bottomRight: Radius.circular(_SwipeCardConstants.cardBorderRadius),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${user.name}, ${user.age}',
                    style: TextStyle(
                      color: context.onSurfaceColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (compatibilityScore != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getCompatibilityColor(compatibilityScore!),
                          _getCompatibilityColor(
                            compatibilityScore!,
                          ).withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _getCompatibilityColor(
                            compatibilityScore!,
                          ).withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.favorite,
                          color: context.onSurfaceColor,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${compatibilityScore!.toInt()}%',
                          style: TextStyle(
                            color: context.onSurfaceColor,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                VerificationBadge(
                  isVerified: user.isVerified,
                  size: VerificationBadgeSize.small,
                ),
              ],
            ),
            if (user.bio.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                user.bio,
                style: TextStyle(color: context.textSecondary, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            // Badges row (occupation, education, etc)
            if (user.occupation != null || user.education != null) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Occupation badge
                  if (user.occupation != null)
                    _buildBadgePill(
                      context: context,
                      icon: Icons.work_outline,
                      label: user.occupation!,
                    ),
                  // Education badge
                  if (user.education != null)
                    _buildBadgePill(
                      context: context,
                      icon: Icons.school_outlined,
                      label: user.education!,
                    ),
                ],
              ),
            ],
            if (user.distanceKm != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: context.textSecondary,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    user.distanceString,
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
            // "Why matched?" button
            if (compatibilityScore != null) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  // Navigate to match explanation screen
                  context.push(
                    AppRoutes.matchExplanation,
                    extra: {
                      'profile': user,
                      'compatibilityScore': compatibilityScore,
                      'matchReasons': <String, dynamic>{
                        'sharedInterests': [],
                        'locationMatch': user.distanceKm != null,
                        'ageMatch': true,
                      },
                    },
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: context.onSurfaceColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: context.onSurfaceColor.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: context.onSurfaceColor,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Why matched?',
                        style: TextStyle(
                          color: context.onSurfaceColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds a badge pill for displaying profile attributes (occupation, education, etc.)
  Widget _buildBadgePill({
    required BuildContext context,
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: context.onSurfaceColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.onSurfaceColor.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: context.onSurfaceColor.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: context.onSurfaceColor, size: 12),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: context.onSurfaceColor,
              shadows: [
                Shadow(
                  color: context.onSurfaceColor.withValues(alpha: 0.2),
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Get color based on compatibility score
  Color _getCompatibilityColor(double score) {
    if (score >= 80) {
      return const Color(0xFF4CAF50); // Green for high compatibility
    } else if (score >= 60) {
      return const Color(0xFFFFC107); // Amber for medium-high compatibility
    } else if (score >= 40) {
      return const Color(0xFFFF9800); // Orange for medium compatibility
    } else {
      return const Color(0xFFFF5722); // Red for low compatibility
    }
  }
}

/// Photo indicators widget for multiple photos
class _PhotoIndicators extends StatelessWidget {
  const _PhotoIndicators({
    required this.photoCount,
    required this.currentIndex,
  });

  final int photoCount;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    if (photoCount <= 1) return const SizedBox.shrink();

    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Row(
        children: List.generate(
          photoCount,
          (index) => Expanded(
            child: Container(
              height: _SwipeCardConstants.photoIndicatorHeight,
              margin: EdgeInsets.only(
                right: index < photoCount - 1
                    ? _SwipeCardConstants.photoIndicatorSpacing
                    : 0,
              ),
              decoration: BoxDecoration(
                color: index == currentIndex
                    ? context.onSurfaceColor.withValues(
                        alpha: _SwipeCardConstants.indicatorActiveOpacity,
                      )
                    : context.onSurfaceColor.withValues(
                        alpha: _SwipeCardConstants.indicatorInactiveOpacity,
                      ),
                borderRadius: BorderRadius.circular(
                  _SwipeCardConstants.photoIndicatorRadius,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Swipe overlay widget with direction-based styling
class _SwipeOverlay extends StatelessWidget {
  const _SwipeOverlay({
    required this.swipeProgress,
    required this.swipeDirection,
  });

  final double swipeProgress;
  final SwipeDirection? swipeDirection;

  @override
  Widget build(BuildContext context) {
    // Early return for better performance
    if (swipeProgress.abs() <= _SwipeCardConstants.swipeProgressThreshold) {
      return const SizedBox.shrink();
    }

    final config = _SwipeConfig.getConfig(swipeDirection);
    if (config == null) return const SizedBox.shrink();

    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: config.color.withValues(
            alpha: swipeProgress.abs() * _SwipeCardConstants.overlayMaxOpacity,
          ),
          borderRadius: BorderRadius.circular(
            _SwipeCardConstants.cardBorderRadius,
          ),
        ),
        child: Center(
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: _SwipeCardConstants.swipeOverlayHorizontalPadding,
              vertical: _SwipeCardConstants.swipeOverlayVerticalPadding,
            ),
            decoration: BoxDecoration(
              color: config.color,
              borderRadius: BorderRadius.circular(
                _SwipeCardConstants.swipeOverlayBorderRadius,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  config.icon,
                  color: context.onSurfaceColor,
                  size: _SwipeCardConstants.swipeIconSize,
                ),
                SizedBox(width: _SwipeCardConstants.swipeIconSpacing),
                Text(
                  config.label,
                  style: TextStyle(
                    color: context.onSurfaceColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Performance-optimized card content to minimize rebuilds
class _PerformanceOptimizedCard extends StatelessWidget {
  const _PerformanceOptimizedCard({
    required this.currentPhoto,
    required this.user,
    required this.actionController,
    required this.onTap,
    required this.buildEnhancedPhotoSection,
    required this.photoIndicators,
    required this.userInfoOverlay,
    required this.swipeOverlay,
    required this.showDetails,
  });

  final ProfilePhoto? currentPhoto;
  final UserProfile user;
  final AnimationController actionController;
  final VoidCallback onTap;
  final Widget Function() buildEnhancedPhotoSection;
  final Widget photoIndicators;
  final Widget userInfoOverlay;
  final Widget swipeOverlay;
  final bool showDetails;

  // Pre-calculated decorations for better performance
  static const _cardDecoration = BoxDecoration(
    borderRadius: BorderRadius.all(
      Radius.circular(_SwipeCardConstants.cardBorderRadius),
    ),
    boxShadow: [
      BoxShadow(
        color: Color.fromRGBO(0, 0, 0, 0.15),
        offset: Offset(0, 8),
        blurRadius: 24,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: Color.fromRGBO(0, 0, 0, 0.08),
        offset: Offset(0, 2),
        blurRadius: 8,
        spreadRadius: 0,
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onTapDown: (_) {
        HapticFeedback.selectionClick();
        actionController.forward();
      },
      onTapUp: (_) => actionController.reverse(),
      onTapCancel: () => actionController.reverse(),
      child: Container(
        decoration: _cardDecoration,
        child: ClipRRect(
          borderRadius: BorderRadius.all(
            Radius.circular(_SwipeCardConstants.cardBorderRadius),
          ),
          child: Stack(
            children: [
              // Enhanced photo background with shimmer loading
              Positioned.fill(child: buildEnhancedPhotoSection()),

              // Photo indicators with smooth transitions
              photoIndicators,

              // Swipe overlay with enhanced animations
              swipeOverlay,

              // Enhanced user info overlay with glassmorphism
              if (showDetails) userInfoOverlay,
            ],
          ),
        ),
      ),
    );
  }
}

/// Direction of swipe gesture
enum SwipeDirection { left, right, up }
