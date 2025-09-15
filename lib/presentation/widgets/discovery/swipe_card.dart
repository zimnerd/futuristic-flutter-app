import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../domain/entities/user_profile.dart';
import '../../animations/pulse_animations.dart';
import '../../screens/profile/profile_details_screen.dart';

/// Enhanced swipeable card widget with smooth animations
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

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard>
    with TickerProviderStateMixin {
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
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _overlayController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _actionController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    // Create smooth animations with enhanced curves
    _scaleAnimation = Tween<double>(
      begin: 0.8, end: 1.0,
    ).animate(CurvedAnimation(
      parent: _photoController,
        curve: PulseCurves.easeOutQuart,
    ));

    // Start enter animations
    _startEnterAnimation();
  }

  void _startEnterAnimation() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _photoController.forward();
        Future.delayed(const Duration(milliseconds: 200), () {
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

  /// Show full profile details with swipe-down-to-dismiss
  void _showProfileDetails() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ProfileDetailsScreen(
          profile: widget.user,
          isOwnProfile: false,
          onLike: widget.onSwipeRight,
          onSuperLike: widget.onSwipeUp,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  Widget _buildPhotoIndicators() {
    if (widget.user.photos.length <= 1) return const SizedBox.shrink();
    
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Row(
        children: List.generate(
          widget.user.photos.length,
          (index) => Expanded(
            child: Container(
              height: 3,
              margin: EdgeInsets.only(
                right: index < widget.user.photos.length - 1 ? 4 : 0,
              ),
              decoration: BoxDecoration(
                color: index == _currentPhotoIndex 
                    ? Colors.white 
                    : Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getSwipeColor() {
    switch (widget.swipeDirection) {
      case SwipeDirection.left:
        return const Color(0xFFFF4458); // Red for nope
      case SwipeDirection.right:
        // Special handling for Super Like
        if (widget.isSuperLike) {
          return const Color(0xFF4FC3F7); // Blue/cyan for super like
        }
        return const Color(0xFF66D7A2); // Green for regular like
      case SwipeDirection.up:
        return const Color(0xFF4FC3F7); // Blue for super like (legacy)
      default:
        return Colors.grey;
    }
  }

  IconData _getSwipeIcon() {
    switch (widget.swipeDirection) {
      case SwipeDirection.left:
        return Icons.close;
      case SwipeDirection.right:
        // Special handling for Super Like
        if (widget.isSuperLike) {
          return Icons.star; // Star for super like
        }
        return Icons.favorite; // Heart for regular like
      case SwipeDirection.up:
        return Icons.star; // Star for super like (legacy)
      default:
        return Icons.help;
    }
  }

  String _getSwipeLabel() {
    switch (widget.swipeDirection) {
      case SwipeDirection.left:
        return 'NOPE';
      case SwipeDirection.right:
        // Special handling for Super Like
        if (widget.isSuperLike) {
          return 'SUPER LIKE';
        }
        return 'LIKE';
      case SwipeDirection.up:
        return 'SUPER LIKE'; // Legacy
      default:
        return '';
    }
  }

  Widget _buildUserInfo() {
    if (!widget.showDetails) return const SizedBox.shrink();
    
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.user.nameWithAge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                ),
                if (widget.user.isVerified) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF4FC3F7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ],
            ),
            if (widget.user.distanceString.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: Colors.white70,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.user.distanceString,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (widget.user.bio.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                widget.user.bio,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (widget.user.interests.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: widget.user.interests.take(3).map((interest) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      interest,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentPhoto = widget.user.photos.isNotEmpty 
        ? widget.user.photos[_currentPhotoIndex]
        : null;
    
    return AnimatedBuilder(
      animation: Listenable.merge([_photoController, _overlayController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              if (widget.onTap != null) {
                widget.onTap!();
              } else {
                _showProfileDetails();
              }
            },
            onTapDown: (_) {
              HapticFeedback.selectionClick();
              _actionController.forward();
            },
            onTapUp: (_) => _actionController.reverse(),
            onTapCancel: () => _actionController.reverse(),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  // Enhanced shadow with multiple layers for depth
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    offset: const Offset(0, 8),
                    blurRadius: 24,
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    offset: const Offset(0, 2),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    // Enhanced photo background with shimmer loading
                    Positioned.fill(
                      child: _buildEnhancedPhotoSection(currentPhoto),
                    ),

                    // Photo indicators with smooth transitions
                    _buildPhotoIndicators(),

                    // Swipe overlay with enhanced animations
                    if (widget.swipeProgress.abs() > 0.1)
                      _buildEnhancedSwipeOverlay(),

                    // Enhanced user info overlay with glassmorphism
                    if (widget.showDetails) _buildUserInfo(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Enhanced photo section with shimmer loading and smooth transitions
  Widget _buildEnhancedPhotoSection(ProfilePhoto? currentPhoto) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: currentPhoto != null
          ? CachedNetworkImage(
              key: ValueKey(currentPhoto.url),
              imageUrl: currentPhoto.url,
              fit: BoxFit.cover,
              placeholder: (context, url) => _buildShimmerPlaceholder(),
              errorWidget: (context, url, error) => _buildErrorPlaceholder(),
            )
          : _buildErrorPlaceholder(),
    );
  }

  /// Shimmer loading placeholder with modern design
  Widget _buildShimmerPlaceholder() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1.0, -0.3),
              end: Alignment(1.0, 0.3),
              colors: [Colors.grey[200]!, Colors.grey[100]!, Colors.grey[200]!],
              stops: [
                _shimmerController.value - 0.3,
                _shimmerController.value,
                _shimmerController.value + 0.3,
              ].map((e) => e.clamp(0.0, 1.0)).toList(),
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.image_outlined, size: 80, color: Colors.grey),
          ),
        );
      },
    );
  }

  /// Error placeholder with modern design
  Widget _buildErrorPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'Photo unavailable',
              style: TextStyle(color: Colors.grey, fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Enhanced swipe overlay with smooth animations
  Widget _buildEnhancedSwipeOverlay() {
    if (widget.swipeDirection == null || widget.swipeProgress.abs() < 0.1) {
      return const SizedBox.shrink();
    }

    final opacity = (widget.swipeProgress.abs() * 2).clamp(0.0, 1.0);
    final scale = (1.0 + widget.swipeProgress.abs() * 0.2).clamp(1.0, 1.2);
    final isSuperLike = widget.isSuperLike || widget.swipeDirection == SwipeDirection.up;
    
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: _getSwipeColor().withValues(alpha: opacity * 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            // Special sparkle effects for Super Like
            if (isSuperLike) ..._buildSparkleEffects(opacity),
            
            // Main overlay content
            Center(
              child: Transform.scale(
                scale: scale,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: _getSwipeColor(),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _getSwipeColor().withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                      // Extra glow for Super Like
                      if (isSuperLike)
                        BoxShadow(
                          color: _getSwipeColor().withValues(alpha: 0.6),
                          blurRadius: 24,
                          offset: const Offset(0, 0),
                        ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getSwipeIcon(),
                        color: Colors.white,
                        size: isSuperLike ? 32 : 28, // Larger icon for Super Like
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _getSwipeLabel(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSuperLike ? 20 : 18, // Larger text for Super Like
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build sparkle effects for Super Like
  List<Widget> _buildSparkleEffects(double opacity) {
    return [
      // Animated sparkles around the card
      Positioned(
        top: 50,
        left: 30,
        child: AnimatedBuilder(
          animation: _shimmerController,
          builder: (context, child) => Transform.rotate(
            angle: _shimmerController.value * 6.28,
            child: Opacity(
              opacity: opacity * 0.8,
              child: const Icon(
                Icons.star,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ),
      Positioned(
        top: 80,
        right: 40,
        child: AnimatedBuilder(
          animation: _shimmerController,
          builder: (context, child) => Transform.rotate(
            angle: -_shimmerController.value * 6.28,
            child: Opacity(
              opacity: opacity * 0.6,
              child: const Icon(
                Icons.star,
                color: Colors.white,
                size: 12,
              ),
            ),
          ),
        ),
      ),
      Positioned(
        bottom: 100,
        left: 50,
        child: AnimatedBuilder(
          animation: _shimmerController,
          builder: (context, child) => Transform.rotate(
            angle: _shimmerController.value * 4,
            child: Opacity(
              opacity: opacity * 0.7,
              child: const Icon(
                Icons.star,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ),
      ),
    ];
  }
}

/// Direction of swipe gesture
enum SwipeDirection {
  left,
  right,
  up,
}
